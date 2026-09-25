# Jumpy Otter — Build & Gameplay Test Plan (iOS + Android, side by side)

Setup: `xcodebuild` BUILD SUCCEEDED for the iPhone simulator; `cd android && ./gradlew lintDebug assembleDebug` passes and produces `app/build/outputs/apk/debug/app-debug.apk`. An iPhone simulator and the `Pixel_7` AVD are booted (the AVD may need `-accel off -gpu swiftshader_indirect` on hosts without Hypervisor.framework). Optional: relay running (`.relay-venv/bin/python relay.py`) so the two builds see each other.

## Test 1: It should install and launch to the title screen on both platforms
1. iOS: `xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/JumpyOtter.app` then `xcrun simctl launch booted com.devin.jumpyotter`.
2. Android: `adb install -r android/app/build/outputs/apk/debug/app-debug.apk` then `adb shell am start -n com.devin.jumpyotter/.MainActivity`.
- Pass: both show the "JUMPY OTTER / TAP TO HOP" title over the rendered voxel world (no crash, no black screen); `adb logcat` has no `FATAL EXCEPTION` for `com.devin.jumpyotter`.

## Test 2: It should play a full run on each platform, simultaneously, recorded
1. Start recorders: `xcrun simctl io booted recordVideo --force videos/ios.mp4` and `adb shell screenrecord /sdcard/android.mp4` (or a single screen recording of the Mac with both windows visible).
2. Tap to start on both. Hop forward with taps, dodge sideways with swipes (Android: swipe on the GL view; iOS: `idb ui swipe`). Cross at least one road, one river, and one rail row per platform.
3. Collect a creatine bottle; the counter top-right increments. With the relay running, the other device's road traffic surges and shows a "PLAYER n SENT TRAFFIC!" banner; a ghost otter of the rival is visible.
4. Continue until game over (car, train, water, or 6 s idle → eagle). Score and TOP score are displayed; tapping retries and score resets to 0.
5. Stop recorders; `adb pull /sdcard/android.mp4 videos/`. Verify each file is non-empty and plays (`ffprobe`).
- Pass: one complete run to GAME OVER on each platform; on-screen score matches the reported score; best score persists across retry; videos valid.

## Test 3 (regression): It should keep single-player working without the relay
1. Stop the relay, relaunch either app.
- Pass: title screen appears and the game is playable with no rival strip and no banners.
