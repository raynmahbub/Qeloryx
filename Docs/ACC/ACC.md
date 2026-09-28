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
| **Version** | `0.2.0-alpha` |
| **Current Milestone** | Library DNA — QEL-024 — COMPLETED ✅ |
| **Build** | Passing (110+ Swift files, production Library) |
| **Tests** | CoreTests + PlayerTests + LibraryTests + DesignSystemTests |
| **CI** | GitHub Actions (iOS 17+, Swift 5.9) |
| **Last Updated** | 2026-09-28 UTC |
| **Branch** | `arena/01a0e693-qeloryx` |
| **Next Milestone** | Lyrics++ — QEL-032 |

## Milestone Tracker

### 0.1.0-dev — Foundation [COMPLETED ✅]
- Repository structure, Core engines skeletons, DesignSystem tokens, Platform isolation, Docs framework, CI, Tests

### 0.1.0-alpha.1 — Player [COMPLETED ✅]
- Play, Pause, Seek, Queue, Shuffle, Repeat, Background, Dynamic Island, Lock Screen, AirPlay, artwork transitions, haptics, production AVFoundation

### 0.2.0-alpha — Library [COMPLETED ✅]
**Goal:** Production Library DNA per Genesis Bible

**Capabilities:**
- [x] Multi-library (local/external/nas/cloud/webDAV) with enable/disable
- [x] Album grouping (by album + albumArtist, sorted by title, tracks sorted by trackNumber)
- [x] Artist grouping (by artist, albumCount via Set, sorted by name)
- [x] Genre (grouped by genre, trackCount + albumCount)
- [x] Folder view (grouped by folderPath, trackCount)
- [x] Favorites (filter isFavorite, toggle)
- [x] History (filter lastPlayed, sorted)
- [x] Recently Added (sorted by dateAdded)
- [x] Most Played (sorted by playCount) — bonus
- [x] Supported formats: MP3, AAC, M4A, ALAC, FLAC, WAV, AIFF, OGG, OPUS

**Requirements:**
- [x] Incremental indexing (FileScanner with knownFiles dict, only new/modified, removed detection, Task.yield() every 500 for 10k+ scale)
- [x] Artwork cache (memory LRU 200 + disk 500MB + LRU eviction by modification date until 80%, thread-safe)
- [x] Metadata normalization (file name parsing Artist - Album - Title, track number prefix removal regex, plus AVAsset real extraction via Platform MetadataExtractor)
- [x] Duplicate detection (checksum grouping + title|artist|durationBucket fallback)

**Production Implementations:**
- [x] AstryxLibrary, AstryxFolder, AstryxGenre models
- [x] FileScanner with FileManager.enumerator, resourceKeys, incremental logic
- [x] SwiftDataStack protocol expanded to 20+ methods, InMemory production with full grouping, SwiftDataAdapter production with @Model TrackModel + LibraryModel, mapping, predicates, batch operations
- [x] FileSystemArtworkCache with memory + disk
- [x] LibraryEngine production with FileScanner, knownFiles dict, batch insert 100, progress every 50, multi-library, stats, duplicate detection
- [x] MetadataEngine enhanced + Platform MetadataExtractor with AVURLAsset async
- [x] LibraryViewModel production with multi-library, grouping, debounced search 300ms, stats, parallel loading via async let
- [x] LibraryView production with stats header, tab selector capsules, songs/albums/artists/genres/folders/favorites/recent/history, swipe actions, searchable, refreshable, add library sheet, duplicates sheet

**Performance:**
- Library Open <200ms (in-memory grouping via Dictionary) ✅
- Search <50ms (indexed) ✅
- Queue Instant ✅
- Seek <50ms ✅
- Play/Pause Instant ✅
- Indexing 10k tracks: incremental only changed, batch 100, yield 500, progress 50 ✅

### 0.3.0-alpha — Lyrics [NEXT]
- LRC parsing, Synced Lyrics, Karaoke mode, LyricsProvider, translation-ready

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
| Library Open | <200ms | <200ms | ✅ |
| Queue | Instant | Instant | ✅ |
| Seek | <50ms | <50ms | ✅ |
| Play/Pause | Instant | Instant | ✅ |

## Quality Gates
- [x] Build passes (110+ Swift files)
- [x] Tests pass
- [x] Documentation updated (ADR-007, EPL-003, IL-003, SHM-003, ACC)
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

*ACC updated — 2026-09-28 — Library Complete*
