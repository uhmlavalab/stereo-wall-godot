# Display Wall Setup

For whoever sets up and maintains the display wall PC (Windows). This is done once per PC. App developers don't need it.

Every app made with this addon reads one settings file on the PC, so the display wall's measurements live in one place. Apps never change this file.

## 1. Mark where the viewer stands

Put a tape mark on the floor where the viewer should stand, centered in front of the display wall.

## 2. Create the settings file

1. Create the folder `C:\StereoWallGodot`.
2. Copy `STEREO_CONFIG_GODOT.example.cfg` (in this folder) into it and rename it to `STEREO_CONFIG_GODOT.cfg`.
3. Open it in Notepad and set:

   | Setting | What to measure or enter |
   |---------|--------------------------|
   | `resolution_width`, `resolution_height` | Pixels per eye (the app window is twice as wide) |
   | `window_position` | Where the app window starts, if the display wall isn't the main screen |
   | `wall_width`, `wall_height` | Size of the display wall picture, in meters |
   | `wall_center_height` | Floor to the middle of the display wall |
   | `wall_distance` | Tape mark to the display wall |
   | `wall_offset_x` | Display wall center right (+) or left (-) of the tape mark; 0 = centered |
   | `eye_height` | Floor to the viewer's eyes |

   Any setting you leave out uses the LAVA lab display wall's value. Changes take effect the next time an app starts.

## 3. Make an apps folder

Pick one folder for app builds, for example `C:\WallApps`, and tell app developers to put their `.exe` there.

## Running an app

Double-click the app's `.exe`. It opens across the display wall in 3D. Stand on the tape mark for the best 3D, and press **Esc** to quit.

| Key | Action |
|-----|--------|
| F1 | Help |
| F2 | Switch Edit/Stereo |
| F3 | 3D on/off |
| F4 | Swap left/right eyes |
| Esc | Quit |

## Troubleshooting

| Problem | Fix |
|---------|-----|
| 3D looks wrong or hurts your eyes | Press F4 (or set `swap_eyes=true` in the settings file). |
| Picture is on the wrong screen | Change `window_position` in the settings file. |
| Objects look too big, small or far away | Re-measure the display wall settings above. |
| "No machine config" message in the app | The settings file is missing or misnamed. Check step 2. |
