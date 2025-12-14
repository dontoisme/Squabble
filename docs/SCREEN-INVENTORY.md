# Squabble Screen Inventory

> Quick lookup of all screens with file paths and accessibility IDs.
> Last updated: December 2025

## Summary

| Category | Screen Count |
|----------|-------------|
| Library | 12 |
| Player | 5 |
| Profile/Guild | 8 |
| Settings | 17 |
| Utility | 3 |
| **Total** | **45** |

---

## Library Screens (12)

| Screen | File Path | Accessibility ID | Notes |
|--------|-----------|------------------|-------|
| **Main Tab View** | `MainView.swift` | `mainview_tab_library` | Tab container |
| **Library Root** | `Library/ItemList/LibraryRootView.swift` | - | NavigationStack root |
| **Item List** | `Library/ItemList/ItemListView.swift` | `library_list_items` | Books/folders list |
| **Empty List** | `Library/ItemList/Views/EmptyListView.swift` | `library_view_empty` | Empty state |
| **Mini Player** | `Library/MiniPlayer/MiniPlayerView.swift` | `library_miniplayer` | Bottom player bar |
| **Item Details** | `Library/ItemDetails/ItemDetailsView.swift` | `itemdetails_view_main` | Edit metadata sheet |
| **Folder Selection** | `Library/FolderSelection/FolderSelectionView.swift` | - | Move items sheet |
| **Import Screen** | `Import/ImportViewController.swift` | - | UIKit import progress |
| **Jellyfin Root** | `Jellyfin/JellyfinRootView.swift` | - | Server browser |
| **Jellyfin Library** | `Jellyfin/JellyfinLibraryView.swift` | - | Library contents |
| **AudiobookShelf Root** | `AudiobookShelf/AudiobookShelfRootView.swift` | - | Server browser |
| **AudiobookShelf Library** | `AudiobookShelf/AudiobookShelfLibraryView.swift` | - | Library contents |

---

## Player Screens (5)

| Screen | File Path | Accessibility ID | Notes |
|--------|-----------|------------------|-------|
| **Full Player** | `Player/Player Screen/PlayerViewController.swift` | - | UIKit main player |
| **Player Controls** | `Player/Controls/PlayerControlsView.swift` | - | Speed/volume sheet |
| **Chapters** | `Player/Chapters/ChaptersView.swift` | `player_button_chapters` | Chapter list sheet |
| **Bookmarks** | `Player/Bookmarks/BookmarksView.swift` | `player_button_bookmarks` | Bookmarks sheet |
| **Ghost Overlay** | `Squabble/Views/SquabbleGhostOverlayView.swift` | - | UIView on slider |

---

## Profile/Guild Screens (8)

| Screen | File Path | Accessibility ID | Notes |
|--------|-----------|------------------|-------|
| **Profile Tab** | `MainView.swift` | `mainview_tab_profile` | Tab container |
| **Squabble Profile** | `Squabble/Views/SquabbleProfileView.swift` | - | Guild hub (replaces Profile) |
| **Not Logged In** | `Squabble/Views/SquabbleProfileView.swift` | - | Nested view |
| **No Guild** | `Squabble/Views/SquabbleProfileView.swift` | - | Nested view |
| **Guild Profile** | `Squabble/Views/SquabbleProfileView.swift` | - | Nested view |
| **Login View** | `Squabble/Views/SquabbleLoginView.swift` | - | Auth sheet |
| **Create Guild** | `Squabble/Views/GuildView.swift` | - | Create form sheet |
| **Join Guild** | `Squabble/Views/GuildView.swift` | - | Join form sheet |
| **Invite Code** | `Squabble/Views/GuildView.swift` | `guild_button_invite` | Share code sheet |

### Profile Button Identifiers

| Button | Accessibility ID |
|--------|------------------|
| Sign In/Sign Up | `profile_button_signin` |
| Create Guild | `profile_button_createguild` |
| Join with Code | `profile_button_joinguild` |
| View Invite Code | `guild_button_invite` |

---

## Settings Screens (17)

| Screen | File Path | Accessibility ID | Notes |
|--------|-----------|------------------|-------|
| **Settings Tab** | `MainView.swift` | `mainview_tab_settings` | Tab container |
| **Settings Main** | `Settings/SettingsView.swift` | - | Settings hub |
| **Themes** | `Settings/Themes/SettingsThemesView.swift` | - | Theme picker |
| **App Icons** | `Settings/Icons/SettingsAppIconsView.swift` | - | Icon picker |
| **Player Controls** | `Settings/Sections/PlayerControls/SettingsPlayerControlsView.swift` | - | Playback settings |
| **Autoplay** | `Settings/Autoplay/SettingsAutoplayView.swift` | - | Autoplay config |
| **Autolock** | `Settings/Autolock/SettingsAutolockView.swift` | - | Screen timeout |
| **Storage** | `Settings/Storage/StorageView.swift` | - | Disk usage |
| **Cloud Sync** | `Settings/Storage/StorageCloudDeletedView.swift` | - | Backup/restore |
| **Jellyfin Settings** | `Jellyfin/JellyfinRootView.swift` | - | Connection config |
| **AudiobookShelf Settings** | `AudiobookShelf/AudiobookShelfRootView.swift` | - | Connection config |
| **Hardcover** | `Hardcover/Settings Page/HardcoverSettingsView.swift` | - | Metadata service |
| **Tip Jar** | `Settings/Sections/SettingsTipJarView.swift` | - | Support dev |
| **Tips** | `Settings/Sections/SettingsTipView.swift` | - | Usage tips |
| **Credits** | `Settings/Sections/CreditsView.swift` | - | Contributors |
| **Contributors** | `Settings/Sections/ContributorsListView.swift` | - | Full list |
| **Squabble Debug** | `Squabble/Views/SettingsSquabbleDebugSectionView.swift` | - | DEBUG only |

---

## Search Screen (1)

| Screen | File Path | Accessibility ID | Notes |
|--------|-----------|------------------|-------|
| **Search Tab** | `Search/SearchView.swift` | `mainview_tab_search` | iOS 26+ only |

---

## Utility Screens (3)

| Screen | File Path | Accessibility ID | Notes |
|--------|-----------|------------------|-------|
| **Loading** | `Loading/LoadingViewController.swift` | - | App startup |
| **Root** | `RootViewController.swift` | - | Main container |
| **Onboarding** | `Onboarding/OnboardingViewController.swift` | - | First launch |

---

## BookPlayer Profile Screens (when Squabble disabled)

| Screen | File Path | Notes |
|--------|-----------|-------|
| **Profile View** | `Profile/Profile/ProfileView.swift` | Account stats |
| **Login View** | `Profile/Login/LoginView.swift` | BookPlayer auth |
| **Account View** | `Profile/Account/AccountView.swift` | Subscription mgmt |
| **Complete Account** | `Profile/CompleteAccount/CompleteAccountView.swift` | Purchase flow |
| **Queued Tasks** | `Profile/Profile/QueuedSyncTasksView.swift` | Sync queue |

---

## Screenshot Test Mapping

Maps automated screenshot tests to screens:

| Test | Screenshot | Screen |
|------|------------|--------|
| `test01` | `01-library-empty.png` | EmptyListView |
| `test02` | `02-library-with-books.png` | ItemListView |
| `test03` | `03-library-folder.png` | ItemListView (nested) |
| `test04` | `04-library-search.png` | SearchView |
| `test05` | `05-library-miniplayer.png` | MiniPlayerView |
| `test06` | `06-item-details.png` | ItemDetailsView |
| `test07` | `07-library-selection-mode.png` | ItemListView (edit mode) |
| `test08` | `08-library-add-menu.png` | ItemListView (dialog) |
| `test09` | `09-player-main.png` | PlayerViewController |
| `test10` | `10-player-chapters.png` | ChaptersView |
| `test11` | `11-player-bookmarks.png` | BookmarksView |
| `test12` | `12-player-controls.png` | PlayerControlsView |
| `test13` | `13-player-sleep-timer.png` | PlayerViewController (sheet) |
| `test14` | `14-profile-not-logged-in.png` | SquabbleProfileView |
| `test15` | `15-profile-login-sheet.png` | SquabbleLoginView |
| `test16` | `16-profile-no-guild.png` | SquabbleProfileView |
| `test17` | `17-guild-create-sheet.png` | CreateGuildView |
| `test18` | `18-guild-join-sheet.png` | JoinGuildView |
| `test19` | `19-guild-view.png` | SquabbleProfileView |
| `test20` | `20-guild-invite-code.png` | InviteCodeView |
| `test21` | `21-settings-main.png` | SettingsView |
| `test22` | `22-settings-themes.png` | SettingsThemesView |
| `test23` | `23-settings-icons.png` | SettingsAppIconsView |
| `test24` | `24-settings-controls.png` | SettingsPlayerControlsView |
| `test25` | `25-settings-storage.png` | StorageView |
| `test26` | `26-settings-integrations.png` | SettingsView (section) |
| `test27` | `27-settings-hardcover.png` | HardcoverSettingsView |
| `test28` | `28-settings-debug.png` | SettingsSquabbleDebugSectionView |

---

## Accessibility Identifier Reference

Quick lookup for UI testing:

```swift
// Library
ScreenIdentifiers.Library.listItems       // "library_list_items"
ScreenIdentifiers.Library.viewEmpty       // "library_view_empty"
ScreenIdentifiers.Library.miniPlayer      // "library_miniplayer"
ScreenIdentifiers.Library.menuMore        // "library_menu_more"

// Item Details
ScreenIdentifiers.ItemDetails.viewMain    // "itemdetails_view_main"

// Player
ScreenIdentifiers.Player.buttonChapters   // "player_button_chapters"
ScreenIdentifiers.Player.buttonBookmarks  // "player_button_bookmarks"
ScreenIdentifiers.Player.buttonSleep      // "player_button_sleep"

// Profile/Guild
ScreenIdentifiers.Profile.buttonSignin    // "profile_button_signin"
ScreenIdentifiers.Profile.buttonCreateGuild // "profile_button_createguild"
ScreenIdentifiers.Profile.buttonJoinGuild // "profile_button_joinguild"
ScreenIdentifiers.Guild.buttonInvite      // "guild_button_invite"

// Tabs
"mainview_tab_library"
"mainview_tab_profile"
"mainview_tab_settings"
"mainview_tab_search"
```

---

## File Path Patterns

```
BookPlayer/
├── Library/
│   ├── ItemList/           # Main library views
│   ├── ItemDetails/        # Edit metadata
│   ├── MiniPlayer/         # Bottom player bar
│   └── FolderSelection/    # Move items
├── Player/
│   ├── Player Screen/      # Full player (UIKit)
│   ├── Controls/           # Speed/volume
│   ├── Chapters/           # Chapter list
│   └── Bookmarks/          # Bookmarks list
├── Profile/                # BookPlayer profile (disabled)
├── Settings/
│   ├── Themes/
│   ├── Icons/
│   ├── Storage/
│   ├── Autoplay/
│   ├── Autolock/
│   └── Sections/           # Various settings sections
├── Search/                 # iOS 26+ search tab
├── Squabble/
│   └── Views/              # All Squabble UI
├── Jellyfin/               # Media server integration
├── AudiobookShelf/         # Audiobook server integration
└── Hardcover/              # Book metadata service
```

---

## See Also

- [ARCHITECTURE.md](./ARCHITECTURE.md) - Technical architecture
- [USER-JOURNEYS.md](./USER-JOURNEYS.md) - User flows
- [ROADMAP.md](./ROADMAP.md) - Planned features
- `/BookPlayerUITests/Helpers/ScreenIdentifiers.swift` - Identifier constants
