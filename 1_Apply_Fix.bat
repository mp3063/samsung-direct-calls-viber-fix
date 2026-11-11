@echo off
setlocal
title Direct Call / Viber fix - apply
rem Makes the Samsung edge panel "Direct Call" place a normal call instead of
rem opening Viber, by saving "Phone -> Always" for the CALL request.
rem See README.md for the explanation.

set "ADB=adb"
where adb >nul 2>nul
if errorlevel 1 set "ADB=%LOCALAPPDATA%\Microsoft\WinGet\Packages\Google.PlatformTools_Microsoft.Winget.Source_8wekyb3d8bbwe\platform-tools\adb.exe"
if /i not "%ADB%"=="adb" if not exist "%ADB%" goto noadb

"%ADB%" get-state >nul 2>nul
if errorlevel 1 goto nophone

rem Already applied? Then starting the request would just dial, so stop here.
"%ADB%" shell cmd package resolve-activity --brief -a android.intent.action.CALL -d tel:123 | findstr /c:"UserCallActivity" >nul
if not errorlevel 1 goto already

echo ============================================================
echo  Unlock the phone and keep it in your hand.
echo  After you press a key here, a chooser appears on the phone:
echo     1. Tap  Phone   (NOT Viber)
echo     2. Tap  Always  (NOT Just once)
echo  A dummy call to the number 1 starts - this script hangs it
echo  up automatically.
echo ============================================================
pause

"%ADB%" shell am start -a android.intent.action.CALL -d tel:1
echo Waiting for your choice on the phone (up to 2 minutes)...
"%ADB%" shell "i=0; while [ $i -lt 300 ]; do n=$(dumpsys telephony.registry | grep -c mCallState=2); if [ $n -gt 0 ]; then input keyevent 6; break; fi; i=$((i+1)); sleep 0.4; done"
timeout /t 2 /nobreak >nul

echo.
"%ADB%" shell cmd package resolve-activity --brief -a android.intent.action.CALL -d tel:123 | findstr /c:"UserCallActivity" >nul
if errorlevel 1 goto notsaved
echo RESULT: FIXED - Direct Call now goes to the real phone.
goto end

:notsaved
echo RESULT: NOT SAVED - you probably tapped "Just once".
echo Run this file again and tap Phone, then Always.
goto end

:already
echo The fix is already active - nothing to do.
goto end

:noadb
echo adb was not found. Install it with:
echo    winget install --id Google.PlatformTools -e
goto end

:nophone
echo No authorized phone found.
echo Turn on USB debugging, plug the phone in, unlock it and tap "Allow".
goto end

:end
echo.
pause
