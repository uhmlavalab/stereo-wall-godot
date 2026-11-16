# Display Wall Setup

For whoever sets up and maintains the display wall PC (Windows). This is done once per PC. App developers don't need it.

Setting up a Samsung Odyssey 3D monitor instead? Do steps 1 to 3, then see [Samsung Odyssey 3D monitor](#samsung-odyssey-3d-monitor).

Every app made with this addon reads one settings file on the PC, so the display wall's measurements live in one place. Apps never change this file.

## 1. Mark where the viewer stands

Put a tape mark on the floor where the viewer should stand, centered in front of the display wall.

## 2. Create the settings file

1. Create the folder `C:\StereoWallGodot`.
2. Copy `STEREO_CONFIG_GODOT.example.cfg` (in this folder) into it and rename it to `STEREO_CONFIG_GODOT.cfg`.
3. Open it in Notepad and set:

   | Setting | What to measure or enter |
   |---------|--------------------------|
   | `window_width`, `window_height` | The whole display's resolution, both eyes side by side (`9600`, `1620` on the LAVA lab display wall). Each eye gets half the width. |
   | `window_position` | Where the app window starts, if the display wall isn't the main screen |
   | `samsung_3d_display` | Leave it `false` on a display wall. `true` is only for a [Samsung Odyssey 3D monitor](#samsung-odyssey-3d-monitor). |
   | `wall_width`, `wall_height` | Size of the display wall picture, in meters |
   | `wall_center_height` | Floor to the middle of the display wall |
   | `wall_distance` | Tape mark to the display wall |
   | `wall_offset_x` | Display wall center right (+) or left (-) of the tape mark; 0 = centered |
   | `eye_height` | Floor to the viewer's eyes |
   | `eye_separation` | Distance between the viewer's eyes, in meters. Smaller = gentler 3D. |

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

## Samsung Odyssey 3D monitor

The same apps also run on a Samsung Odyssey 3D (glasses-free) monitor. Samsung's **Odyssey 3D Hub** must be running on that PC; it turns the side-by-side picture into 3D.

In that PC's settings file, set:

```
[display]
samsung_3d_display=true

[wall]
wall_width=0.597             ; the screen's picture, in meters (27" model)
wall_height=0.336
wall_center_height=1.2       ; floor to the middle of the screen
wall_distance=0.5            ; your eyes to the screen

[render]
eye_separation=0.015         ; 0.01 to 0.02 is comfortable; the display wall's 0.063 is too strong here

[viewer]
eye_height=1.2               ; floor to your eyes (same as wall_center_height = eyes level with the middle)
```

With `samsung_3d_display=true` the app fills the screen it opens on and the three `window_` settings are ignored. When an app starts, the window grows first and goes full screen about a second later; that's normal.

| Problem | Fix |
|---------|-----|
| Picture in a corner, or 3D doesn't turn on | Check that `samsung_3d_display=true` is under `[display]`. Then quit Odyssey 3D Hub from the system tray, start it again, and restart the app. |
| Everything looks twice as wide (round things look like wide ovals) | `samsung_3d_display` isn't `true`, or the settings file wasn't found. |
| 3D is too strong | Lower `eye_separation`. |
