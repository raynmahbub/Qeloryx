# SHM-005: Downloads Research — QEL-041

## Purpose
Record engineering research for Downloads milestone, per Genesis Bible research policy. Study but implement within QELORYX identity, no code reuse.

## Research Entries

### R-029: URLSession Background Downloads & Resume Data
- **Source:** https://developer.apple.com/documentation/foundation/urlsessionconfiguration/background(withidentifier:) + https://developer.apple.com/documentation/foundation/urlsessiondownloadtask
- **What we learned:** Background URLSession allows downloads to continue after app killed, uses identifier com.example.app. Must be created with background(withIdentifier:), isDiscretionary false for immediate, sessionSendsLaunchEvents true for background events, allowsCellularAccess true, waitsForConnectivity true to wait for network rather than fail immediately (offline optimization). Download tasks produce resumeData on cancel or failure via NSError userInfo NSURLSessionDownloadTaskResumeData, which can be used to create new downloadTask(withResumeData:) to resume. Timeout interval for request 30s, resource 300s. Need to store taskID mapping via taskIdentifier because URLSession tasks have integer identifiers, not our string IDs.
- **How we used:** AstryxDownloadSessionManager with background config, identifier com.qeloryx.downloads.{UUID}, waitsForConnectivity true, activeTasks dict taskID->URLSessionDownloadTask, taskIDMap Int->String, startDownload with/without resumeData, pauseDownload via cancel producing resumeData, cancelDownload, checkDiskSpace, delegate callbacks mapping to our delegate protocol.
- **QELORYX identity:** Our manager is greenfield, Astryx prefix, not copying Apple sample code. We use protocol abstraction for layer isolation.

### R-030: Download State Machine Queued→Downloading→Paused→Retry→Completed→Failed
- **Source:** Genesis Bible QEL-041 spec + common download managers research (IDM, etc.)
- **What we learned:** State machine per spec: Queued→Downloading→Paused→Retry→Completed→Failed. Need to validate transitions: Queued can go to Downloading/Paused/Cancelled/Failed, Downloading to Paused/Completed/Failed/Cancelled/Retry, Paused to Queued/Downloading/Cancelled/Failed/Retry, Retry to Queued/Downloading/Paused/Failed/Cancelled, Failed to Queued/Retry/Cancelled, Terminal (Completed/Cancelled) cannot transition. Need properties isTerminal, isActive, canPause/Resume/Retry/Cancel for UI. Also need exponential backoff for retry: pow(2, retryCount) max 30s to avoid spamming, maxRetries 3.
- **How we used:** AstryxDownloadState with canTransition(to:) validating per spec, isTerminal, isActive, canPause/Resume/Retry/Cancel, displayName, icon. DownloadError with isRetryable. Engine validates transitions before changing state, uses exponential backoff in retry().
- **QELORYX identity:** State machine per Genesis Bible, not copying external manager.

### R-031: Priority Queue & Concurrent Limit
- **Source:** Download manager research, queue management patterns
- **What we learned:** Priority queue: low 0, normal 1, high 2, immediate 3, higher priority first. Insert into queue based on priority, removing existing if re-queued. Concurrent limit 3 to avoid resource contention, activeDownloads Set tracks currently downloading, processQueue checks active < maxConcurrent and queue not empty, finds next queued/retry task. Sort filtered tasks by state order downloading/retry/queued/paused/failed/cancelled/completed then createdAt desc for UI.
- **How we used:** DownloadPriority enum Comparable, insertIntoQueue priority ordering, maxConcurrentDownloads 3, activeDownloads Set, processQueue with transition validation, applyFilter sorting by state order.
- **QELORYX identity:** Our queue is greenfield, simple but production.

### R-032: Offline Optimization — Disk Space & Connectivity
- **Source:** Offline-first principle from Genesis Bible + URLSession waitsForConnectivity
- **What we learned:** Offline optimization includes: check disk space before enqueue via volumeAvailableCapacity, keep 100MB buffer, fail with noSpace error if not enough; waitsForConnectivity true makes URLSession wait for network rather than fail immediately when offline; resume data allows resuming after network loss; file moving from temp location to destination must create directory and handle existing file removal.
- **How we used:** checkDiskSpace via FileManager resourceValues volumeAvailableCapacity, 100MB buffer, enqueue checks totalBytes if known, fails with noSpace; waitsForConnectivity true in config; downloadDidComplete moves file from temp to destination with createDirectory and remove existing; downloadDidFail saves resumeData and retries if retryable.
- **QELORYX identity:** Offline-first per QELORYX spec, not copying.

### R-033: Download UI — Progress, Actions, Stats
- **Source:** Apple App Store downloads, Spotify offline downloads UI research
- **What we learned:** Download UI needs: stats header with total/downloading/queued/completed/failed/size, filter selector capsules for state, list with icon circle stateColor, title/artist, state displayName + progress %, ProgressView, formattedBytes, retry count, error, actions bordered Pause/Resume/Retry/Cancel/Remove, priority indicator, menu Resume All/Pause All/Cancel All/Clear Completed, searchable, refreshable. Performance: enqueue <50ms in-memory, progress <100ms via delegate.
- **How we used:** DownloadsView with statsHeader horizontal StatCards, filterSelector capsules, DownloadRow with icon circle, ProgressView, actions, StatCard component, menuButton, searchable, refreshable. Uses Midnight Aurora design system.
- **QELORYX identity:** Our UI is Midnight Aurora, Astryx components, not copying App Store/Spotify.

### R-034: Layer Isolation — Core Protocol, Platform Adapter
- **Source:** QELORYX Genesis Bible architectural layers + clean architecture dependency inversion
- **What we learned:** Core should define abstraction (DownloadSessionProtocol), Platform implements adapter (DownloadSessionManager), App layer injects. This respects isolation: Core doesn't depend on concrete Platform, only protocol. Platform depends on Core (Package.swift shows Platform depends on Core), allowed for adapter pattern. Existing example: SwiftDataAdapter in Platform implements SwiftDataStackProtocol from Core. Same pattern for downloads.
- **How we used:** Created DownloadSessionProtocol + DownloadSessionDelegate in Core, Platform DownloadSessionManager implements protocol, Engine holds optional protocol and has injectSession(_:) for App layer to inject Platform manager. Fallback simulation for tests/Linux when no session injected.
- **QELORYX identity:** Follows existing QELORYX pattern, greenfield.

## Summary
- Background URLSession with resume data + waitsForConnectivity ✅
- State machine validated per spec ✅
- Priority queue + concurrent limit 3 ✅
- Offline optimization disk space + connectivity ✅
- UI with stats, filtering, progress, actions ✅
- Layer isolation via protocol injection ✅
- No external code reuse, all greenfield QELORYX owned ✅

*Research completed: 2026-09-28 — QEL-041 Downloads*
