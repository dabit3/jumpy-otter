# Jumpy Otter iOS — Build & Gameplay Test Plan

Setup done: fresh `xcodebuild` BUILD SUCCEEDED (iPhone 17 sim, iOS 26.2, UDID 53EECADE-52AF-4C6E-A2D6-5522E6E568CB, booted). idb (python3.13) + idb_companion available.

## Test 1: It should install and launch to the title screen
1. `xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/JumpyOtter.app`
2. `xcrun simctl launch booted com.devin.jumpyotter`
- Pass: launch returns a PID; screenshot shows Jumpy Otter title screen (not a crash/black screen).

## Test 2: It should play and achieve as high a score as possible (recorded)
1. Start `xcrun simctl io booted recordVideo --force ../videos/jumpy-otter-highscore.mp4` in background.
2. Tap anywhere to start. Manual play: screenshot before each hop (`xcrun simctl io booted screenshot`), tap (201,600) to hop forward when lane ahead is safe; use `idb ui swipe` laterally to dodge cars/align with logs.
3. Play until game over; note SCORE. Retry (tap) up to ~3 runs to improve the best score. Only if manual play scores <5 across attempts, fall back to AUTOPILOT launch arg and clearly note it.
4. Capture screenshot of the game-over score screen for the best run.
5. SIGINT recorder; confirm "Wrote video to:" and verify file exists with nonzero size and sane duration.
- Pass: at least one full run completes to "GAME OVER / SCORE"; on-screen score matches reported score; video file valid in videos/ dir.
