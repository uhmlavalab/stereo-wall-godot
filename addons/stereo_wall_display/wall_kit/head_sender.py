"""Webcam head tracker: MediaPipe Face Landmarker -> OpenTrack UDP packets for Godot.

Each packet is 6 little-endian doubles: x, y, z (cm), yaw, pitch, roll (always 0).
Axes: +x = viewer's right, +y = up, +z = away from the camera.
Place the webcam at the wall, facing the viewer.

Works with 3D shutter glasses: the eyes are never used. The head pose comes from
forehead, nose, mouth, chin and cheek points fitted to an average 3D face, and the
point between the eyes is computed from that pose.
"""
import argparse
import math
import socket
import struct
import time
import urllib.request
from pathlib import Path

import cv2
import numpy as np
import mediapipe as mp
from mediapipe.tasks.python import BaseOptions, vision

# Landmark index -> position on MediaPipe's average face (cm, +y up, +z out of the face).
# All are outside the area covered by glasses: forehead, nose, mouth, chin, cheeks.
FACE = {10: (0, 8.26, 4.48), 151: (0, 6.55, 5.03), 1: (0, -1.13, 7.48), 2: (0, -2.09, 6.06),
        61: (-2.46, -4.34, 4.28), 291: (2.46, -4.34, 4.28), 152: (0, -9.4, 4.26),
        132: (-7.27, -2.89, -2.25), 361: (7.27, -2.89, -2.25), 234: (-7.66, 0.67, -2.44), 454: (7.66, 0.67, -2.44)}
MODEL = np.array(list(FACE.values()), dtype=np.float64)
EYES = np.array([0, 2.63, 3.47])  # Midpoint between the eyes on the same face
MAX_JUMP_CM = 25  # A bigger jump in one frame is a glitch, unless it lasts JUMP_FRAMES frames
JUMP_FRAMES = 5
MODEL_PATH = Path(__file__).with_name("face_landmarker.task")
MODEL_URL = ("https://storage.googleapis.com/mediapipe-models/face_landmarker/"
             "face_landmarker/float16/latest/face_landmarker.task")  # Free, Apache 2.0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--camera", type=int, default=0, help="webcam index")
    parser.add_argument("--fov", type=float, default=60.0, help="horizontal camera FOV in degrees")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=4242)
    parser.add_argument("--preview", action="store_true", help="show the camera image")
    args = parser.parse_args()

    capture = cv2.VideoCapture(args.camera)
    if not capture.isOpened():
        raise SystemExit(f"Could not open camera {args.camera}. On macOS, allow Camera access for your terminal "
                         "(System Settings > Privacy & Security > Camera).")
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    if not MODEL_PATH.exists():
        print(f"Downloading model to {MODEL_PATH} ...")
        urllib.request.urlretrieve(MODEL_URL, MODEL_PATH)
    landmarker = vision.FaceLandmarker.create_from_options(vision.FaceLandmarkerOptions(
        base_options=BaseOptions(model_asset_path=str(MODEL_PATH)),
        running_mode=vision.RunningMode.VIDEO))
    print(f"Sending head position to {args.host}:{args.port}. Ctrl+C to stop.")
    last, jumps = None, 0

    while capture.isOpened():
        ok, frame = capture.read()
        if not ok:
            break
        h, w = frame.shape[:2]
        focal = (w / 2) / math.tan(math.radians(args.fov) / 2)  # In pixels
        image = mp.Image(image_format=mp.ImageFormat.SRGB, data=cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
        result = landmarker.detect_for_video(image, int(time.monotonic() * 1000))

        if result.face_landmarks:
            lm = result.face_landmarks[0]
            points = np.array([(lm[i].x * w, lm[i].y * h) for i in FACE])
            camera = np.array([[focal, 0, w / 2], [0, focal, h / 2], [0, 0, 1]])
            ok, rvec, tvec = cv2.solvePnP(MODEL, points, camera, None, flags=cv2.SOLVEPNP_SQPNP)
            if ok:
                # Eye midpoint in camera space (cm; +x image right, +y image down, +z forward).
                cx, cy, cz = cv2.Rodrigues(rvec)[0] @ EYES + tvec.ravel()
                head = np.array([-cx, -cy, cz])  # Camera image is mirrored relative to the viewer
                jumps = jumps + 1 if last is not None and np.linalg.norm(head - last) > MAX_JUMP_CM else 0
                if jumps == 0 or jumps >= JUMP_FRAMES:
                    last, jumps = head, 0
                    sock.sendto(struct.pack("<6d", *head, 0, 0, 0), (args.host, args.port))
                if args.preview:
                    for u, v in points:
                        cv2.circle(frame, (int(u), int(v)), 3, (0, 255, 0), -1)
                    text = "x={:+.2f}  y={:+.2f}  z={:.2f} m".format(*last / 100)
                    cv2.putText(frame, text, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0), 2)

        if args.preview:
            cv2.imshow("head_sender (q to quit)", frame)
            if cv2.waitKey(1) & 0xFF == ord("q"):
                break
    capture.release()


if __name__ == "__main__":
    main()
