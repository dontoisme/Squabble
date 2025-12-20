# Squabble Session Handoff

**Last Updated:** December 19, 2025

---

## Latest Session Summary (Dec 19, 2025)

**What was done:**
- **Branding Complete** - Squabble Inn visual identity implemented
  - App icon (1024x1024 tavern theme - book + ale mug)
  - Splash screen with brown background (#432618)
  - Empty library image updated with Squabble Inn branding
  - Display name set to "Squabble Inn"
  - Removed legacy `AppIcon.icon` folder from project

- **Test Scenario for Device Testing** - "Tavern of Infinite Levels"
  - `SquabbleTestHelper.seedTestBookScenario()` - seeds 4 fake guildmates + 10 comments
  - Debug UI: Settings → Squabble Debug → "Seed Test Book Scenario"
  - 3 comments before user's position (visible immediately)
  - 7 comments ahead (reveal as you progress)
  - Duration matches real 20hr audiobook for realistic testing

- **MVP Documentation**
  - Added MVP punch list to ROADMAP.md
  - Added wild ideas to VISION.md (3D Guild Hall, Trinket Quality Tiers)
  - Theme storage architecture question documented

- **Brain PRD Archived**
  - Moved old PRD docs to `_archive/` folder
  - index.md now redirects to Squabble/docs/ as source of truth

- **Darwin Manifest Fixed**
  - Updated 9 file paths to match actual locations
  - `darwin manifest validate` now passes with no warnings

**MVP Polish Status:**
| Item | Status |
|------|--------|
| App Icon | ✅ Done |
| Splash Screen | ✅ Done |
| Empty Library Image | ✅ Done |
| Display Name | ✅ Done |
| Default Color Theme | Not started |

**Next steps:**
1. On-device testing with "Tavern of Infinite Levels" scenario
2. Manual test of spoiler-free comment reveal
3. Default color theme (if needed)
4. Then → TestFlight!

---

## Previous Session Summary (Dec 17, 2025)

**What was done:**
- **Epic 2.1 (Leave Comment)** - Integration tested and working with Firebase emulator
  - `CommentFlowIntegrationTests.swift` added - full flow test passes
  - Sign up → create guild → open player → post comment → sheet dismisses
- **Epic 2.2 (Display Comments)** - Code complete, ready for manual testing
  - Spoiler-free reveal system fully implemented
  - Real-time Firestore listener fetches comments up to current progress
  - Toast overlay appears when user passes comment timestamp
  - Timeline markers show passed comments
  - **Note:** Listener optimization attempted but deferred (caused test issues)
- **Firebase Emulator Integration** - Working setup for integration tests
  - Auth emulator on port 9099, Firestore on port 8080
  - Requires Node 18 via nvm (Node 25 has compatibility issues)

**Testing verified:**
- Comment posting to Firestore emulator works
- Guild creation and membership works
- Full comment flow end-to-end passes

**Next steps:** Manual testing of spoiler-free reveal in simulator, then Epic 3.1

---

## Darwin Integration (Visual Regression Testing)

Darwin is installed and configured for automatic visual regression testing.

### Quick Reference
```bash
darwin status           # See current state
darwin capture          # Smart capture (changed screens only)
darwin capture --all    # Capture all screens
darwin viewer           # Open visual timeline
darwin manifest sync    # Check if tests match manifest
darwin manifest sync --generate  # Generate missing test stubs
darwin manifest validate  # Check for missing source files
```

### Automation (Installed)
The git hook is installed in **auto mode**:
- After each commit with Swift changes → auto-captures affected screens
- Viewer is auto-regenerated after each capture
- Open `Screenshots/viewer.html` anytime to review changes

### Adding New Screens
1. Add screen entry to `Screenshots/manifest.json`
2. Run `darwin manifest sync --generate` to get test stub
3. Copy stub to `ScreenshotTests.swift` and implement navigation
4. Commit → auto-capture runs → viewer shows new screen

### Key Files
- `darwin.json` - Project configuration
- `Screenshots/manifest.json` - Screen definitions (29 screens)
- `Screenshots/index.json` - Capture timeline
- `Screenshots/viewer.html` - Interactive viewer (auto-generated)
- `Screenshots/captures/` - Screenshot storage by commit
- `BookPlayerUITests/ScreenshotTests.swift` - XCUITest screenshot tests

---

> **Quick Start Guide** - For detailed documentation, see the `/docs/` folder:
> - [VISION.md](./docs/VISION.md) - Product vision and philosophy (start here!)
> - [ROADMAP.md](./docs/ROADMAP.md) - Feature roadmap with MVP scope and acceptance criteria
> - [IMPLEMENTATION-PLANS.md](./docs/IMPLEMENTATION-PLANS.md) - Technical implementation plans for MVP epics
> - [ARCHITECTURE.md](./docs/ARCHITECTURE.md) - Technical architecture with Mermaid diagrams
> - [USER-JOURNEYS.md](./docs/USER-JOURNEYS.md) - All 26 user flows documented
> - [SCREEN-INVENTORY.md](./docs/SCREEN-INVENTORY.md) - All 45 screens with file paths
> - [SCREEN-MOCKUPS.md](./docs/SCREEN-MOCKUPS.md) - ASCII art screen mockups

## Project Overview

Squabble Inn is a social audiobook app built for LitRPG fans, forked from [BookPlayer](https://github.com/TortugaPower/BookPlayer). Core features:
- **Guilds** - Form a group of up to 6 readers (creator + 5 friends)
- **Ghost Markers** - See where guildmates are on the timeline in real-time
- **Timestamp Comments** - Leave Dark Souls-style reactions that only appear after guildmates pass that point (spoiler-free)

## Current Status

### Completed

#### Epic 0: Architecture Refactor ✅
Isolated Squabble code from BookPlayer core using extension pattern for clean upstream merges.

- **Directory Structure:** `BookPlayer/Squabble/{Core,Extensions,Models,Services,Views}/`
- **Extension Pattern:** All Squabble hooks are in extension files, minimal changes to BookPlayer core
- **Integration Points:** Documented in `BookPlayer/Squabble/INTEGRATION.md`

#### Epic 1: Guild System ✅
Full guild management with Firestore backend.

- Create guild with name
- Join guild via 6-character invite code
- View guild members with roles (owner/member)
- Leave guild (non-owners)
- Generate/share new invite codes
- Real-time Firestore listeners for updates

#### Profile Tab Hijack ✅
Replaced BookPlayer's Profile tab with Squabble guild hub.

- **Not signed in:** Sign in prompt
- **No guild:** Create/Join guild options
- **Has guild:** Guild info, members list, invite code, leave option
- Guild Library section (placeholder - "Coming soon")

#### Auth Flow Simplification ✅
Removed auth gate at app launch.

- App launches directly to Library
- Users sign in lazily when accessing guild features
- BookPlayer Pro/account UI hidden when Squabble enabled

#### Screenshot Automation ✅
XCUITest infrastructure for automated screenshot capture.

- **Test Target:** `BookPlayerUITests` with screenshot tests
- **CLI Script:** `./scripts/capture-screenshots.sh` runs all screenshot tests
- **Output:** Screenshots saved to `Screenshots/` folder with smart diffing
- **State Injection:** Mock auth/guild data via launch arguments

**UI Test Launch Arguments:**
- `--uitesting` - Enable UI test mode (bypasses Firebase)
- `--squabble-enabled` - Force Squabble features on
- `--disable-animations` - Speed up tests
- `--fresh-install` - Fresh state, not logged in
- `--logged-in` - Mock logged-in user, no guild
- `--with-guild` - Mock user with guild and 6 members
- `--with-books` - Copy test audiobook to library

**Key Test Files:**
- `BookPlayerUITests/BookPlayerUITests.swift` - Base test class with helpers
- `BookPlayerUITests/ScreenshotTests.swift` - Screenshot capture tests
- `BookPlayerUITests/Helpers/ScreenIdentifiers.swift` - Accessibility ID constants
- `BookPlayerUITests/Helpers/XCUIApp+Navigation.swift` - Navigation helpers
- `BookPlayerUITests/Helpers/XCUIApp+Screenshots.swift` - Screenshot capture helpers

**Mock State Injection:**
- `AppDelegate+Squabble.swift` - `setupUITestMode()` injects mock data
- `SquabbleAuthService.swift` - `setUITestState()` for mock auth
- `GuildService.swift` - `setUITestState()` for mock guild, skips Firestore in test mode

### In Progress / Known Issues

#### Progress Sync to New Guild
Progress sync may not be working with newly created guilds. The sync service uses dynamic guild ID from `GuildService.shared.currentGuildId`. Debug by checking logs:
- `[Squabble] User already authenticated, loading guild...`
- `[Squabble] Loaded current guild: <name>`
- `[Squabble] Progress synced: <book> - X.X%`

If you see "Not syncing - no guild", the guild hasn't loaded yet.

**Note:** 5-minute throttle on syncs. Use pause (forceSyncProgress) to test faster.

### Code Complete (Needs Manual Testing)

#### Epic 2: Timestamp Comments (Dark Souls Style) ✅
- **2.1 Leave Comment** ✅ - Comment button in player, posts to Firestore
  - `CommentInputView.swift` - Sheet with text input and timestamp badge
  - `PlayerCoordinator+Squabble.swift` - Presents comment sheet
  - `CommentsService.postComment()` - Writes to `guilds/{guildId}/comments`
- **2.2 Display Comments** ✅ - Spoiler-free reveal system
  - `CommentOverlayView.swift` - Toast popup with auto-dismiss
  - `CommentMarkerView.swift` - Timeline markers for passed comments
  - `CommentsService.startListening()` - Real-time Firestore listener
  - `CommentsService.getNewlyVisibleComments()` - Filters by progress
  - `PlayerViewController+Squabble.checkForNewlyVisibleComments()` - Called on progress update

**Integration Test:** `CommentFlowIntegrationTests.testUserCanPostCommentFromPlayer()`

### In Progress

#### Epic 3: Progress Sync & Ghost Markers (Partial)
- **3.1 Progress Sync** - Mostly done, some reliability issues with new guilds
- **3.2 Ghost Markers** - Complete
- **3.3 Active Book Tracking** - Not started

See [ROADMAP.md](./docs/ROADMAP.md) for full epic breakdown including Phase 2 (Delight) and Phase 3 (Monetization).

## File Structure

```
BookPlayer/Squabble/
├── Core/
│   ├── SquabbleConfig.swift          # Feature flags, logging
│   └── SquabbleManager.swift         # Central coordinator, auth listener
├── Debug/
│   └── SquabbleTestHelper.swift      # DEBUG only: seed fake members & progress
├── Extensions/
│   ├── AppDelegate+Squabble.swift    # Setup hook + UI test mode setup
│   ├── LoadingCoordinator+Squabble.swift  # Launch flow (no auth gate)
│   ├── PlayerCoordinator+Squabble.swift   # Comment sheet presentation
│   ├── PlayerManager+Squabble.swift  # Progress sync observer
│   └── PlayerViewController+Squabble.swift  # Ghost overlay + comment display
├── Models/
│   ├── Comment.swift                 # Comment model with timestamp
│   ├── GhostMarker.swift             # Progress marker model
│   └── Guild.swift                   # Guild & GuildMember models
├── Services/
│   ├── CommentsService.swift         # Comment CRUD, real-time listener, spoiler-free logic
│   ├── GuildService.swift            # Guild CRUD, Firestore listeners, UI test state
│   ├── SquabbleAuthService.swift     # Firebase Auth wrapper, UI test state
│   └── SquabbleSyncService.swift     # Progress sync to Firestore
├── Views/
│   ├── CommentInputView.swift        # Comment sheet with text input
│   ├── CommentMarkerView.swift       # Timeline markers for passed comments
│   ├── CommentOverlayView.swift      # Toast popup for revealed comments
│   ├── GuildView.swift               # Guild management UI (used in Settings)
│   ├── SettingsSquabbleSectionView.swift  # Settings section (unused now)
│   ├── SquabbleGhostOverlayView.swift     # Ghost markers on slider
│   ├── SquabbleLoginView.swift       # Auth UI
│   └── SquabbleProfileView.swift     # Profile tab replacement
└── INTEGRATION.md                    # Integration points documentation

BookPlayerUITests/
├── BookPlayerUITests.swift           # Base test class, helpers
├── ScreenshotTests.swift             # Screenshot capture tests (~28 screens)
├── FirebaseIntegrationTests.swift    # Base class for emulator-based tests
├── AuthFlowIntegrationTests.swift    # Auth integration tests
├── Helpers/
│   ├── ScreenIdentifiers.swift       # Accessibility ID constants
│   ├── XCUIApp+Navigation.swift      # Tab/screen navigation
│   └── XCUIApp+Screenshots.swift     # Screenshot capture to filesystem
└── Info.plist

scripts/
└── capture-screenshots.sh            # CLI to run screenshot tests

Screenshots/                          # Output folder for captured screenshots
├── *.png                             # Individual screenshots
└── README.md                         # Screenshot documentation

# Firebase Emulator Config
firebase.json                         # Emulator configuration
.firebaserc                          # Project ID reference
firestore.rules                      # Firestore security rules
```

## Firestore Structure

```
guilds/{guildId}
  - name: String
  - createdBy: String (userId)
  - createdAt: Timestamp
  - inviteCode: String (6-char alphanumeric)
  - memberCount: Int

guilds/{guildId}/members/{userId}
  - displayName: String
  - email: String
  - role: "owner" | "member"
  - joinedAt: Timestamp

guilds/{guildId}/progress/{bookId_userId}
  - bookId: String
  - bookTitle: String
  - userId: String
  - userEmail: String
  - progressPercent: Double
  - progressTimestamp: Double
  - totalDuration: Double
  - lastUpdatedAt: Timestamp
  - isActive: Bool

users/{userId}
  - currentGuildId: String
  - email: String
```

## Key Configuration

**SquabbleConfig.swift:**
```swift
static let isEnabled = true              // Master toggle
static let ghostMarkersEnabled = true    // Ghost markers on timeline
static let progressSyncEnabled = true    // Sync progress to Firestore
static let syncIntervalSeconds = 300     // 5 min throttle
static let debugLoggingEnabled = true    // Console logging
```

## BookPlayer Core Modifications

Minimal changes to BookPlayer files (marked with `// SQUABBLE:` comments):

1. **AppDelegate.swift** - Calls `SquabbleManager.shared.setup()`
2. **LoadingCoordinator.swift** - Calls `squabbleAuthGate(completion:)`
3. **PlayerManager.swift** - Posts progress notification
4. **PlayerViewController.swift** - Calls ghost overlay setup
5. **MainView.swift** - Swaps Profile tab content
6. **SettingsView.swift** - Hides BookPlayer Pro UI
7. **SettingsScreen.swift** - Added `squabbleGuild` case

## Git Remotes

```
origin    git@github.com:dontoisme/Squabble.git (your fork)
upstream  https://github.com/TortugaPower/BookPlayer.git (original)
```

## Upstream Sync Strategy

Squabble is powered by BookPlayer's audio engine. As Squabble develops its own visual identity (Squabble Inn branding), we'll diverge from upstream UI but want to keep the core playback engine updated.

### Current Phase: Full Merge (Safe)

While our changes are limited to the 7 integration points + `/BookPlayer/Squabble/` folder, full merges are safe:

```bash
# 1. Fetch and check what changed
git fetch upstream
git diff develop...upstream/develop --stat

# 2. Check if our integration points were touched
git diff develop...upstream/develop --stat | grep -E "(AppDelegate|LoadingCoordinator|PlayerManager|PlayerViewController|MainView|SettingsView|SettingsScreen)"

# 3. If clean, merge
git merge upstream/develop
```

**Last sync:** Dec 14, 2025 (commit `ac25fec3`) - 17 upstream commits merged cleanly.

### Future Phase: Cherry-Pick Bug Fixes Only

Once we start heavy UI customization (Squabble Inn theming), switch to selective cherry-picking:

```bash
# Find bug fix commits in upstream (look for "fix" in messages)
git log upstream/develop --oneline --grep="fix" | head -20

# Cherry-pick specific commits
git cherry-pick <commit-hash>
```

**What to cherry-pick:**
- Audio engine bug fixes (`PlayerManager`, `AudioPlayer`, codecs)
- Core data / storage fixes
- Crash fixes
- Performance improvements

**What to skip:**
- UI changes (we'll have our own)
- New BookPlayer features (unless relevant)
- Theming changes (we have Squabble themes)

### Files We Care About (Audio Engine)

These are the core playback files worth watching for upstream fixes:
- `Shared/Player/` - Core audio playback
- `Shared/Services/Sync/` - Sync engine
- `Shared/Models/` - Data models
- `BookPlayer/Utils/` - Utilities
- `BookPlayerKit/` - Core framework

### Integration Points (Our Modifications)

These 7 files have `// SQUABBLE:` markers. Conflicts here need manual resolution:
1. `AppDelegate.swift`
2. `LoadingCoordinator.swift`
3. `PlayerManager.swift`
4. `PlayerViewController.swift`
5. `MainView.swift`
6. `SettingsView.swift`
7. `SettingsScreen.swift`

## Next Steps

#### Firebase Integration Testing ✅
Firebase Emulator setup for integration tests that exercise real Firebase flows.

**Configuration Files:**
- `firebase.json` - Emulator configuration (Auth on 9099, Firestore on 8080)
- `.firebaserc` - Project ID (`squabble-app-fbc28`)
- `firestore.rules` - Security rules for development

**Integration Test Files:**
- `BookPlayerUITests/FirebaseIntegrationTests.swift` - Base class with emulator verification, sign-out helpers
- `BookPlayerUITests/AuthFlowIntegrationTests.swift` - Auth tests (signup, signin, signout, validation)
- `BookPlayerUITests/GuildFlowIntegrationTests.swift` - Guild tests (create, join, leave, members)
- `BookPlayerUITests/ProgressSyncIntegrationTests.swift` - Playback tests with audiobook import

**Launch Arguments:**
- `--use-emulator` - Connect to local Firebase emulators (NOT mock data)
- `--with-books` - Copy test audiobook to library (for playback tests)

**Test Coverage (14 tests):**
- AuthFlowIntegrationTests: 5 tests (signup, signin, signout, validation)
- GuildFlowIntegrationTests: 7 tests (create, join via code, leave, members)
- ProgressSyncIntegrationTests: 2 tests (playback with/without guild)

**Running Integration Tests:**
```bash
# 1. Start emulators (requires Node.js 18/20, not 25)
export NVM_DIR="$HOME/.nvm" && . "$NVM_DIR/nvm.sh" && nvm use 20
firebase emulators:start --only auth,firestore

# 2. Reset simulator (REQUIRED before running multiple test suites)
xcrun simctl erase <SIMULATOR_ID>

# 3. Run individual test suite
xcodebuild test -project BookPlayer.xcodeproj -scheme BookPlayer \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:BookPlayerUITests/GuildFlowIntegrationTests

# Or run specific test
xcodebuild test ... -only-testing:BookPlayerUITests/AuthFlowIntegrationTests/testUserCanSignUpWithEmail
```

**Test Isolation:**
- Each test calls `ensureSignedOut()` in setup to clear auth state
- For running multiple test suites in sequence, reset simulator AND restart emulators between suites
- This is because auth state persists in the emulator across test runs

**Firebase Emulator Ports:**
- Auth: `http://127.0.0.1:9099`
- Firestore: `http://127.0.0.1:8080`
- Emulator UI: `http://127.0.0.1:4000`

**Key Implementation:**
- `AppDelegate+Squabble.swift` - `setupFirebaseEmulators()` method configures Auth and Firestore to use local emulators when `--use-emulator` flag is present

**Note:** Integration tests use button LABELS (not accessibility identifiers) because SwiftUI parent view identifiers can override child identifiers. Example: `app.buttons["Sign In / Sign Up"]` instead of `findElement(ScreenIdentifiers.Profile.buttonSignIn)`

### Ghost Marker Visual Polish (2025-12-13) ✅

Enhanced `SquabbleGhostOverlayView.swift` with improved visuals:
- **Gradient circles** instead of solid colors (vertical gradient with alpha)
- **Initials inside markers** - Shows "JD" for "John Doe", etc.
- **Glow/shadow effects** - Colored shadow matching member color
- **White border** - 1.5pt stroke for visibility
- **22px diameter** markers positioned on slider track

### Screenshot Manifest Complete (2025-12-13) ✅

All screenshot gaps have been closed:

**Screens 06-08 (Library):**
- **06-item-details**: Metadata editor for books (title, author, artwork)
- **07-library-selection-mode**: Multi-select mode with bottom toolbar
- **08-library-add-menu**: More menu showing add files and sort options

**Screens 12-13 (Player):**
- **12-player-controls**: Speed and boost volume controls sheet
- **13-player-sleep-timer**: Sleep timer action sheet

**Screen 26 (Settings):**
- **26-settings-integrations**: Integrations settings screen

**Files Modified:**
- `BookPlayer/Library/ItemDetails/ItemDetailsView.swift` - Added accessibility identifier
- `BookPlayer/Library/ItemList/ItemListView.swift` - Added menu identifier
- `BookPlayer/Player/Controls/PlayerControlsView.swift` - Added sheet identifier
- `BookPlayer/Player/Player Screen/PlayerViewController.swift` - Added speed/sleep button identifiers
- `BookPlayerUITests/ScreenshotTests.swift` - Added tests 06-08, 12-13
- `BookPlayerUITests/Helpers/ScreenIdentifiers.swift` - Added new identifiers
- `Screenshots/manifest.json` - Added all new screen entries

### MVP Next Steps
1. **Epic 2.1** - Leave Comment at Timestamp (new view: `CommentInputView.swift`)
2. **Epic 2.2** - Display Comments (spoiler-free reveal as user progresses)
3. **Epic 3.1** - Fix progress sync reliability with new guilds

### Future Phases
- **Phase 2 (Delight):** Achievements, themes, guild library, comment history
- **Phase 3 (Monetization):** Tier system (Traveler, Resident Adventurer, Guild Master, Ascendant Adventurer)

See [ROADMAP.md](./docs/ROADMAP.md) for complete breakdown.

### Progress Sync Debug (2025-12-13)

**Issue:** Progress sync may not work with newly created guilds.

**Root Cause Analysis:**
- `SquabbleSyncService.syncProgress()` reads `GuildService.shared.currentGuildId`
- `currentGuild` is a `@Published` property set on MainActor
- Progress notifications from `PlayerManager` may come from background thread
- Reading `currentGuild` from background thread could race with MainActor updates

**Fix Applied:**
- Added thread-safe `guildId` property that dispatches to main thread if called from background
- Added debug logging to track when guildId is nil and why:
  - `SquabbleSyncService.swift` - logs userId, guild name, isMainThread when sync skipped
  - `GuildService.swift` - logs when currentGuild is set and listeners started

**Testing:**
To verify the fix, check Console.app for `[Squabble]` logs when:
1. Create a new guild
2. Start playing an audiobook immediately after
3. Should see "Progress synced" logs, not "Not syncing - no guild"

## Test Accounts

- test2@test.com (owner of "Goobers" guild, invite code: ZQ5LX9)
- Additional test accounts as needed

## Build Notes

- Xcode 15+
- iOS 18.0+ deployment target
- Firebase SDK via SPM
- Watch app schemes restored but not actively developed
