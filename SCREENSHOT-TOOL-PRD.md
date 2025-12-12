# Screenshot Timelapse Tool - Mini PRD

## Overview

A tool to capture the visual evolution of BookPlayer → Squabble through automated screenshots, enabling a timelapse of the app's transformation.

## Goals

1. **Baseline capture**: Full "deep dive" screenshot of every screen as the starting point
2. **Incremental capture**: Smart detection of which screens changed, only re-capturing those
3. **Organized output**: Screenshots organized by commit for easy timelapse assembly
4. **Future video**: Eventually stitch into a video with smart zoom/focus on changing areas

## Non-Goals (for now)

- Automatic video generation
- Visual diff highlighting
- CI/CD integration
- Cross-device screenshots (just iPhone 17 Pro for now)

---

## Workflow

### 1. Baseline Run (First Time)

```bash
./scripts/capture-screenshots.sh --baseline
```

- Captures ALL screens (~25-30)
- Saves to `Screenshots/baseline/`
- Creates manifest of screen → source file mappings

### 2. Incremental Run (After Changes)

```bash
./scripts/capture-screenshots.sh
```

- Checks git diff for modified view files
- Maps changed files → affected screens
- Only captures screens that changed
- Saves to `Screenshots/<commit-hash>/`
- Copies unchanged screens from previous run (or baseline)

---

## Folder Structure

```
Screenshots/
├── baseline/                    # Initial full capture
│   ├── manifest.json            # Screen → source file mappings
│   ├── 01-library-empty.png
│   ├── 02-library-with-books.png
│   └── ...
├── a1b2c3d/                      # Commit short hash
│   ├── metadata.json            # What changed, timestamp, etc.
│   ├── 14-profile-not-logged-in.png  # Only changed screens
│   └── 19-guild-view.png
├── e4f5g6h/                      # Next commit
│   ├── metadata.json
│   └── 21-settings-main.png
└── README.md
```

---

## Screen → Source File Mapping

The tool needs to know which Swift files affect which screens:

```json
{
  "screens": {
    "01-library-empty": {
      "name": "Library (Empty)",
      "sources": [
        "BookPlayer/Library/ItemList/ItemListView.swift",
        "BookPlayer/Library/LibraryRootView.swift"
      ]
    },
    "14-profile-not-logged-in": {
      "name": "Profile (Not Logged In)",
      "sources": [
        "BookPlayer/Squabble/Views/SquabbleProfileView.swift"
      ]
    },
    "19-guild-view": {
      "name": "Guild View",
      "sources": [
        "BookPlayer/Squabble/Views/SquabbleProfileView.swift",
        "BookPlayer/Squabble/Views/GuildView.swift"
      ]
    },
    "21-settings-main": {
      "name": "Settings Main",
      "sources": [
        "BookPlayer/Settings/SettingsView.swift",
        "BookPlayer/Settings/SettingsScreen.swift"
      ]
    }
  }
}
```

---

## Diff Detection Logic

```
1. Get list of changed files since last capture:
   git diff --name-only <last-commit> HEAD -- '*.swift'

2. For each changed file:
   - If in "shared" list → mark ALL screens for capture
   - If maps to specific screen(s) → mark those screens

3. Run only marked screen tests

4. Save results to Screenshots/<current-commit>/
```

---

## Metadata File

Each run creates `metadata.json`:

```json
{
  "commit": "a1b2c3d",
  "timestamp": "2025-12-12T11:30:00Z",
  "parent_commit": "baseline",
  "changed_files": [
    "BookPlayer/Squabble/Views/SquabbleProfileView.swift"
  ],
  "captured_screens": [
    "14-profile-not-logged-in",
    "16-profile-no-guild",
    "19-guild-view"
  ],
  "skipped_screens": [
    "10-player-chapters"
  ],
  "inherited_from": {
    "01-library-empty": "baseline",
    "21-settings-main": "baseline"
  }
}
```

---

## Screen List (28 Total)

### Library Tab (8)
| ID | Screen | Key Source Files |
|----|--------|------------------|
| 01 | Library Empty | ItemListView, LibraryRootView |
| 02 | Library With Books | ItemListView |
| 03 | Library Folder | ItemListView |
| 04 | Library Search | SearchView |
| 05 | Library Mini Player | MiniPlayerView |
| 06 | Library Edit Mode | ItemListView |
| 07 | Book Details | BookDetailsView |
| 08 | Import Screen | ImportView |

### Player Tab (5)
| ID | Screen | Key Source Files |
|----|--------|------------------|
| 09 | Player Main | PlayerView |
| 10 | Player Chapters | ChaptersView |
| 11 | Player Bookmarks | BookmarksView |
| 12 | Player Controls | PlayerControlsView |
| 13 | Player Ghost Markers | PlayerView |

### Profile/Guild Tab (7)
| ID | Screen | Key Source Files |
|----|--------|------------------|
| 14 | Profile Not Logged In | SquabbleProfileView |
| 15 | Profile Login Sheet | SquabbleLoginView |
| 16 | Profile No Guild | SquabbleProfileView |
| 17 | Guild Create Sheet | CreateGuildView |
| 18 | Guild Join Sheet | JoinGuildView |
| 19 | Guild View | SquabbleProfileView, GuildView |
| 20 | Guild Invite Code | InviteCodeView |

### Settings Tab (8)
| ID | Screen | Key Source Files |
|----|--------|------------------|
| 21 | Settings Main | SettingsView |
| 22 | Settings Themes | ThemesView |
| 23 | Settings Icons | IconsView |
| 24 | Settings Controls | ControlsSettingsView |
| 25 | Settings Storage | StorageView |
| 26 | Settings Integrations | IntegrationsView |
| 27 | Settings Hardcover | HardcoverSettingsView |
| 28 | Settings Debug | SquabbleDebugView |

---

## Implementation Phases

### Phase 1: Baseline Infrastructure (Current)
- [x] XCUITest target setup
- [x] Screenshot capture to filesystem
- [x] Basic CLI script
- [ ] Screen manifest file
- [ ] Baseline capture command

### Phase 2: Smart Diffing
- [ ] Git diff integration
- [ ] File → screen mapping
- [ ] Incremental capture logic
- [ ] Metadata generation

### Phase 3: Commit Organization
- [ ] Folder-per-commit structure
- [ ] Inheritance from previous runs
- [ ] Full screenshot set reconstruction

### Phase 4: Video Generation (Future)
- [ ] Timelapse stitching
- [ ] Smart zoom/pan on changed areas
- [ ] Transition effects between commits

---

## Decisions

1. **Shared file changes**: Lightweight approach - only trigger on direct view file changes. Use `--all` manually if theme/shared changes need capturing. Can get smarter later.

2. **Screens requiring state**: Tests will be improved over time to properly seed states (logged in, has books, has guild). For now, accept some screens may be skipped.

3. **Storage**: ~14MB per full run is acceptable. Incremental runs will be much smaller (only changed screens).

---

## Commands (Proposed)

```bash
# First time: capture everything
./scripts/capture-screenshots.sh --baseline

# After changes: smart capture
./scripts/capture-screenshots.sh

# Force full recapture
./scripts/capture-screenshots.sh --all

# Capture specific screen(s)
./scripts/capture-screenshots.sh --screens 14,19,21

# List what would be captured (dry run)
./scripts/capture-screenshots.sh --dry-run

# Reconstruct full set for a commit (pulls from inheritance chain)
./scripts/capture-screenshots.sh --reconstruct a1b2c3d
```
