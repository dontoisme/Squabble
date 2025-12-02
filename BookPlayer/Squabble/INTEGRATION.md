# Squabble Integration Guide

This document describes how Squabble social features integrate with the BookPlayer codebase, and how to maintain compatibility with upstream BookPlayer updates.

## Directory Structure

```
BookPlayer/Squabble/
├── Core/
│   ├── SquabbleConfig.swift       # Feature flags and configuration
│   └── SquabbleManager.swift      # Central coordinator, initialization
├── Extensions/
│   ├── AppDelegate+Squabble.swift           # Firebase/Squabble setup
│   ├── LoadingCoordinator+Squabble.swift    # Auth gate
│   ├── PlayerManager+Squabble.swift         # Progress sync observer
│   └── PlayerViewController+Squabble.swift  # Ghost overlay and fetch
├── Models/
│   └── GhostMarker.swift          # Ghost progress marker model
├── Services/
│   ├── SquabbleAuthService.swift  # Firebase authentication
│   └── SquabbleSyncService.swift  # Firestore progress sync
├── Views/
│   ├── SquabbleLoginView.swift          # SwiftUI login screen
│   └── SquabbleGhostOverlayView.swift   # Ghost marker overlay
└── INTEGRATION.md                 # This file
```

## Integration Points

Squabble integrates with BookPlayer through **minimal hooks** in core files. All Squabble logic lives in the `Squabble/` directory.

### 1. AppDelegate.swift

**Hook:** Call `setupSquabble()` after Firebase is configured.

```swift
// Setup Firebase and Squabble - see AppDelegate+Squabble.swift
FirebaseApp.configure()
setupSquabble()
```

**What it does:** Initializes SquabbleManager, which sets up the playback observer for progress sync.

### 2. LoadingCoordinator.swift

**Hook:** Call `squabbleAuthGate()` from `didFinishLoadingSequence()`.

```swift
func didFinishLoadingSequence() {
  // SQUABBLE: Auth gate - see LoadingCoordinator+Squabble.swift
  squabbleAuthGate { [weak self] in
    self?.proceedToMainApp()
  }
}
```

**What it does:** Shows the Squabble login screen if the user is not authenticated. If authenticated, proceeds directly to the main app.

### 3. PlayerManager.swift

**Hook:** Call `postSquabbleProgressUpdate()` from `updatePlaybackTime()`.

```swift
// SQUABBLE: Post progress update notification - see PlayerManager+Squabble.swift
postSquabbleProgressUpdate(
  bookTitle: item.title,
  currentTime: time,
  duration: item.duration,
  percentCompleted: item.percentCompleted
)
```

**What it does:** Posts a notification that the SquabblePlaybackObserver listens for to trigger Firestore sync.

### 4. PlayerViewController.swift

**Hook:** Call `setupSquabbleGhostOverlay()` and `fetchAndDisplayGhosts()` from `setupPlayerView()`.

```swift
// SQUABBLE: Setup ghost overlay and fetch markers - see PlayerViewController+Squabble.swift
setupSquabbleGhostOverlay()
fetchAndDisplayGhosts(for: currentItem.title)
```

**What it does:** Adds a transparent overlay view for ghost markers and fetches guild members' progress from Firestore.

## Pulling Upstream Changes

When pulling updates from the upstream BookPlayer repository:

1. **Merge the upstream changes** into your branch
2. **Check the 4 integration points** listed above for conflicts
3. **Resolve conflicts** by keeping both the upstream code and the Squabble hooks
4. **Test** the app to ensure both BookPlayer and Squabble features work

### Files Modified from Upstream

| File | Modification |
|------|--------------|
| `AppDelegate.swift` | Added `FirebaseApp.configure()` and `setupSquabble()` |
| `LoadingCoordinator.swift` | Changed `didFinishLoadingSequence()` to use `squabbleAuthGate()` |
| `PlayerManager.swift` | Added `postSquabbleProgressUpdate()` call in `updatePlaybackTime()` |
| `PlayerViewController.swift` | Added ghost overlay setup in `setupPlayerView()` |

### Files NOT Modified

All other BookPlayer files remain unchanged, including:
- `ProgressSlider.swift` (ghost markers moved to overlay)
- All navigation, library, settings screens
- Watch app and extensions

## Extension Pattern

All Squabble functionality is added through Swift extensions, which:

1. **Don't modify core classes** - Only add new methods
2. **Use notifications** for loose coupling
3. **Check feature flags** before executing (via `SquabbleConfig`)
4. **Can be disabled** by setting `SquabbleConfig.isEnabled = false`

### Example: Adding a New Feature

To add a new Squabble feature that needs to hook into a BookPlayer class:

1. Create an extension file in `Squabble/Extensions/ClassName+Squabble.swift`
2. Add a minimal hook in the BookPlayer file that calls the extension method
3. Keep all logic in the extension file
4. Document the integration point in this file

## Feature Flags

`SquabbleConfig.swift` contains feature flags to enable/disable functionality:

```swift
static let isEnabled = true              // Master switch
static let ghostMarkersEnabled = true    // Ghost markers on progress bar
static let progressSyncEnabled = true    // Progress sync to Firestore
```

## Disabling Squabble

To completely disable Squabble features without removing code:

1. Set `SquabbleConfig.isEnabled = false`
2. The app will behave like vanilla BookPlayer

---

*Last updated: December 1, 2025*
