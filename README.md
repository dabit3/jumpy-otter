# Jumpy Otter

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

## Controls

Tap to jump forward. Swipe up, down, left, or right to move in that direction.
