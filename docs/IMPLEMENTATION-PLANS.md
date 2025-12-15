# MVP Implementation Plans

> Detailed technical implementation plans for Squabble MVP epics.
> Created: December 14, 2025

---

## Overview

| Epic | Description | Complexity | Est. Files |
|------|-------------|------------|------------|
| **2.1** | Leave Comment at Timestamp | Medium | 6 new, 4 modified |
| **2.2** | Display Comments (Spoiler-Free) | Medium | 3 new, 2 modified |
| **3.1** | Progress Sync Reliability | Low | 2 modified |

---

# Epic 2.1: Leave Comment at Timestamp

## Goal
Add a comment button to the player that lets users leave timestamped reactions.

## Files to Create

### 1. `BookPlayer/Squabble/Models/Comment.swift`
```swift
struct Comment: Identifiable, Codable {
    let id: String
    let bookId: String
    let bookTitle: String
    let userId: String
    let userDisplayName: String
    let timestamp: TimeInterval  // seconds into audiobook
    let text: String
    let createdAt: Date

    static func from(documentId: String, data: [String: Any]) -> Comment?
    func toFirestoreData() -> [String: Any]
}
```

### 2. `BookPlayer/Squabble/Services/CommentsService.swift`
```swift
final class CommentsService: ObservableObject {
    static let shared = CommentsService()

    @Published private(set) var comments: [Comment] = []
    @Published private(set) var isLoading = false

    // Core methods
    func postComment(bookId: String, bookTitle: String, timestamp: TimeInterval, text: String) async throws
    func fetchComments(bookId: String, beforeTimestamp: TimeInterval) async throws -> [Comment]
    func deleteComment(_ commentId: String) async throws
    func startListening(bookId: String, currentProgress: TimeInterval)
    func stopListening()
}
```

**Firestore Path:** `guilds/{guildId}/comments/{commentId}`

### 3. `BookPlayer/Squabble/Views/CommentInputView.swift`
```swift
struct CommentInputView: View {
    let bookTitle: String
    let timestamp: TimeInterval
    let onSubmit: (String) async throws -> Void
    let onCancel: () -> Void

    @State private var commentText = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    // Character limit: 280
    // Shows formatted timestamp
    // Disable submit if empty or submitting
}
```

### 4. `BookPlayer/Squabble/Extensions/PlayerCoordinator+Squabble.swift`
```swift
extension PlayerCoordinator {
    func showCommentInput(bookTitle: String, timestamp: TimeInterval) {
        // Present CommentInputView as .medium() sheet
    }
}
```

## Files to Modify

### 5. `BookPlayer/Player/Player Screen/PlayerViewController.swift`
**Changes:**
- Add `@IBOutlet` for comment button (or add to "More" menu)
- Add `@IBAction func leaveComment()`
- Call `setupSquabbleCommentButton()` in viewDidLoad

### 6. `BookPlayer/Player/Player Screen/PlayerViewModel.swift`
**Changes:**
- Add `func leaveComment()` method
- Get current timestamp via `getBookCurrentTime()`
- Delegate to coordinator

### 7. `BookPlayer/Coordinators/PlayerCoordinator.swift`
**Changes:**
- Add `func showCommentInput()` method
- Present SwiftUI sheet with UIHostingController

### 8. `firestore.rules`
**Add:**
```firestore
match /comments/{commentId} {
    allow read: if isGuildMember();
    allow create: if isGuildMember() && request.resource.data.userId == request.auth.uid;
    allow delete: if request.auth.uid == resource.data.userId;
}
```

## Implementation Order

1. Create `Comment.swift` model
2. Create `CommentsService.swift` with postComment method
3. Create `CommentInputView.swift` UI
4. Add coordinator method `showCommentInput()`
5. Wire up PlayerViewModel → Coordinator
6. Add button to PlayerViewController (toolbar or More menu)
7. Update Firestore rules
8. Test end-to-end

## UI Decision: CTA Link Above Playback Controls

**Chosen Approach:**
- Add "Add Comment" CTA link positioned above the rewind/play/fastforward container
- Tappable text link style (not a toolbar button)
- Visible during playback, contextually relevant

**Implementation:**
- Add UIButton or SwiftUI Text with tap gesture
- Position in player layout above transport controls
- Style as link (underlined or accent color text)

---

# Epic 2.2: Display Comments (Spoiler-Free)

## Goal
Show guildmates' comments only AFTER the user passes that timestamp.

## Files to Create

### 1. `BookPlayer/Squabble/Views/CommentOverlayView.swift`
```swift
struct CommentOverlayView: View {
    let comment: Comment
    let onDismiss: () -> Void

    // Toast-style overlay showing:
    // - Commenter name
    // - Comment text
    // - Timestamp
    // Auto-dismiss after 4 seconds
}
```

### 2. `BookPlayer/Squabble/Views/CommentMarkerView.swift`
```swift
// Similar to GhostMarkerView but for comments
// Small indicator on timeline for passed comments
// Tap to show comment popup
```

### 3. `BookPlayer/Squabble/Extensions/PlayerViewController+Comments.swift`
```swift
extension PlayerViewController {
    func setupCommentListener()
    func checkForNewComments(at progress: TimeInterval)
    func showCommentToast(_ comment: Comment)
    func updateCommentMarkers()
}
```

## Files to Modify

### 4. `BookPlayer/Squabble/Services/CommentsService.swift`
**Add:**
```swift
// Track which comments user has seen
private var seenCommentIds: Set<String> = []

// Get newly-revealed comments when progress updates
func getNewlyVisibleComments(progress: TimeInterval) -> [Comment]

// Real-time listener filtered by timestamp
func startListening(bookId: String, maxTimestamp: TimeInterval)
```

### 5. `BookPlayer/Player/Player Screen/PlayerViewController.swift`
**Add:**
- Call `checkForNewComments()` on progress update
- Integrate comment markers with ghost markers

## Implementation Order

1. Extend CommentsService with filtered queries
2. Create CommentOverlayView (toast UI)
3. Add progress-based comment checking to PlayerViewController
4. Create CommentMarkerView for timeline indicators
5. Wire up real-time listener
6. Test spoiler-free reveal logic

## Key Logic: Spoiler-Free Reveal

```swift
// On every progress update:
func checkForNewComments(currentProgress: TimeInterval) {
    let newComments = commentsService.getNewlyVisibleComments(progress: currentProgress)
    for comment in newComments {
        showCommentToast(comment)
        commentsService.markAsSeen(comment.id)
    }
}
```

---

# Epic 3.1: Progress Sync Reliability

## Goal
Fix intermittent sync failures, especially with newly created guilds.

## Files to Modify

### 1. `BookPlayer/Squabble/Services/SquabbleSyncService.swift`
**Current Issues:**
- Race condition: guild ID may be nil when sync triggers
- No retry logic for failed syncs
- No queue for offline syncs

**Fixes:**
```swift
// 1. Wait for guild to load before syncing
private func ensureGuildLoaded() async -> String? {
    if let guildId = GuildService.shared.currentGuildId {
        return guildId
    }
    // Wait up to 5 seconds for guild to load
    for _ in 0..<10 {
        try? await Task.sleep(nanoseconds: 500_000_000)
        if let guildId = GuildService.shared.currentGuildId {
            return guildId
        }
    }
    return nil
}

// 2. Add retry logic
private func syncWithRetry(data: [String: Any], retries: Int = 3) async

// 3. Queue failed syncs for later
private var pendingSyncs: [[String: Any]] = []
func processPendingSyncs()
```

### 2. `BookPlayer/Squabble/Services/GuildService.swift`
**Add:**
```swift
// Notify when guild becomes available
@Published var isGuildReady = false

// In loadCurrentGuild():
await MainActor.run {
    self.isGuildReady = true
}
```

## Implementation Order

1. Add `isGuildReady` flag to GuildService
2. Add async guild wait in SquabbleSyncService
3. Add retry logic for transient failures
4. Add pending sync queue
5. Process queue on app foreground
6. Test with fresh guild creation

---

# Testing Strategy

## Screenshot Test Compatibility

### New Accessibility Identifiers Required
Add to `BookPlayerUITests/Helpers/ScreenIdentifiers.swift`:
```swift
enum Player {
    // Existing...
    static let buttonAddComment = "player_button_add_comment"
    static let commentInputSheet = "comment_input_sheet"
    static let commentTextField = "comment_text_field"
    static let commentSubmitButton = "comment_submit_button"
    static let commentOverlay = "comment_overlay_toast"
    static let commentMarker = "comment_marker"
}
```

### New Launch Arguments for Mock Data
Add to `AppDelegate+Squabble.swift`:
```swift
// Existing: --with-guild, --logged-in
// New:
--with-comments    // Inject mock comments for current book
--comment-visible  // Show a comment overlay (for screenshot)
```

### Mock Comment Data
Create `SquabbleTestHelper+Comments.swift`:
```swift
static func seedMockComments() -> [Comment] {
    return [
        Comment(id: "mock1", bookId: "book1", bookTitle: "Test Book",
                userId: "user2", userDisplayName: "Sam",
                timestamp: 1234.5, text: "WHAT. NO. WHAT.",
                createdAt: Date()),
        // More mock comments at various timestamps
    ]
}
```

### New Screenshot Tests
Add to `ScreenshotTests.swift`:
```swift
func test29_PlayerAddComment() throws {
    // Navigate to player with book
    // Capture: Player with "Add Comment" CTA visible
}

func test30_CommentInputSheet() throws {
    // Tap Add Comment
    // Capture: Comment input sheet with timestamp shown
}

func test31_CommentOverlay() throws {
    // Use --comment-visible launch arg
    // Capture: Comment toast overlay on player
}

func test32_CommentMarkers() throws {
    // Use --with-comments launch arg
    // Capture: Player timeline with comment markers
}
```

### Screenshot Manifest Updates
Add to `Screenshots/manifest.json`:
```json
{
  "id": "29-player-add-comment",
  "name": "Player Add Comment CTA",
  "category": "Player"
},
{
  "id": "30-comment-input-sheet",
  "name": "Comment Input Sheet",
  "category": "Squabble"
},
{
  "id": "31-comment-overlay",
  "name": "Comment Toast Overlay",
  "category": "Squabble"
},
{
  "id": "32-comment-markers",
  "name": "Timeline Comment Markers",
  "category": "Squabble"
}
```

## UI Test State Injection

### CommentsService Test Mode
```swift
// In CommentsService.swift
#if DEBUG
static func setUITestState(comments: [Comment]) {
    // Bypass Firestore, use mock data
}
#endif
```

### Integration with Existing Test Infrastructure
- Follow pattern from `GuildService.setUITestState()`
- Follow pattern from `SquabbleAuthService.setUITestState()`
- Comments should appear when `--with-comments` + `--with-guild` flags set

## Integration Tests (Firebase Emulator)

### New Test File: `CommentFlowIntegrationTests.swift`
```swift
class CommentFlowIntegrationTests: FirebaseIntegrationTests {
    func testUserCanPostComment() throws
    func testCommentAppearsAfterTimestamp() throws
    func testUserCanDeleteOwnComment() throws
    func testCannotDeleteOthersComment() throws
    func testCommentsFilteredByProgress() throws
}
```

## Unit Tests (Future)
- Comment model encoding/decoding
- Spoiler-free filter logic
- Timestamp formatting

## Manual Testing Checklist
1. Create comment at specific timestamp
2. Different user: verify comment hidden until reaching timestamp
3. Verify comment toast appears on crossing
4. Verify comment marker appears on timeline
5. Fresh guild creation → immediate progress sync
6. Screenshot capture script runs clean with new tests
7. All accessibility identifiers work for UI testing

---

# Summary: Build Order

**Phase 1: Epic 2.1 (Leave Comment)**
1. Comment model
2. CommentsService (post only)
3. CommentInputView
4. Coordinator integration
5. Player button

**Phase 2: Epic 2.2 (Display Comments)**
1. CommentsService extensions (fetch, listen)
2. CommentOverlayView (toast)
3. Player progress integration
4. CommentMarkerView (timeline)

**Phase 3: Epic 3.1 (Sync Fixes)**
1. GuildService ready flag
2. SquabbleSyncService reliability improvements

**Estimated total: 9 new files, 6 modified files**
