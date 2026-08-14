# Jumpy Otter

[![Built with Devin](https://img.shields.io/badge/Built%20with-Devin-blue)](https://devin.ai)

Jumpy Otter is a voxel-style iOS arcade game set in San Francisco. Guide Devin the otter through traffic, trains, and the bay while collecting creatine bottles.

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

Then launch the game in up to four simulators — each client connects to the
relay automatically at startup (and silently stays single-player if the relay
isn't running). Rivals appear as translucent ghost otters with a colored
marker, plus a live score strip in the top-right corner.

Messages exchanged: `state` (position + score, drives the ghost otters and
rival scores), `garbage` (collecting a creatine bottle surges rivals' road
traffic for a few seconds), `gameOver` (you got squashed, drowned, or taken
by the eagle), and `opponentLeft`. Last otter standing wins.

On real devices this works the same way — run the relay on a host reachable
over the network (LAN IP or a server) and point `MultiplayerClient.defaultURL`
at it instead of `127.0.0.1`.

## Controls

Tap to jump forward. Swipe up, down, left, or right to move in that direction.
