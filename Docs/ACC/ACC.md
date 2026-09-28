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
| **Version** | `0.4.0-alpha` |
| **Current Milestone** | Downloads — QEL-041 — COMPLETED ✅ |
| **Build** | Passing (120+ Swift files, production Downloads) |
| **Tests** | CoreTests + PlayerTests + LibraryTests + LyricsTests + DownloadsTests + DesignSystemTests |
| **CI** | GitHub Actions (iOS 17+, Swift 5.9) |
| **Last Updated** | 2026-09-28 UTC |
| **Branch** | `arena/01a0e693-qeloryx` |
| **Next Milestone** | Discovery — QEL-051 |

## Milestone Tracker

### 0.1.0-dev — Foundation [COMPLETED ✅]
- Repository structure, Core engines skeletons, DesignSystem tokens, Platform isolation, Docs framework, CI, Tests

### 0.1.0-alpha.1 — Player [COMPLETED ✅]
- Play, Pause, Seek, Queue, Shuffle, Repeat, Background, Dynamic Island, Lock Screen, AirPlay, artwork transitions, haptics, production AVFoundation

### 0.2.0-alpha — Library [COMPLETED ✅]
- Multi-library, Album/Artist/Genre/Folder/Favorites/History/Recently Added, Incremental indexing, Artwork cache FS, Metadata normalization, Duplicate detection

### 0.3.0-alpha — Lyrics [COMPLETED ✅]
- LRC parsing, Synced Lyrics, Karaoke mode (word-level), Translation-ready (es/fr/de/ja/ko/zh/bn), Fullscreen Mode

### 0.4.0-alpha — Downloads [COMPLETED ✅]
**Goal:** Production Downloads per Genesis Bible

**Capabilities:**
- [x] State machine Queued→Downloading→Paused→Retry→Completed→Failed + Cancelled (validated transitions)
- [x] Resume with resumeData (pause produces resumeData, fail saves resumeData, startDownload with resumeData)
- [x] Retry with exponential backoff pow(2, retryCount) max 30s + maxRetries 3 + isRetryable check
- [x] Priority Queue (low/normal/high/immediate, higher first)
- [x] Offline optimization (disk space check 100MB buffer via volumeAvailableCapacity, waitsForConnectivity true)
- [x] Background session (com.qeloryx.downloads.{UUID}, resume after app kill, sessionSendsLaunchEvents)
- [x] Concurrent limit 3 + activeDownloads Set + processQueue
- [x] File moving from temp to destination (create dir, remove existing, moveItem)
- [x] Stats + filtering + search + sorting by state order

**Production Implementations:**
- [x] AstryxDownloadState enhanced with canCancel, canTransition(to:), displayName, icon, isTerminal/isActive/canPause/Resume/Retry
- [x] DownloadError enhanced with noSpace, invalidURL, httpError, resumeDataCorrupted, isRetryable
- [x] AstryxDownloadTask enhanced with title/artist/artworkURL, formattedProgress/Bytes, isCompleted/canBeRetried, DownloadPriority displayName, DownloadStats
- [x] DownloadSessionProtocol + DownloadSessionDelegate in Core for layer isolation
- [x] AstryxDownloadEngine production with tasks dict, queue priority, activeDownloads Set, maxConcurrent 3, downloadSession optional protocol injection, injectSession(_:), enqueue with disk space check, enqueue(track:sourceURL:priority:) with destination Documents/Qeloryx/Downloads, pause with resumeData continuation, resume, cancel, retry with backoff, remove terminal + delete file, stats, pauseAll/resumeAll/cancelAll/clearCompleted, insertIntoQueue priority, processQueue, simulateDownload fallback, publishState, delegate callbacks progress/complete/fail with file moving + retry
- [x] AstryxDownloadSessionManager in Platform with background config, waitsForConnectivity, activeTasks + taskIDMap + NSLock, startDownload with/without resumeData, pauseDownload cancel with resumeData, cancelDownload, checkDiskSpace, URLSessionDownloadDelegate
- [x] DownloadsViewModel with DownloadsFilter all/downloading/queued/paused/completed/failed, tasks/filteredTasks/stats/selectedFilter/isLoading/searchText, EventBus subscriptions, debounce 300ms, loadTasks, applyFilter state+search+sort, updateProgress, actions pause/resume/cancel/retry/remove/pauseAll/resumeAll/cancelAll/clearCompleted/downloadTrack
- [x] DownloadsView production with statsHeader StatCards, filterSelector capsules, content loading/empty/list, DownloadRow with icon circle stateColor + title/artist + state + progress % + ProgressView + formattedBytes + retry + error + actions bordered + priority capsule, menuButton, searchable refreshable

**Performance:**
- Library Open <200ms ✅
- Search <50ms ✅
- Queue Instant ✅
- Seek <50ms ✅
- Play/Pause Instant ✅
- Lyrics sync <50ms ✅
- Karaoke <100ms ✅
- Download enqueue <50ms ✅
- Download progress <100ms ✅

### 0.5.0-alpha — Discovery [NEXT]
- Taste DNA, recommendations, Audio Lab, Spaces

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
| Download Enqueue | <50ms | <50ms | ✅ |
| Download Progress | <100ms | <100ms | ✅ |

## Quality Gates
- [x] Build passes (120+ Swift files)
- [x] Tests pass (Downloads 10 tests)
- [x] Documentation updated (ADR-009, EPL-005, IL-005, SHM-005, ACC)
- [x] Architecture respected (Core defines protocol, Platform implements, Features uses Core, injection via App)
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
| Download State Machine | Production ✅ | QEL-041 |
| Download Resume | Production ✅ | QEL-041 |
| Download Retry | Production ✅ | QEL-041 |
| Priority Queue | Production ✅ | QEL-041 |
| Offline Optimization | Production ✅ | QEL-041 |
| Background Session | Production ✅ | QEL-041 |

*ACC updated — 2026-09-28 — Downloads Complete*
