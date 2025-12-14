# Squabble Feature Roadmap

> Planned features with acceptance criteria for implementation.
> Last updated: December 2025

## Table of Contents
- [Completed Work](#completed-work)
- [Epic 2: Timestamp Comments](#epic-2-timestamp-comments-dark-souls-style)
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

# Epic 2: Timestamp Comments (Dark Souls Style)

## 2.1 Leave Comment at Timestamp
**Status:** Not Started
**Priority:** P1 (High)
**Dependencies:** Guild system complete

**User Story:**
As a guild member, I want to leave a comment at a specific moment in an audiobook so that my guildmates can see my reaction when they reach that point.

**Acceptance Criteria:**
- [ ] Comment button available in player UI
- [ ] Tapping opens comment input with current timestamp shown
- [ ] Can type reaction/comment (character limit TBD, ~280?)
- [ ] Post saves comment to Firestore with:
  - [ ] Timestamp (seconds into audiobook)
  - [ ] Book ID
  - [ ] User ID
  - [ ] Comment text
  - [ ] Created date
- [ ] Confirmation that comment was posted
- [ ] Can cancel without posting

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

## 2.2 Display Comments (Spoiler-Free)
**Status:** Not Started
**Priority:** P1 (High)
**Dependencies:** Leave Comment (2.1)

**User Story:**
As a guild member, I want to see my guildmates' comments only AFTER I pass that timestamp so that I don't get spoilers.

**Acceptance Criteria:**
- [ ] Comments only appear after user's progress passes the timestamp
- [ ] When crossing a comment timestamp:
  - [ ] Subtle notification/chime
  - [ ] Comment appears briefly on screen
  - [ ] Comment indicator added to timeline
- [ ] Can tap timeline indicator to re-read comment
- [ ] Multiple comments at same timestamp shown in order
- [ ] Comments from all guild members shown (not just active readers)

**Technical Notes:**
- Query comments where `timestamp <= currentProgress`
- Track "last seen timestamp" to detect newly-passed comments
- Local cache of already-seen comments
- UI overlay for comment display (non-blocking)
- Consider: batch fetch comments for entire book on load

---

## 2.3 Comment Indicators on Timeline
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

## 2.4 Comment History View
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

## 2.5 Delete Own Comment
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
| **P1 (High)** | Leave Comment, Display Comments (spoiler-free) |
| **P2 (Medium)** | Comment Indicators, Comment History, Guild Library, Error Handling, Loading States |
| **P3 (Low)** | Delete Comment, Recommendations, Offline Support, Push Notifications |

---

## See Also

- [ARCHITECTURE.md](./ARCHITECTURE.md) - Technical architecture
- [USER-JOURNEYS.md](./USER-JOURNEYS.md) - User flows
- [SCREEN-INVENTORY.md](./SCREEN-INVENTORY.md) - Screen reference
