# Stereo Wall Display

A Godot 4.7+ addon that turns one large 3D display wall into a single-wall "CAVE". It renders side-by-side stereo with off-axis projection and uses webcam head tracking, so the view shifts as people walk around the room.

![Godot 4.7+](https://img.shields.io/badge/Godot-4.7+-blue)
![License: MIT](https://img.shields.io/badge/License-MIT-green)

![Editor View](screenshots/editor.jpeg)

## How it works

- **You develop normally.** When you press Play in Godot, the rig runs in **Edit mode**: a regular window with one camera and no stereo or tracking. The wall shows as a blue see-through rectangle.
- **The wall computer runs the exported game.** Exported builds start in **Stereo mode** automatically. They use a machine config file for the wall's size and resolution and read head tracking from a small webcam program.

Things in front of the blue rectangle pop out of the screen in 3D. Things behind it appear inside the screen. Keep important content near or behind the wall, since objects that pop out too far are hard to look at.

---

## For developers

### 1. Install

1. Copy `addons/stereo_wall_display/` into your project's `addons/` folder, or install it from the Godot Asset Store.
2. Enable it under **Project → Project Settings → Plugins → Stereo Wall Display**.

### 2. Add the rig

Drag **`addons/stereo_wall_display/stereo_wall_rig.tscn`** into your 3D scene. Move and rotate it to where the viewer should start. The rig is your player, and the wall moves with it.

Pick a control scheme with the rig's **`controls`** setting:

| Controls | What it does |
|----------|--------------|
| **Walk** (default) | FPS style: walks on the ground with gravity and collisions, and can jump. |
| **Fly** | Moves freely in the look direction, straight through walls. |
| **None** | No built-in movement or mouse look. Move the rig from your own code (`rig.global_position = ...`), with an AnimationPlayer, or by making it a child of something that moves. |

- Nodes you add under `Room/Head` follow the viewer's head. Nodes under `Room` follow the rig.
- Other settings: `mode` (leave on **Auto**), `move_speed`, `jump_velocity`, look sensitivity, and `show_wall`.

See `addons/stereo_wall_display/examples/example_scene.tscn` for an example.

### 3. Develop

Press Play. You're in Edit mode, with no config file, webcam or 3D glasses needed. The hotkeys work in both modes. On a Mac laptop, hold **Fn** for F-keys.

| Key | Action |
|-----|--------|
| WASD / Left stick | Move |
| Mouse / Right stick | Look |
| Shift / Left stick click | Move faster |
| Space / A | Jump (Walk) |
| E / RB, Q / LB | Up, down (Fly) |
| R | Reset position |
| F1 | Help |
| F2 | Switch Edit ⇄ Stereo (to preview the wall output) |
| F3 | 3D on/off (mono) |
| F4 | Swap left/right eyes |
| F5 | Head tracking on/off |
| F6 | Calibrate head tracking |
| Esc | Quit |

You can rebind the F-keys, R and Esc in **Project Settings → Input Map** (the `stereo_*` actions). They keep working when `controls` is None.

### 4. Build for the wall

1. **Project → Export**, add a **Windows Desktop** preset, and export to an empty folder, e.g. `StereoWall/`.
2. Copy everything in **`addons/stereo_wall_display/wall_kit/`** into that folder, except `.venv` and `face_landmarker.task` if you have them.
3. In that folder:
   - Rename `STEREO_CONFIG_GODOT.example.cfg` to **`STEREO_CONFIG_GODOT.cfg`** and fill in the wall's measurements.
   - Open `START_WALL.bat` in a text editor and set `GAME=` to your `.exe` name.
4. Give the folder to whoever sets up the wall. `README.txt` inside it has their instructions.

The folder should look like this:

```
StereoWall/
├─ MyGame.exe, MyGame.pck      ← your export
├─ STEREO_CONFIG_GODOT.cfg     ← wall settings
├─ START_WALL.bat              ← double-click to run everything
├─ head_tracker.bat            ← webcam tracking (installs itself on first run)
├─ head_sender.py, requirements.txt
└─ README.txt                  ← instructions for the wall operator
```

To test the exported game on your own machine without the wall output, run it with `--edit`. The command-line flags `--stereo` and `--edit` override Auto mode.

### Testing head tracking locally

1. Double-click `addons/stereo_wall_display/wall_kit/head_tracker_mac.command` (Mac/Linux) or `head_tracker.bat` (Windows). The first run installs MediaPipe, and a camera preview opens.
2. In Godot, run **`addons/stereo_wall_display/examples/head_tracking_demo.tscn`**. A side camera shows your head (the green ball) in front of the wall.
3. Press F6 to calibrate, then move around.

On a Mac, allow Camera access for Terminal in **System Settings → Privacy & Security → Camera**.

---

## For the wall setup

See **[`wall_kit/README.txt`](addons/stereo_wall_display/wall_kit/README.txt)**: one-time setup, daily use and troubleshooting, written for non-developers.

---

## Reference

### Machine config (`STEREO_CONFIG_GODOT.cfg`)

The rig looks for the file in this order:
1. The path in the `STEREO_WALL_CONFIG` environment variable
2. Your home folder
3. Next to the game `.exe`

Without a file, it uses defaults. Every setting is explained in [`STEREO_CONFIG_GODOT.example.cfg`](addons/stereo_wall_display/wall_kit/STEREO_CONFIG_GODOT.example.cfg).

Room coordinates are in meters. The origin is the floor under the **sweet spot** (the ideal viewing position), +X is right, +Y is up, and the wall is `wall_distance` in front, at -Z.

### Head tracking

Godot listens on UDP port 4242 for [OpenTrack](https://github.com/opentrack/opentrack)-format packets (6 doubles: x, y, z in cm, then yaw, pitch and roll). `head_sender.py` sends these from a webcam using Google's free MediaPipe Face Landmarker. OpenTrack itself works too, with any of its trackers (for example OptiTrack or its own webcam tracker), with no changes on the Godot side.

Calibration (F6) records where the person standing on the sweet spot is. After that, movement is tracked relative to that spot. Webcam depth is estimated from the distance between the eyes, so it's approximate.

## Publishing (maintainers)

See [PUBLISHING.md](PUBLISHING.md).

## License

MIT, see [LICENSE](LICENSE).
