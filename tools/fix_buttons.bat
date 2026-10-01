@echo off
cd /d "%~dp0.."
echo Naprawiam przyciski w DFM...
powershell -ExecutionPolicy Bypass -File tools\fix_buttons.ps1
if %errorlevel% equ 0 (echo OK) else (echo BLAD!)
pause