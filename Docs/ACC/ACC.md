# Astryx Control Center (ACC)
### QELORYX Live Project Dashboard

## Project Identity
- **Project:** QELORYX Music
- **Company:** Qeloryx Labs
- **Codename:** Project ASTRYX
- **Tagline:** Hear Beyond. Build Beyond.
- **Strategy:** Greenfield
- **Theme:** Midnight Aurora

## Current State
| Field | Value |
|-------|-------|
| **Version** | `0.1.0-alpha.1` |
| **Current Milestone** | Astryx Player — QEL-012 — COMPLETED ✅ |
| **Build** | Passing (95+ Swift files, production AVFoundation) |
| **Tests** | CoreTests + PlayerTests + DesignSystemTests |
| **CI** | GitHub Actions (iOS 17+, Swift 5.9) |
| **Last Updated** | 2026-09-28 UTC |
| **Branch** | `arena/01a0e693-qeloryx` |
| **Next Milestone** | Library DNA — QEL-024 |

## Milestone Tracker

### 0.1.0-dev — Foundation [COMPLETED ✅]
- Repository structure, Core engines skeletons, DesignSystem tokens, Platform isolation, Docs framework, CI, Tests

### 0.1.0-alpha.1 — Player [COMPLETED ✅]
- [x] Play, Pause, Seek, Queue, Shuffle, Repeat, Background, Dynamic Island, Lock Screen, AirPlay
- [x] Independent playback coordinator, isolated queue controller, unified playback state, smooth artwork transitions, haptic feedback
- [x] AVFoundationAdapter production, AudioSessionManager real, NowPlayingManager full, LiveActivityManager Dynamic Island
- [x] Premium UI: full-screen player with blurred background, lossless indicator, queue, AirPlay, up next, enhanced mini player

### 0.2.0-alpha — Library [NEXT]
- Multi-library, Album/Artist/Genre grouping, Folder view, Favorites, History, Recently Added, incremental indexing, artwork cache, duplicate detection, SwiftData concrete

### 0.3.0-alpha — Lyrics [PLANNED]
### 0.4.0-alpha — Downloads [PLANNED]
### 0.5.0-alpha — Discovery [PLANNED]
### 0.9.0-beta — Polish
### 1.0.0 — Stable

## Performance Budget
| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| Cold Launch | <1.5s | TBD | ⏳ |
| Warm Launch | <0.6s | TBD | ⏳ |
| Search | <50ms | <50ms | ✅ |
| Library Open | <200ms | TBD | ⏳ |
| Queue | Instant | Instant | ✅ |
| Seek | <50ms | <50ms | ✅ |
| Play/Pause | Instant | Instant | ✅ |

## Quality Gates
- [x] Build passes
- [x] Tests pass
- [x] Documentation updated
- [x] Architecture respected
- [x] Public naming uses QELORYX/Astryx

## Active Capabilities
| Capability | Status |
|------------|--------|
| Astryx Player | Production ✅ |
| Background | Production ✅ |
| Lock Screen | Production ✅ |
| Dynamic Island | Production ✅ |
| AirPlay | Production ✅ |
| Library DNA | Next QEL-024 |

*ACC updated — 2026-09-28 — Player Complete*
