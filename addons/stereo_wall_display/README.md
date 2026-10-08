# Stereo Wall Display: Plugin Usage

For people making Godot apps for the stereo display wall. Godot 4.7+.

You don't need to set up the display wall itself. The display wall PC already knows its own size and settings.

## Quick start

1. Install the addon (see the [download steps](https://github.com/uhmlavalab/stereo-wall-godot#download)).
2. Drag `addons/stereo_wall_display/stereo_wall_rig.tscn` into your scene where the viewer should start. The rig is the player.
3. Pick the rig's **Controls** in the Inspector:
   - **Walk**: first-person movement with gravity, collisions and jumping.
   - **Fly**: free movement, straight through walls.
   - **None**: no built-in movement. Move the rig yourself (code, AnimationPlayer, or parent it to something).
4. Press Play.

See `examples/example_scene.tscn` for a working scene.

## What you see

- **Pressing Play in Godot** gives **Edit mode**: a normal window with one camera. The display wall is shown as a blue see-through rectangle.
- **Your exported app** starts in **Stereo mode**: side-by-side left/right images for the display wall. Press F2 in either to switch.

Objects in front of the blue rectangle pop out of the display wall; objects behind it appear inside it. Keep important content near or behind it.

Nodes you add under the rig's `Room/Head` stay at the viewer's eyes; nodes under `Room` move with the rig.

## Display Wall settings

The rig's **Display Wall** section in the Inspector holds the display wall's size and position and the viewer's eye height. The defaults are the LAVA lab display wall, so **leave them alone** unless you are making an app for a different display wall.

When you run from Godot, these values are used. The exported app on the display wall PC uses that PC's own settings instead.

## Keys

On a Mac laptop, hold **Fn** for F-keys.

These work in every app. Don't use them for anything else.

| Key | Action |
|-----|--------|
| F1 | Help |
| F2 | Edit ⇄ Stereo |
| F3 | 3D on/off |
| F4 | Swap eyes |
| Esc | Quit |

Movement keys turn off when **Controls** is None, which frees them for your app.

| Key | Action |
|-----|--------|
| WASD / Left stick | Move (Shift / stick click = faster) |
| Mouse / Right stick | Look |
| Space / A | Jump (Walk) |
| E / RB, Q / LB | Up, down (Fly) |
| R | Reset to start position |

## Put your app on the display wall

1. **Project → Export** a **Windows Desktop** build. Turn on **Embed PCK** so it's a single `.exe`.
2. Copy the `.exe` into the display wall PC's apps folder (ask the display wall maintainer where it is).
3. Double-click it on the display wall PC. It starts in stereo, sized for the display wall.

To force a mode, start the app with `--edit` or `--stereo`.

MIT license, see LICENSE.
