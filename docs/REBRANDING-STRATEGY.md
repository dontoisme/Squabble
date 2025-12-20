# Squabble Inn Rebrand & Upstream Sync Strategy

> Transform from "BookPlayer + Squabble features" to "Squabble Inn app powered by BookPlayer engine"
> Last updated: December 2025

## Goal

Full rebrand of the app while maintaining ability to merge upstream BookPlayer engine improvements.

## User Requirements

1. **Full rebrand** - Replace ALL BookPlayer branding, themes, icons, images, terminology
2. **Subtle nods** - Acknowledge "Powered by BookPlayer" but otherwise new identity
3. **Engine-only sync** - Merge only audio engine from upstream, never UI/Settings

---

## Phase 1: Upstream Sync Strategy

### Create `.gitattributes` for merge control

```gitattributes
# ALWAYS OURS (Never accept upstream changes)
BookPlayer/Info.plist merge=ours
BookPlayer/Credits.html merge=ours
BookPlayer/Assets.xcassets/** merge=ours
BookPlayer/*.lproj/** merge=ours
BuildConfiguration/*.xcconfig merge=ours
BookPlayer/Squabble/** merge=ours
BookPlayer/AppDelegate.swift merge=ours
BookPlayer/MainView.swift merge=ours
BookPlayer/Settings/** merge=ours
BookPlayer/Profile/** merge=ours
BookPlayer/Coordinators/LoadingCoordinator.swift merge=ours
BookPlayer/Player/Player Screen/PlayerViewController.swift merge=ours
BookPlayerUITests/** merge=ours
*.png binary merge=ours

# ALWAYS THEIRS (Accept upstream engine)
Shared/Services/PlaybackService.swift merge=theirs
Shared/Artwork/** merge=theirs
Shared/CoreData/** merge=theirs
Shared/Network/** merge=theirs
BookPlayer/Player/PlayerLoaderService.swift merge=theirs
BookPlayer/Player/SpeedService.swift merge=theirs
BookPlayer/Player/SleepTimer.swift merge=theirs
BookPlayer/Player/Bookmarks/** merge=theirs
BookPlayer/Player/Chapters/** merge=theirs

# MANUAL (Has SQUABBLE hook - needs careful merge)
BookPlayer/Player/PlayerManager.swift merge=manual
```

### Add to `.git/config`

```ini
[merge "ours"]
    driver = true
[merge "theirs"]
    driver = "git show :3:%A > %A"
[merge "manual"]
    driver = false
```

---

## Phase 2: Core Identity Rebrand

| Item | File | Status |
|------|------|--------|
| App Display Name | `Info.plist:29` | Complete |
| Bundle ID | `BuildConfiguration/*.xcconfig` | Update to Squabble identifier |
| URL Scheme | `Info.plist:366` | Change `bookplayer` to `squabble` |
| App Icon | `Assets.xcassets/AppIcon.appiconset/` | Complete |
| Splash Screen | `Assets.xcassets/SplashImage.imageset/` | Complete |
| Credits | `Credits.html` | Add "Powered by BookPlayer" attribution |

---

## Phase 3: Visual Assets

| Asset | Location | Status |
|-------|----------|--------|
| Empty Library | `Assets.xcassets/emptyLibrary.imageset/` | Needs Squabble art |
| Empty Playlist | `Assets.xcassets/emptyPlaylist.imageset/` | Needs Squabble art |
| Default Artwork | `Assets.xcassets/defaultArtwork.imageset/` | Needs Squabble art |
| Alternate Icons | `Info.plist` + `Settings/Icons/assets/` | Create Squabble variants or remove |

---

## Phase 4: Localization (26 languages)

### Key strings to change in `en.lproj/Localizable.strings`:

| Key | Current | New |
|-----|---------|-----|
| `import_description` | "select BookPlayer from the list" | "select Squabble Inn from the list" |
| `support_bookplayer_title` | "Support BookPlayer" | "Support Squabble Inn" |
| `icons_bookplayer_credit_description` | "By your friends at BookPlayer" | "Powered by BookPlayer" |
| `bookplayer_opensource_description` | "BookPlayer is free and Open Source..." | Move to Credits |
| `plus_*` and `pro_*` strings | Various | Remove (Pro UI hidden) |

### Languages to update:
ar, ca, cs, da, de, el, en, es, fi, fr, hu, it, ja, nb, nl, pl, pt-BR, pt-PT, ro, ru, sk-SK, sv, tr, uk, zh-Hans

---

## Phase 5: Test Unification

### Conceptual shift:
- Remove "BookPlayer vs Squabble" distinction in documentation
- All screenshots are "Squabble Inn" screenshots
- All tests are "Squabble Inn" tests

### Files to update:
- `ScreenshotTests.swift` - Update comments/documentation
- `Screenshots/manifest.json` - All screens are Squabble Inn screens
- `SQUABBLE-HANDOFF.md` - Update architecture description

---

## Phase 6: Architecture Documentation

### Updated mental model:
```
OLD: BookPlayer app + Squabble/ folder with social features
NEW: Squabble Inn app with BookPlayer engine underneath
```

### Keep current structure:
- `/BookPlayer/Squabble/` - Social features (guilds, comments, ghosts)
- Extension pattern still valid for engine integration points
- `// SQUABBLE:` markers remain for upstream merge awareness

### What changes:
- Everything outside Squabble folder is ALSO Squabble Inn now
- Branding changes go in main BookPlayer folders, not Squabble folder
- Tests don't distinguish BookPlayer vs Squabble features

---

## Implementation Priority

1. **`.gitattributes`** - Protect future upstream merges
2. **Credits.html** - Add "Powered by BookPlayer" attribution
3. **URL Scheme** - Change to `squabbleinn`
4. **Empty state images** - Create Squabble-themed art
5. **Localizable.strings** - Rebrand user-facing strings (en first, then others)
6. **Alternate icons** - Create Squabble variants or remove BookPlayer ones
7. **Test documentation** - Update to reflect unified identity

---

## Critical Files Reference

| Purpose | Path |
|---------|------|
| Upstream merge control | `.gitattributes` (create) |
| Attribution | `BookPlayer/Credits.html` |
| URL scheme | `BookPlayer/Info.plist` |
| Empty states | `BookPlayer/Assets.xcassets/emptyLibrary.imageset/` |
| Core strings | `BookPlayer/en.lproj/Localizable.strings` |
| Engine hook (protect) | `BookPlayer/Player/PlayerManager.swift:1184-1186` |

---

## Success Criteria

- [ ] App feels wholly "Squabble Inn" - no obvious BookPlayer branding
- [ ] "Powered by BookPlayer" visible in Credits/About
- [ ] Upstream engine merges work cleanly with `.gitattributes`
- [ ] All tests pass and treat app as unified Squabble Inn
- [ ] Empty states, icons, and splash show Squabble branding

---

## See Also

- [ROADMAP.md](./ROADMAP.md) - Feature roadmap
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Technical architecture
- [VISION.md](./VISION.md) - Product vision
