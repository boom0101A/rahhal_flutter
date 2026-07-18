@echo off
title Clean Drive C Temp Files
echo Running PowerShell Cleanup Script...
powershell -ExecutionPolicy Bypass -File "%~dp0clean_drive_c.ps1"
pause
