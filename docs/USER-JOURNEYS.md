# Squabble User Journeys

> Complete documentation of all user flows and interactions in the app.
> Last updated: December 2025

## Table of Contents
- [Library Tab](#library-tab-journeys) (8 journeys)
- [Player](#player-journeys) (6 journeys)
- [Profile/Guild Tab](#profileguild-tab-journeys) (7 journeys)
- [Settings Tab](#settings-tab-journeys) (5 journeys)

---

## Journey Format

Each journey follows this structure:
- **Goal:** What the user wants to accomplish
- **Entry Point:** Where the journey starts
- **Steps:** Numbered flow with screen references
- **Exit Points:** Where the journey can end
- **Edge Cases:** Error states, cancellations

---

# Library Tab Journeys

## L1: Browse Library

**Goal:** View and navigate audiobook collection

**Entry Point:** App launch → Library tab (default)

**Steps:**
1. App launches to `LibraryRootView`
2. If empty library → `EmptyListView` with "Add files" prompt
3. If has books → `ItemListView` shows list of books/folders
4. Tap folder → Navigate to nested `ItemListView` for that folder
5. Pull down → Refresh library content

**Exit Points:**
- Tap book → Start playback (see [L7](#l7-start-playback))
- Tap folder → Navigate deeper
- Switch to another tab

**Edge Cases:**
- Empty library shows helpful empty state with import options
- Long list shows "Load more" button at bottom

**Screens:** `ItemListView`, `EmptyListView`

---

## L2: Import Audiobook

**Goal:** Add new audiobooks to the library

**Entry Point:** Library tab → Add button OR Files app share

**Steps (via Add Menu):**
1. Tap "+" button in navigation bar
2. `confirmationDialog` shows options:
   - "From Files" → iOS file picker
   - "From URL" → URL input alert
   - "Create Folder" → Folder name input
3. Select file(s) from Files app
4. `ImportViewController` shows import progress
5. Import completes → Books appear in library

**Steps (via Drag & Drop):**
1. Drag file from Files/other app onto Library
2. Drop triggers `handleDrop()` in `MainView`
3. File copied to Documents folder
4. Inbox watcher detects new file
5. Import dialog appears → Confirm destination
6. Book appears in library

**Steps (via Jellyfin/AudiobookShelf):**
1. Settings → Integrations → Jellyfin/AudiobookShelf
2. Enter server URL and credentials
3. Browse server library
4. Tap book → View details
5. Tap "Download" → Book downloads to library

**Exit Points:**
- Import complete → Back to library
- Cancel import → Files not added
- Download from server → Book in library

**Edge Cases:**
- Invalid file format shows error
- Large files show progress indicator
- Server connection fails shows retry option

**Screens:** `ItemListView`, `ImportViewController`, `JellyfinRootView`, `AudiobookShelfRootView`

---

## L3: Search Library

**Goal:** Find a specific book or folder

**Entry Point:** Library tab (iOS 26: Search tab)

**Steps (iOS 26 - Search Tab):**
1. Tap Search tab in tab bar
2. `SearchView` shows recent items
3. Type in search field
4. Results update in real-time
5. Results grouped by folder
6. Tap result → Start playback

**Steps (Pre-iOS 26 - Searchable):**
1. Pull down on library list to reveal search
2. Type in search field
3. Results filter in real-time
4. Tap result → Navigate or play

**Exit Points:**
- Tap result → Play book
- Clear search → Return to full list
- Switch tabs → Exit search

**Edge Cases:**
- No results shows empty state
- Search includes titles and authors

**Screens:** `SearchView`, `ItemListView` (with searchable)

---

## L4: Manage Folders

**Goal:** Organize library with folders

**Entry Point:** Library tab → Add menu OR long-press

**Steps (Create Folder):**
1. Tap "+" → "Create Folder"
2. Enter folder name in alert
3. Tap "Create"
4. Folder appears in library

**Steps (Move Items to Folder):**
1. Long-press item OR tap "..." → "Select"
2. Select items to move
3. Tap folder icon in toolbar
4. Choose destination folder
5. Items moved to folder

**Steps (Delete Folder):**
1. Enter selection mode
2. Select folder
3. Tap trash icon
4. Confirm deletion
5. Contents optionally moved to parent

**Exit Points:**
- Folder created → In library
- Items moved → In new location
- Cancel → No changes

**Edge Cases:**
- Cannot create folder with empty name
- Moving to same location no-op
- Deleting non-empty folder shows warning

**Screens:** `ItemListView`, `FolderSelectionView`

---

## L5: Edit Book Metadata

**Goal:** Update book title, author, or artwork

**Entry Point:** Library → Long-press book → Edit

**Steps:**
1. Long-press book in library
2. Context menu appears
3. Tap "Edit" (or select → tap edit icon)
4. `ItemDetailsView` sheet opens
5. Edit title and/or author
6. Optionally change artwork:
   - Tap artwork → Camera or Photo Library
   - Select new image
7. Optionally link to Hardcover:
   - Tap "Search Hardcover"
   - Select matching book
8. Tap "Done" to save

**Exit Points:**
- Save changes → Back to library
- Cancel → Discard changes
- Swipe down → Discard changes

**Edge Cases:**
- Empty title shows validation error
- Hardcover match may not exist
- Artwork aspect ratio preserved

**Screens:** `ItemDetailsView`, `HardcoverBookPickerView`

---

## L6: Multi-Select Operations

**Goal:** Perform batch actions on multiple items

**Entry Point:** Library → "..." menu → "Select"

**Steps:**
1. Tap "..." menu in library
2. Tap "Select" to enter edit mode
3. Tap items to select (checkmarks appear)
4. Bottom toolbar shows actions:
   - Move (folder icon)
   - Edit (pencil icon) - single item only
   - Delete (trash icon)
5. Perform action
6. Confirm if destructive
7. Exit edit mode

**Exit Points:**
- Complete action → Back to library
- Tap "Done" → Exit without action
- Cancel in confirmation → Stay in select mode

**Edge Cases:**
- Edit disabled when multiple selected
- Delete shows confirmation with count
- Cannot select root library folder

**Screens:** `ItemListView` (edit mode)

---

## L7: Start Playback

**Goal:** Begin listening to an audiobook

**Entry Point:** Library → Tap book

**Steps:**
1. Tap book in library list
2. Loading indicator appears briefly
3. `PlayerManager` loads book
4. Book starts playing automatically
5. Mini player appears at bottom of library
6. Tap mini player → Full player opens

**Exit Points:**
- Playback starts → Mini player visible
- Tap mini player → Full player
- Error → Alert shown

**Edge Cases:**
- Resume from last position (if previously played)
- No audio file shows error
- Download required for cloud items

**Screens:** `ItemListView`, `MiniPlayerView`, `PlayerViewController`

---

## L8: Connect External Service

**Goal:** Set up Jellyfin or AudiobookShelf server

**Entry Point:** Settings → Integrations

**Steps (Jellyfin):**
1. Settings → Integrations → Jellyfin
2. `JellyfinConnectionView` shows form
3. Enter server URL (e.g., http://192.168.1.100:8096)
4. Enter username and password
5. Tap "Connect"
6. On success → `JellyfinLibraryView` shows libraries
7. Browse libraries and books
8. Download books to local library

**Steps (AudiobookShelf):**
1. Settings → Integrations → AudiobookShelf
2. Enter server URL and credentials
3. Connect → Browse libraries
4. Download books

**Exit Points:**
- Connected → Browse server
- Disconnect → Back to connection form
- Download → Book in local library

**Edge Cases:**
- Invalid URL shows error
- Auth failure prompts retry
- Network timeout with retry option

**Screens:** `JellyfinConnectionView`, `JellyfinLibraryView`, `AudiobookShelfRootView`

---

# Player Journeys

## P1: Full Player Experience

**Goal:** Control audiobook playback with full UI

**Entry Point:** Tap mini player OR tap book in library

**Steps:**
1. Full player (`PlayerViewController`) slides up
2. View shows:
   - Artwork (draggable for dismiss)
   - Progress slider with time labels
   - Play/Pause, Rewind, Forward buttons
   - Chapter title (tappable)
   - Speed, Sleep, Chapters, Bookmarks buttons
3. Tap play/pause → Toggle playback
4. Drag slider → Seek to position
5. Tap rewind/forward → Skip by configured interval
6. Swipe down → Dismiss to mini player

**Exit Points:**
- Swipe down → Mini player remains
- Tap artwork + drag down → Dismiss
- Book ends → Auto-advance or stop

**Edge Cases:**
- Very long books show formatted time (HH:MM:SS)
- Artwork scales to fit screen
- Landscape orientation supported

**Screens:** `PlayerViewController`, `MiniPlayerView`

---

## P2: Navigate Chapters

**Goal:** Jump to a specific chapter

**Entry Point:** Player → Chapters button (list icon)

**Steps:**
1. Tap list button in player
2. `ChaptersView` sheet opens
3. All chapters listed with:
   - Chapter title
   - Duration
   - Checkmark on current chapter
4. View auto-scrolls to current chapter
5. Tap any chapter → Jump to start
6. Sheet dismisses automatically

**Exit Points:**
- Tap chapter → Jump and dismiss
- Tap "Done" → Dismiss without jump
- Swipe down → Dismiss

**Edge Cases:**
- Books without chapters show single entry
- Very long chapter lists scroll
- Current chapter highlighted

**Screens:** `ChaptersView`

---

## P3: Manage Bookmarks

**Goal:** Create, view, and navigate bookmarks

**Entry Point:** Player → Bookmarks button

**Steps (View Bookmarks):**
1. Tap bookmark button in player
2. `BookmarksView` sheet opens
3. Sections show:
   - Automatic bookmarks (collapsible)
   - User bookmarks
4. Each bookmark shows time and optional note

**Steps (Create Bookmark):**
1. During playback, tap bookmark button
2. Bookmark created at current time
3. Optional: Add note via edit

**Steps (Navigate to Bookmark):**
1. Open bookmarks view
2. Tap any bookmark
3. Player jumps to that time
4. Sheet dismisses

**Steps (Edit/Delete Bookmark):**
1. Swipe left on user bookmark
2. Options: Edit note, Delete
3. Edit → Enter note text
4. Delete → Confirm removal

**Exit Points:**
- Tap bookmark → Jump and dismiss
- Done → Dismiss
- Delete → Bookmark removed

**Edge Cases:**
- Automatic bookmarks from app closure
- Notes can be multi-line
- Cannot edit automatic bookmarks

**Screens:** `BookmarksView`

---

## P4: Adjust Playback Speed

**Goal:** Change playback speed for current book

**Entry Point:** Player → Speed button

**Steps:**
1. Tap speed button in player (shows current speed)
2. `PlayerControlsView` sheet opens
3. Speed section shows:
   - Slider (0.5x - 3.0x)
   - Preset buttons (1.0x, 1.25x, 1.5x, 2.0x)
4. Adjust speed with slider or tap preset
5. Optional: Toggle "Boost Volume"
6. Changes apply immediately
7. Dismiss sheet

**Exit Points:**
- Swipe down → Speed saved
- Tap outside → Dismiss

**Edge Cases:**
- Speed persists per book
- Extreme speeds affect audio quality
- Boost helps with quiet audiobooks

**Screens:** `PlayerControlsView`

---

## P5: Set Sleep Timer

**Goal:** Stop playback after a duration or chapter end

**Entry Point:** Player → Sleep button (moon icon)

**Steps:**
1. Tap sleep timer button
2. Options appear:
   - Off
   - 5, 10, 15, 30, 45, 60 minutes
   - End of chapter
3. Select duration
4. Timer starts counting down
5. When timer ends → Playback pauses
6. Optional: Shake device to extend

**Exit Points:**
- Timer set → Countdown active
- Cancel → Timer cleared
- Timer ends → Playback stops

**Edge Cases:**
- "End of chapter" waits for chapter boundary
- Shake-to-extend configurable in settings
- Timer persists if app backgrounded

**Screens:** `PlayerViewController` (action sheet)

---

## P6: View Ghost Markers (Squabble)

**Goal:** See guild members' reading progress on timeline

**Entry Point:** Player opens (automatic when in guild)

**Steps:**
1. Player loads book
2. `fetchAndDisplayGhosts()` called automatically
3. Fetches guild members' progress from Firestore
4. Ghost markers appear on progress slider:
   - Colored circles with member initials
   - Position shows their progress percentage
   - Current user excluded
5. Markers update on player refresh

**Exit Points:**
- Visual only - no interaction
- Leave guild → Markers disappear

**Edge Cases:**
- No guild → No markers shown
- Same book required for markers
- Stale progress (>24h) may be dimmed
- Max 5 guild members shown

**Screens:** `PlayerViewController`, `SquabbleGhostOverlayView`

---

# Profile/Guild Tab Journeys

## G1: Sign Up for Squabble

**Goal:** Create a new Squabble account

**Entry Point:** Profile tab → "Sign In / Sign Up"

**Steps:**
1. Tap Profile tab
2. `SquabbleNotLoggedInView` shows sign-in prompt
3. Tap "Sign In / Sign Up" button
4. `SquabbleLoginView` sheet opens
5. Toggle to "Sign Up" mode
6. Enter email address
7. Enter password (min 6 chars)
8. Tap "Create Account"
9. Loading indicator appears
10. On success → Sheet dismisses, profile updates

**Exit Points:**
- Account created → Profile shows "No Guild" state
- Cancel → Stay logged out
- Error → Show message, retry

**Edge Cases:**
- Email already registered → Error message
- Weak password → Validation error
- Network error → Retry prompt

**Screens:** `SquabbleProfileView`, `SquabbleLoginView`

---

## G2: Sign In to Squabble

**Goal:** Log into existing Squabble account

**Entry Point:** Profile tab → "Sign In / Sign Up"

**Steps:**
1. Tap Profile tab
2. Tap "Sign In / Sign Up"
3. `SquabbleLoginView` in Sign In mode (default)
4. Enter email and password
5. Tap "Sign In"
6. Loading indicator
7. On success → Load existing guild (if any)
8. Profile updates to show guild or "No Guild"

**Exit Points:**
- Signed in with guild → Guild view
- Signed in no guild → Create/Join options
- Cancel → Stay logged out
- Error → Retry

**Edge Cases:**
- Wrong password → Error message
- Account not found → Suggest sign up
- Session restoration on app launch (automatic)

**Screens:** `SquabbleProfileView`, `SquabbleLoginView`

---

## G3: Create a New Guild

**Goal:** Start a new guild as owner

**Entry Point:** Profile tab (logged in, no guild) → "Create Guild"

**Steps:**
1. Profile shows `SquabbleNoGuildProfileView`
2. Tap "Create Guild" button
3. `CreateGuildView` sheet opens
4. Enter guild name (required)
5. Tap "Create"
6. Loading indicator
7. Guild created in Firestore:
   - Guild document with unique ID
   - User added as owner
   - 6-char invite code generated
8. Sheet dismisses
9. Profile shows guild details

**Exit Points:**
- Guild created → Guild profile view
- Cancel → Back to no-guild state
- Error → Show message

**Edge Cases:**
- Empty name → Create button disabled
- Network error → Retry or cancel
- Auto-generated invite code is unique

**Screens:** `SquabbleNoGuildProfileView`, `CreateGuildView`

---

## G4: Join Guild via Invite Code

**Goal:** Join an existing guild using invite code

**Entry Point:** Profile tab (logged in, no guild) → "Join with Code"

**Steps:**
1. Tap "Join with Code" button
2. `JoinGuildView` sheet opens
3. Enter 6-character invite code
4. Code auto-uppercases as typed
5. Tap "Join" (enabled when 6 chars)
6. Loading indicator
7. Server validates code:
   - Finds guild with matching code
   - Adds user as member
8. Sheet dismisses
9. Profile shows guild details

**Exit Points:**
- Joined → Guild profile view
- Invalid code → Error message
- Cancel → Back to no-guild state

**Edge Cases:**
- Invalid code → "Guild not found" error
- Already a member → Error (shouldn't happen)
- Guild full (if limit implemented) → Error

**Screens:** `SquabbleNoGuildProfileView`, `JoinGuildView`

---

## G5: View Guild Members

**Goal:** See who's in the guild

**Entry Point:** Profile tab (in guild)

**Steps:**
1. Profile tab shows `SquabbleGuildProfileView`
2. Guild header shows:
   - Guild name
   - Member count
3. Members section lists all members:
   - Display name
   - Crown icon for owner
   - Role label
4. Real-time updates via Firestore listeners

**Exit Points:**
- View only - tap member does nothing (future: profile)
- Switch tabs

**Edge Cases:**
- New member joins → List updates automatically
- Member leaves → Removed from list
- Owner has special styling

**Screens:** `SquabbleGuildProfileView`

---

## G6: Share/Regenerate Invite Code

**Goal:** Get invite code to share with friends

**Entry Point:** Profile tab (in guild) → "View Invite Code"

**Steps (View/Share):**
1. Tap "View Invite Code" button
2. `InviteCodeView` sheet opens
3. Large code displayed (monospace, easy to read)
4. Options:
   - "Copy Code" → Copies to clipboard, shows "Copied!"
   - "Share" → iOS share sheet opens
5. Share via Messages, email, etc.

**Steps (Regenerate - Owner Only):**
1. Open invite code view
2. Tap "Generate New Code" (orange, owner only)
3. Confirmation (implicit or explicit)
4. New code generated
5. Old code immediately invalid
6. Display updates

**Exit Points:**
- Done → Dismiss sheet
- Code shared via external app

**Edge Cases:**
- Non-owners cannot regenerate
- Regeneration invalidates old code instantly
- Share includes guild name context

**Screens:** `InviteCodeView`

---

## G7: Leave Guild

**Goal:** Exit current guild

**Entry Point:** Profile tab (in guild) → "Leave Guild"

**Steps:**
1. Scroll to bottom of guild profile
2. Tap "Leave Guild" button (red, non-owners only)
3. Confirmation dialog appears
4. Tap "Leave" to confirm
5. Loading indicator
6. Server removes user from guild:
   - Deletes member document
   - Decrements member count
   - Clears user's currentGuildId
7. Profile returns to "No Guild" state

**Exit Points:**
- Left → No-guild state
- Cancel → Stay in guild

**Edge Cases:**
- Owners cannot leave (must transfer or delete guild)
- Progress data remains (for potential rejoin)
- Real-time listeners stopped

**Screens:** `SquabbleGuildProfileView`

---

# Settings Tab Journeys

## S1: Customize Appearance

**Goal:** Change app theme and icon

**Entry Point:** Settings → Appearance section

**Steps (Themes):**
1. Settings tab → "Themes"
2. `SettingsThemesView` shows theme grid
3. Preview shows current theme applied
4. Tap theme to select
5. Some themes locked (require purchase/Pro)
6. Tap locked theme → Purchase flow
7. Theme applies immediately

**Steps (Icons):**
1. Settings → "App Icons"
2. `SettingsAppIconsView` shows icon grid
3. Tap icon to select
4. iOS changes app icon
5. Some icons locked (require purchase/Pro)

**Exit Points:**
- Theme/icon changed → Immediate effect
- Purchase → Unlock premium options
- Back → Keep current

**Edge Cases:**
- Pro users get all themes/icons
- Purchase restores via "Restore Purchases"
- Dark mode themes for dark system setting

**Screens:** `SettingsThemesView`, `SettingsAppIconsView`

---

## S2: Configure Playback Controls

**Goal:** Customize playback behavior

**Entry Point:** Settings → Controls

**Steps:**
1. Settings → "Controls"
2. `SettingsPlayerControlsView` shows options:
   - Smart Rewind (auto-rewind on resume)
   - Skip intervals (forward/back seconds)
   - Global speed default
   - Progress seeking behavior
   - Volume boost
   - Auto sleep timer
3. Tap setting to adjust
4. Changes apply to future playback

**Exit Points:**
- Settings saved automatically
- Back → Return to settings

**Edge Cases:**
- Skip intervals: 5, 10, 15, 30, 45, 60, 90 seconds
- Speed range: 0.5x - 3.0x
- Smart rewind helps resume context

**Screens:** `SettingsPlayerControlsView`

---

## S3: Manage Storage

**Goal:** View and free up storage space

**Entry Point:** Settings → Storage

**Steps:**
1. Settings → "Storage"
2. `StorageView` shows:
   - Total space used
   - Breakdown by item type
   - Individual book sizes
3. Tap item to see details
4. Swipe to delete or offload
5. Confirm deletion
6. Space freed

**Exit Points:**
- Delete items → Space freed
- Back → Return to settings

**Edge Cases:**
- Offload keeps metadata, removes audio
- Cannot delete currently playing book
- Shows download status for cloud items

**Screens:** `StorageView`

---

## S4: Set Up Integrations

**Goal:** Connect external services

**Entry Point:** Settings → Integrations

**Steps:**
1. Settings tab shows Integrations section
2. Options:
   - Jellyfin (media server)
   - AudiobookShelf (audiobook server)
   - Hardcover (book metadata)
3. Tap service → Configuration view
4. Enter credentials/settings
5. Connect → Browse content

**Exit Points:**
- Connected → Can browse/download
- Disconnect → Credentials cleared
- Error → Retry or cancel

**Edge Cases:**
- See [L8](#l8-connect-external-service) for details
- Hardcover links for metadata enrichment

**Screens:** `JellyfinRootView`, `AudiobookShelfRootView`, `HardcoverSettingsView`

---

## S5: Access Support

**Goal:** Get help or provide feedback

**Entry Point:** Settings → Support section

**Steps (Send Feedback):**
1. Settings → "Send Feedback"
2. Mail composer opens (if available)
3. Pre-filled with:
   - App version
   - Device info
   - Debug info
4. Write feedback
5. Send email

**Steps (Tip Jar):**
1. Settings → "Tip Jar"
2. `SettingsTipJarView` shows tip amounts
3. Select tip
4. Apple Pay / payment flow
5. Thank you message

**Steps (View Debug Info):**
1. Settings → Debug section (developer mode)
2. View app state, cache info
3. Clear caches if needed

**Exit Points:**
- Email sent → Confirmation
- Tip completed → Thank you
- Back → Return to settings

**Edge Cases:**
- No mail configured → Copy debug info prompt
- Payment fails → Error handling
- Restore purchases option available

**Screens:** `SettingsSupportSectionView`, `SettingsTipJarView`

---

## See Also

- [ARCHITECTURE.md](./ARCHITECTURE.md) - Technical architecture diagrams
- [ROADMAP.md](./ROADMAP.md) - Planned features
- [SCREEN-INVENTORY.md](./SCREEN-INVENTORY.md) - Complete screen list
