# Stereo Wall Display

A Godot 4.7+ addon that turns one 3D display wall into a single-wall "CAVE". It renders side-by-side stereo with off-axis projection and uses webcam head tracking.

Full documentation: https://github.com/uhmlavalab/stereo-wall-godot

## Quick start

1. Enable the plugin: **Project → Project Settings → Plugins**.
2. Drag `stereo_wall_rig.tscn` into your scene and place it where the viewer starts.
3. Pick `controls` on the rig: **Walk** (FPS with gravity), **Fly** (free movement) or **None** (drive the rig from your own code).
4. Press Play. **Edit mode** gives you a normal window, and the wall shows as a blue rectangle: things in front of it pop out, things behind it sit inside the screen.
5. Exported builds start in **Stereo mode** automatically. To set up the wall, copy the `wall_kit/` folder next to your exported game and follow `wall_kit/README.txt`.

Examples are in `examples/`.

## Keys

WASD/Mouse or gamepad move and look · Shift fast · Space jump (Walk) · E/Q up/down (Fly) · R reset · F1 help · F2 Edit/Stereo · F3 3D on/off · F4 swap eyes · F5 tracking · F6 calibrate · Esc quit

## License

MIT, see LICENSE.
