# Stereo Wall Display

A Godot 4.7+ addon that turns a large 3D display wall into a single-wall "CAVE": side-by-side stereo with off-axis projection, plus webcam head tracking so the view follows the viewer.

![Godot 4.7+](https://img.shields.io/badge/Godot-4.7+-blue)
![License: MIT](https://img.shields.io/badge/License-MIT-green)

![Editor View](screenshots/editor.jpeg)

- **In Godot (Play):** Edit mode. A normal window with one camera; no stereo, tracking or config needed.
- **Exported build:** Stereo mode. Reads the wall's machine config and head tracking from a webcam program.

The wall appears as a blue see-through rectangle. Objects in front of it pop out of the screen; objects behind it sit inside. Keep important content near or behind the wall.

## Quick start

1. Copy `addons/stereo_wall_display/` into your project (or install it from the Asset Library).
2. Drag `addons/stereo_wall_display/stereo_wall_rig.tscn` into your scene where the viewer starts. The rig is the player; the wall moves with it.
3. Set the rig's `controls`:
   - **Walk** (default): FPS with gravity, collisions and jump.
   - **Fly**: free movement through walls.
   - **None**: move the rig yourself (code, AnimationPlayer, or parent it to something).
4. Press Play.

Nodes under `Room/Head` follow the viewer's head; nodes under `Room` follow the rig. See `addons/stereo_wall_display/examples/example_scene.tscn`.

## Keys

On a Mac laptop, hold **Fn** for F-keys.

**Hotkeys** are always on, in every mode. Don't use these keys for anything else in your app.

| Key | Action |
|-----|--------|
| F1 | Help |
| F2 | Edit ⇄ Stereo (preview wall output) |
| F3 | 3D on/off |
| F4 | Swap eyes |
| F5 | Head tracking on/off |
| F6 | Calibrate head tracking |
| Esc | Quit |

**Movement controls** turn off when `controls` is None, which frees these keys and buttons for your app.

| Key | Action |
|-----|--------|
| WASD / Left stick | Move (Shift / stick click = faster) |
| Mouse / Right stick | Look |
| Space / A | Jump (Walk) |
| E / RB, Q / LB | Up, down (Fly) |
| R | Reset to start position |

## Build for the wall

1. **Project → Export** a **Windows Desktop** build into an empty folder.
2. Copy the contents of `addons/stereo_wall_display/wall_kit/` into it (skip `.venv` and `face_landmarker.task`).
3. On the wall PC, create `C:\StereoWallGodot\`, put `STEREO_CONFIG_GODOT.example.cfg` in it renamed to `STEREO_CONFIG_GODOT.cfg`, and enter the wall's measurements. Every game on that PC shares this one file.
4. Set `GAME=` in `START_WALL.bat` to your `.exe` name.
5. Hand the folder over. `README.txt` inside tells the operator what to do.

```
StereoWall/
├─ MyGame.exe, MyGame.pck      your export
├─ START_WALL.bat              starts tracking + game
├─ head_tracker.bat            webcam tracking (installs itself)
├─ head_sender.py, requirements.txt
└─ README.txt                  operator instructions
```

`--edit` and `--stereo` on the command line override the automatic mode.

## Test head tracking locally

1. Run `addons/stereo_wall_display/wall_kit/head_tracker_mac.command` (Mac/Linux) or `head_tracker.bat` (Windows). The first run installs MediaPipe and opens a camera preview.
2. Run `addons/stereo_wall_display/examples/head_tracking_demo.tscn`. The green ball is your head.
3. Press F6 to calibrate, then move around.

On a Mac, allow Camera access for Terminal in **System Settings → Privacy & Security → Camera**.

## Reference

**Machine config.** `STEREO_CONFIG_GODOT.cfg` always lives in `C:\StereoWallGodot\` on Windows (`~/StereoWallGodot/` on Mac/Linux). The app never writes to it. F6 saves its calibration to `STEREO_CALIBRATION_GODOT.cfg` in the same folder (delete it to reset). Missing keys use defaults. Every setting is documented in [the example file](addons/stereo_wall_display/wall_kit/STEREO_CONFIG_GODOT.example.cfg). Coordinates are in meters: origin on the floor under the sweet spot, +X right, +Y up, wall at -Z.

**Head tracking.** Godot listens on UDP 4242 for [OpenTrack](https://github.com/opentrack/opentrack)-format packets (x, y, z in cm, then yaw, pitch, roll). `head_sender.py` sends these from a webcam using MediaPipe; OpenTrack itself also works. F6 records the sweet-spot position, and movement is measured from there. It never looks at the eyes, so 3D shutter glasses don't confuse it: the head pose is fitted from forehead, nose, mouth, chin and cheek points on an average face. Depth is approximate (faces vary in size).

**Publishing:** see [PUBLISHING.md](PUBLISHING.md). **License:** MIT, see [LICENSE](LICENSE).
