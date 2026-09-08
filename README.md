# Jumpy Otter

[![Built with Devin](https://img.shields.io/badge/Built%20with-Devin-blue)](https://devin.ai)

Jumpy Otter is a voxel-style arcade game set in San Francisco. Guide Devin the otter through traffic, trains, and the bay while collecting creatine bottles.

It ships for two platforms from one repo:

- **iOS** — Swift + SceneKit (`JumpyOtter/`, `JumpyOtter.xcodeproj`).
- **Android** — Kotlin + a small OpenGL ES 2.0 engine (`android/`). Same rules,
  same procedural world, same multiplayer protocol, so an iPhone and an Android
  phone can play against each other through the relay.

## Run in Xcode

1. Open `JumpyOtter.xcodeproj`.
2. Select the `JumpyOtter` scheme and an iOS simulator.
3. Press Run.

## Run from the command line

Boot an iOS simulator, then run:

```sh
xcodebuild -project JumpyOtter.xcodeproj \
  -scheme JumpyOtter \
  -sdk iphonesimulator \
  -configuration Debug \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO build

xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/JumpyOtter.app
xcrun simctl launch booted com.devin.jumpyotter
```

Run `xcodegen generate` after changing `project.yml`.

## Android

Requirements: JDK 17, Android SDK with platform 35 / build-tools 35.0.0, and
(for the emulator) `system-images;android-35;google_apis;arm64-v8a`. Point
`ANDROID_HOME` at the SDK or create `android/local.properties` with
`sdk.dir=/path/to/sdk`.

```sh
cd android
./gradlew assembleDebug            # → app/build/outputs/apk/debug/app-debug.apk
./gradlew lintDebug                # Android lint

$ANDROID_HOME/emulator/emulator -avd Pixel_7 &
$ANDROID_HOME/platform-tools/adb wait-for-device
$ANDROID_HOME/platform-tools/adb install -r app/build/outputs/apk/debug/app-debug.apk
$ANDROID_HOME/platform-tools/adb shell am start -n com.devin.jumpyotter/.MainActivity
```

Create the AVD once with
`avdmanager create avd -n Pixel_7 -k "system-images;android-35;google_apis;arm64-v8a" -d pixel_7`.
If the emulator refuses to start because Hypervisor.framework is unavailable
(nested virtualisation, some CI Macs), add `-accel off -gpu swiftshader_indirect`;
it boots in software emulation, just slowly.

Autopilot for unattended runs:
`adb shell am start -n com.devin.jumpyotter/.MainActivity --ez AUTOPILOT true`
(the iOS equivalent is the `AUTOPILOT` launch argument).

The Android port lives in `android/app/src/main/java/com/devin/jumpyotter/`:
`engine/` (mesh builder, scene graph, SceneKit-style actions, GLES2 renderer),
`VoxelFactory.kt`/`Terrain.kt` (the same procedural models and row generator as
the Swift versions), `GameController.kt` (game rules), `MainActivity.kt` (HUD,
gestures), `MultiplayerClient.kt` and `SoundManager.kt`.

## Multiplayer (up to 4 players)

A tiny WebSocket relay groups the first connecting clients into a room and
forwards each message to the others, tagged with the sender's player id.

Start the relay on the Mac:

```sh
python3 -m venv .relay-venv
.relay-venv/bin/pip install websockets
.relay-venv/bin/python relay.py   # listens on ws://127.0.0.1:8765
```

Optional protocol check (with the relay running):

```sh
.relay-venv/bin/python scripts/test_relay.py
```

Then launch the game in up to four simulators/emulators — each client connects
to the relay automatically at startup (and silently stays single-player if the
relay isn't running). The Android emulator reaches the host's relay through
`ws://10.0.2.2:8765` (the emulator's alias for the host loopback); override it
with `--es RELAY_URL ws://host:8765` on the `am start` command. Rivals appear
as translucent ghost otters with a colored marker, plus a live score strip in
the top-right corner.

Messages exchanged: `state` (position + score, drives the ghost otters and
rival scores), `garbage` (collecting a creatine bottle surges rivals' road
traffic for a few seconds), `gameOver` (you got squashed, drowned, or taken
by the eagle), and `opponentLeft`. Last otter standing wins.

On real devices this works the same way — run the relay on a host reachable
over the network (LAN IP or a server) and point `MultiplayerClient.defaultURL`
(iOS) / `MultiplayerClient.DEFAULT_URL` (Android) at it instead of the loopback
address.

## Controls

Tap to jump forward. Swipe up, down, left, or right to move in that direction.
