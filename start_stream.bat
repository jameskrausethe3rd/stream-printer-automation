@echo off
REM Launch go2rtc
start /D "%~dp0" go2rtc.exe

REM Wait for a few seconds
timeout /t 5 /nobreak > nul

REM Launch OBS
start "" "%~dp0\obs.lnk"

