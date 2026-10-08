# Stereo Wall Display

Turns a 3D display wall into a single-wall "CAVE": side-by-side stereo with off-axis projection. Godot 4.7+.

Full docs: https://github.com/uhmlavalab/stereo-wall-godot

## Quick start

1. Drag `stereo_wall_rig.tscn` into your scene where the viewer starts.
2. Set `controls` on the rig: **Walk**, **Fly** or **None** (move it yourself).
3. Press Play. You get a normal window, and the blue rectangle marks the wall.
4. For the wall, export a Windows `.exe` and put it in the wall PC's builds folder. The wall's settings live in `C:\StereoWallGodot\STEREO_CONFIG_GODOT.cfg`; `wall_kit/README.md` covers the one-time setup.

Examples are in `examples/`.

## Keys

**Hotkeys** (always on, so don't reuse them in your app): F1 help · F2 Edit/Stereo · F3 3D on/off · F4 swap eyes · Esc quit

**Movement** (off when `controls` is None, which frees these keys): WASD/mouse or gamepad · Shift fast · Space jump (Walk) · E/Q up/down (Fly) · R reset

MIT license, see LICENSE.
