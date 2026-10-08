STEREO WALL - SETUP AND DAILY USE
=================================

ONE-TIME SETUP
--------------
1. Put this folder somewhere, like the Desktop or C:\StereoWall.

2. Put a tape mark on the floor where the viewer should stand
   (the "sweet spot").

3. Create the folder C:\StereoWallGodot and move STEREO_CONFIG_GODOT.example.cfg
   into it, renamed to STEREO_CONFIG_GODOT.cfg. All wall games use this one
   file. Open it in Notepad and set:
     wall_width, wall_height   size of the wall picture (meters)
     wall_center_height        floor to the middle of the wall
     wall_distance             tape mark to the wall
     sweet_spot                change 1.64 to your eye height (meters)

4. Right-click START_WALL.bat > "Send to" > "Desktop (create shortcut)".


EVERY DAY
---------
1. Double-click the START_WALL shortcut.
2. Stand on the tape mark for the best 3D.
3. Press Esc to quit.


KEYS
----
F1   Help
F2   Switch Edit/Stereo
F3   3D on/off
F4   Swap left/right eyes
Esc  Quit
WASD / mouse / gamepad = move and look    R = reset position


TROUBLESHOOTING
---------------
3D looks wrong / hurts eyes      Press F4.
Picture on the wrong screen      Change window_position in the config.
