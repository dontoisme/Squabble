# Squabble Feature Roadmap

> Planned features with acceptance criteria for implementation.
> Last updated: December 2025

## Table of Contents
- [Completed Work](#completed-work)
- [Epic 2: Competitions & Races](#epic-2-competitions--races)
- [Guild Library](#guild-library)
- [Quality of Life](#quality-of-life-improvements)
- [Future Ideas](#future-ideas)

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

**Summary:** Full guild management system with create, join, leave, and invite functionality.

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

# Epic 2: Competitions & Races

## 2.1 Create Reading Race
**Status:** Not Started
**Priority:** P1 (High)
**Dependencies:** Guild system complete

**User Story:**
As a guild owner/member, I want to create a reading race so that my guild can compete to finish a book together.

**Acceptance Criteria:**
- [ ] "Create Race" button available in guild view
- [ ] Form to configure race:
  - [ ] Select book from personal library
  - [ ] Set race name (optional, defaults to book title)
  - [ ] Set start date (default: now)
  - [ ] Set end date (required)
  - [ ] Set goal: finish book OR reach X% progress
- [ ] Race created in Firestore with unique ID
- [ ] Creator auto-joined as participant
- [ ] Race visible to all guild members

**Technical Notes:**
- New Firestore collection: `guilds/{guildId}/races/{raceId}`
- Race document schema:
  ```
  {
    id: string,
    bookId: string,
    bookTitle: string,
    name: string,
    createdBy: string,
    createdAt: timestamp,
    startDate: timestamp,
    endDate: timestamp,
    goalType: "finish" | "percentage",
    goalValue: number (100 for finish, or target %),
    status: "upcoming" | "active" | "completed"
  }
  ```
- New view: `CreateRaceView.swift`
- Book selection from local library only (v1)

---

## 2.2 Join Race
**Status:** Not Started
**Priority:** P1 (High)
**Dependencies:** Create Race (2.1)

**User Story:**
As a guild member, I want to join an active race so that I can compete with my friends.

**Acceptance Criteria:**
- [ ] Guild view shows active races section
- [ ] Each race card shows:
  - [ ] Book title and cover
  - [ ] Time remaining
  - [ ] Participant count
  - [ ] "Join" button (if not joined)
- [ ] Tap "Join" → Add user to participants
- [ ] Must have book in local library to join (or prompt to add)
- [ ] Cannot join races that have ended
- [ ] Cannot join race already participating in

**Technical Notes:**
- Race participants subcollection: `races/{raceId}/participants/{userId}`
- Participant document:
  ```
  {
    userId: string,
    joinedAt: timestamp,
    currentProgress: number,
    lastUpdated: timestamp,
    finished: boolean,
    finishedAt: timestamp?
  }
  ```
- Book matching by title (same as ghost markers)
- Show "Get Book" option if not in library

---

## 2.3 Live Leaderboard
**Status:** Not Started
**Priority:** P1 (High)
**Dependencies:** Join Race (2.2)

**User Story:**
As a race participant, I want to see a live leaderboard so that I know how I rank against other readers.

**Acceptance Criteria:**
- [ ] Race detail view shows leaderboard
- [ ] Leaderboard sorted by progress (highest first)
- [ ] Each entry shows:
  - [ ] Rank (#1, #2, etc.)
  - [ ] Member name/avatar
  - [ ] Current progress %
  - [ ] Time since last update
- [ ] Current user highlighted
- [ ] Updates in real-time via listeners
- [ ] Shows "Finished!" badge for completers

**Technical Notes:**
- Real-time Firestore listener on participants collection
- Sort client-side by `currentProgress` descending
- Progress synced via existing `SquabbleSyncService`
- Detect "finished" when progress >= goalValue
- New view: `RaceLeaderboardView.swift`

---

## 2.4 Race Progress Sync
**Status:** Not Started
**Priority:** P1 (High)
**Dependencies:** Live Leaderboard (2.3)

**User Story:**
As a race participant, I want my progress to automatically update in the race so that the leaderboard reflects my reading.

**Acceptance Criteria:**
- [ ] When playing race book, progress syncs to race participants doc
- [ ] Sync uses same throttle as guild progress (5 min)
- [ ] Force sync on pause/background
- [ ] Progress shows on leaderboard within seconds
- [ ] Finishing book marks participant as "finished"
- [ ] First to finish gets special indicator

**Technical Notes:**
- Extend `SquabbleSyncService` to check active races
- On progress update:
  1. Sync to guild progress (existing)
  2. Check if book matches any active race
  3. If match, update participant document
- Winner detection: First `finishedAt` timestamp
- Consider: batch writes for efficiency

---

## 2.5 Race Completion & Results
**Status:** Not Started
**Priority:** P2 (Medium)
**Dependencies:** Race Progress Sync (2.4)

**User Story:**
As a race participant, I want to see final results when a race ends so that I know who won.

**Acceptance Criteria:**
- [ ] Race auto-completes when end date reached
- [ ] Final leaderboard frozen at end time
- [ ] Winner announced (highest progress or first to finish)
- [ ] Results view shows:
  - [ ] Winner with celebration UI
  - [ ] Final rankings for all participants
  - [ ] Personal stats (your rank, progress, reading time)
- [ ] Past races accessible from guild view

**Technical Notes:**
- Cloud Function or client-side check for race end
- Status transitions: `active` → `completed`
- Preserve final state in race document
- New view: `RaceResultsView.swift`
- Consider: Push notification when race ends

---

## 2.6 Race History
**Status:** Not Started
**Priority:** P3 (Low)
**Dependencies:** Race Completion (2.5)

**User Story:**
As a guild member, I want to see past races so that I can view our competition history.

**Acceptance Criteria:**
- [ ] "Past Races" section in guild view
- [ ] List of completed races with:
  - [ ] Book title
  - [ ] Winner name
  - [ ] End date
  - [ ] Your final rank
- [ ] Tap race → View full results
- [ ] Sorted by most recent first

**Technical Notes:**
- Query races where `status == "completed"`
- Paginate if many races (unlikely early on)
- Cache results for performance

---

# Guild Library

## GL1: View Guild Members' Books
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

## GL2: Book Recommendations
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
  - [ ] Race started/ended
  - [ ] Someone passed you in race
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

These are potential features not yet scoped:

## Social Features
- **Guild Chat** - Real-time messaging within guild
- **Activity Feed** - Timeline of guild events
- **Member Profiles** - View member stats and history
- **Friend System** - Add friends across guilds

## Gamification
- **Achievements** - Badges for reading milestones
- **Streaks** - Daily listening streaks
- **XP System** - Points for progress
- **Guild Levels** - Level up guild with activity

## Discovery
- **Public Guilds** - Join open guilds
- **Guild Search** - Find guilds by interest
- **Book Clubs** - Structured reading schedules
- **Cross-Guild Races** - Compete between guilds

## Integration
- **Apple Watch** - Guild progress on watch
- **Widgets** - Race progress widget
- **Shortcuts** - Siri shortcuts for common actions
- **Share Extensions** - Share books to guild

---

## Priority Matrix

| Priority | Features |
|----------|----------|
| **P0 (Critical)** | - |
| **P1 (High)** | Create Race, Join Race, Live Leaderboard, Race Progress Sync |
| **P2 (Medium)** | Race Results, Guild Library, Error Handling, Loading States |
| **P3 (Low)** | Race History, Recommendations, Offline Support, Push Notifications |

---

## See Also

- [ARCHITECTURE.md](./ARCHITECTURE.md) - Technical architecture
- [USER-JOURNEYS.md](./USER-JOURNEYS.md) - User flows
- [SCREEN-INVENTORY.md](./SCREEN-INVENTORY.md) - Screen reference
