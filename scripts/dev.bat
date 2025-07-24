@echo off
setlocal enabledelayedexpansion

rem If Packages aren't installed, install them.
if not exist "Packages" (
    call scripts\install-packages.bat
)

start /b cmd /c rojo serve build.project.json
start /b cmd /c rojo sourcemap default.project.json -o sourcemap.json --watch
start /b cmd /c set "ROBLOX_DEV=true" && darklua process --config .darklua.json --watch src/ dist/

endlocal