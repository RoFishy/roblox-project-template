@echo off
setlocal

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0create-place.ps1" %*
exit /b %ERRORLEVEL%
