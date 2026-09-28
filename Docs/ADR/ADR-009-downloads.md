# ADR-009: Downloads Architecture — QEL-041

## Status
Accepted — 2026-09-28

## Context
QELORYX Downloads milestone requires production download system per Genesis Bible:
- DownloadEngine, offline cache, state machine Queued→Downloading→Paused→Retry→Completed→Failed
- Resume, Retry, Priority Queue, Offline optimization

Constraints:
- Greenfield, offline-first, native performance, modular, testable
- Must support concurrent downloads (max 3), priority queue, resume data, retry with exponential backoff
- Offline optimization: check disk space, wait for connectivity, background session
- Layer isolation: Core defines protocols, Platform implements URLSession, Features UI
- No external download library, use URLSession background

## Decision

### 1. State Machine — QEL-041 Enhanced
- AstryxDownloadState: queued, downloading, paused, retry, completed, failed, cancelled (extra terminal)
- Properties: isTerminal (completed/failed/cancelled), isActive (downloading/retry), canPause (downloading/queued/retry), canResume (paused/failed), canRetry (failed/paused), canCancel (!terminal)
- canTransition(to:) validates per spec: Queued→Downloading/Paused/Cancelled/Failed, Downloading→Paused/Completed/Failed/Cancelled/Retry, Paused→Queued/Downloading/Cancelled/Failed/Retry, Retry→Queued/Downloading/Paused/Failed/Cancelled, Failed→Queued/Retry/Cancelled, Terminal cannot transition
- displayName, icon for UI
- DownloadError: networkError, fileSystemError, cancelled, noSpace, invalidURL, httpError, resumeDataCorrupted, unknown + isRetryable (network/http/unknown/resumeDataCorrupted retryable, others not) + localizedDescription

### 2. Task Model — Enhanced
- AstryxDownloadTask: id, trackID, sourceURL, destinationURL, state, progress 0-1, bytesDownloaded, totalBytes, priority, retryCount, maxRetries, error, resumeData, createdAt, startedAt, completedAt, artworkURL, title, artist
- Computed: formattedProgress %, formattedBytes via ByteCountFormatter, isCompleted, canBeRetried
- DownloadPriority: low 0, normal 1, high 2, immediate 3, Comparable, displayName
- DownloadStats: total, queued, downloading, paused, completed, failed, totalBytes, downloadedBytes + formattedTotalSize/DownloadedSize

### 3. Session Protocol — Layer Isolation
- DownloadSessionProtocol (in Core): delegate, startDownload(taskID:from:resumeData:), pauseDownload(taskID:completion:), cancelDownload(taskID:), checkDiskSpace(requiredBytes:)
- DownloadSessionDelegate (in Core): downloadDidProgress, downloadDidComplete, downloadDidFail with resumeData
- This respects isolation: Core defines abstraction, Platform implements, App layer injects. Platform already depends on Core (Package.swift), so Platform can implement Core protocol.

### 4. Platform Session Manager — Production URLSession
- AstryxDownloadSessionManager: NSObject, DownloadSessionProtocol, URLSessionDownloadDelegate
- setupSession: background config with identifier com.qeloryx.downloads.{UUID}, isDiscretionary false, sessionSendsLaunchEvents true, allowsCellularAccess true, waitsForConnectivity true (offline optimization: wait for connectivity), timeout 30/300
- activeTasks dict taskID->URLSessionDownloadTask, taskIDMap Int->String (taskIdentifier to taskID), NSLock
- startDownload: creates downloadTask with or without resumeData, stores in maps, resume()
- pauseDownload: cancel with completion producing resumeData, removes from maps
- cancelDownload: cancel and remove
- checkDiskSpace: via volumeAvailableCapacity, keeps 100MB buffer, offline optimization
- Delegate callbacks: didWriteData -> downloadDidProgress, didFinishDownloadingTo -> downloadDidComplete (removes from maps), didCompleteWithError -> extracts resumeData from NSError userInfo NSURLSessionDownloadTaskResumeData, calls downloadDidFail
- urlSessionDidFinishEvents for background completion

### 5. Engine — Production
- AstryxDownloadEngine: DownloadEngineProtocol + DownloadSessionDelegate, tasks dict, queue ordered by priority, activeDownloads Set, maxConcurrent 3, downloadSession optional protocol (injected), useRealSession bool, lock NSLock, eventBus
- init with eventBus, downloadSession optional, maxConcurrent, useRealSession, sets delegate
- injectSession(_:) for App layer to inject Platform manager after init (respects layer isolation)
- enqueue(task:): checks disk space via session if totalBytes known, fails with noSpace if not enough, inserts into tasks and queue (insertIntoQueue removes existing then inserts based on priority higher first), publishes state, processQueue()
- enqueue(track:sourceURL:priority:): creates destination URL in Documents/Qeloryx/Downloads, fileName "{artist} - {title}.ext" sanitized, creates dir, creates AstryxDownloadTask with trackID/title/artist, enqueues, returns id
- pause: validates canPause and canTransition, tries to get resumeData via session.pauseDownload (checked continuation), sets state paused, removes from active, publishes, processQueue next
- resume: validates canResume and canTransition to queued, sets queued, clears error, inserts into queue, publishes, processQueue
- cancel: validates canCancel, calls session.cancelDownload, sets cancelled, error cancelled, removes from active and queue, publishes, processQueue
- retry: validates canRetry and retryCount < maxRetries, else marks failed max retries reached, validates canTransition to retry, sets retry, retryCount++, clears error, exponential backoff pow(2, retryCount) max 30s sleep, then sets queued and inserts, publishes retry then queued, processQueue
- remove: only if terminal, removes from tasks/queue/active, deletes file
- allTasks, task(id:), stats (counts per state, totalBytes, downloadedBytes), pauseAll/resumeAll/cancelAll/clearCompleted (iterate filtered tasks)
- insertIntoQueue: priority ordering higher first
- processQueue: checks active < maxConcurrent and queue not empty, finds next queued/retry task, validates transition to downloading, removes from queue, sets downloading, startedAt, clears error, adds to active, publishes, starts download via session.startDownload or simulateDownload fallback
- simulateDownload fallback for tests/Linux: loop 10 steps 0.1s each, updates progress, publishes progress, completes, publishes completed, processQueue
- publishState via eventBus downloadStateChanged with snapshot
- DownloadSessionDelegate callbacks: downloadDidProgress updates bytesDownloaded/totalBytes/progress, publishes progress; downloadDidComplete moves file from temp location to destination (creates dir, removes existing, moveItem), sets completed, progress 1.0, completedAt, removes from active, publishes completed + downloadCompleted event, processQueue; downloadDidFail saves resumeData, maps URLError to DownloadError, if retryable and retries left sets retry and calls retry(), else failed, removes from active, publishes failed, processQueue

### 6. ViewModel — DownloadsViewModel
- DownloadsFilter: all/downloading/queued/paused/completed/failed with icons and matches(state:)
- @Published tasks, filteredTasks, stats, selectedFilter, isLoading, searchText, errorMessage
- Dependencies: downloadEngine, eventBus
- observeEvents: subscribes to downloadStateChanged, downloadProgress, downloadCompleted, triggers loadTasks or updateProgress
- observeSearch: debounce 300ms searchText + selectedFilter -> applyFilter
- loadTasks: allTasks + stats, applyFilter, isLoading
- applyFilter: filter by state via selectedFilter.matches, filter by search (title/artist/sourceURL), sort by state order downloading/retry/queued/paused/failed/cancelled/completed then createdAt desc
- updateProgress: updates tasks and filteredTasks progress
- Actions: pause, resume, cancel, retry, remove, pauseAll, resumeAll, cancelAll, clearCompleted, downloadTrack (enqueue track)
- @MainActor

### 7. UI — DownloadsView Production
- ZStack midnight, VStack statsHeader + filterSelector + content
- statsHeader: horizontal ScrollView StatCards total/downloading/queued/completed/failed/size with icons colors
- filterSelector: horizontal capsules for DownloadsFilter with icons, blue when selected
- content: loading/empty/list
- listView: List of DownloadRow with listRowBackground surface and separator border
- DownloadRow: icon circle with stateColor 0.15 bg + state icon, title/artist/source host, state displayName + progress %, ProgressView if active/queued/paused, formattedBytes + retry count + error, actions buttons bordered: Pause if canPause, Resume if canResume, Retry if canRetry, Cancel if canCancel, Remove if terminal, priority indicator capsule if not normal
- menuButton: Menu Resume All, Pause All, Cancel All destructive, Clear Completed
- Searchable, refreshable, task load
- Uses DesignSystem AstryxColors + AstryxTypography
- StatCard: VStack icon+title + value, surface bg rounded 12

### 8. Performance & Offline
- Concurrent 3 max to avoid resource contention
- Priority queue ensures high priority downloads first
- Resume data saved on pause/fail for resuming
- Exponential backoff for retry (1s, 2s, 4s, 8s, max 30s) avoids spamming
- Disk space check before enqueue with 100MB buffer
- waitsForConnectivity true for offline optimization (waits for network rather than failing immediately)
- Background session allows resuming after app kill

## Alternatives Considered
- Alamofire or external download lib: rejected for greenfield, no external dependencies per spec
- Foreground URLSession only: rejected, background allows resume after app kill, better for offline-first
- Core directly using URLSession: rejected for layer isolation, use protocol injection instead

## Consequences
- Production download with resume, retry, priority, offline optimization ✅
- State machine validated per spec Queued→Downloading→Paused→Retry→Completed→Failed ✅
- Layer isolation respected via protocol injection ✅
- Testable with simulation fallback for Linux/tests ✅
- UI with progress, actions, stats, filtering ✅

## References
- URLSession background downloads: https://developer.apple.com/documentation/foundation/urlsessionconfiguration/background(withidentifier:)
- Resume data: https://developer.apple.com/documentation/foundation/urlsessiondownloadtask
- Genesis Bible v3.0 QEL-041

*QELORYX — Hear Beyond. Build Beyond.*
