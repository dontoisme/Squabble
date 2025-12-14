# Squabble Technical Architecture

> Quick technical reference for AI assistants and future development sessions.
> Last updated: December 2025

## Table of Contents
- [System Overview](#system-overview)
- [Service Architecture](#service-architecture)
- [Data Flow Diagrams](#data-flow-diagrams)
- [Firestore Schema](#firestore-schema)
- [Extension Pattern](#extension-pattern)
- [Key Files Reference](#key-files-reference)

---

## System Overview

Squabble is a social audiobook app built as a fork of BookPlayer. It adds guild-based features where friends can see each other's reading progress as "ghost markers" on shared playback timelines.

```mermaid
flowchart TB
    subgraph UI["UI Layer"]
        direction LR
        SwiftUI["SwiftUI Views"]
        UIKit["UIKit ViewControllers"]
    end

    subgraph State["State Management"]
        direction LR
        VM["ViewModels<br/>(ThemeViewModel, SearchViewModel)"]
        OO["ObservableObjects<br/>(AuthService, GuildService)"]
        Env["EnvironmentObjects<br/>(PlayerManager, Theme)"]
    end

    subgraph Services["Service Layer"]
        direction LR
        subgraph Squabble["Squabble Services"]
            Auth["SquabbleAuthService"]
            Guild["GuildService"]
            Sync["SquabbleSyncService"]
            Observer["PlaybackObserver"]
        end
        subgraph BookPlayer["BookPlayer Services"]
            Playback["PlaybackService"]
            Library["LibraryService"]
            Account["AccountService"]
        end
    end

    subgraph Data["Data Layer"]
        direction LR
        Firestore["Cloud Firestore<br/>(guilds, members, progress)"]
        CoreData["CoreData<br/>(library items, bookmarks)"]
        Keychain["Keychain<br/>(credentials, tokens)"]
        UserDef["UserDefaults<br/>(preferences)"]
    end

    subgraph External["External Services"]
        direction LR
        Firebase["Firebase Auth"]
        RevenueCat["RevenueCat<br/>(subscriptions)"]
        Jellyfin["Jellyfin<br/>(media server)"]
        ABS["AudiobookShelf"]
        Hardcover["Hardcover<br/>(metadata)"]
    end

    UI --> State
    State --> Services
    Services --> Data
    Services --> External
```

### Architecture Highlights

| Aspect | Approach |
|--------|----------|
| **UI Framework** | SwiftUI primary, UIKit for complex views (Player) |
| **State Management** | ObservableObject + @Published + Combine |
| **Squabble Integration** | Extension pattern (minimal BookPlayer modifications) |
| **Backend** | Firebase Auth + Cloud Firestore |
| **Local Storage** | CoreData (library), Keychain (secrets), UserDefaults (prefs) |

---

## Service Architecture

### Squabble Services (4 total)

```mermaid
flowchart LR
    subgraph External
        FireAuth["Firebase Auth"]
        FireStore["Cloud Firestore"]
    end

    subgraph SquabbleServices["Squabble Service Layer"]
        AuthSvc["SquabbleAuthService<br/>━━━━━━━━━━━━<br/>• signUp/signIn<br/>• session restore<br/>• @Published isAuthenticated"]
        GuildSvc["GuildService<br/>━━━━━━━━━━━━<br/>• create/join/leave guild<br/>• real-time listeners<br/>• @Published currentGuild"]
        SyncSvc["SquabbleSyncService<br/>━━━━━━━━━━━━<br/>• progress sync (5min throttle)<br/>• fetch guild progress<br/>• force sync on pause"]
        ObsSvc["PlaybackObserver<br/>━━━━━━━━━━━━<br/>• NotificationCenter listener<br/>• routes to SyncService"]
    end

    subgraph BookPlayerServices["BookPlayer Integration"]
        PlayerMgr["PlayerManager<br/>━━━━━━━━━━━━<br/>• posts progress notifications"]
    end

    AuthSvc --> FireAuth
    GuildSvc --> FireStore
    GuildSvc -.-> AuthSvc
    SyncSvc --> FireStore
    SyncSvc -.-> GuildSvc
    ObsSvc --> SyncSvc
    PlayerMgr -.->|NotificationCenter| ObsSvc
```

### Service Responsibilities

| Service | Singleton | Observable | Responsibilities |
|---------|-----------|------------|------------------|
| **SquabbleAuthService** | `shared` | Yes | Firebase email/password auth, session management |
| **GuildService** | `shared` | Yes | Guild CRUD, member management, Firestore listeners |
| **SquabbleSyncService** | `shared` | No | Progress sync with 5-min throttle, fetch guild progress |
| **SquabblePlaybackObserver** | `shared` | No | Routes playback notifications to sync service |
| **SquabbleManager** | `shared` | No | Central coordinator, setup and initialization |

### BookPlayer Core Services (used by Squabble)

| Service | Purpose |
|---------|---------|
| **PlayerManager** | Playback state, progress updates, notifications |
| **LibraryService** | Audiobook library management, metadata |
| **DataManager** | CoreData persistence, file system operations |
| **KeychainService** | Secure credential storage |

---

## Data Flow Diagrams

### Authentication Flow

```mermaid
sequenceDiagram
    participant User
    participant ProfileView as SquabbleProfileView
    participant LoginView as SquabbleLoginView
    participant AuthSvc as SquabbleAuthService
    participant Firebase as Firebase Auth
    participant GuildSvc as GuildService

    User->>ProfileView: Tap "Sign In"
    ProfileView->>LoginView: Present sheet
    User->>LoginView: Enter email/password
    LoginView->>AuthSvc: signIn(email, password)
    AuthSvc->>Firebase: signIn request
    Firebase-->>AuthSvc: User credential
    AuthSvc->>AuthSvc: Update @Published isAuthenticated
    AuthSvc-->>LoginView: Success
    LoginView->>ProfileView: Dismiss & callback
    ProfileView->>GuildSvc: loadCurrentGuild()
    GuildSvc->>GuildSvc: Start Firestore listeners
```

### Progress Sync Flow

```mermaid
sequenceDiagram
    participant Player as PlayerManager
    participant NC as NotificationCenter
    participant Observer as PlaybackObserver
    participant Sync as SyncService
    participant FS as Firestore

    Player->>Player: updatePlaybackTime()
    Player->>NC: post(.squabbleProgressUpdate)
    NC->>Observer: notification received
    Observer->>Sync: syncProgress(book, time, %)

    alt Throttle check (< 5 min since last)
        Sync-->>Observer: Skip (throttled)
    else Sync allowed
        Sync->>FS: Write progress document
        FS-->>Sync: Success
        Sync->>Sync: Update lastSyncTime
    end

    Note over Player,FS: On pause/background: forceSyncProgress() bypasses throttle
```

### Ghost Markers Display Flow

```mermaid
sequenceDiagram
    participant PVC as PlayerViewController
    participant Sync as SyncService
    participant FS as Firestore
    participant Overlay as GhostOverlayView

    PVC->>PVC: viewDidLoad()
    PVC->>PVC: setupSquabbleGhostOverlay()
    PVC->>Sync: fetchGuildProgress(bookId)
    Sync->>FS: Query progress collection
    FS-->>Sync: [GhostProgress] array
    Sync-->>PVC: Progress for all members
    PVC->>PVC: Filter out current user
    PVC->>PVC: Assign colors cyclically
    PVC->>Overlay: Update ghostMarkers
    Overlay->>Overlay: layoutSubviews()
    Overlay->>Overlay: Render markers on slider
```

### Guild Creation Flow

```mermaid
sequenceDiagram
    participant User
    participant View as CreateGuildView
    participant Guild as GuildService
    participant FS as Firestore

    User->>View: Enter guild name
    User->>View: Tap "Create"
    View->>Guild: createGuild(name)

    Guild->>Guild: Generate 6-char invite code
    Guild->>FS: Create guilds/{id} document
    Guild->>FS: Create members/{userId} (as owner)
    Guild->>FS: Create users/{userId} with guildId

    FS-->>Guild: Success
    Guild->>Guild: Update @Published currentGuild
    Guild->>Guild: Start real-time listeners
    Guild-->>View: Success
    View->>View: Dismiss sheet
```

---

## Firestore Schema

```mermaid
erDiagram
    GUILDS {
        string id PK "UUID"
        string name "Display name"
        string createdBy FK "User ID"
        timestamp createdAt
        string inviteCode "6-char alphanumeric"
        int memberCount "Denormalized"
    }

    MEMBERS {
        string id PK "User ID"
        string guildId FK
        string displayName
        string email
        string role "owner | member"
        timestamp joinedAt
    }

    PROGRESS {
        string id PK "bookId_userId"
        string guildId FK
        string bookId "Hash of title"
        string bookTitle
        string userId FK
        string userEmail
        double progressPercent "0-100"
        double progressTimestamp "seconds"
        double totalDuration "seconds"
        timestamp lastUpdatedAt "server"
        boolean isActive
    }

    USERS {
        string id PK "Firebase UID"
        string currentGuildId FK
        string email
    }

    GUILDS ||--o{ MEMBERS : "has"
    GUILDS ||--o{ PROGRESS : "tracks"
    USERS ||--o| GUILDS : "belongs to"
```

### Collection Paths

```
guilds/{guildId}
guilds/{guildId}/members/{userId}
guilds/{guildId}/progress/{bookId_userId}
users/{userId}
```

### Document Examples

**Guild Document:**
```json
{
  "name": "Book Club",
  "createdBy": "user-123",
  "createdAt": "2025-12-10T10:00:00Z",
  "inviteCode": "ABC123",
  "memberCount": 3
}
```

**Member Document:**
```json
{
  "displayName": "John",
  "email": "john@example.com",
  "role": "owner",
  "joinedAt": "2025-12-10T10:00:00Z"
}
```

**Progress Document:**
```json
{
  "bookId": "the-hobbit",
  "bookTitle": "The Hobbit",
  "userId": "user-123",
  "userEmail": "john@example.com",
  "progressPercent": 42.5,
  "progressTimestamp": 3847.2,
  "totalDuration": 9052.0,
  "lastUpdatedAt": "2025-12-13T15:30:00Z",
  "isActive": true
}
```

---

## Extension Pattern

Squabble integrates with BookPlayer using a clean extension pattern that minimizes changes to core files.

### Integration Points (4 files modified)

```mermaid
flowchart LR
    subgraph BookPlayerCore["BookPlayer Core (minimal changes)"]
        AD["AppDelegate.swift<br/>// SQUABBLE: setupSquabble()"]
        LC["LoadingCoordinator.swift<br/>// SQUABBLE: squabbleAuthGate()"]
        PM["PlayerManager.swift<br/>// SQUABBLE: postProgressUpdate()"]
        PVC["PlayerViewController.swift<br/>// SQUABBLE: setupGhostOverlay()"]
    end

    subgraph Extensions["Squabble Extensions"]
        ADE["AppDelegate+Squabble.swift"]
        LCE["LoadingCoordinator+Squabble.swift"]
        PME["PlayerManager+Squabble.swift"]
        PVCE["PlayerViewController+Squabble.swift"]
    end

    AD -.->|calls| ADE
    LC -.->|calls| LCE
    PM -.->|calls| PME
    PVC -.->|calls| PVCE
```

### Extension File Responsibilities

| Extension | Purpose |
|-----------|---------|
| `AppDelegate+Squabble.swift` | Firebase setup, emulator config, UI test mode |
| `LoadingCoordinator+Squabble.swift` | Auth gate (currently no-op for lazy auth) |
| `PlayerManager+Squabble.swift` | PlaybackObserver + progress notifications |
| `PlayerViewController+Squabble.swift` | Ghost overlay setup and display |

### Benefits of Extension Pattern

1. **Upstream Compatibility** - Easy to merge BookPlayer updates
2. **Isolated Code** - All Squabble code in `/BookPlayer/Squabble/`
3. **Marked Integration** - Search `// SQUABBLE:` to find all hooks
4. **Feature Flags** - `SquabbleConfig.isEnabled` guards all features

---

## Key Files Reference

### Squabble Core

| File | Purpose |
|------|---------|
| `Squabble/Core/SquabbleConfig.swift` | Feature flags, sync intervals, logging |
| `Squabble/Core/SquabbleManager.swift` | Central coordinator, initialization |

### Services

| File | Purpose |
|------|---------|
| `Squabble/Services/SquabbleAuthService.swift` | Firebase Auth wrapper |
| `Squabble/Services/GuildService.swift` | Guild CRUD + Firestore listeners |
| `Squabble/Services/SquabbleSyncService.swift` | Progress sync to Firestore |

### Models

| File | Purpose |
|------|---------|
| `Squabble/Models/Guild.swift` | Guild, GuildMember, GuildRole |
| `Squabble/Models/GhostMarker.swift` | GhostMarker, GhostProgress |

### Views

| File | Purpose |
|------|---------|
| `Squabble/Views/SquabbleProfileView.swift` | Profile tab replacement (guild hub) |
| `Squabble/Views/SquabbleLoginView.swift` | Email/password auth UI |
| `Squabble/Views/GuildView.swift` | Create/Join/Detail views |
| `Squabble/Views/SquabbleGhostOverlayView.swift` | Ghost markers on player |

### Extensions

| File | Purpose |
|------|---------|
| `Squabble/Extensions/AppDelegate+Squabble.swift` | Firebase setup, test mode |
| `Squabble/Extensions/PlayerManager+Squabble.swift` | PlaybackObserver |
| `Squabble/Extensions/PlayerViewController+Squabble.swift` | Ghost overlay |

### Testing

| File | Purpose |
|------|---------|
| `BookPlayerUITests/ScreenshotTests.swift` | 28 automated screenshots |
| `BookPlayerUITests/FirebaseIntegrationTests.swift` | Emulator test base class |
| `BookPlayerUITests/AuthFlowIntegrationTests.swift` | Auth flow tests |
| `BookPlayerUITests/GuildFlowIntegrationTests.swift` | Guild CRUD tests |

### Configuration

| File | Purpose |
|------|---------|
| `firebase.json` | Emulator configuration |
| `firestore.rules` | Security rules |
| `.firebaserc` | Project ID reference |

---

## Quick Commands

```bash
# Start Firebase emulators
firebase emulators:start --only auth,firestore

# Run screenshot tests
./scripts/capture-screenshots.sh

# Run integration tests (requires emulators)
xcodebuild test -scheme BookPlayer -only-testing:BookPlayerUITests/AuthFlowIntegrationTests
```

---

## See Also

- [USER-JOURNEYS.md](./USER-JOURNEYS.md) - All user flows and interactions
- [ROADMAP.md](./ROADMAP.md) - Planned features with acceptance criteria
- [SCREEN-INVENTORY.md](./SCREEN-INVENTORY.md) - Complete screen reference
- [SQUABBLE-HANDOFF.md](../SQUABBLE-HANDOFF.md) - Quick-start reference
