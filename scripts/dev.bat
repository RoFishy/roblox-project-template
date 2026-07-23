@echo off
setlocal

if not "%~2"=="" (
    echo Usage: scripts\dev.bat [PlaceName] 1>&2
    exit /b 1
)

set "DEVELOPMENT_PROJECT=default.project.json"
set "BUILD_PROJECT=build.project.json"
set "PLACE_NAME="
set "EXIT_CODE=0"

if not "%~1"=="" (
    set "PLACE_DIRECTORY=places\%~1"

    if not exist "places\%~1\" goto :unknown_place
    if not exist "places\%~1\default.project.json" goto :invalid_place
    if not exist "places\%~1\build.project.json" goto :invalid_place
    if not exist "src\Places\%~1\" goto :invalid_place

    set "SELECTED_PROJECT=places\%~1\default.project.json"
    set "BUILD_PROJECT=places\%~1\build.project.json"
    set "PLACE_NAME=%~1"
)

if defined PLACE_NAME (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0write-active-project.ps1" "%SELECTED_PROJECT%"
    if errorlevel 1 goto :failed
    set "DEVELOPMENT_PROJECT=.active-place.project.json"
)

rem If Packages aren't installed, install them.
if not exist "Packages" (
    call scripts\install-packages.bat
    if errorlevel 1 goto :failed
)

if defined PLACE_NAME (
    for %%D in (Core Client\Systems Client\Modules Server\Systems Server\Modules) do if not exist "dist\Places\%PLACE_NAME%\%%D" mkdir "dist\Places\%PLACE_NAME%\%%D"
)

if "%DEV_DRY_RUN%"=="1" (
    echo rojo serve "%BUILD_PROJECT%"
    echo rojo sourcemap "%DEVELOPMENT_PROJECT%" -o sourcemap.json --watch
    echo ROBLOX_DEV=true darklua process --config .darklua.json --watch src/Core dist/Core
    echo ROBLOX_DEV=true darklua process --config .darklua.json --watch src/Client dist/Client
    echo ROBLOX_DEV=true darklua process --config .darklua.json --watch src/Server dist/Server
    if defined PLACE_NAME echo ROBLOX_DEV=true darklua process --config .darklua.json --watch src/Places/%PLACE_NAME% dist/Places/%PLACE_NAME%
    goto :cleanup
)

start "" /b cmd /c rojo serve "%BUILD_PROJECT%"
start "" /b cmd /c rojo sourcemap "%DEVELOPMENT_PROJECT%" -o sourcemap.json --watch
set "ROBLOX_DEV=true"
start "" /b cmd /c darklua process --config .darklua.json --watch src/Core dist/Core
start "" /b cmd /c darklua process --config .darklua.json --watch src/Client dist/Client
if defined PLACE_NAME (
    start "" /b cmd /c darklua process --config .darklua.json --watch src/Server dist/Server
    darklua process --config .darklua.json --watch "src/Places/%PLACE_NAME%" "dist/Places/%PLACE_NAME%"
) else (
    darklua process --config .darklua.json --watch src/Server dist/Server
)

set "EXIT_CODE=%ERRORLEVEL%"

:cleanup
if defined PLACE_NAME if exist ".active-place.project.json" del /q ".active-place.project.json"
endlocal & exit /b %EXIT_CODE%

:failed
set "EXIT_CODE=1"
goto :cleanup

:unknown_place
echo Unknown place: %~1 1>&2
:list_places
echo Available places: 1>&2
set "FOUND_PLACE="
for /d %%D in ("places\*") do if exist "%%~fD\default.project.json" if exist "%%~fD\build.project.json" if exist "src\Places\%%~nxD\" (
    echo   %%~nxD 1>&2
    set "FOUND_PLACE=1"
)
if not defined FOUND_PLACE echo   ^(no optional places currently exist^) 1>&2
endlocal
exit /b 1

:invalid_place
echo Invalid place: %~1 requires both project files and src/Places/%~1 1>&2
goto :list_places
