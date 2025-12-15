# Squabble Feature Roadmap

> Planned features with acceptance criteria for implementation.
> Aligned with [VISION.md](./VISION.md) | Last updated: December 2025

## Table of Contents
- [MVP Scope](#mvp-scope-v10)
- [Completed Work](#completed-work)
- [MVP: Active Development](#mvp-active-development)
- [Phase 2: Delight Layer](#phase-2-delight-layer)
- [Phase 3: Monetization & Growth](#phase-3-monetization--growth)
- [Quality of Life](#quality-of-life-improvements)
- [Future Ideas](#future-ideas)
- [Terminology](#terminology)

---

## Feature Format

```
### Feature Name
**Epic:** Parent epic
**Status:** Not Started | In Progress | Complete
**Priority:** P0 (Critical) | P1 (High) | P2 (Medium) | P3 (Low)
**Dependencies:** What must exist first

**User Story:**
As a [user], I want to [action] so that [benefit]

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2

**Technical Notes:**
- Implementation details
```

---

# MVP Scope (v1.0)

> **Goal:** Validate the core value proposition - guilds + ghost markers + spoiler-free comments.

## What's In MVP

| Epic | Features | Status |
|------|----------|--------|
| **Epic 0** | Architecture refactor (extension pattern) | Complete |
| **Epic 1** | Guild system (create, join, leave, invite) | Complete |
| **Epic 1B** | Screenshot automation | Complete |
| **Epic 2** | Timestamp comments (2.1 Leave, 2.2 Display only) | In Progress (Code Complete) |
| **Epic 3** | Progress sync & ghost markers | Partial |

## What's NOT in MVP (Deferred)

- Epic 2.3-2.5 (Comment indicators, history, delete)
- Epic 4 (Monetization tiers - free only for MVP)
- Epic 5 (Achievements & themes)
- Epic 6 (Bounty board)
- Epic 7 (Inn experience)
- Guild Library features
- QoL improvements (error polish, loading states, offline)

## MVP Success Criteria

- [ ] User can create/join a guild with up to 6 members
- [ ] User can see guildmates' progress on timeline (ghost markers)
- [ ] User can leave comments at timestamps
- [ ] Comments appear to guildmates only after they pass that point (spoiler-free)
- [ ] Core loop is functional and testable with real users

---

# Completed Work

## Epic 0: Architecture Refactor
**Status:** Complete (Dec 2025)
**Commit:** `e81fbdc7`

**Summary:** Established clean separation between BookPlayer core and Squabble features using Swift extension pattern.

**Deliverables:**
- [x] All Squabble code isolated in `/BookPlayer/Squabble/`
- [x] 4 extension files for integration points
- [x] Marked integration points with `// SQUABBLE:` comments
- [x] Feature flags in `SquabbleConfig.swift`
- [x] Upstream merge compatibility maintained

---

## Epic 1: Guild System
**Status:** Complete (Dec 2025)
**Commit:** `c5efa18c`

**Summary:** Full guild management system with create, join, leave, and invite functionality. Guilds support up to 6 members (creator + 5 friends).

**Deliverables:**
- [x] Firebase Auth integration (email/password)
- [x] Guild creation with auto-generated invite codes
- [x] Join guild via 6-character code
- [x] Real-time member list via Firestore listeners
- [x] Owner and member roles
- [x] Leave guild functionality
- [x] Invite code regeneration (owner only)
- [x] Profile tab replaced with guild hub
- [x] Hidden BookPlayer Pro UI when Squabble enabled

---

## Epic 1B: Screenshot Automation & Visual Polish
**Status:** Complete (Dec 2025)
**Commit:** `543018d7`

**Summary:** Automated screenshot capture tool and ghost marker visual improvements.

**Deliverables:**
- [x] 28 automated screenshot tests
- [x] CLI script: `./scripts/capture-screenshots.sh`
- [x] Mock state injection via launch arguments
- [x] Ghost markers with gradient fills
- [x] Member initials inside markers
- [x] Colored shadows and white borders
- [x] Firebase emulator integration tests

---

# MVP: Active Development

## Epic 2: Timestamp Comments (Dark Souls Style)

### 2.1 Leave Comment at Timestamp
**Status:** In Progress (Implementation Complete, Needs Testing)
**Priority:** P1 (High) - MVP
**Dependencies:** Guild system complete

**User Story:**
As a guild member, I want to leave a comment at a specific moment in an audiobook so that my guildmates can see my reaction when they reach that point.

**Acceptance Criteria:**
- [x] Comment button available in player UI
- [x] Tapping opens comment input with current timestamp shown
- [x] Can type reaction/comment (280 char limit)
- [x] Post saves comment to Firestore with:
  - [x] Timestamp (seconds into audiobook)
  - [x] Book ID
  - [x] User ID
  - [x] Comment text
  - [x] Created date
- [x] Confirmation that comment was posted
- [x] Can cancel without posting

**Technical Notes:**
- New Firestore collection: `guilds/{guildId}/comments/{commentId}`
- Comment document schema:
  ```
  {
    id: string,
    bookId: string,
    bookTitle: string,
    userId: string,
    userDisplayName: string,
    timestamp: number (seconds),
    text: string,
    createdAt: timestamp
  }
  ```
- New view: `CommentInputView.swift`
- Index on (bookId, timestamp) for efficient queries

---

### 2.2 Display Comments (Spoiler-Free)
**Status:** In Progress (Implementation Complete, Needs Testing)
**Priority:** P1 (High) - MVP
**Dependencies:** Leave Comment (2.1)

**User Story:**
As a guild member, I want to see my guildmates' comments only AFTER I pass that timestamp so that I don't get spoilers.

**Acceptance Criteria:**
- [x] Comments only appear after user's progress passes the timestamp
- [x] When crossing a comment timestamp:
  - [ ] Subtle notification/chime (haptic feedback only, no audio yet)
  - [x] Comment appears briefly on screen
  - [x] Comment indicator added to timeline
- [x] Can tap timeline indicator to re-read comment
- [x] Multiple comments at same timestamp shown in order
- [x] Comments from all guild members shown (not just active readers)

**Technical Notes:**
- Query comments where `timestamp <= currentProgress`
- Track "last seen timestamp" to detect newly-passed comments
- Local cache of already-seen comments
- UI overlay for comment display (non-blocking)
- Consider: batch fetch comments for entire book on load

---

## Epic 3: Progress Sync & Ghost Markers

### 3.1 Real-Time Progress Sync
**Status:** Partial (existing implementation)
**Priority:** P1 (High) - MVP
**Dependencies:** Guild system complete

**User Story:**
As a guild member, I want my reading progress to sync to my guild so that my guildmates can see where I am.

**Acceptance Criteria:**
- [x] Progress syncs to Firestore automatically during playback
- [x] Sync includes: book ID, book title, progress %, timestamp, total duration
- [x] Throttled to prevent excessive writes (5-minute interval)
- [ ] Force sync on pause/stop
- [ ] Sync works reliably with newly created guilds
- [ ] Handle offline → online sync queue

**Technical Notes:**
- Existing: `SquabbleSyncService.swift`
- Collection: `guilds/{guildId}/progress/{bookId_userId}`
- Debug logging for sync issues
- Thread-safe guild ID access

---

### 3.2 Ghost Marker Display
**Status:** Complete
**Priority:** P1 (High) - MVP
**Dependencies:** Progress Sync (3.1)

**User Story:**
As a guild member, I want to see ghost markers on the timeline showing where my guildmates are in the same book.

**Acceptance Criteria:**
- [x] Markers appear on progress slider for each guildmate reading same book
- [x] Markers show member initials inside
- [x] Markers use gradient fill with member color
- [x] Markers have colored shadow and white border
- [x] Real-time updates via Firestore listeners
- [ ] Markers only show for "active" books (recent activity)
- [ ] Handle overlapping markers gracefully

**Technical Notes:**
- Existing: `SquabbleGhostOverlayView.swift`
- 22px diameter markers
- Colors assigned per member
- UIKit overlay on UISlider

---

### 3.3 Active Book Tracking
**Status:** Not Started
**Priority:** P2 (Medium)
**Dependencies:** Progress Sync (3.1)

**User Story:**
As a user, I want control over which books show my progress to my guild.

**Acceptance Criteria:**
- [ ] "Active" flag per book in progress collection
- [ ] Books auto-deactivate after X days of no progress
- [ ] User can manually toggle book visibility
- [ ] Only active books show ghost markers
- [ ] Guild library shows only active books

**Technical Notes:**
- Add `isActive` boolean to progress documents
- Auto-deactivate threshold: 14 days?
- UI in book detail or player menu

---

# Phase 2: Delight Layer

> **Goal:** Add engagement features that make the app delightful and sticky.

## Epic 2: Timestamp Comments (Completion)

### 2.3 Comment Indicators on Timeline
**Status:** Not Started
**Priority:** P2 (Medium)
**Dependencies:** Display Comments (2.2)

**User Story:**
As a guild member, I want to see indicators on the timeline showing where comments exist (that I've passed) so that I can revisit reactions.

**Acceptance Criteria:**
- [ ] Small markers on progress slider for passed comments
- [ ] Markers only visible for timestamps user has passed
- [ ] Tap marker → Show comment in popup
- [ ] Different marker for own comments vs others
- [ ] Markers don't clutter (cluster if too close together)

**Technical Notes:**
- Similar implementation to ghost markers
- Filter to only show `timestamp <= currentProgress`
- Cluster markers within X seconds of each other
- Color-code by commenter or use unified style

---

### 2.4 Comment History View
**Status:** Not Started
**Priority:** P2 (Medium)
**Dependencies:** Display Comments (2.2)

**User Story:**
As a guild member, I want to see all comments for a book in one place so that I can catch up on the discussion.

**Acceptance Criteria:**
- [ ] "Comments" button/tab in player or book details
- [ ] List of all comments for current book
- [ ] Only shows comments at timestamps user has passed
- [ ] Shows: commenter name, timestamp, comment text
- [ ] Tap comment → Jump to that timestamp
- [ ] Sorted by timestamp (ascending)

**Technical Notes:**
- New view: `BookCommentsView.swift`
- Filter: `timestamp <= userCurrentProgress`
- Pagination for books with many comments
- Real-time updates as user progresses

---

### 2.5 Delete Own Comment
**Status:** Not Started
**Priority:** P3 (Low)
**Dependencies:** Leave Comment (2.1)

**User Story:**
As a guild member, I want to delete a comment I made so that I can remove something I regret posting.

**Acceptance Criteria:**
- [ ] Can only delete own comments
- [ ] Swipe or long-press to reveal delete option
- [ ] Confirmation before deletion
- [ ] Comment removed from Firestore
- [ ] Comment removed from all guildmates' views

**Technical Notes:**
- Simple Firestore document deletion
- Security rules: only author can delete
- No soft delete (v1)

---

## Epic 5: Achievements & Themes

> From VISION "Earned Aesthetic" pillar - nothing is bought, it's earned through reading.

### 5.1 Achievement System
**Status:** Not Started
**Priority:** P2 (Medium)
**Dependencies:** Guild system complete, book completion tracking
**Tier:** Resident Adventurer

**User Story:**
As a reader, I want to earn achievements for reading milestones so that I feel recognized for my progress.

**Acceptance Criteria:**
- [ ] Achievement notifications appear on unlock
- [ ] DCC-style sardonic, clever voice for messages
- [ ] Achievement types:
  - [ ] Book completion (first book, 10th book, etc.)
  - [ ] Series completion
  - [ ] Speed achievements (finished quickly)
  - [ ] Re-read achievements
  - [ ] Guild achievements (everyone finished)
- [ ] Achievement history viewable in profile
- [ ] Achievements shareable

**Technical Notes:**
- New collection: `users/{userId}/achievements/{achievementId}`
- Achievement definitions in app bundle (JSON)
- Trigger logic in completion handlers
- Examples from VISION:
  - "Speed Reader or Liar?" - finished 40hr book in 6hrs at 3x
  - "The Wandering Listener" - started 15 books, finished 2
  - "Completionist" - finished entire series

---

### 5.2 Theme Unlocks
**Status:** Not Started
**Priority:** P2 (Medium)
**Dependencies:** Achievement system (5.1)
**Tier:** Resident Adventurer

**User Story:**
As a reader, I want to unlock themes by completing books and series so that my app reflects my reading history.

**Acceptance Criteria:**
- [ ] Complete book → Unlock book-specific trinket
- [ ] Complete series → Unlock series theme
- [ ] Guild completes together → Unlock guild-wide theme option
- [ ] Re-read → Enhanced trinket variant
- [ ] Theme picker in settings shows locked/unlocked status
- [ ] Preview themes before selecting

**Technical Notes:**
- Theme assets bundled in app
- Unlock state stored in: `users/{userId}/unlockedThemes`
- Theme scope (v1): color palette, background
- Future: app icon, sound effects, UI chrome

---

### 5.3 Trinket Display
**Status:** Not Started
**Priority:** P3 (Low)
**Dependencies:** Theme unlocks (5.2)
**Tier:** Resident Adventurer

**User Story:**
As a reader, I want to see trinkets from completed books displayed in my profile so that I have a visual collection of my reading.

**Acceptance Criteria:**
- [ ] Trinkets displayed as small icons in profile/inn
- [ ] Tap trinket → Book info popup
- [ ] Trinkets organized by series or chronologically
- [ ] Some trinkets have easter egg interactions
- [ ] Guild profile shows collective trinkets

**Technical Notes:**
- Trinket assets: small PNG/SVG icons
- From VISION: "Click the cat trinket → Donut quote"
- Layout: shelf/grid metaphor

---

## Guild Library

### GL1: View Guild Members' Books
**Status:** Not Started
**Priority:** P2 (Medium)
**Dependencies:** Guild system complete

**User Story:**
As a guild member, I want to see what books my friends are reading so that I can discover new audiobooks.

**Acceptance Criteria:**
- [ ] "Guild Library" section in guild view (replace placeholder)
- [ ] Shows books currently being read by members
- [ ] Each book card shows:
  - [ ] Cover art
  - [ ] Title
  - [ ] Who's reading (avatar/name)
  - [ ] Their progress %
- [ ] Tap book → Detail view with all readers
- [ ] Books sorted by most recently active

**Technical Notes:**
- Aggregate from `guilds/{guildId}/progress` collection
- Group by bookId, show unique books
- Include reader list per book
- Consider: Cover art from Hardcover API or local

---

### GL2: Book Recommendations
**Status:** Not Started
**Priority:** P3 (Low)
**Dependencies:** View Guild Books (GL1)

**User Story:**
As a guild member, I want to recommend books to my guild so that we can share discoveries.

**Acceptance Criteria:**
- [ ] "Recommend" button on book detail view
- [ ] Recommended books show special badge in guild library
- [ ] Recommendation includes optional note
- [ ] Members can see who recommended each book
- [ ] Recommendations persist even if recommender finishes book

**Technical Notes:**
- New collection: `guilds/{guildId}/recommendations`
- Schema:
  ```
  {
    bookId: string,
    bookTitle: string,
    recommendedBy: string,
    note: string?,
    createdAt: timestamp
  }
  ```
- Merge with active books in guild library view

---

# Phase 3: Monetization & Growth

> **Goal:** Introduce paid tiers and advanced features for sustainability.

## Epic 4: Monetization Tiers

> From VISION Monetization Philosophy - core is free, creation has value, delight is optional.

### 4.1 Tier System Implementation
**Status:** Not Started
**Priority:** P2 (Medium)
**Dependencies:** MVP complete

**User Story:**
As the app developer, I want to implement monetization tiers so that the app is sustainable while keeping the core experience free.

**Acceptance Criteria:**
- [ ] Traveler (Free) tier:
  - [ ] Full playback, library, chapters, bookmarks
  - [ ] Join existing guilds (up to 6 members)
  - [ ] Ghost markers on timeline
  - [ ] Timestamp comments (leave and view)
  - [ ] Default "Squabble Inn" theme
- [ ] Resident Adventurer (One-time ~$5-7):
  - [ ] Everything in Traveler
  - [ ] Achievement system (DCC-style)
  - [ ] Theme unlocks by completing books/series
  - [ ] Trinkets and trophies
  - [ ] Class identity
  - [ ] Bounty board access
- [ ] Guild Master (One-time ~$10-15):
  - [ ] Everything in Resident Adventurer
  - [ ] Create your own guild
  - [ ] Generate and share invite codes
  - [ ] Manage guild members (up to 6 total)
- [ ] Ascendant Adventurer (TBD):
  - [ ] Everything in Guild Master
  - [ ] Global social features ("the multiverse")
  - [ ] Cross-guild connections and events
  - [ ] Public profile and reading history
  - [ ] *Features TBD - future expansion tier*

**Technical Notes:**
- StoreKit 2 for purchases (one-time non-consumable)
- Store tier in: `users/{userId}/purchasedTier`
- Feature gating logic in `SquabbleConfig.swift`
- Receipt validation

---

### 4.2 Purchase Flow
**Status:** Not Started
**Priority:** P2 (Medium)
**Dependencies:** Tier system (4.1)

**User Story:**
As a user, I want to upgrade my tier so that I can access premium features.

**Acceptance Criteria:**
- [ ] Clear upgrade prompts when accessing gated features
- [ ] Purchase sheet shows tier benefits
- [ ] One-time purchase flow for Resident Adventurer
- [ ] One-time purchase flow for Guild Master
- [ ] Restore purchases functionality
- [ ] Graceful handling of purchase failures

**Technical Notes:**
- Use SwiftUI `.subscriptionStoreView()`
- Handle subscription status changes
- Offline grace period for subscribers

---

## Epic 6: Bounty Board

> From VISION "Bounty Board" pillar - quests and challenges framed as bounties.

### 6.1 Personal Bounties
**Status:** Not Started
**Priority:** P3 (Low)
**Dependencies:** Achievement system (5.1)
**Tier:** Resident Adventurer

**User Story:**
As a reader, I want to see personal reading challenges so that I have goals to work toward.

**Acceptance Criteria:**
- [ ] Bounty board accessible from profile/inn
- [ ] Personal bounty types:
  - [ ] Finish current book
  - [ ] Listen for X hours this week/month
  - [ ] Complete a book in a series
  - [ ] Re-read a favorite
- [ ] Bounties show progress toward completion
- [ ] Completing bounty grants achievement

**Technical Notes:**
- Bounty definitions in app bundle
- Progress tracked locally and in Firestore
- Refresh bounties weekly/monthly

---

### 6.2 Guild Bounties
**Status:** Not Started
**Priority:** P3 (Low)
**Dependencies:** Personal bounties (6.1)
**Tier:** Resident Adventurer

**User Story:**
As a guild member, I want to see shared guild challenges so that we can work together toward reading goals.

**Acceptance Criteria:**
- [ ] Guild bounties visible to all members
- [ ] Guild bounty types:
  - [ ] Everyone finish this book
  - [ ] Guild listens X total hours
  - [ ] Complete a series together
- [ ] Progress shows each member's contribution
- [ ] Completing guild bounty unlocks shared reward

**Technical Notes:**
- Aggregate progress across guild members
- Collection: `guilds/{guildId}/bounties`
- Real-time updates

---

### 6.3 Raid Boss Recommendations
**Status:** Not Started
**Priority:** P3 (Low)
**Dependencies:** Class identity (from 5.1), Guild bounties (6.2)
**Tier:** Resident Adventurer

**User Story:**
As a guild, we want book recommendations based on our collective reading taste so that we can find our next adventure together.

**Acceptance Criteria:**
- [ ] "Raid Boss" section in bounty board
- [ ] Recommendations based on:
  - [ ] Guild members' reading history
  - [ ] Class composition (if implemented)
  - [ ] Genre preferences
- [ ] Raid boss = challenging book/series to tackle together
- [ ] Completing raid boss grants special achievement

**Technical Notes:**
- Recommendation logic (simple v1: genre matching)
- Future: ML-based recommendations
- Partner with Hardcover for metadata?

---

## Epic 7: The Inn Experience

> From VISION "The Inn" pillar - the app is a place, not just a tool.

### 7.1 Inn Visualization
**Status:** Not Started
**Priority:** P3 (Low)
**Dependencies:** Theme unlocks (5.2), Trinkets (5.3)
**Tier:** Resident Adventurer

**User Story:**
As a reader, I want the app to feel like my personal corner of an inn so that opening the app feels like coming home.

**Acceptance Criteria:**
- [ ] Profile/home transformed into "inn" metaphor
- [ ] Visual elements:
  - [ ] Your library as bookshelves
  - [ ] Trinkets displayed on shelves
  - [ ] Theme applied to background/atmosphere
  - [ ] Guild table visible in corner
- [ ] Interactive elements reward exploration

**Technical Notes:**
- Custom SwiftUI views
- Animation and parallax effects
- Theme-specific assets

---

### 7.2 Guild Table Visualization
**Status:** Not Started
**Priority:** P3 (Low)
**Dependencies:** Inn visualization (7.1)
**Tier:** Resident Adventurer

**User Story:**
As a guild member, I want to see a visual representation of my guild as a table at the inn.

**Acceptance Criteria:**
- [ ] Guild table shows member avatars/icons
- [ ] Currently reading indicators per member
- [ ] Collective trophy case
- [ ] Guild theme applied to table area
- [ ] Tap member → View their profile

**Technical Notes:**
- From VISION "Guild Hall Visualization"
- Positioned in inn view
- Real-time presence indicators

---

### 7.3 Audio Stingers
**Status:** Not Started
**Priority:** P3 (Low)
**Dependencies:** Achievement system (5.1)
**Tier:** Resident Adventurer

**User Story:**
As a reader, I want satisfying audio feedback for achievements and events so that the app feels alive.

**Acceptance Criteria:**
- [ ] Achievement unlock sound
- [ ] Theme-specific notification sounds
- [ ] Guild completion celebration
- [ ] Comment notification chime
- [ ] Sounds respect device mute/volume

**Technical Notes:**
- From VISION "Audio Stingers"
- Short audio clips (< 2 seconds)
- Could license from games or commission original
- Store in app bundle

---

# Quality of Life Improvements

## QoL1: Error Handling Polish
**Status:** Not Started
**Priority:** P2 (Medium)
**Dependencies:** None

**User Story:**
As a user, I want clear error messages so that I know what went wrong and how to fix it.

**Acceptance Criteria:**
- [ ] All network errors show user-friendly message
- [ ] Retry option for transient failures
- [ ] Specific messages for:
  - [ ] No internet connection
  - [ ] Invalid credentials
  - [ ] Guild not found
  - [ ] Rate limiting
- [ ] Errors logged for debugging
- [ ] No raw error codes shown to users

**Technical Notes:**
- Create `SquabbleError` enum with user messages
- Centralized error handling in services
- Toast/banner UI for non-blocking errors
- Alert for blocking errors

---

## QoL2: Loading States
**Status:** Not Started
**Priority:** P2 (Medium)
**Dependencies:** None

**User Story:**
As a user, I want to see loading indicators so that I know the app is working.

**Acceptance Criteria:**
- [ ] All async operations show loading state
- [ ] Loading indicators are:
  - [ ] Skeleton views for content loading
  - [ ] Spinner for actions (create, join, etc.)
  - [ ] Progress bar for downloads
- [ ] Buttons disabled during loading
- [ ] Minimum display time to prevent flicker (300ms)

**Technical Notes:**
- Use SwiftUI `ProgressView` consistently
- Consider skeleton loading for lists
- Debounce rapid state changes

---

## QoL3: Offline Support
**Status:** Not Started
**Priority:** P3 (Low)
**Dependencies:** None

**User Story:**
As a user, I want the app to work offline so that I can listen without internet.

**Acceptance Criteria:**
- [ ] Playback works offline (existing BookPlayer feature)
- [ ] Guild data cached locally
- [ ] Progress queued for sync when online
- [ ] Clear indication of offline state
- [ ] Graceful degradation:
  - [ ] Can view cached guild info
  - [ ] Cannot create/join guilds
  - [ ] Ghost markers show cached data

**Technical Notes:**
- Firestore offline persistence (built-in)
- Queue progress updates in UserDefaults
- Sync queue on app foreground
- Network reachability monitoring

---

## QoL4: Push Notifications
**Status:** Not Started
**Priority:** P3 (Low)
**Dependencies:** Guild system complete

**User Story:**
As a guild member, I want notifications so that I know about guild activity.

**Acceptance Criteria:**
- [ ] Notification types:
  - [ ] New member joined guild
  - [ ] Member finished a book
  - [ ] New comment on book you're reading
  - [ ] Guild bounty completed
- [ ] Notifications configurable in settings
- [ ] Deep link to relevant screen
- [ ] Badge count on app icon

**Technical Notes:**
- Firebase Cloud Messaging (FCM)
- Cloud Functions to trigger notifications
- Store FCM token in user document
- Notification preferences in UserDefaults

---

# Future Ideas

These are potential features not yet scoped (from VISION Wild Ideas):

## Social Features
- **Guild Chat** - Real-time messaging within guild
- **Activity Feed** - Timeline of guild events
- **Member Profiles** - View member stats and history
- **Friend System** - Add friends across guilds

## Discovery
- **Public Guilds** - Join open guilds
- **Guild Search** - Find guilds by interest
- **Book Clubs** - Structured reading schedules

## Integration
- **Apple Watch** - Guild progress on watch
- **Widgets** - Progress widget for home screen
- **Shortcuts** - Siri shortcuts for common actions
- **Share Extensions** - Share books to guild

## Wild Ideas
- **Class System** - Identity generated from reading history (Chronoshifter, Delver, Ascendant, Hearth Keeper)
- **Royal Road Novel** - Companion LitRPG story with in-app unlocks
- **Artist Collaboration** - Official themes from LitRPG cover artists

---

# Priority Matrix

| Priority | Features |
|----------|----------|
| **P0 (Critical)** | - |
| **P1 (High) - MVP** | Leave Comment (2.1), Display Comments (2.2), Progress Sync (3.1), Ghost Markers (3.2) |
| **P2 (Medium) - Phase 2** | Comment Indicators (2.3), Comment History (2.4), Achievements (5.1), Themes (5.2), Guild Library (GL1), Error Handling, Loading States, Monetization (4.1) |
| **P3 (Low) - Phase 3** | Delete Comment (2.5), Trinkets (5.3), Recommendations (GL2), Bounty Board (6.x), Inn Experience (7.x), Offline Support, Push Notifications |

---

# Terminology

| Term | Meaning |
|------|---------|
| **The Inn** | The app itself, framed as a gathering place |
| **Guild** | A group of up to 6 readers (creator + 5 friends) |
| **Ghost Markers** | Visual indicators of guild members' progress on the timeline |
| **Bounty Board** | Quest/challenge hub within the app |
| **Raid Boss** | A significant reading challenge, often guild-level |
| **Trinket** | Small decorative item earned by completing a book |
| **Theme** | Full visual customization unlocked by completing a series |
| **Class** | Personal identity generated from reading history |
| **Traveler** | Free tier user |
| **Resident Adventurer** | One-time purchase (~$5-7) - achievements, themes, bounty board |
| **Guild Master** | One-time purchase (~$10-15) - everything + guild creation |
| **Ascendant Adventurer** | Future tier for global social features ("the multiverse") |

---

## See Also

- [VISION.md](./VISION.md) - Product vision and philosophy
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Technical architecture
- [USER-JOURNEYS.md](./USER-JOURNEYS.md) - User flows
- [SCREEN-INVENTORY.md](./SCREEN-INVENTORY.md) - Screen reference
- [SCREEN-MOCKUPS.md](./SCREEN-MOCKUPS.md) - ASCII mockups
