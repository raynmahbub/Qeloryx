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
    
    private var tasks: [String: AstryxDownloadTask] = [:]
    private var queue: [String] = [] // Ordered by priority
    private let lock = NSLock()
    private let eventBus: any EventBusProtocol
    private var activeDownloads: Set<String> = []
    private let maxConcurrentDownloads: Int
    private var downloadSession: (any DownloadSessionProtocol)?
    
    // For testing / fallback without URLSession (Linux)
    private let useRealSession: Bool
    
    public init(
        eventBus: any EventBusProtocol = AstryxEventBus.shared,
        downloadSession: (any DownloadSessionProtocol)? = nil,
        maxConcurrent: Int = 3,
        useRealSession: Bool = true
    ) {
        self.eventBus = eventBus
        self.maxConcurrentDownloads = maxConcurrent
        self.useRealSession = useRealSession
        self.downloadSession = downloadSession
        
        // If no session injected and we want real session, create platform manager via factory
        // To respect layer isolation, session is injected from Platform layer (App layer)
        // If nil, fallback to simulation (tests/Linux)
        if self.downloadSession == nil && useRealSession {
            #if !canImport(FoundationNetworking)
            // On Apple platforms, if no session injected, we still work with simulation until Platform injects
            // Real app injects AstryxDownloadSessionManager from Platform
            #endif
        }
        
        // Set self as delegate if session exists
        self.downloadSession?.delegate = self
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
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let downloadsDir = docs.appendingPathComponent("Qeloryx/Downloads", isDirectory: true)
        try? FileManager.default.createDirectory(at: downloadsDir, withIntermediateDirectories: true)
        
        let ext = sourceURL.pathExtension.isEmpty ? track.fileFormat.fileExtensions.first ?? "mp3" : sourceURL.pathExtension
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
        guard var task = tasks[taskID], task.state.canPause else {
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
                task = current
            }
            lock.unlock()
        } else {
            // Fallback: simulate pause
            lock.lock()
            if var current = tasks[taskID] {
                current.state = .paused
                activeDownloads.remove(taskID)
                tasks[taskID] = current
                task = current
            }
            lock.unlock()
        }
        
        publishState(taskID: taskID, state: .paused, progress: task.progress)
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
        guard var task = tasks[taskID] else {
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
            task = current
        }
        activeDownloads.remove(taskID)
        queue.removeAll { $0 == taskID }
        lock.unlock()
        
        publishState(taskID: taskID, state: .cancelled, progress: task.progress, error: task.error?.localizedDescription)
        
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
    
    // MARK: - Private Queue Management
    
    private func insertIntoQueue(taskID: String, priority: DownloadPriority) {
        queue.removeAll { $0 == taskID }
        
        var inserted = false
        for (index, existingID) in queue.enumerated() {
            if let existingTask = tasks[existingID], existingTask.priority < priority {
                queue.insert(taskID, at: index)
                inserted = true
                break
            }
        }
        if !inserted {
            queue.append(taskID)
        }
    }
    
    private func processQueue() async {
        lock.lock()
        guard activeDownloads.count < maxConcurrentDownloads, !queue.isEmpty else {
            lock.unlock()
            return
        }
        
        // Get next task that is queued or retry
        var nextID: String?
        var nextTask: AstryxDownloadTask?
        
        for id in queue {
            if let task = tasks[id], (task.state == .queued || task.state == .retry) {
                nextID = id
                nextTask = task
                break
            }
        }
        
        guard let taskID = nextID, var task = nextTask else {
            lock.unlock()
            return
        }
        
        // Validate transition
        guard task.state.canTransition(to: .downloading) else {
            queue.removeAll { $0 == taskID }
            lock.unlock()
            return
        }
        
        queue.removeAll { $0 == taskID }
        task.state = .downloading
        task.startedAt = Date()
        task.error = nil
        tasks[taskID] = task
        activeDownloads.insert(taskID)
        lock.unlock()
        
        publishState(taskID: taskID, state: .downloading, progress: task.progress)
        
        // Start actual download
        if let session = downloadSession {
            session.startDownload(taskID: taskID, from: task.sourceURL, resumeData: task.resumeData)
        } else {
            // Fallback simulation for tests/Linux
            Task {
                await simulateDownload(taskID: taskID)
            }
        }
    }
    
    private func simulateDownload(taskID: String) async {
        // Fallback simulation for environments without URLSession background support
        for i in 1...10 {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            
            lock.lock()
            guard var task = tasks[taskID], task.state == .downloading else {
                lock.unlock()
                return
            }
            task.progress = Double(i) / 10.0
            task.bytesDownloaded = Int64(Double(task.totalBytes ?? 10_000_000) * task.progress)
            tasks[taskID] = task
            lock.unlock()
            
            eventBus.publish(.downloadProgress(taskID: taskID, progress: task.progress))
        }
        
        lock.lock()
        guard var task = tasks[taskID] else {
            lock.unlock()
            return
        }
        task.state = .completed
        task.progress = 1.0
        task.completedAt = Date()
        task.bytesDownloaded = task.totalBytes ?? task.bytesDownloaded
        tasks[taskID] = task
        activeDownloads.remove(taskID)
        lock.unlock()
        
        publishState(taskID: taskID, state: .completed, progress: 1.0)
        eventBus.publish(.downloadCompleted(taskID: taskID, trackID: task.trackID ?? ""))
        
        await processQueue()
    }
    
    private func publishState(taskID: String, state: AstryxDownloadState, progress: Double, error: String? = nil) {
        eventBus.publish(.downloadStateChanged(taskID: taskID, state: DownloadStateSnapshot(state: state.rawValue, progress: progress, error: error)))
    }
}

// MARK: - DownloadSessionDelegate — Platform callbacks

extension AstryxDownloadEngine: DownloadSessionDelegate {
    
    public func downloadDidProgress(taskID: String, bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpected: Int64) {
        lock.lock()
        guard var task = tasks[taskID] else {
            lock.unlock()
            return
        }
        task.bytesDownloaded = totalBytesWritten
        if totalBytesExpected > 0 {
            task.totalBytes = totalBytesExpected
            task.progress = Double(totalBytesWritten) / Double(totalBytesExpected)
        }
        tasks[taskID] = task
        let progress = task.progress
        lock.unlock()
        
        eventBus.publish(.downloadProgress(taskID: taskID, progress: progress))
    }
    
    public func downloadDidComplete(taskID: String, location: URL) {
        lock.lock()
        guard var task = tasks[taskID] else {
            lock.unlock()
            return
        }
        lock.unlock()
        
        // Move file from temp location to destination
        do {
            let destDir = task.destinationURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
            
            if FileManager.default.fileExists(atPath: task.destinationURL.path) {
                try FileManager.default.removeItem(at: task.destinationURL)
            }
            try FileManager.default.moveItem(at: location, to: task.destinationURL)
            
            lock.lock()
            if var current = tasks[taskID] {
                current.state = .completed
                current.progress = 1.0
                current.completedAt = Date()
                current.bytesDownloaded = current.totalBytes ?? current.bytesDownloaded
                tasks[taskID] = current
                task = current
            }
            activeDownloads.remove(taskID)
            lock.unlock()
            
            publishState(taskID: taskID, state: .completed, progress: 1.0)
            eventBus.publish(.downloadCompleted(taskID: taskID, trackID: task.trackID ?? ""))
            
            Task {
                await processQueue()
            }
            
        } catch {
            lock.lock()
            if var current = tasks[taskID] {
                current.state = .failed
                current.error = .fileSystemError(error.localizedDescription)
                tasks[taskID] = current
            }
            activeDownloads.remove(taskID)
            lock.unlock()
            
            publishState(taskID: taskID, state: .failed, progress: task.progress, error: error.localizedDescription)
            
            Task {
                await processQueue()
            }
        }
    }
    
    public func downloadDidFail(taskID: String, error: Error, resumeData: Data?) {
        lock.lock()
        guard var task = tasks[taskID] else {
            lock.unlock()
            return
        }
        
        // Save resume data
        task.resumeData = resumeData
        
        // Check if retryable and retries left
        let downloadError: DownloadError
        if let urlError = error as? URLError {
            switch urlError.code {
            case .cancelled:
                downloadError = .cancelled
            case .notConnectedToInternet, .timedOut, .networkConnectionLost:
                downloadError = .networkError(urlError.localizedDescription)
            default:
                downloadError = .networkError(urlError.localizedDescription)
            }
        } else {
            downloadError = .networkError(error.localizedDescription)
        }
        
        task.error = downloadError
        
        if downloadError.isRetryable && task.retryCount < task.maxRetries {
            task.state = .retry
            tasks[taskID] = task
            lock.unlock()
            
            publishState(taskID: taskID, state: .retry, progress: task.progress, error: downloadError.localizedDescription)
            
            Task {
                await retry(taskID: taskID)
            }
        } else {
            task.state = .failed
            tasks[taskID] = task
            activeDownloads.remove(taskID)
            lock.unlock()
            
            publishState(taskID: taskID, state: .failed, progress: task.progress, error: downloadError.localizedDescription)
            
            Task {
                await processQueue()
            }
        }
    }
}
