# Stereo Wall PC: Setup and Daily Use

## One-time setup

1. Put a tape mark on the floor where the viewer should stand.
2. Create the folder `C:\StereoWallGodot` and move `STEREO_CONFIG_GODOT.example.cfg` into it, renamed to `STEREO_CONFIG_GODOT.cfg`. All wall games use this one file. Open it in Notepad and set:

   | Setting | Meaning |
   |---------|---------|
   | `wall_width`, `wall_height` | Size of the wall picture (meters) |
   | `wall_center_height` | Floor to the middle of the wall |
   | `wall_distance` | Tape mark to the wall |
   | `wall_offset_x` | Wall center right (+) or left (-) of the tape mark; 0 = centered |
   | `eye_height` | Floor to the viewer's eyes (meters) |

## Every day

1. Double-click a game's `.exe` in the builds folder.
2. Stand on the tape mark for the best 3D.
3. Press **Esc** to quit.

## Keys

| Key | Action |
|-----|--------|
| F1 | Help |
| F2 | Switch Edit/Stereo |
| F3 | 3D on/off |
| F4 | Swap left/right eyes |
| Esc | Quit |
| WASD / mouse / gamepad | Move and look |
| R | Reset position |

## Troubleshooting

| Problem | Fix |
|---------|-----|
| 3D looks wrong / hurts eyes | Press F4. |
| Picture on the wrong screen | Change `window_position` in the config. |
