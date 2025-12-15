# Firebase Emulator Cheatsheet

## Quick Start

```bash
# Start emulators (from project root)
export NVM_DIR="$HOME/.nvm" && . "$NVM_DIR/nvm.sh" && nvm use 20 && firebase emulators:start --only auth,firestore
```

## Emulator URLs

| Service    | URL                          |
|------------|------------------------------|
| UI Console | http://127.0.0.1:4000        |
| Auth       | http://127.0.0.1:9099        |
| Firestore  | http://127.0.0.1:8080        |

## Running Integration Tests

```bash
# 1. Start emulators (in one terminal)
export NVM_DIR="$HOME/.nvm" && . "$NVM_DIR/nvm.sh" && nvm use 20
firebase emulators:start --only auth,firestore

# 2. Reset simulator for clean state (optional but recommended)
xcrun simctl erase 22BE4F9F-B3B4-45DB-B4A2-5CB30A4F9E82

# 3. Run tests (in another terminal)
xcodebuild test -project BookPlayer.xcodeproj -scheme BookPlayer \
  -destination 'platform=iOS Simulator,id=22BE4F9F-B3B4-45DB-B4A2-5CB30A4F9E82' \
  -only-testing:BookPlayerUITests/AuthFlowIntegrationTests
```

## Stop Emulators

```bash
# Ctrl+C in the terminal, or:
pkill -f "firebase.*emulator"
```

## Troubleshooting

**"Cannot read properties of undefined"** - Wrong Node version
```bash
nvm use 20  # Firebase CLI needs Node 18 or 20, not 25
```

**Test fails finding buttons** - Stale auth state
```bash
xcrun simctl erase <SIMULATOR_ID>  # Reset simulator
pkill -f "firebase.*emulator"       # Restart emulators fresh
```

**Find simulator ID**
```bash
xcrun simctl list devices available | grep -E "iPhone.*(Booted|17)"
```
