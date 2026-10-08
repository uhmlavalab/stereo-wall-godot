@echo off
rem Starts the wall app. Keep this file in the same folder as the exported game.

rem Name of the exported game .exe:
set GAME=MyGame.exe

cd /d "%~dp0"
start "" "%GAME%"
