STEREO WALL - SETUP AND DAILY USE
=================================

ONE-TIME SETUP
--------------
1. Install Python 3 from https://www.python.org/downloads/
   In the installer, tick "Add python.exe to PATH".

2. Put this folder somewhere writable, like the Desktop or C:\StereoWall
   (not "Program Files").

3. Mount the webcam just above or below the wall, centered, facing the room.

4. Double-click head_tracker.bat. The first run installs itself (a few
   minutes, needs internet). In the camera window, a green dot should
   appear between your eyes. Press Q to close it.
   Wrong camera? Edit head_tracker.bat and change CAMERA=0 to CAMERA=1.

5. Put a tape mark on the floor where the viewer should stand
   (the "sweet spot").

6. Open STEREO_CONFIG_GODOT.cfg in Notepad and set:
     wall_width, wall_height   size of the wall picture (meters)
     wall_center_height        floor to the middle of the wall
     wall_distance             tape mark to the wall
     tracking_enabled          true
     camera_pitch              degrees the webcam tilts down (minus if up)
     sweet_spot                change 1.64 to your eye height (meters)

7. Right-click START_WALL.bat > "Send to" > "Desktop (create shortcut)".


EVERY DAY
---------
1. Double-click the START_WALL shortcut.
2. Calibrate (first time, or after the camera moves): stand on the tape
   mark, look at the wall, press F6 and hold still until "Calibrated".
   It's saved, so you don't need to do this every day.
3. Press Esc to quit. Head tracking stops by itself.


KEYS
----
F1  Help                  F4  Swap left/right eyes
F2  Switch Edit/Stereo    F5  Head tracking on/off
F3  3D on/off             F6  Calibrate
WASD / mouse / gamepad = move and look    R = reset position    Esc = quit


TROUBLESHOOTING
---------------
3D looks wrong / hurts eyes      Press F4.
"Head tracking: no data"         Head tracker isn't running or sees no one.
                                 Run head_tracker.bat to check.
Head tracking does nothing       Press F5, or set tracking_enabled=true.
View moves the wrong way         Flip that axis in axis_sign in the config,
                                 e.g. Vector3(-1, 1, 1) flips left/right.
Stepping forward moves up/down   Adjust camera_pitch.
Picture on the wrong screen      Change window_position in the config.
"Python 3 is not installed"      Redo step 1 and tick "Add to PATH".
