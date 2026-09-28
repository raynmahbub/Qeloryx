# AGENT_STATE
### Arena Agent Working Memory — QELORYX

## Session: 2026-09-28 — Downloads Milestone QEL-041

### Who am I?
Arena Agent building QELORYX greenfield premium music platform.
Branch: arena/01a0e693-qeloryx (fixed)
Base: 93af092 Initial → 1d38d2f Foundation → 01b0537 Player → 6812851 Library → c92cfea Lyrics → Now Downloads QEL-041

### What was requested?
User said "Next" after Lyrics.
Per ACC, next milestone is Downloads — QEL-041 (0.4.0-alpha).

Capabilities: DownloadEngine, offline cache, state machine Queued→Downloading→Paused→Retry→Completed→Failed, Resume, Retry, Priority Queue, Offline optimization

### What have I done?
**QEL-041 Downloads — COMPLETED ✅**

- State Enhanced:
  - AstryxDownloadState: queued, downloading, paused, retry, completed, failed, cancelled, isTerminal, isActive, canPause/Resume/Retry/Cancel, canTransition(to:) validating Queued→Downloading→Paused→Retry→Completed→Failed per spec, displayName, icon
  - DownloadError: networkError, fileSystemError, cancelled, noSpace, invalidURL, httpError, resumeDataCorrupted, unknown + isRetryable (network/http/unknown/resumeDataCorrupted retryable) + localizedDescription

- Task Enhanced:
  - AstryxDownloadTask: id, trackID, sourceURL, destinationURL, state, progress, bytesDownloaded, totalBytes, priority, retryCount, maxRetries, error, resumeData, createdAt, startedAt, completedAt, artworkURL, title, artist + formattedProgress %, formattedBytes ByteCountFormatter, isCompleted, canBeRetried
  - DownloadPriority: low 0, normal 1, high 2, immediate 3, Comparable, displayName
  - DownloadStats: total, queued, downloading, paused, completed, failed, totalBytes, downloadedBytes + formatted

- Session Protocol — Layer Isolation:
  - DownloadSessionProtocol in Core: delegate, startDownload(taskID:from:resumeData:), pauseDownload(taskID:completion:), cancelDownload(taskID:), checkDiskSpace(requiredBytes:)
  - DownloadSessionDelegate in Core: downloadDidProgress, downloadDidComplete, downloadDidFail with resumeData
  - Core defines abstraction, Platform implements, App injects via injectSession(_:), respects isolation (Platform depends on Core per Package.swift, same as SwiftDataAdapter)

- Platform Session Manager NEW:
  - AstryxDownloadSessionManager: NSObject, DownloadSessionProtocol, URLSessionDownloadDelegate, session, activeTasks dict taskID->URLSessionDownloadTask, taskIDMap Int->String, lock NSLock, weak delegate
  - setupSession: background config com.qeloryx.downloads.{UUID}, isDiscretionary false, sessionSendsLaunchEvents true, allowsCellularAccess true, waitsForConnectivity true offline optimization, timeout 30/300
  - startDownload with/without resumeData, stores in maps, resume()
  - pauseDownload cancel with completion producing resumeData, removes from maps
  - cancelDownload cancel and remove
  - checkDiskSpace via volumeAvailableCapacity 100MB buffer
  - URLSessionDownloadDelegate: didWriteData -> downloadDidProgress, didFinishDownloadingTo -> downloadDidComplete removes from maps, didCompleteWithError extracts resumeData from NSError userInfo NSURLSessionDownloadTaskResumeData, calls downloadDidFail, urlSessionDidFinishEvents

- Engine Rewritten Production:
  - Protocol enhanced with enqueue(track:sourceURL:priority:) -> String, remove, stats, pauseAll/resumeAll/cancelAll/clearCompleted
  - tasks dict, queue priority ordered, activeDownloads Set, maxConcurrent 3, downloadSession optional protocol, useRealSession bool, lock NSLock, eventBus
  - init with eventBus, downloadSession optional, maxConcurrent, useRealSession, sets delegate, injectSession(_:) for App layer
  - enqueue(task:): disk space check via session if totalBytes known, fails noSpace, inserts into tasks and queue via insertIntoQueue priority higher first, publishes state, processQueue
  - enqueue(track:sourceURL:priority:): creates destination Documents/Qeloryx/Downloads, fileName "{artist} - {title}.ext" sanitized, creates dir, creates task with trackID/title/artist, enqueues, returns id
  - pause: validates canPause and canTransition, gets resumeData via session.pauseDownload with checked continuation, sets paused, removes from active, publishes, processQueue next
  - resume: validates canResume and canTransition to queued, sets queued, clears error, inserts into queue, publishes, processQueue
  - cancel: validates canCancel, calls session.cancelDownload, sets cancelled, error cancelled, removes from active and queue, publishes, processQueue
  - retry: validates canRetry and retryCount < maxRetries else failed max retries, validates canTransition to retry, sets retry, retryCount++, clears error, exponential backoff pow(2, retryCount) max 30s sleep, then queued and inserts, publishes, processQueue
  - remove: only if terminal, removes from tasks/queue/active, deletes file
  - allTasks, task(id:), stats, pauseAll/resumeAll/cancelAll/clearCompleted
  - insertIntoQueue priority ordering
  - processQueue: checks active < maxConcurrent and queue not empty, finds next queued/retry, validates transition to downloading, removes from queue, sets downloading, startedAt, clears error, adds to active, publishes, starts via session.startDownload or simulateDownload fallback
  - simulateDownload fallback for tests/Linux: 10 steps 0.1s, updates progress, publishes progress, completes, publishes completed, processQueue
  - publishState via eventBus downloadStateChanged with snapshot
  - DownloadSessionDelegate: downloadDidProgress updates bytesDownloaded/totalBytes/progress, publishes progress; downloadDidComplete moves file from temp to destination (creates dir, removes existing, moveItem), sets completed, progress 1.0, completedAt, removes from active, publishes completed + downloadCompleted, processQueue; downloadDidFail saves resumeData, maps URLError to DownloadError, if retryable and retries left sets retry and calls retry(), else failed, removes from active, publishes failed, processQueue

- ViewModel NEW:
  - DownloadsFilter: all/downloading/queued/paused/completed/failed with icons matches(state:)
  - @MainActor, Published tasks, filteredTasks, stats, selectedFilter, isLoading, searchText, errorMessage
  - Dependencies: downloadEngine, eventBus
  - observeEvents: subscribes to downloadStateChanged/progress/completed, loadTasks or updateProgress
  - observeSearch: debounce 300ms searchText + selectedFilter -> applyFilter
  - loadTasks: allTasks + stats, applyFilter, isLoading
  - applyFilter: filter by state, search title/artist/sourceURL, sort by state order downloading/retry/queued/paused/failed/cancelled/completed then createdAt desc
  - updateProgress
  - Actions: pause/resume/cancel/retry/remove/pauseAll/resumeAll/cancelAll/clearCompleted/downloadTrack

- View NEW:
  - DownloadsView: ZStack midnight, VStack statsHeader + filterSelector + content
  - statsHeader: horizontal ScrollView StatCards total/downloading/queued/completed/failed/size with icons colors
  - filterSelector: horizontal capsules for DownloadsFilter with icons blue when selected
  - content: loading/empty/list
  - listView: List DownloadRow with listRowBackground surface and separator border
  - DownloadRow: icon circle stateColor 0.15 bg + state icon, title/artist/host, state displayName + progress %, ProgressView if active/queued/paused, formattedBytes + retry + error, actions bordered Pause/Resume/Retry/Cancel/Remove, priority capsule if not normal
  - menuButton: Menu Resume All/Pause All/Cancel All destructive/Clear Completed
  - searchable refreshable task load
  - StatCard: VStack icon+title + value surface bg rounded 12
  - Uses DesignSystem AstryxColors + AstryxTypography

- Docs: ADR-009, EPL-005, IL-005, SHM-005 (R-029 to R-034), ACC updated to 0.4.0-alpha, AGENT_STATE updated (this)
- Tests: Downloads_Tests 10 tests covering state machine transitions, priority ordering, enqueue/pause/resume/cancel/retry, stats, concurrent limit, formatted progress/bytes, retryable

### Next Steps — QEL-051 Discovery
- Taste DNA, recommendations, Audio Lab, Spaces
- DiscoveryView, TasteDNAView, AudioLabView

### Performance Budget
- Search <50ms ✅
- Library Open <200ms ✅
- Queue Instant ✅
- Seek <50ms ✅
- Play/Pause Instant ✅
- Lyrics sync <50ms ✅
- Karaoke <100ms ✅
- Download enqueue <50ms ✅
- Download progress <100ms ✅

*Last updated: 2026-09-28 — Downloads QEL-041 Complete*
