# Squabble Screenshots

This folder contains automated screenshots of the Squabble app for timelapse documentation.

## Captured Screens

### Library Tab
- `01-library-empty.png` - Empty library state
- `02-library-with-books.png` - Library with audiobooks
- `03-library-folder.png` - Inside a folder
- `04-library-search.png` - Search active
- `05-library-miniplayer.png` - Mini player visible

### Player
- `09-player-main.png` - Full player view
- `10-player-chapters.png` - Chapters list
- `11-player-bookmarks.png` - Bookmarks view

### Profile/Guild (Squabble)
- `14-profile-not-logged-in.png` - Unauthenticated state
- `15-profile-login-sheet.png` - Login sheet
- `16-profile-no-guild.png` - Logged in, no guild
- `17-guild-create-sheet.png` - Create guild sheet
- `18-guild-join-sheet.png` - Join guild sheet
- `19-guild-view.png` - Active guild with members
- `20-guild-invite-code.png` - Invite code sheet

### Settings
- `21-settings-main.png` - Settings main view
- `22-settings-themes.png` - Theme picker
- `23-settings-icons.png` - App icon picker
- `24-settings-controls.png` - Player control settings
- `25-settings-storage.png` - Storage management
- `27-settings-hardcover.png` - Hardcover settings
- `28-settings-debug.png` - Squabble debug tools

## Capturing Screenshots

Run the capture script:
```bash
./scripts/capture-screenshots.sh
```

Options:
- `--archive` - Create a timestamped archive after capture
- `--clean` - Remove all existing screenshots
- `--help` - Show help

## Requirements

1. XCUITest target must be added to the project (see setup below)
2. Accessibility identifiers must be added to key views
3. xcpretty must be installed (`gem install xcpretty`)

## Adding XCUITest Target

In Xcode:
1. File > New > Target
2. Select "UI Testing Bundle"
3. Name: `BookPlayerUITests`
4. Move existing files from `BookPlayerUITests/` into the new target
5. Build and run tests
