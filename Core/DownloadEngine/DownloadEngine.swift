// QELORYX — DownloadEngine
// DownloadEngine.swift
// QEL-041 Downloads — Production with URLSession, Resume, Retry, Priority Queue, Offline optimization

import Foundation

public protocol DownloadEngineProtocol: Sendable {
    func enqueue(task: AstryxDownloadTask) async
    func enqueue(track: AstryxTrack, sourceURL: URL, priority: DownloadPriority) async -> String
    func pause(taskID: String) async
    func resume(taskID: String) async
    func cancel(taskID: String) async
    func retry(taskID: String) async
    func remove(taskID: String) async
    func allTasks() async -> [AstryxDownloadTask]
    func task(id: String) async -> AstryxDownloadTask?
    func stats() async -> DownloadStats
    func pauseAll() async
    func resumeAll() async
    func cancelAll() async
    func clearCompleted() async
}

// MARK: - Production Download Engine — QEL-041

public final class AstryxDownloadEngine: DownloadEngineProtocol, @unchecked Sendable {
    
    // `internal` rather than `private`: the queue/delegate/ingestion code
    // lives in sibling extensions (type_body_length split) and must reach it.
    var tasks: [String: AstryxDownloadTask] = [:]
    var queue: [String] = [] // Ordered by priority
    let lock = NSLock()
    let eventBus: any EventBusProtocol
    var activeDownloads: Set<String> = []
    let maxConcurrentDownloads: Int
    var downloadSession: (any DownloadSessionProtocol)?

    /// Persistence for the task table (BUG-09). Without it a paused download
    /// vanished on relaunch and nothing could be reconciled with the session.
    let taskStore: any DownloadTaskStoring

    /// Hand-off to the library once a file lands (BUG-10). Optional so the
    /// engine stays usable in isolation and in tests.
    let library: (any LibraryEngineProtocol)?

    /// Injected metadata reader so completed downloads get real tags and
    /// artwork instead of being indexed as "Unknown Artist".
    let metadataEngine: any MetadataEngineProtocol

    public init(
        eventBus: any EventBusProtocol = AstryxEventBus.shared,
        downloadSession: (any DownloadSessionProtocol)? = nil,
        maxConcurrent: Int = 3,
        taskStore: any DownloadTaskStoring = InMemoryDownloadTaskStore(),
        library: (any LibraryEngineProtocol)? = nil,
        metadataEngine: any MetadataEngineProtocol = AstryxMetadataEngine()
    ) {
        self.eventBus = eventBus
        self.maxConcurrentDownloads = maxConcurrent
        self.downloadSession = downloadSession
        self.taskStore = taskStore
        self.library = library
        self.metadataEngine = metadataEngine

        // Restore the persisted table before anyone can observe the engine.
        let restored = taskStore.load()
        for task in restored {
            tasks[task.id] = task
            // Anything that claimed to be in flight when the process died is
            // put back in the queue rather than left stuck.
            if task.state == .downloading || task.state == .retry {
                var recovered = task
                recovered.state = .queued
                tasks[task.id] = recovered
                insertIntoQueue(taskID: task.id, priority: task.priority)
            } else if task.state == .queued {
                insertIntoQueue(taskID: task.id, priority: task.priority)
            }
        }

        self.downloadSession?.delegate = self
    }

    /// Thread-safe read of one task, used where the old code kept a stale copy
    /// across an `await` (a data race on the mutable `tasks` dictionary).
    func currentTaskSnapshot(taskID: String) -> AstryxDownloadTask? {
        lock.lock()
        defer { lock.unlock() }
        return tasks[taskID]
    }

    /// Persists the current task table. Called after every state transition.
    func persist() {
        lock.lock()
        let snapshot = Array(tasks.values)
        lock.unlock()
        taskStore.save(snapshot)
    }
    
    public func injectSession(_ session: any DownloadSessionProtocol) {
        lock.lock()
        downloadSession = session
        downloadSession?.delegate = self
        lock.unlock()
    }
    
    // MARK: - Public API
    
    public func enqueue(task: AstryxDownloadTask) async {
        // Offline optimization: check disk space
        if let totalBytes = task.totalBytes, let session = downloadSession {
            if !session.checkDiskSpace(requiredBytes: totalBytes) {
                var failedTask = task
                failedTask.state = .failed
                failedTask.error = .noSpace
                lock.lock()
                tasks[task.id] = failedTask
                lock.unlock()
                publishState(taskID: task.id, state: .failed, progress: task.progress, error: DownloadError.noSpace.localizedDescription)
                return
            }
        }
        
        lock.lock()
        tasks[task.id] = task
        insertIntoQueue(taskID: task.id, priority: task.priority)
        lock.unlock()
        
        publishState(taskID: task.id, state: task.state, progress: task.progress)
        
        await processQueue()
    }
    
    public func enqueue(track: AstryxTrack, sourceURL: URL, priority: DownloadPriority = .normal) async -> String {
        // Create destination URL in Documents/Qeloryx/Downloads
        let docs = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let downloadsDir = docs.appendingPathComponent("Qeloryx/Downloads", isDirectory: true)
        try? FileManager.default.createDirectory(at: downloadsDir, withIntermediateDirectories: true)
        
        let ext = sourceURL.pathExtension.isEmpty
            ? (track.fileFormat.fileExtensions.first ?? "mp3")
            : sourceURL.pathExtension
        let fileName = "\(track.artist) - \(track.title).\(ext)".replacingOccurrences(of: "/", with: "-")
        let destURL = downloadsDir.appendingPathComponent(fileName)
        
        let task = AstryxDownloadTask(
            trackID: track.id,
            sourceURL: sourceURL,
            destinationURL: destURL,
            priority: priority,
            title: track.title,
            artist: track.artist
        )
        
        await enqueue(task: task)
        return task.id
    }
    
    public func pause(taskID: String) async {
        lock.lock()
        guard let task = tasks[taskID], task.state.canPause else {
            lock.unlock()
            return
        }
        // Validate state transition
        guard task.state.canTransition(to: .paused) else {
            lock.unlock()
            return
        }
        lock.unlock()
        
        // Try to get resume data from session
        if let session = downloadSession {
            let resumeData = await withCheckedContinuation { continuation in
                session.pauseDownload(taskID: taskID) { data in
                    continuation.resume(returning: data)
                }
            }
            
            lock.lock()
            if var current = tasks[taskID] {
                current.state = .paused
                current.resumeData = resumeData
                activeDownloads.remove(taskID)
                tasks[taskID] = current
            }
            lock.unlock()
        } else {
            // Fallback: simulate pause
            lock.lock()
            if var current = tasks[taskID] {
                current.state = .paused
                activeDownloads.remove(taskID)
                tasks[taskID] = current
            }
            lock.unlock()
        }
        
        let pausedProgress = currentTaskSnapshot(taskID: taskID)?.progress ?? 0
        publishState(taskID: taskID, state: .paused, progress: pausedProgress)
        await processQueue() // Process next in queue
    }
    
    public func resume(taskID: String) async {
        lock.lock()
        guard var task = tasks[taskID], task.state.canResume else {
            lock.unlock()
            return
        }
        guard task.state.canTransition(to: .queued) else {
            lock.unlock()
            return
        }
        task.state = .queued
        task.error = nil
        tasks[taskID] = task
        insertIntoQueue(taskID: taskID, priority: task.priority)
        lock.unlock()
        
        publishState(taskID: taskID, state: .queued, progress: task.progress)
        
        await processQueue()
    }
    
    public func cancel(taskID: String) async {
        lock.lock()
        guard let task = tasks[taskID] else {
            lock.unlock()
            return
        }
        guard task.state.canCancel else {
            lock.unlock()
            return
        }
        lock.unlock()
        
        downloadSession?.cancelDownload(taskID: taskID)
        
        lock.lock()
        if var current = tasks[taskID] {
            current.state = .cancelled
            current.error = .cancelled
            tasks[taskID] = current
        }
        activeDownloads.remove(taskID)
        queue.removeAll { $0 == taskID }
        lock.unlock()
        
        let cancelled = currentTaskSnapshot(taskID: taskID)
        publishState(
            taskID: taskID,
            state: .cancelled,
            progress: cancelled?.progress ?? 0,
            error: cancelled?.error?.localizedDescription
        )
        
        await processQueue()
    }
    
    public func retry(taskID: String) async {
        lock.lock()
        guard var task = tasks[taskID], task.state.canRetry else {
            lock.unlock()
            return
        }
        guard task.retryCount < task.maxRetries else {
            // Max retries reached, mark failed
            if var current = tasks[taskID] {
                current.state = .failed
                current.error = .unknown("Max retries reached")
                tasks[taskID] = current
            }
            lock.unlock()
            publishState(taskID: taskID, state: .failed, progress: task.progress, error: "Max retries reached")
            return
        }
        guard task.state.canTransition(to: .retry) else {
            lock.unlock()
            return
        }
        task.state = .retry
        task.retryCount += 1
        task.error = nil
        tasks[taskID] = task
        // Exponential backoff: wait before re-queuing
        let backoff = min(pow(2.0, Double(task.retryCount)) * 1.0, 30.0) // Max 30s
        lock.unlock()
        
        publishState(taskID: taskID, state: .retry, progress: task.progress)
        
        // Wait with backoff then re-queue
        try? await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
        
        lock.lock()
        if var current = tasks[taskID], current.state == .retry {
            current.state = .queued
            tasks[taskID] = current
            insertIntoQueue(taskID: taskID, priority: current.priority)
        }
        lock.unlock()
        
        await processQueue()
    }
    
    public func remove(taskID: String) async {
        lock.lock()
        guard let task = tasks[taskID], task.state.isTerminal else {
            lock.unlock()
            return
        }
        tasks.removeValue(forKey: taskID)
        queue.removeAll { $0 == taskID }
        activeDownloads.remove(taskID)
        lock.unlock()
        
        persist()
        // Optionally delete file
        try? FileManager.default.removeItem(at: task.destinationURL)
    }
    
    public func allTasks() async -> [AstryxDownloadTask] {
        lock.lock()
        defer { lock.unlock() }
        return Array(tasks.values).sorted { $0.createdAt < $1.createdAt }
    }
    
    public func task(id: String) async -> AstryxDownloadTask? {
        lock.lock()
        defer { lock.unlock() }
        return tasks[id]
    }
    
    public func stats() async -> DownloadStats {
        lock.lock()
        defer { lock.unlock() }
        
        var queued = 0, downloading = 0, paused = 0, completed = 0, failed = 0
        var totalBytes: Int64 = 0, downloadedBytes: Int64 = 0
        
        for task in tasks.values {
            switch task.state {
            case .queued, .retry: queued += 1
            case .downloading: downloading += 1
            case .paused: paused += 1
            case .completed: completed += 1
            case .failed, .cancelled: failed += 1
            }
            if let total = task.totalBytes {
                totalBytes += total
            }
            downloadedBytes += task.bytesDownloaded
        }
        
        return DownloadStats(
            total: tasks.count,
            queued: queued,
            downloading: downloading,
            paused: paused,
            completed: completed,
            failed: failed,
            totalBytes: totalBytes,
            downloadedBytes: downloadedBytes
        )
    }
    
    public func pauseAll() async {
        let ids: [String]
        lock.lock()
        ids = tasks.values.filter { $0.state.canPause }.map { $0.id }
        lock.unlock()
        
        for id in ids {
            await pause(taskID: id)
        }
    }
    
    public func resumeAll() async {
        let ids: [String]
        lock.lock()
        ids = tasks.values.filter { $0.state.canResume }.map { $0.id }
        lock.unlock()
        
        for id in ids {
            await resume(taskID: id)
        }
    }
    
    public func cancelAll() async {
        let ids: [String]
        lock.lock()
        ids = tasks.values.filter { !$0.state.isTerminal }.map { $0.id }
        lock.unlock()
        
        for id in ids {
            await cancel(taskID: id)
        }
    }
    
    public func clearCompleted() async {
        let ids: [String]
        lock.lock()
        ids = tasks.values.filter { $0.state == .completed }.map { $0.id }
        lock.unlock()
        
        for id in ids {
            await remove(taskID: id)
        }
    }
    
}
