# Squabble Development Timelapse

> An MRI of app development - slice by slice, commit by commit.

**Created:** December 15, 2025

---

## The Vision

A visual time-travel tool for iOS app development. Watch your app evolve commit-by-commit, screen-by-screen. See exactly what changed, when, and why.

**Core Metaphor:** Like an MRI scan - you can move through slices (commits) and see the internal structure (screens) change over time. Or like git blame, but for pixels.

---

## Current Implementation (Phase 0)

### Smart Screenshot Capture
```bash
./scripts/capture-screenshots.sh              # Smart: only changed screens
./scripts/capture-screenshots.sh --baseline   # Capture all screens
./scripts/capture-screenshots.sh --screens 9,13  # Specific screens
```

**Features:**
- `manifest.json` maps source files → screens
- Git-aware: detects which files changed since last capture
- Commit-organized: `Screenshots/{commit-hash}/`
- XCUITest-powered: real simulator screenshots

### Visual Diff Tool
```bash
./scripts/diff-screenshots.sh <before> <after>        # Compare commits
./scripts/diff-screenshots.sh <before> <after> --html # HTML report
```

**Features:**
- ImageMagick pixel-level comparison
- Percentage difference with thresholds (minor vs significant)
- HTML report with before/after/diff side-by-side
- Highlights exactly where pixels changed

---

## Phase 1: GIF Auto-Generation

### Concept
For each screen, generate an animated GIF showing its evolution across commits.

```bash
./scripts/generate-timelapse.sh                    # All screens
./scripts/generate-timelapse.sh --screen 09        # Single screen
./scripts/generate-timelapse.sh --from abc123 --to def456  # Range
```

### Output
```
Screenshots/timelapse/
├── 09-player-main.gif          # Animated evolution
├── 09-player-main-annotated.gif # With commit hashes overlay
├── 13-player-sleep-timer.gif
└── full-app.gif                # All screens in grid
```

### Technical Approach
- Use ImageMagick `convert` to create GIFs
- Frame rate: ~0.5s per commit (adjustable)
- Optional: overlay commit hash + date on each frame
- Optional: highlight changed regions with colored border

### Example Output
```
┌─────────────────────────────────────────┐
│  09-player-main.gif                     │
│  ┌───────┐ ┌───────┐ ┌───────┐         │
│  │ abc123│→│ def456│→│ ghi789│→ ...    │
│  │       │ │  +btn │ │+toast │         │
│  └───────┘ └───────┘ └───────┘         │
│  12 commits | 6 changes | 2.4s          │
└─────────────────────────────────────────┘
```

---

## Phase 2: Timeline Navigator

### Concept
A horizontal timeline UI where commits flow left-to-right (oldest → newest). Scrub through time and watch the app change.

```
    ←── TIME ──→

    abc123    def456    ghi789    jkl012    mno345
       ●─────────●─────────●─────────●─────────●
       │         │                   │
       │         └─ "Add Comment"    └─ "Comment Toast"
       │            button added        overlay added
       └─ Initial player UI
```

### Interaction Modes

**1. Scrub Mode**
- Drag along timeline to see instant screen updates
- Smooth interpolation between commits (optional)
- Current commit info displayed: hash, date, message

**2. Diff Mode**
- Toggle to show diff overlay instead of raw screenshot
- Red highlights show what changed from previous commit
- Useful for spotting subtle changes

**3. Comparison Mode**
- Pin a commit on left, scrub on right
- Side-by-side comparison at any two points
- Great for "before feature X vs after"

**4. Playback Mode**
- Auto-play through commits at configurable speed
- Pause on significant changes (>5% diff)
- Export as video

### UI Layout
```
┌────────────────────────────────────────────────────────────────┐
│  ◀ ▶ ⏸  1.0x   [Scrub] [Diff] [Compare]     abc123 → def456   │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│    ┌─────────────┐              ┌─────────────┐               │
│    │             │              │             │               │
│    │   BEFORE    │              │    AFTER    │               │
│    │  (pinned)   │              │  (current)  │               │
│    │             │              │             │               │
│    └─────────────┘              └─────────────┘               │
│                                                                │
├────────────────────────────────────────────────────────────────┤
│  ●───●───●───●───●───●───●───●───●───●───●───●───●───●───●──▶ │
│  Oct 1                    Nov 15                    Dec 15     │
│                              ▲                                 │
│                           current                              │
└────────────────────────────────────────────────────────────────┘
```

---

## Phase 3: Figma-Style Canvas ("The MRI View")

### Concept
A zoomable, pannable canvas showing ALL screens simultaneously. Each commit only updates the screens that changed - like watching an organism evolve.

**The MRI Metaphor:**
- Each "slice" is a commit
- Each "organ" is a screen
- Step through slices and watch organs change
- Some organs change frequently, others are stable
- The whole picture tells the story of development

### Canvas Layout
```
┌────────────────────────────────────────────────────────────────────────┐
│  🔍 100%  ◀ ▶  Commit: def456 "Add comment button"  Dec 15, 2025      │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│   ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐                     │
│   │ Library │ │ Library │ │ Library │ │ Library │     LIBRARY         │
│   │ (empty) │ │ (books) │ │(folder) │ │(search) │     SCREENS         │
│   └─────────┘ └─────────┘ └─────────┘ └─────────┘                     │
│                                                                        │
│   ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐                     │
│   │ Player  │ │ Player  │ │ Player  │ │ Player  │     PLAYER          │
│   │  Main   │ │Chapters │ │Bookmarks│ │Controls │     SCREENS         │
│   │ ██████  │ │         │ │         │ │         │ ← changed this      │
│   └─────────┘ └─────────┘ └─────────┘ └─────────┘   commit!           │
│                                                                        │
│   ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐                     │
│   │ Guild   │ │  Guild  │ │  Guild  │ │ Guild   │     GUILD           │
│   │ (none)  │ │ Create  │ │  Join   │ │  View   │     SCREENS         │
│   └─────────┘ └─────────┘ └─────────┘ └─────────┘                     │
│                                                                        │
│   ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐                     │
│   │Settings │ │Settings │ │Settings │ │Settings │     SETTINGS        │
│   │  Main   │ │ Themes  │ │ Icons   │ │Controls │     SCREENS         │
│   └─────────┘ └─────────┘ └─────────┘ └─────────┘                     │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

### Visual Indicators

**Screen States:**
- 🟢 Green border = changed this commit
- 🟡 Yellow border = changed recently (last 5 commits)
- ⚪ No border = stable (unchanged for 10+ commits)
- 🔴 Red border = significant change (>5% diff)

**Heatmap Mode:**
- Color screens by "churn" - how often they change
- Hot (red) = frequently modified
- Cool (blue) = stable
- Reveals which parts of the app get the most attention

**Dependency Lines:**
- Optional: show lines connecting related screens
- Based on navigation flow or shared components
- Helps understand the app's structure

### Zoom Levels

**1. Overview (10%)**
- See entire app at a glance
- Screens as small thumbnails
- Good for pattern recognition

**2. Section (50%)**
- Focus on one area (Player, Settings, etc.)
- Screens readable
- Good for feature-level review

**3. Detail (100%+)**
- Single screen fills view
- Pixel-perfect detail
- Good for design review

### Interactions

**Canvas:**
- Pan: drag or arrow keys
- Zoom: scroll wheel or pinch
- Click screen: zoom to fill + show timeline for that screen

**Timeline (at bottom):**
- Same as Phase 2 timeline
- Scrub to change current commit
- Canvas updates only changed screens (smooth!)

**Screen Click:**
- Shows that screen's individual timeline
- Mini-diff view for that screen only
- Jump to commit where it last changed

---

## Technical Architecture

### Data Model
```
Screenshots/
├── manifest.json              # Screen definitions
├── index.json                 # All captures metadata
│   {
│     "captures": [
│       {
│         "commit": "abc123",
│         "date": "2025-12-15T00:32:00Z",
│         "message": "Add comment button",
│         "screens": ["09-player-main", "13-player-sleep-timer"],
│         "changes": {
│           "09-player-main": { "diff": 0.88, "from": "previous-commit" },
│           "13-player-sleep-timer": { "diff": 6.21, "from": "previous-commit" }
│         }
│       }
│     ]
│   }
├── abc123/
│   ├── 09-player-main.png
│   └── 13-player-sleep-timer.png
├── def456/
│   └── ...
├── diff/
│   ├── abc123-def456/
│   │   ├── 09-player-main-diff.png
│   │   └── report.html
└── timelapse/
    ├── 09-player-main.gif
    └── full-app.gif
```

### Web Viewer Options

**Option A: Static HTML + JavaScript**
- Single HTML file with embedded JS
- Loads screenshots from local paths
- Works offline, no server needed
- Good for personal use / sharing

**Option B: Local Web Server**
- Python/Node simple server
- Enables more dynamic features
- Better for large screenshot sets

**Option C: Hosted Service**
- Upload to GitHub Pages or similar
- Shareable links
- Could be a separate product eventually

### Dependencies
- ImageMagick (already using for diff)
- FFmpeg (for video export)
- Modern browser (for canvas viewer)

---

## Use Cases

### 1. Development Documentation
*"Here's how we built Squabble, commit by commit"*
- Embed GIFs in blog posts
- Link to interactive timelapse
- Show evolution of specific features

### 2. Code Review
*"Show me what this PR changes visually"*
- Diff the before/after branches
- See exactly which screens changed
- Catch unintended visual regressions

### 3. Design Review
*"Is this implementation matching the design?"*
- Pin design mockup on left
- Compare to current screenshot
- Iterate until matched

### 4. Onboarding
*"How did this screen end up looking like this?"*
- Travel back in time
- See the evolution of decisions
- Understand why things are the way they are

### 5. Portfolio / Case Study
*"Here's my development process"*
- Impressive visual demonstration
- Shows thoroughness and attention to detail
- Differentiator for freelancers/agencies

---

## Implementation Roadmap

### Phase 0 (Done)
- [x] Smart screenshot capture
- [x] Git-aware change detection
- [x] Commit-organized storage
- [x] Visual diff tool
- [x] HTML diff reports

### Phase 1 (GIF Generation)
- [ ] Single-screen GIF generation
- [ ] Full-app grid GIF
- [ ] Commit annotation overlay
- [ ] Configurable frame rate
- [ ] Range selection (from/to commits)

### Phase 2 (Timeline Navigator)
- [ ] Basic HTML timeline UI
- [ ] Scrub through commits
- [ ] Diff toggle mode
- [ ] Side-by-side comparison
- [ ] Playback mode

### Phase 3 (Canvas Viewer)
- [ ] Zoomable/pannable canvas
- [ ] All screens grid layout
- [ ] Change indicators (borders)
- [ ] Heatmap mode
- [ ] Screen detail view
- [ ] Video export

---

## Open Questions

1. **Storage**: How many commits before disk space becomes an issue? Consider compression or selective retention.

2. **Performance**: Loading hundreds of screenshots - lazy load? Thumbnails?

3. **Branching**: How to handle git branches? Separate timelines? Merge visualization?

4. **Sharing**: What's the easiest way to share a timelapse? Single HTML file? Hosted viewer?

5. **Integration**: Could this integrate with GitHub PR reviews? Xcode?

---

## Inspiration

- **Git history visualizations** (GitKraken, SourceTree graphs)
- **Figma version history** (timeline scrubbing)
- **Medical imaging viewers** (slice-by-slice navigation)
- **Wayback Machine** (web page time travel)
- **After Effects timeline** (keyframes and playback)

---

*This document is a living vision. Update as we build and learn.*
