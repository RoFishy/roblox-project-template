@echo off
setlocal

rem Install packages using wally
start /b /wait cmd /c wally install
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

rem Generate sourcemap for type definitions
start /b /wait cmd /c rojo sourcemap default.project.json -o sourcemap.json
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

rem Patch the Wally package link modules to export Luau type definitions
start /b /wait cmd /c wally-package-types --sourcemap sourcemap.json Packages/
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

endlocal