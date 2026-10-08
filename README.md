# Stereo Wall Display

A Godot 4.7+ addon that turns a large 3D display wall into a single-wall "CAVE": side-by-side stereo with off-axis projection from a fixed viewer position (the "sweet spot").

![Godot 4.7+](https://img.shields.io/badge/Godot-4.7+-blue)
![License: MIT](https://img.shields.io/badge/License-MIT-green)

![Editor View](screenshots/editor.jpeg)

- **In Godot (Play):** Edit mode. A normal window with one camera; no stereo or config needed.
- **Exported build:** Stereo mode. Reads the wall's machine config.

The wall appears as a blue see-through rectangle. Objects in front of it pop out of the screen; objects behind it sit inside. Keep important content near or behind the wall.

## Quick start

1. Copy `addons/stereo_wall_display/` into your project (or install it from the Asset Library).
2. Drag `addons/stereo_wall_display/stereo_wall_rig.tscn` into your scene where the viewer starts. The rig is the player; the wall moves with it.
3. Set the rig's `controls`:
   - **Walk** (default): FPS with gravity, collisions and jump.
   - **Fly**: free movement through walls.
   - **None**: move the rig yourself (code, AnimationPlayer, or parent it to something).
4. Press Play.

Nodes under `Room/Head` sit at the viewer's eyes; nodes under `Room` follow the rig. See `addons/stereo_wall_display/examples/example_scene.tscn`.

## Keys

On a Mac laptop, hold **Fn** for F-keys.

**Hotkeys** are always on, in every mode. Don't use these keys for anything else in your app.

| Key | Action |
|-----|--------|
| F1 | Help |
| F2 | Edit ⇄ Stereo (preview wall output) |
| F3 | 3D on/off |
| F4 | Swap eyes |
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

1. **Project → Export** a **Windows Desktop** build. Turn on **Embed PCK** to get a single `.exe`.
2. Put the `.exe` in the wall PC's builds folder and double-click it. Exported builds start in stereo.

The wall PC needs a one-time setup: its measurements go in `C:\StereoWallGodot\STEREO_CONFIG_GODOT.cfg`, which every game on that PC shares. See [`wall_kit/README.md`](addons/stereo_wall_display/wall_kit/README.md).

`--edit` and `--stereo` on the command line override the automatic mode.

## Reference

**Machine config.** `STEREO_CONFIG_GODOT.cfg` always lives in `C:\StereoWallGodot\` on Windows (`~/StereoWallGodot/` on Mac/Linux). The app never writes to it, and the editor preview uses it too, so copy the wall PC's file to each developer's computer. Any key the file doesn't set (or every key, when there is no file) comes from the rig's **Wall** settings in the Inspector, which default to LAVA lab's wall. Every setting is documented in [the example file](addons/stereo_wall_display/wall_kit/STEREO_CONFIG_GODOT.example.cfg). Coordinates are in meters: origin on the floor under the sweet spot, +X right, +Y up, wall at -Z.

**Publishing:** see [PUBLISHING.md](PUBLISHING.md). **License:** MIT, see [LICENSE](LICENSE).
