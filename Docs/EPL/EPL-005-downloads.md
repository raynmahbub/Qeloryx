# EPL-005: Downloads Progress Ledger — QEL-041

## Milestone
0.4.0-alpha — Downloads — QEL-041

## Goal
Production Downloads per Genesis Bible: DownloadEngine, offline cache, state machine Queued→Downloading→Paused→Retry→Completed→Failed

## Tasks

### Core
- [x] Enhance AstryxDownloadState with canCancel, canTransition(to:), displayName, icon, isTerminal, isActive, canPause/Resume/Retry
- [x] Enhance DownloadError with noSpace, invalidURL, httpError, resumeDataCorrupted, isRetryable
- [x] Enhance AstryxDownloadTask with title, artist, artworkURL, formattedProgress, formattedBytes, isCompleted, canBeRetried
- [x] Create DownloadPriority with displayName, Comparable
- [x] Create DownloadStats with total/queued/downloading/paused/completed/failed/totalBytes/downloadedBytes + formatted
- [x] Create DownloadSessionProtocol + DownloadSessionDelegate in Core for layer isolation
- [x] Rewrite DownloadEngine to production with tasks dict, queue priority ordered, activeDownloads Set, maxConcurrent 3, downloadSession optional protocol injection, injectSession(_:), enqueue with disk space check, enqueue(track:sourceURL:priority:) with destination in Documents/Qeloryx/Downloads, pause with resumeData via continuation, resume with validation, cancel, retry with exponential backoff pow(2, retryCount) max 30s, remove only terminal + delete file, allTasks, task(id:), stats, pauseAll/resumeAll/cancelAll/clearCompleted, insertIntoQueue priority ordering, processQueue with transition validation, simulateDownload fallback for tests/Linux, publishState via EventBus, DownloadSessionDelegate callbacks progress/complete/fail with file moving and retry logic

### Platform
- [x] Create AstryxDownloadSessionManager implementing DownloadSessionProtocol, background config com.qeloryx.downloads.{UUID}, isDiscretionary false, sessionSendsLaunchEvents true, allowsCellularAccess true, waitsForConnectivity true offline optimization, timeout 30/300, activeTasks + taskIDMap + NSLock, startDownload with/without resumeData, pauseDownload cancel with resumeData completion, cancelDownload, checkDiskSpace via volumeAvailableCapacity 100MB buffer, URLSessionDownloadDelegate callbacks

### Features
- [x] Create DownloadsFilter with all/downloading/queued/paused/completed/failed icons matches(state:)
- [x] Create DownloadsViewModel with tasks, filteredTasks, stats, selectedFilter, isLoading, searchText, errorMessage, eventBus subscriptions downloadStateChanged/progress/completed, search debounce 300ms, loadTasks, applyFilter with state + search + sort by state order + createdAt desc, updateProgress, pause/resume/cancel/retry/remove/pauseAll/resumeAll/cancelAll/clearCompleted/downloadTrack
- [x] Create DownloadsView production with statsHeader horizontal StatCards, filterSelector capsules, content loading/empty/list, DownloadRow with icon circle stateColor, title/artist, state displayName + progress, ProgressView, formattedBytes + retry + error, actions bordered Pause/Resume/Retry/Cancel/Remove, priority capsule, menuButton Resume All/Pause All/Cancel All/Clear Completed, searchable refreshable task

### Tests
- [x] Downloads_Tests with 10 tests: state machine transitions, priority ordering, enqueue/pause/resume/cancel/retry, disk space check, retry backoff, stats, concurrent limit, formatted progress/bytes

### Docs
- [x] ADR-009
- [x] EPL-005 (this)
- [x] IL-005
- [x] SHM-005
- [x] ACC update to 0.4.0-alpha

## Performance Budget
- Search <50ms ✅
- Library Open <200ms ✅
- Queue Instant ✅
- Seek <50ms ✅
- Play/Pause Instant ✅
- Lyrics sync <50ms ✅
- Karaoke <100ms ✅
- Download enqueue <50ms ✅ (in-memory)
- Download progress <100ms ✅ (via delegate)

## Capabilities Delivered
- State machine Queued→Downloading→Paused→Retry→Completed→Failed + Cancelled ✅
- Resume with resumeData ✅
- Retry with exponential backoff + maxRetries ✅
- Priority Queue (low/normal/high/immediate) ✅
- Offline optimization (disk space check 100MB buffer, waitsForConnectivity) ✅
- Background session (resume after app kill) ✅
- Concurrent limit 3 ✅
- File moving from temp to destination ✅
- Stats + filtering + search ✅
- UI with progress + actions ✅

## Next
0.5.0-alpha — Discovery — QEL-051

*Updated: 2026-09-28 — Downloads Complete*
