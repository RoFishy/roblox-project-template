@echo off
setlocal

set "DEVELOPMENT_PROJECT=default.project.json"
set "BUILD_PROJECT=build.project.json"
set "PLACE_NAME="

if not "%~1"=="" (
    set "PLACE_DIRECTORY=places\%~1"

    if not exist "places\%~1\default.project.json" goto :unknown_place
    if not exist "places\%~1\build.project.json" goto :unknown_place

    set "SELECTED_PROJECT=places\%~1\default.project.json"
    set "BUILD_PROJECT=places\%~1\build.project.json"
    set "PLACE_NAME=%~1"
)

if defined PLACE_NAME (
    powershell.exe -NoProfile -Command "$content = Get-Content -Raw -LiteralPath $env:SELECTED_PROJECT; [IO.File]::WriteAllText((Join-Path (Get-Location).Path '.active-place.project.json'), $content.Replace('../../', ''))"
    if errorlevel 1 exit /b 1
    set "DEVELOPMENT_PROJECT=.active-place.project.json"
)

rem If Packages aren't installed, install them.
if not exist "Packages" (
    call scripts\install-packages.bat
    if errorlevel 1 exit /b 1
)

if defined PLACE_NAME (
    for %%D in (Core Client\Systems Client\Modules Server\Systems Server\Modules) do if not exist "dist\Places\%PLACE_NAME%\%%D" mkdir "dist\Places\%PLACE_NAME%\%%D"
)

start "" /b cmd /c rojo serve "%BUILD_PROJECT%"
start "" /b cmd /c rojo sourcemap "%DEVELOPMENT_PROJECT%" -o sourcemap.json --watch
set "ROBLOX_DEV=true"
darklua process --config .darklua.json --watch src/ dist/

endlocal & exit /b %ERRORLEVEL%

:unknown_place
echo Unknown place: %~1 1>&2
echo Available places: 1>&2
for /d %%D in ("places\*") do if exist "%%~fD\default.project.json" echo   %%~nxD 1>&2
endlocal
exit /b 1
