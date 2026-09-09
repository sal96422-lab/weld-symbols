@echo off
setlocal
cd /d "%~dp0"

echo Installing AutoCAD Weld Symbols...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-WeldSymbols.ps1"

echo.
pause
