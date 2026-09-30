STEREO WALL - SETUP AND DAILY USE
=================================

ONE-TIME SETUP
--------------
1. Install Python 3 from https://www.python.org/downloads/
   IMPORTANT: in the installer, tick "Add python.exe to PATH".

2. Put this whole folder somewhere you can write to, like the Desktop
   or C:\StereoWall (not inside "Program Files").

3. Mount the webcam just above or below the wall, centered, facing the room.

4. Double-click  head_tracker.bat
   The first time, it installs itself (a few minutes, needs internet).
   A camera window opens. Stand in front of it: a green dot should
   appear between your eyes. Press Q in the camera window to close it.
   (Wrong camera? Edit head_tracker.bat and change CAMERA=0 to CAMERA=1.)

5. Put a tape mark on the floor where the viewer should stand
   (the "sweet spot", usually the room center).

6. Open STEREO_CONFIG_GODOT.cfg in Notepad and check these values:
     [wall]  wall_width, wall_height    size of the wall picture, in meters
             wall_center_height         floor to the middle of the wall
             wall_distance              tape mark to the wall
     [tracking] camera_pitch            how many degrees the webcam tilts
                                        DOWN (use a minus number if it tilts up)
     [calibration] sweet_spot           change 1.64 to the eye height of the
                                        person who calibrates, in meters

7. Make a desktop shortcut: right-click START_WALL.bat,
   then "Send to" > "Desktop (create shortcut)".


EVERY DAY
---------
1. Double-click the START_WALL shortcut. Head tracking and the wall app start.
2. Calibrate (first time, or after the camera moved):
   stand on the tape mark, look at the wall, press F6, hold still until
   it says "Calibrated". This is saved; you don't need to do it every day.
3. Press Esc to quit. Head tracking stops by itself.


KEYS
----
F1  Help                      F4  Swap left/right eyes
F2  Switch Edit / Stereo      F5  Head tracking on/off
F3  3D on/off                 F6  Calibrate
WASD / mouse / gamepad = move and look      R = reset position      Esc = quit


TROUBLESHOOTING
---------------
3D looks wrong or hurts the eyes     Press F4 (swaps the eyes).
"Head tracking: no data"             The head tracker window isn't running, or the
                                     camera can't see anyone. Run head_tracker.bat
                                     to check.
View moves the wrong way             In STEREO_CONFIG_GODOT.cfg, flip that axis in
                                     axis_sign, e.g. Vector3(-1, 1, 1) flips left/right.
Walking forward also moves up/down   Adjust camera_pitch.
Picture is on the wrong screen       Change window_position in the config.
"Python 3 is not installed"          Redo setup step 1 (tick "Add to PATH").
