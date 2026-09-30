@echo off
rem Starts head tracking, then the wall app. Closing the app also stops head tracking.
rem Keep this file in the same folder as the exported game.

rem Name of the exported game .exe:
set GAME=MyGame.exe

cd /d "%~dp0"
start "Head tracker" /min cmd /c head_tracker.bat
timeout /t 3 /nobreak >nul
start "" /wait "%GAME%"
taskkill /fi "WINDOWTITLE eq Head tracker*" /t /f >nul 2>&1
