@echo off
rem Webcam head tracking for the stereo wall. Double-click to run.
rem The first run installs everything it needs (needs Python 3 and internet).

rem Webcam number (0 = first webcam) and its horizontal field of view in degrees:
set CAMERA=0
set FOV=60

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
.venv\Scripts\python head_sender.py --preview --camera %CAMERA% --fov %FOV%
pause
