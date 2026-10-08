@echo off
rem Webcam head tracking for the stereo wall. Double-click to run.
rem The first run installs everything it needs (needs Python 3 and internet).

rem Webcam number (0 = first webcam) and its horizontal field of view in degrees:
set CAMERA=0
set FOV=60
rem Track a printed marker instead of the face (best with 3D glasses): set MARKER
rem to the width of the printed black square in cm, e.g. set MARKER=7
rem Leave it empty for face tracking. The first marker run saves marker.png to print.
set MARKER=

cd /d "%~dp0"
if not exist .venv\installed (
    echo First run: installing head tracking. This takes a few minutes...
    if not exist .venv\Scripts\python.exe (
        py -3 -m venv .venv 2>nul || python -m venv .venv
    )
    if not exist .venv\Scripts\python.exe (
        echo.
        echo Python 3 is not installed. Install it from https://www.python.org/downloads/
        echo and tick "Add python.exe to PATH" in the installer. Then run this again.
        pause
        exit /b 1
    )
    .venv\Scripts\python -m pip install -r requirements.txt || (pause & exit /b 1)
    echo done> .venv\installed
)
set EXTRA=
if not "%MARKER%"=="" set EXTRA=--marker %MARKER%
.venv\Scripts\python head_sender.py --preview --camera %CAMERA% --fov %FOV% %EXTRA%
pause
