@echo off
setlocal
title Direct Call / Viber fix - undo
rem Removes the saved "Phone -> Always" choice for call requests.
rem After this, Direct Call will open Viber again.

set "ADB=adb"
where adb >nul 2>nul
if errorlevel 1 set "ADB=%LOCALAPPDATA%\Microsoft\WinGet\Packages\Google.PlatformTools_Microsoft.Winget.Source_8wekyb3d8bbwe\platform-tools\adb.exe"
if /i not "%ADB%"=="adb" if not exist "%ADB%" goto noadb

"%ADB%" get-state >nul 2>nul
if errorlevel 1 goto nophone

echo This removes the fix. Direct Call will open Viber again.
echo Close this window now to cancel, or
pause

"%ADB%" shell pm clear-package-preferred-activities com.android.server.telecom
echo.
echo Android now picks:
"%ADB%" shell cmd package resolve-activity --brief -a android.intent.action.CALL -d tel:123
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
