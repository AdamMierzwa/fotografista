@echo off
cd /d "%~dp0.."
powershell -ExecutionPolicy Bypass -File tools\gen_i18n.ps1
pause
