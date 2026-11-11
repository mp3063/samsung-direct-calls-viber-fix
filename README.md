# Samsung edge panel "Direct Call" opens Viber instead of calling — fix

On Samsung Galaxy phones, tapping a contact in the **Direct Call** edge panel opens **Viber** instead of placing a normal phone call. Uninstalling Viber makes the problem go away, but nothing in Settings does.

This repo explains why it happens and fixes it in about a minute, **without root and without uninstalling Viber**.

## Is this your problem?

- You swipe open the edge panel, tap a contact in Direct Call, and Viber opens.
- Settings → Apps → Viber → Set as default has no "Clear defaults" button.
- Your default Phone app is already Samsung Phone.
- Turning off "Viber In Calls", Caller ID, or Viber's Phone permission changes nothing.

Users have reported the same behaviour with Skype, Zoom and RingCentral in place of Viber. The fix should apply to those too, but it has only been tested with Viber.

## Quick fix (Windows)

You need a PC, a USB cable, and [adb](#installing-adb).

1. On the phone, enable USB debugging: **Settings → About phone → Software information**, tap **Build number** 7 times, then **Settings → Developer options → USB debugging**.
2. Plug the phone into the PC, unlock it, and tap **Allow** on the "Allow USB debugging?" prompt.
3. Download this repo (**Code → Download ZIP**) and unzip it.
4. Double-click **`1_Apply_Fix.bat`** and follow the text. On the phone, tap **Phone**, then **Always**.

The script starts a dummy call to the number `1` and hangs it up automatically. When it prints `RESULT: FIXED`, try Direct Call again.

You can turn USB debugging off again afterwards.

## Manual fix (Windows, macOS, Linux)

After steps 1 and 2 above, check the phone is listed as `device` (not `unauthorized`):

```
adb devices
```

Open the app chooser. **This really dials the number `1` once you choose, so hang up straight away:**

```
adb shell am start -a android.intent.action.CALL -d tel:1
```

On the phone tap **Phone**, then **Always**. If it only offers "Just once", run the command again and choose Always the second time.

Verify:

```
adb shell cmd package resolve-activity --brief -a android.intent.action.CALL -d tel:123
```

It must print `com.android.server.telecom/.components.UserCallActivity`. If it prints `android/com.android.internal.app.ResolverActivity`, the choice was not saved.

## Why it happens

1. The tap does not place a call directly. Samsung's launcher (One UI Home, `com.sec.android.app.launcher`, which hosts the edge panel) sends a generic request: action `android.intent.action.CALL` with data `tel:<number>`.
2. Two apps answer that request:
   - `com.android.server.telecom/.components.UserCallActivity` — the real phone
   - `com.viber.voip/.WelcomeActivityPublic` — Viber
3. With two candidates, Android opens its app chooser. The chooser hides every app the **sender** is not allowed to start. The real phone entry requires the `CALL_PHONE` permission, and the launcher does not hold it.
4. The real phone is removed from the list, Viber is the only candidate left, and Android launches it automatically without showing a chooser.

These two log lines show it (uid 10154 was the launcher on the test phone):

```
START u0 {act=android.intent.action.CALL dat=tel:... cmp=android/com.android.internal.app.ResolverActivity} from uid 10154
START u0 {act=android.intent.action.CALL dat=tel:... cmp=com.viber.voip/.WelcomeActivityPublic} from uid 10154
```

**The fix:** saving "Phone → Always" for the `CALL` request means Android never opens the chooser, so nothing gets filtered and the call goes straight to the phone. The chooser can only be reached by a sender that holds the Phone permission, which adb does.

## When to repeat it

Android forgets the saved choice when the set of apps that answer call requests changes: installing another calling app, sometimes a large Viber update, or **Reset app preferences**. If Viber starts opening again, run `1_Apply_Fix.bat` again.

## Undo

Run `3_Undo_Fix.bat`, or:

```
adb shell pm clear-package-preferred-activities com.android.server.telecom
```

This removes the saved choice, and Direct Call will open Viber again.

## Files

| File | What it does |
| --- | --- |
| `1_Apply_Fix.bat` | Opens the chooser, hangs up the dummy call, verifies the result. Does nothing if the fix is already active. |
| `2_Check_Status.bat` | Read-only. Shows whether the fix is currently active. |
| `3_Undo_Fix.bat` | Removes the saved choice. |

## Installing adb

Windows:

```
winget install --id Google.PlatformTools -e
```

Open a new terminal afterwards so `adb` is found. The scripts also look in winget's install folder, so they work even before the PATH change takes effect.

macOS (`brew install android-platform-tools`), Linux (`android-tools` / `adb` package), or download [Android SDK Platform-Tools](https://developer.android.com/tools/releases/platform-tools) from Google.

## Diagnostic commands

All read-only.

```
# Which apps answer a call request
adb shell cmd package query-activities --brief -a android.intent.action.CALL -d tel:123

# Which one Android picks right now
adb shell cmd package resolve-activity --brief -a android.intent.action.CALL -d tel:123

# Saved "always open with" choices
adb shell dumpsys package preferred

# Default dialer
adb shell telecom get-default-dialer

# Watch what a tap really starts: clear the log, tap on the phone, then read
adb logcat -c
adb shell "logcat -d | grep 'START u0'"
```

## Things that do not work

- Settings → Apps → Viber → Set as default → Clear defaults (the button is missing, because Viber holds no default)
- Turning off "Viber In Calls" or Caller ID inside Viber
- Removing Viber's Phone permission
- Checking or changing the default Phone app
- The "Direct dial" home-screen widget trick

## Tested on

- Samsung Galaxy S21 Ultra (SM-G998B), Android 15, One UI 7
- Direct Call edge panel `com.sallysoft.srpol.edge.directcall` 2.0.16
- Viber `com.viber.voip` 29.4.0.0

Other Galaxy models and versions are untested. If it works (or doesn't) on yours, an issue with your model and Android version is welcome.

## Disclaimer

Provided as is, with no warranty. The fix changes one saved app preference and is reversible. The scripts place a short dummy call to the number `1` and end it; the call may appear in your call log.

## License

[MIT](LICENSE)
