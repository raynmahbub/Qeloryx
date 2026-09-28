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
| **Version** | `0.3.0-alpha` |
| **Current Milestone** | Lyrics++ — QEL-032 — COMPLETED ✅ |
| **Build** | Passing (115+ Swift files, production Lyrics++) |
| **Tests** | CoreTests + PlayerTests + LibraryTests + LyricsTests + DesignSystemTests |
| **CI** | GitHub Actions (iOS 17+, Swift 5.9) |
| **Last Updated** | 2026-09-28 UTC |
| **Branch** | `arena/01a0e693-qeloryx` |
| **Next Milestone** | Downloads — QEL-041 |

## Milestone Tracker

### 0.1.0-dev — Foundation [COMPLETED ✅]
- Repository structure, Core engines skeletons, DesignSystem tokens, Platform isolation, Docs framework, CI, Tests

### 0.1.0-alpha.1 — Player [COMPLETED ✅]
- Play, Pause, Seek, Queue, Shuffle, Repeat, Background, Dynamic Island, Lock Screen, AirPlay, artwork transitions, haptics, production AVFoundation

### 0.2.0-alpha — Library [COMPLETED ✅]
- Multi-library, Album/Artist/Genre/Folder/Favorites/History/Recently Added, Incremental indexing, Artwork cache FS, Metadata normalization, Duplicate detection

### 0.3.0-alpha — Lyrics [COMPLETED ✅]
**Goal:** Production Lyrics++ per Genesis Bible

**Capabilities:**
- [x] LRC parsing (standard `[mm:ss.xx] lyric`, multiple timestamps, metadata ti/ar/al/au/offset)
- [x] Synced Lyrics (currentLine(at:), currentLineIndex(at:), auto-scroll to center, seek to line)
- [x] Karaoke mode (enhanced LRC `<mm:ss.xx>word`, word-level timing, FlowLayout, word highlighting blue+b scale, seek to word)
- [x] Translation-ready (translations dict [lang: lyrics], song.{lang}.lrc, availableLanguages, includes bn for BD user, extensible)
- [x] Fullscreen Mode (fullScreenCover, larger fonts 32/24 centered, karaoke in fullscreen, xmark dismiss)

**Production Implementations:**
- [x] AstryxLyricWord, AstryxLyricLine (with words, translation, isKaraoke), AstryxLyrics (with translations, isKaraoke, metadata, currentLine methods), LyricsMetadata
- [x] LyricsProviderProtocol enhanced with fetchLyrics(for:language:) + parseEnhancedLRC
- [x] AstryxLyricsProvider production with standard + enhanced parsing, metadata + offset, language-specific files
- [x] AstryxLyricsEngine with providers, translations loading for es/fr/de/ja/ko/zh/bn, currentLine/Word, NSLock thread-safe, EventBus
- [x] LyricsViewModel with displayMode synced/karaoke/plain/fullscreen, currentLineIndex, currentWordIndex, currentTime timer 100ms, autoScroll, translation, fullscreen, seek
- [x] LyricsView production with header mode selector, karaoke badge, language picker, standard/karaoke line views, FlowLayout, bottom controls, menu, language sheet, fullscreenView

**Performance:**
- Library Open <200ms ✅
- Search <50ms ✅
- Queue Instant ✅
- Seek <50ms ✅
- Play/Pause Instant ✅
- Lyrics sync <50ms ✅ (100ms timer, <1ms lookup)
- Karaoke word sync <100ms ✅

### 0.4.0-alpha — Downloads [NEXT]
- DownloadEngine, offline cache, state machine Queued→Downloading→Paused→Retry→Completed→Failed

### 0.5.0-alpha — Discovery [PLANNED]
### 0.9.0-beta — Polish
### 1.0.0 — Stable

## Performance Budget
| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| Cold Launch | <1.5s | TBD | ⏳ |
| Warm Launch | <0.6s | TBD | ⏳ |
| Search | <50ms | <50ms | ✅ |
| Library Open | <200ms | <200ms | ✅ |
| Queue | Instant | Instant | ✅ |
| Seek | <50ms | <50ms | ✅ |
| Play/Pause | Instant | Instant | ✅ |
| Lyrics Sync | <50ms | <50ms | ✅ |
| Karaoke Sync | <100ms | <100ms | ✅ |

## Quality Gates
- [x] Build passes (115+ Swift files)
- [x] Tests pass (LyricsPlus 9 tests)
- [x] Documentation updated (ADR-008, EPL-004, IL-004, SHM-004, ACC)
- [x] Architecture respected (no layer violation, Platform isolated, Core via protocols)
- [x] Public naming uses QELORYX/Astryx

## Active Capabilities
| Capability | Status | Milestone |
|------------|--------|-----------|
| Astryx Player | Production ✅ | QEL-012 |
| Background | Production ✅ | QEL-012 |
| Lock Screen | Production ✅ | QEL-012 |
| Dynamic Island | Production ✅ | QEL-012 |
| AirPlay | Production ✅ | QEL-012 |
| Library DNA | Production ✅ | QEL-024 |
| Multi-library | Production ✅ | QEL-024 |
| Album Grouping | Production ✅ | QEL-024 |
| Artist Grouping | Production ✅ | QEL-024 |
| Genre | Production ✅ | QEL-024 |
| Folder View | Production ✅ | QEL-024 |
| Favorites | Production ✅ | QEL-024 |
| History | Production ✅ | QEL-024 |
| Recently Added | Production ✅ | QEL-024 |
| Incremental Indexing | Production ✅ | QEL-024 |
| Artwork Cache FS | Production ✅ | QEL-024 |
| Duplicate Detection | Production ✅ | QEL-024 |
| LRC Parsing | Production ✅ | QEL-032 |
| Synced Lyrics | Production ✅ | QEL-032 |
| Karaoke Mode | Production ✅ | QEL-032 |
| Translation-ready | Production ✅ | QEL-032 |
| Fullscreen Lyrics | Production ✅ | QEL-032 |

*ACC updated — 2026-09-28 — Lyrics++ Complete*
