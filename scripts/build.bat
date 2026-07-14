@echo off
setlocal

if not "%~2"=="" (
    echo Usage: scripts\build.bat [PlaceName] 1>&2
    exit /b 1
)

set "DEVELOPMENT_PROJECT=default.project.json"
set "BUILD_PROJECT=build.project.json"
set "PLACE_NAME="
set "EXIT_CODE=0"

if not "%~1"=="" (
    if not exist "places\%~1\" goto :unknown_place
    if not exist "places\%~1\default.project.json" goto :invalid_place
    if not exist "places\%~1\build.project.json" goto :invalid_place

    set "SELECTED_PROJECT=places\%~1\default.project.json"
    set "BUILD_PROJECT=places\%~1\build.project.json"
    set "PLACE_NAME=%~1"
)

if defined PLACE_NAME (
    powershell.exe -NoProfile -Command "$content = Get-Content -Raw -LiteralPath $env:SELECTED_PROJECT; [IO.File]::WriteAllText((Join-Path (Get-Location).Path '.active-place.project.json'), $content.Replace('../../', ''))"
    if errorlevel 1 exit /b 1
    set "DEVELOPMENT_PROJECT=.active-place.project.json"
)

if not exist "Packages" (
    call scripts\install-packages.bat
    if errorlevel 1 goto :failed
)

if defined PLACE_NAME (
    for %%D in (Core Client\Systems Client\Modules Server\Systems Server\Modules) do if not exist "dist\Places\%PLACE_NAME%\%%D" mkdir "dist\Places\%PLACE_NAME%\%%D"
)

if defined BUILD_OUTPUT (
    set "OUTPUT_PATH=%BUILD_OUTPUT%"
) else if defined PLACE_NAME (
    set "OUTPUT_PATH=builds\%PLACE_NAME%.rbxl"
) else (
    set "OUTPUT_PATH=builds\Game.rbxl"
)

for %%D in ("%OUTPUT_PATH%") do if not exist "%%~dpD" mkdir "%%~dpD"

rojo sourcemap "%DEVELOPMENT_PROJECT%" -o sourcemap.json
if errorlevel 1 goto :failed

set "ROBLOX_DEV=false"
darklua process --config .darklua.json src/ dist/
if errorlevel 1 goto :failed

rojo build "%BUILD_PROJECT%" -o "%OUTPUT_PATH%"
if errorlevel 1 goto :failed

echo Built %OUTPUT_PATH%
goto :cleanup

:failed
set "EXIT_CODE=1"

:cleanup
if defined PLACE_NAME if exist ".active-place.project.json" del /q ".active-place.project.json"
endlocal & exit /b %EXIT_CODE%

:unknown_place
echo Unknown place: %~1 1>&2
goto :list_places

:invalid_place
echo Invalid place: %~1 requires default.project.json and build.project.json 1>&2

:list_places
echo Available places: 1>&2
set "FOUND_PLACE="
for /d %%D in ("places\*") do if exist "%%~fD\default.project.json" if exist "%%~fD\build.project.json" (
    echo   %%~nxD 1>&2
    set "FOUND_PLACE=1"
)
if not defined FOUND_PLACE echo   ^(none^) 1>&2
endlocal
exit /b 1
