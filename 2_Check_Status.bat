@echo off
setlocal
title Direct Call / Viber fix - check status
rem Read-only. Shows whether the "Phone -> Always" choice is active.

set "ADB=adb"
where adb >nul 2>nul
if errorlevel 1 set "ADB=%LOCALAPPDATA%\Microsoft\WinGet\Packages\Google.PlatformTools_Microsoft.Winget.Source_8wekyb3d8bbwe\platform-tools\adb.exe"
if /i not "%ADB%"=="adb" if not exist "%ADB%" goto noadb

"%ADB%" get-state >nul 2>nul
if errorlevel 1 goto nophone

echo Apps that answer a call request:
"%ADB%" shell cmd package query-activities --brief -a android.intent.action.CALL -d tel:123
echo.
echo Android currently picks:
"%ADB%" shell cmd package resolve-activity --brief -a android.intent.action.CALL -d tel:123
echo.
"%ADB%" shell cmd package resolve-activity --brief -a android.intent.action.CALL -d tel:123 | findstr /c:"UserCallActivity" >nul
if errorlevel 1 goto notactive
echo RESULT: FIX IS ACTIVE - Direct Call goes to the real phone.
goto end

:notactive
echo RESULT: FIX IS NOT ACTIVE - Direct Call will open Viber. Run 1_Apply_Fix.bat
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
