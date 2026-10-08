"""Webcam head tracker -> OpenTrack UDP packets for Godot.

Each packet is 6 little-endian doubles: x, y, z (cm), yaw, pitch, roll (always 0).
Axes: +x = viewer's right, +y = up, +z = away from the camera.
Place the webcam at the wall, facing the viewer.

Two ways to find the head:
  Face (default): MediaPipe face landmarks. The eyes are never used, so glasses are
    okay: the pose comes from forehead, nose, mouth, chin and cheek points fitted to
    an average 3D face.
  Marker (--marker WIDTH_CM): a printed ArUco marker taped to the 3D glasses or a
    headband. Most reliable with 3D glasses. The first run saves marker.png to print.
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

# Landmark index -> position on MediaPipe's average face (cm, +y up, +z out of the face).
# All are outside the area covered by glasses: forehead, nose, mouth, chin, cheeks.
FACE = {10: (0, 8.26, 4.48), 151: (0, 6.55, 5.03), 1: (0, -1.13, 7.48), 2: (0, -2.09, 6.06),
        61: (-2.46, -4.34, 4.28), 291: (2.46, -4.34, 4.28), 152: (0, -9.4, 4.26),
        132: (-7.27, -2.89, -2.25), 361: (7.27, -2.89, -2.25), 234: (-7.66, 0.67, -2.44), 454: (7.66, 0.67, -2.44)}
FACE_MODEL = np.array(list(FACE.values()), dtype=np.float64)
EYES = np.array([0, 2.63, 3.47])  # Midpoint between the eyes on the same face
MARKER_ID = 0
MARKER_PATH = Path(__file__).with_name("marker.png")
MAX_JUMP_CM = 25  # A bigger jump in one frame is a glitch, unless it lasts JUMP_FRAMES frames
JUMP_FRAMES = 5
MODEL_PATH = Path(__file__).with_name("face_landmarker.task")
MODEL_URL = ("https://storage.googleapis.com/mediapipe-models/face_landmarker/"
             "face_landmarker/float16/latest/face_landmarker.task")  # Free, Apache 2.0


def open_camera(args):
    capture = cv2.VideoCapture(args.camera)
    if not capture.isOpened():
        raise SystemExit(f"Could not open camera {args.camera}. On macOS, allow Camera access for your terminal "
                         "(System Settings > Privacy & Security > Camera).")
    # Webcams often start at 640x480; ask for widescreen (MJPG is needed for HD on many USB webcams).
    capture.set(cv2.CAP_PROP_FOURCC, cv2.VideoWriter_fourcc(*"MJPG"))
    capture.set(cv2.CAP_PROP_FRAME_WIDTH, args.width)
    capture.set(cv2.CAP_PROP_FRAME_HEIGHT, args.height)
    w, h = capture.get(cv2.CAP_PROP_FRAME_WIDTH), capture.get(cv2.CAP_PROP_FRAME_HEIGHT)
    print(f"Camera {args.camera}: {w:.0f}x{h:.0f}")
    return capture


def make_face_finder():
    import mediapipe as mp
    from mediapipe.tasks.python import BaseOptions, vision
    if not MODEL_PATH.exists():
        print(f"Downloading model to {MODEL_PATH} ...")
        urllib.request.urlretrieve(MODEL_URL, MODEL_PATH)
    landmarker = vision.FaceLandmarker.create_from_options(vision.FaceLandmarkerOptions(
        base_options=BaseOptions(model_asset_path=str(MODEL_PATH)), running_mode=vision.RunningMode.VIDEO,
        min_face_detection_confidence=0.3, min_face_presence_confidence=0.3, min_tracking_confidence=0.3))

    def find(frame, camera):
        """Eye midpoint in camera space (cm), plus the image points used, or None."""
        h, w = frame.shape[:2]
        image = mp.Image(image_format=mp.ImageFormat.SRGB, data=cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
        result = landmarker.detect_for_video(image, int(time.monotonic() * 1000))
        if not result.face_landmarks:
            return None
        lm = result.face_landmarks[0]
        points = np.array([(lm[i].x * w, lm[i].y * h) for i in FACE])
        ok, rvec, tvec = cv2.solvePnP(FACE_MODEL, points, camera, None, flags=cv2.SOLVEPNP_SQPNP)
        return (cv2.Rodrigues(rvec)[0] @ EYES + tvec.ravel(), points) if ok else None
    return find


def make_marker_finder(width_cm):
    dictionary = cv2.aruco.getPredefinedDictionary(cv2.aruco.DICT_4X4_50)
    if not MARKER_PATH.exists():
        # 4x4 cells + black border = 6 cells; the white margin makes it easy to cut out.
        marker = cv2.aruco.generateImageMarker(dictionary, MARKER_ID, 600)
        cv2.imwrite(str(MARKER_PATH), cv2.copyMakeBorder(marker, 100, 100, 100, 100, cv2.BORDER_CONSTANT, value=255))
        print(f"Saved {MARKER_PATH}. Print it, measure the black square and pass that width to --marker.")
    detector = cv2.aruco.ArucoDetector(dictionary)
    s = width_cm / 2
    corners_3d = np.array([(-s, s, 0), (s, s, 0), (s, -s, 0), (-s, -s, 0)], dtype=np.float64)

    def find(frame, camera):
        """Marker center in camera space (cm), plus its corners, or None."""
        corners, ids, _ = detector.detectMarkers(frame)
        for c, i in zip(corners, ids.ravel() if ids is not None else []):
            if i == MARKER_ID:
                ok, _, tvec = cv2.solvePnP(corners_3d, c[0], camera, None, flags=cv2.SOLVEPNP_IPPE_SQUARE)
                return (tvec.ravel(), c[0]) if ok else None
        return None
    return find


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--camera", type=int, default=0, help="webcam index")
    parser.add_argument("--width", type=int, default=1280, help="requested camera width")
    parser.add_argument("--height", type=int, default=720, help="requested camera height")
    parser.add_argument("--fov", type=float, default=60.0, help="horizontal camera FOV in degrees")
    parser.add_argument("--marker", type=float, help="track a printed marker this wide (cm) instead of the face")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=4242)
    parser.add_argument("--preview", action="store_true", help="show the camera image")
    args = parser.parse_args()

    capture = open_camera(args)
    find = make_marker_finder(args.marker) if args.marker else make_face_finder()
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    print(f"Tracking {'marker' if args.marker else 'face'}, sending to {args.host}:{args.port}. Ctrl+C to stop.")
    last, jumps = None, 0

    while capture.isOpened():
        ok, frame = capture.read()
        if not ok:
            break
        h, w = frame.shape[:2]
        focal = (w / 2) / math.tan(math.radians(args.fov) / 2)  # In pixels
        found = find(frame, np.array([[focal, 0, w / 2], [0, focal, h / 2], [0, 0, 1]]))

        if found:
            (cx, cy, cz), points = found  # Camera space: +x image right, +y image down, +z forward
            head = np.array([-cx, -cy, cz])  # Camera image is mirrored relative to the viewer
            jumps = jumps + 1 if last is not None and np.linalg.norm(head - last) > MAX_JUMP_CM else 0
            if jumps == 0 or jumps >= JUMP_FRAMES:
                last, jumps = head, 0
                sock.sendto(struct.pack("<6d", *head, 0, 0, 0), (args.host, args.port))

        if args.preview:
            if found:
                for u, v in points:
                    cv2.circle(frame, (int(u), int(v)), 4, (0, 255, 0), -1)
                text, color = "x={:+.2f}  y={:+.2f}  z={:.2f} m".format(*last / 100), (0, 255, 0)
            else:
                text, color = "LOST: no " + ("marker" if args.marker else "face"), (0, 0, 255)
            cv2.putText(frame, text, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.8, color, 2)
            cv2.imshow("head_sender (q to quit)", frame)
            if cv2.waitKey(1) & 0xFF == ord("q"):
                break
    capture.release()


if __name__ == "__main__":
    main()
