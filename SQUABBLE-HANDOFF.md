# Squabble Session Handoff

**Last Updated:** December 2, 2025

## Project Overview

Squabble is a social audiobook app built as a fork of [BookPlayer](https://github.com/TortugaPower/BookPlayer). It adds guild-based social features where friends can see each other's audiobook progress ("ghost markers") on the playback timeline.

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

### In Progress / Known Issues

#### Progress Sync to New Guild
Progress sync may not be working with newly created guilds. The sync service uses dynamic guild ID from `GuildService.shared.currentGuildId`. Debug by checking logs:
- `[Squabble] User already authenticated, loading guild...`
- `[Squabble] Loaded current guild: <name>`
- `[Squabble] Progress synced: <book> - X.X%`

If you see "Not syncing - no guild", the guild hasn't loaded yet.

**Note:** 5-minute throttle on syncs. Use pause (forceSyncProgress) to test faster.

### Not Started

#### Epic 2: Competitions/Races
- Create reading race for a book
- Set race parameters (start date, end date, goal)
- Join races
- Live leaderboard
- Race completion/results

#### Guild Library
- Display books being read by guild members
- Shared reading lists
- Book recommendations within guild

## File Structure

```
BookPlayer/Squabble/
├── Core/
│   ├── SquabbleConfig.swift          # Feature flags, logging
│   └── SquabbleManager.swift         # Central coordinator, auth listener
├── Debug/
│   └── SquabbleTestHelper.swift      # DEBUG only: seed fake members & progress
├── Extensions/
│   ├── AppDelegate+Squabble.swift    # Setup hook
│   ├── LoadingCoordinator+Squabble.swift  # Launch flow (no auth gate)
│   ├── PlayerManager+Squabble.swift  # Progress sync observer
│   └── PlayerViewController+Squabble.swift  # Ghost overlay setup
├── Models/
│   ├── GhostMarker.swift             # Progress marker model
│   └── Guild.swift                   # Guild & GuildMember models
├── Services/
│   ├── GuildService.swift            # Guild CRUD, Firestore listeners
│   ├── SquabbleAuthService.swift     # Firebase Auth wrapper
│   └── SquabbleSyncService.swift     # Progress sync to Firestore
├── Views/
│   ├── GuildView.swift               # Guild management UI (used in Settings)
│   ├── SettingsSquabbleSectionView.swift  # Settings section (unused now)
│   ├── SquabbleGhostOverlayView.swift     # Ghost markers on slider
│   ├── SquabbleLoginView.swift       # Auth UI
│   └── SquabbleProfileView.swift     # Profile tab replacement
└── INTEGRATION.md                    # Integration points documentation
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
origin    git@github.com:<your-username>/Squabble.git (your fork)
upstream  https://github.com/TortugaPower/BookPlayer.git (original)
```

To pull upstream fixes:
```bash
git fetch upstream
git merge upstream/main
```

## Next Steps

1. **Test progress sync** - Verify sync works with new guilds
2. **Guild Library** - Implement shared book list in profile
3. **Epic 2: Races** - Competition feature
4. **Polish UI** - Improve ghost marker visuals, animations
5. **Error handling** - Better user feedback for network errors

## Test Accounts

- test2@test.com (owner of "Goobers" guild, invite code: ZQ5LX9)
- Additional test accounts as needed

## Build Notes

- Xcode 15+
- iOS 18.0+ deployment target
- Firebase SDK via SPM
- Watch app schemes restored but not actively developed
