# Squabble Inn: ASCII Screen Mockups

> Visual reference for existing screens and ideation canvas for new ones.
> Last updated: December 14, 2025

---

## Table of Contents
- [Library Tab](#library-tab)
- [Player](#player)
- [Guild Tab](#guild-tab)
- [Settings](#settings)
- [Future Screens](#future-screens-ideas)

---

# Library Tab

## Library - Empty State
```
┌─────────────────────────────────────┐
│  ◀ Library                      ⋯   │
├─────────────────────────────────────┤
│                                     │
│                                     │
│           ┌─────────┐               │
│           │  📚     │               │
│           │         │               │
│           └─────────┘               │
│                                     │
│        Your library is empty        │
│                                     │
│     Import audiobooks to get        │
│           started                   │
│                                     │
│        ┌───────────────┐            │
│        │  + Add Files  │            │
│        └───────────────┘            │
│                                     │
│                                     │
├─────────────────────────────────────┤
│  📚        👤        ⚙️       🔍    │
│ Library   Guild   Settings  Search  │
└─────────────────────────────────────┘
```

## Library - With Books
```
┌─────────────────────────────────────┐
│  ◀ Library                      ⋯   │
├─────────────────────────────────────┤
│  🔍 Search Library                  │
├─────────────────────────────────────┤
│                                     │
│  ┌──────┐  Dungeon Crawler Carl     │
│  │ 🎧   │  Matt Dinniman            │
│  │ DCC  │  ▓▓▓▓▓▓▓▓░░ 78%          │
│  └──────┘                           │
│  ─────────────────────────────────  │
│  ┌──────┐  He Who Fights Monsters   │
│  │ 🎧   │  Shirtaloon               │
│  │ HWFM │  ▓▓▓▓░░░░░░ 42%          │
│  └──────┘                           │
│  ─────────────────────────────────  │
│  ┌──────┐  Defiance of the Fall     │
│  │ 🎧   │  TheFirstDefier           │
│  │ DotF │  ▓▓░░░░░░░░ 23%          │
│  └──────┘                           │
│                                     │
├─────────────────────────────────────┤
│ ▶ Now Playing: DCC Book 6     2:34  │
├─────────────────────────────────────┤
│  📚        👤        ⚙️       🔍    │
│ Library   Guild   Settings  Search  │
└─────────────────────────────────────┘
```

## Mini Player
```
├─────────────────────────────────────┤
│ ┌────┐                              │
│ │ 🎧 │  Dungeon Crawler Carl        │
│ │DCC │  Book 6: The Haunted...      │
│ └────┘  ▶  ▓▓▓▓▓▓▓░░░  2:34:17     │
├─────────────────────────────────────┤
```

---

# Player

## Full Player
```
┌─────────────────────────────────────┐
│                              ▼ down │
│                                     │
│       ┌───────────────────┐         │
│       │                   │         │
│       │    ┌─────────┐    │         │
│       │    │  🐱     │    │         │
│       │    │ DONUT   │    │         │
│       │    └─────────┘    │         │
│       │                   │         │
│       │  Dungeon Crawler  │         │
│       │      Carl         │         │
│       └───────────────────┘         │
│                                     │
│   Chapter 47: The Pineapple...      │
│                                     │
│   2:34:17 ▓▓▓▓▓▓▓░░░░░░░ 8:52:31   │
│           👻  👻    👻               │
│           Al  Sam   Jess            │
│                                     │
│      ⏪30    ▶/⏸    30⏩             │
│                                     │
│    🌙     📑     📚     🔖     ⋯    │
│   Sleep  Chap  Speed  Mark  More    │
│                                     │
└─────────────────────────────────────┘
```

## Player with Ghost Markers Detail
```
   2:34:17 ━━━━━━━━━━━●━━━━━━━━━━ 8:52:31
                     ↑ You
           👻       👻         👻
           ┃        ┃          ┃
           Al       Sam       Jess
         1:45:22  2:12:08   3:45:19
```

## Player with Comment Notification
```
┌─────────────────────────────────────┐
│                                     │
│   2:34:17 ━━━━━━━●━━━━━━━━━ 8:52:31 │
│                                     │
│   ┌─────────────────────────────┐   │
│   │ 💬 Sam @ 2:32:45            │   │
│   │ "WHAT. NO. WHAT."           │   │
│   └─────────────────────────────┘   │
│                                     │
│   ┌─────────────────────────────┐   │
│   │ 💬 Al @ 2:33:01             │   │
│   │ "I SCREAMED"                │   │
│   └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

## Chapters View
```
┌─────────────────────────────────────┐
│  Chapters                     Done  │
├─────────────────────────────────────┤
│                                     │
│  ○  Chapter 45: The Setup    18:32  │
│  ─────────────────────────────────  │
│  ○  Chapter 46: The Trap     24:17  │
│  ─────────────────────────────────  │
│  ●  Chapter 47: The Pine...  31:45  │  ← Current
│  ─────────────────────────────────  │
│  ○  Chapter 48: Aftermath    22:08  │
│  ─────────────────────────────────  │
│  ○  Chapter 49: New Plans    19:54  │
│                                     │
└─────────────────────────────────────┘
```

## Bookmarks View
```
┌─────────────────────────────────────┐
│  Bookmarks                    Done  │
├─────────────────────────────────────┤
│                                     │
│  YOUR BOOKMARKS                     │
│  ─────────────────────────────────  │
│  🔖 2:34:17  "Best Donut moment"   │
│  ─────────────────────────────────  │
│  🔖 1:45:22  "Foreshadowing?"      │
│                                     │
│  ▼ AUTOMATIC (tap to expand)       │
│  ─────────────────────────────────  │
│  📍 2:30:00  Session ended         │
│  📍 1:15:00  Session ended         │
│                                     │
└─────────────────────────────────────┘
```

---

# Guild Tab

## Not Signed In
```
┌─────────────────────────────────────┐
│  Guild                              │
├─────────────────────────────────────┤
│                                     │
│                                     │
│           ┌─────────┐               │
│           │  👥     │               │
│           │         │               │
│           └─────────┘               │
│                                     │
│       Sign in to Squabble           │
│                                     │
│    Form a guild with friends        │
│     and read books together         │
│                                     │
│      ┌─────────────────┐            │
│      │ Sign In / Sign Up│            │
│      └─────────────────┘            │
│                                     │
│                                     │
├─────────────────────────────────────┤
│  📚        👤        ⚙️       🔍    │
│ Library   Guild   Settings  Search  │
└─────────────────────────────────────┘
```

## No Guild
```
┌─────────────────────────────────────┐
│  Guild                              │
├─────────────────────────────────────┤
│                                     │
│           ┌─────────┐               │
│           │  🏰     │               │
│           │         │               │
│           └─────────┘               │
│                                     │
│          Join a Guild               │
│                                     │
│   Form your party and adventure     │
│          together                   │
│                                     │
│      ┌─────────────────┐            │
│      │  Create Guild   │            │
│      └─────────────────┘            │
│                                     │
│      ┌─────────────────┐            │
│      │  Join with Code │            │
│      └─────────────────┘            │
│                                     │
│  ─────────────────────────────────  │
│  Signed in as: don@example.com      │
│                        Sign Out     │
├─────────────────────────────────────┤
│  📚        👤        ⚙️       🔍    │
└─────────────────────────────────────┘
```

## Guild View - Has Guild
```
┌─────────────────────────────────────┐
│  Guild                              │
├─────────────────────────────────────┤
│                                     │
│   ┌─────────────────────────────┐   │
│   │  🏰  The Goobers            │   │
│   │      5/5 members            │   │
│   └─────────────────────────────┘   │
│                                     │
│   INVITE CODE           View >      │
│   ┌─────────────────────────────┐   │
│   │     Z Q 5 L X 9             │   │
│   └─────────────────────────────┘   │
│                                     │
│   MEMBERS                           │
│   ─────────────────────────────     │
│   👑 Don          Reading: DCC 6    │
│   👤 Sam          Reading: DCC 6    │
│   👤 Alex         Reading: HWFM 3   │
│   👤 Jess         Reading: DCC 5    │
│   👤 Morgan       Idle              │
│                                     │
│   GUILD LIBRARY        Coming Soon  │
│                                     │
│                      Leave Guild    │
├─────────────────────────────────────┤
│  📚        👤        ⚙️       🔍    │
└─────────────────────────────────────┘
```

## Create Guild Sheet
```
┌─────────────────────────────────────┐
│  Cancel     Create Guild      Done  │
├─────────────────────────────────────┤
│                                     │
│   Name your guild                   │
│   ┌─────────────────────────────┐   │
│   │ The Goobers                 │   │
│   └─────────────────────────────┘   │
│                                     │
│   Your guild can have up to 5       │
│   members (including you).          │
│                                     │
│   ┌─────────────────────────────┐   │
│   │         Create              │   │
│   └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

## Join Guild Sheet
```
┌─────────────────────────────────────┐
│  Cancel      Join Guild       Done  │
├─────────────────────────────────────┤
│                                     │
│   Enter invite code                 │
│   ┌─────────────────────────────┐   │
│   │  Z  Q  5  L  X  9           │   │
│   └─────────────────────────────┘   │
│                                     │
│   Ask your guild leader for         │
│   the 6-character code.             │
│                                     │
│   ┌─────────────────────────────┐   │
│   │          Join               │   │
│   └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

## Invite Code Sheet
```
┌─────────────────────────────────────┐
│                              Done   │
├─────────────────────────────────────┤
│                                     │
│         Share this code             │
│      with your guildmates           │
│                                     │
│   ┌─────────────────────────────┐   │
│   │                             │   │
│   │      Z Q 5 L X 9            │   │
│   │                             │   │
│   └─────────────────────────────┘   │
│                                     │
│   ┌────────────┐ ┌────────────┐     │
│   │ Copy Code  │ │   Share    │     │
│   └────────────┘ └────────────┘     │
│                                     │
│   ┌─────────────────────────────┐   │
│   │    Generate New Code        │   │  ← Owner only
│   └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

---

# Settings

## Settings Main
```
┌─────────────────────────────────────┐
│  Settings                           │
├─────────────────────────────────────┤
│                                     │
│  APPEARANCE                         │
│  ─────────────────────────────────  │
│  🎨  Themes                      >  │
│  📱  App Icons                   >  │
│                                     │
│  PLAYBACK                           │
│  ─────────────────────────────────  │
│  🎛️  Controls                    >  │
│  ▶️  Autoplay                    >  │
│  🔒  Auto-Lock                   >  │
│                                     │
│  STORAGE                            │
│  ─────────────────────────────────  │
│  💾  Manage Storage              >  │
│                                     │
│  INTEGRATIONS                       │
│  ─────────────────────────────────  │
│  🟣  Jellyfin                    >  │
│  📚  AudiobookShelf              >  │
│  📖  Hardcover                   >  │
│                                     │
│  SUPPORT                            │
│  ─────────────────────────────────  │
│  💬  Send Feedback               >  │
│  ☕  Tip Jar                     >  │
│                                     │
├─────────────────────────────────────┤
│  📚        👤        ⚙️       🔍    │
└─────────────────────────────────────┘
```

---

# Future Screens (Ideas)

## Bounty Board (Concept)
```
┌─────────────────────────────────────┐
│  ◀ Guild          Bounty Board      │
├─────────────────────────────────────┤
│                                     │
│  ╔═══════════════════════════════╗  │
│  ║  🏆 GUILD BOUNTIES            ║  │
│  ╠═══════════════════════════════╣  │
│  ║                               ║  │
│  ║  ⚔️ Raid Boss: Cradle Series  ║  │
│  ║     All members finish        ║  │
│  ║     Reward: Cradle Theme      ║  │
│  ║     Progress: 2/5 complete    ║  │
│  ║                               ║  │
│  ║  📖 Finish DCC Book 6         ║  │
│  ║     Progress: 3/5 complete    ║  │
│  ║     Reward: Safe Room trinket ║  │
│  ║                               ║  │
│  ╚═══════════════════════════════╝  │
│                                     │
│  ╔═══════════════════════════════╗  │
│  ║  📜 PERSONAL BOUNTIES         ║  │
│  ╠═══════════════════════════════╣  │
│  ║  ○ Finish 5 books this month  ║  │
│  ║  ○ Listen for 20 hours        ║  │
│  ║  ● Re-read a favorite         ║  │
│  ╚═══════════════════════════════╝  │
│                                     │
└─────────────────────────────────────┘
```

## Race Leaderboard (Concept)
```
┌─────────────────────────────────────┐
│  ◀ Guild              Race: DCC 6   │
├─────────────────────────────────────┤
│                                     │
│   🏁 RACE TO FINISH                 │
│   Ends: Dec 31, 2025                │
│                                     │
│   ┌─────────────────────────────┐   │
│   │  🥇 Sam        ▓▓▓▓▓▓▓▓░ 89% │   │
│   │  🥈 Don        ▓▓▓▓▓▓▓░░ 78% │   │  ← You
│   │  🥉 Alex       ▓▓▓▓▓░░░░ 56% │   │
│   │  4. Jess       ▓▓▓▓░░░░░ 45% │   │
│   │  5. Morgan     ▓▓░░░░░░░ 23% │   │
│   └─────────────────────────────┘   │
│                                     │
│   ⏱️ Time remaining: 17 days        │
│                                     │
│   Last update: Sam • 2 min ago      │
│                                     │
└─────────────────────────────────────┘
```

## Achievement Popup (Concept)
```
┌─────────────────────────────────────┐
│                                     │
│   ╔═══════════════════════════════╗ │
│   ║                               ║ │
│   ║      🏆 ACHIEVEMENT           ║ │
│   ║                               ║ │
│   ║   "Carl Would Be Proud"       ║ │
│   ║                               ║ │
│   ║   You finished Dungeon        ║ │
│   ║   Crawler Carl. The dungeon   ║ │
│   ║   acknowledges your           ║ │
│   ║   commitment. Barely.         ║ │
│   ║                               ║ │
│   ║   🎁 Unlocked: DCC Theme      ║ │
│   ║                               ║ │
│   ╚═══════════════════════════════╝ │
│                                     │
│         [ Dismiss ]                 │
│                                     │
└─────────────────────────────────────┘
```

## Comment Input (Concept)
```
┌─────────────────────────────────────┐
│                                     │
│   💬 Leave a comment at 2:34:17     │
│                                     │
│   ┌─────────────────────────────┐   │
│   │                             │   │
│   │ WHAT. NO. WHAT.             │   │
│   │                             │   │
│   └─────────────────────────────┘   │
│                                     │
│   Your guildmates will see this     │
│   after they reach this moment.     │
│                                     │
│   ┌────────────┐ ┌────────────┐     │
│   │   Cancel   │ │    Post    │     │
│   └────────────┘ └────────────┘     │
│                                     │
└─────────────────────────────────────┘
```

## Themed Library (Concept - DCC Theme)
```
┌─────────────────────────────────────┐
│  ◀ Library               🍍 DCC     │
├─────────────────────────────────────┤
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│ ░  🔍 Search the Safe Room       ░ │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
│ ▓                                 ▓ │
│ ▓  ┌──────┐  Dungeon Crawler Carl ▓ │
│ ▓  │ 🐱   │  Matt Dinniman        ▓ │
│ ▓  │Donut │  ▓▓▓▓▓▓▓▓░░ 78%      ▓ │
│ ▓  └──────┘                       ▓ │
│ ▓  ═══════════════════════════    ▓ │
│ ▓  ┌──────┐  He Who Fights...     ▓ │
│ ▓  │ 🎧   │  Shirtaloon           ▓ │
│ ▓  │ HWFM │  ▓▓▓▓░░░░░░ 42%      ▓ │
│ ▓  └──────┘                       ▓ │
│ ▓                                 ▓ │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
├─────────────────────────────────────┤
│ 🍍 Now Playing: DCC Book 6   2:34  │
├─────────────────────────────────────┤
│  📚        👤        ⚙️       🔍    │
└─────────────────────────────────────┘
```

## Class Identity Card (Concept)
```
┌─────────────────────────────────────┐
│                                     │
│   ╔═══════════════════════════════╗ │
│   ║     YOUR CLASS IDENTITY       ║ │
│   ╠═══════════════════════════════╣ │
│   ║                               ║ │
│   ║         ⚔️                    ║ │
│   ║                               ║ │
│   ║      DELVER                   ║ │
│   ║                               ║ │
│   ║   "One who descends into      ║ │
│   ║    the depths, seeking        ║ │
│   ║    treasure and glory"        ║ │
│   ║                               ║ │
│   ║   Based on your reads:        ║ │
│   ║   • Dungeon Crawler Carl      ║ │
│   ║   • Divine Dungeon            ║ │
│   ║   • The Dungeon Slayer        ║ │
│   ║   • Delve                     ║ │
│   ║   • The Primal Hunter         ║ │
│   ║                               ║ │
│   ╚═══════════════════════════════╝ │
│                                     │
└─────────────────────────────────────┘
```

---

## Notes on ASCII Mockups

**Using these for ideation:**
```
Copy a template, modify it, paste into a doc or issue.
Quick way to communicate "here's roughly what I'm thinking"
without firing up Figma.
```

**Symbols commonly used:**
```
Borders:  ┌ ┐ └ ┘ │ ─ ├ ┤ ┬ ┴ ┼
Double:   ╔ ╗ ╚ ╝ ║ ═ ╠ ╣ ╦ ╩ ╬
Progress: ▓ ░ ● ○ ━
Icons:    📚 🎧 👤 ⚙️ 🔍 👑 🏰 🎨 💬 🏆 ⚔️ 🍍 🐱
Arrows:   ◀ ▶ ▲ ▼ > <
```

---

*Add new mockups here as features are designed.*
