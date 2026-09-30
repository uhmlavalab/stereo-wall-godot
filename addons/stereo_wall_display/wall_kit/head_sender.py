"""Webcam head tracker: MediaPipe Face Landmarker -> OpenTrack UDP packets for Godot.

Each packet is 6 little-endian doubles: x, y, z (cm), yaw, pitch, roll (always 0).
Axes: +x = viewer's right, +y = up, +z = away from the camera.
Place the webcam at the wall, facing the viewer.
"""
import argparse
import math
import socket
import struct
import time
import urllib.request
from pathlib import Path

import cv2
import mediapipe as mp
from mediapipe.tasks.python import BaseOptions, vision

IPD_M = 0.063  # Average distance between pupils, used to estimate depth
LEFT_IRIS, RIGHT_IRIS = 468, 473  # Iris center landmarks
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
            a, b = lm[LEFT_IRIS], lm[RIGHT_IRIS]
            iris_px = math.hypot((a.x - b.x) * w, (a.y - b.y) * h)
            if iris_px > 1:
                # Pinhole camera: depth from known eye spacing, then back-project the eye midpoint.
                z = focal * IPD_M / iris_px
                u, v = (a.x + b.x) / 2 * w, (a.y + b.y) / 2 * h
                x = -(u - w / 2) * z / focal  # Camera image is mirrored relative to the viewer
                y = -(v - h / 2) * z / focal
                packet = struct.pack("<6d", x * 100, y * 100, z * 100, 0, 0, 0)
                sock.sendto(packet, (args.host, args.port))
                if args.preview:
                    cv2.circle(frame, (int(u), int(v)), 6, (0, 255, 0), -1)
                    text = f"x={x:+.2f}  y={y:+.2f}  z={z:.2f} m"
                    cv2.putText(frame, text, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0), 2)

        if args.preview:
            cv2.imshow("head_sender (q to quit)", frame)
            if cv2.waitKey(1) & 0xFF == ord("q"):
                break
    capture.release()


if __name__ == "__main__":
    main()
