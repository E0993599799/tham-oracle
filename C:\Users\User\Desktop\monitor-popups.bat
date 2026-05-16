@echo off
REM Run PowerShell script invisible + minimized in background
powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& 'C:\Users\User\Desktop\catch-powershell-popups.ps1'"
