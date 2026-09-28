// QELORYX — DownloadEngine
// DownloadEngine.swift
// Resume, Retry, Priority Queue, Offline optimization

import Foundation

public protocol DownloadEngineProtocol: Sendable {
    func enqueue(task: AstryxDownloadTask) async
    func pause(taskID: String) async
    func resume(taskID: String) async
    func cancel(taskID: String) async
    func retry(taskID: String) async
    func allTasks() async -> [AstryxDownloadTask]
    func task(id: String) async -> AstryxDownloadTask?
}

public final class AstryxDownloadEngine: DownloadEngineProtocol, @unchecked Sendable {
    
    private var tasks: [String: AstryxDownloadTask] = [:]
    private var queue: [String] = [] // Ordered by priority
    private let lock = NSLock()
    private let eventBus: any EventBusProtocol
    private var activeDownloads: Set<String> = []
    private let maxConcurrentDownloads = 3
    
    public init(eventBus: any EventBusProtocol = AstryxEventBus.shared) {
        self.eventBus = eventBus
    }
    
    public func enqueue(task: AstryxDownloadTask) async {
        lock.lock()
        tasks[task.id] = task
        insertIntoQueue(taskID: task.id, priority: task.priority)
        lock.unlock()
        
        eventBus.publish(.downloadStateChanged(taskID: task.id, state: DownloadStateSnapshot(state: task.state.rawValue, progress: task.progress)))
        
        await processQueue()
    }
    
    public func pause(taskID: String) async {
        lock.lock()
        guard var task = tasks[taskID], task.state.canPause else {
            lock.unlock()
            return
        }
        task.state = .paused
        activeDownloads.remove(taskID)
        tasks[taskID] = task
        lock.unlock()
        
        eventBus.publish(.downloadStateChanged(taskID: taskID, state: DownloadStateSnapshot(state: task.state.rawValue, progress: task.progress)))
    }
    
    public func resume(taskID: String) async {
        lock.lock()
        guard var task = tasks[taskID], task.state.canResume else {
            lock.unlock()
            return
        }
        task.state = .queued
        tasks[taskID] = task
        insertIntoQueue(taskID: taskID, priority: task.priority)
        lock.unlock()
        
        eventBus.publish(.downloadStateChanged(taskID: taskID, state: DownloadStateSnapshot(state: AstryxDownloadState.queued.rawValue, progress: task.progress)))
        
        await processQueue()
    }
    
    public func cancel(taskID: String) async {
        lock.lock()
        guard var task = tasks[taskID] else {
            lock.unlock()
            return
        }
        task.state = .cancelled
        task.error = .cancelled
        tasks[taskID] = task
        activeDownloads.remove(taskID)
        queue.removeAll { $0 == taskID }
        lock.unlock()
        
        eventBus.publish(.downloadStateChanged(taskID: taskID, state: DownloadStateSnapshot(state: task.state.rawValue, progress: task.progress, error: task.error?.localizedDescription)))
    }
    
    public func retry(taskID: String) async {
        lock.lock()
        guard var task = tasks[taskID], task.state.canRetry else {
            lock.unlock()
            return
        }
        task.state = .retry
        task.retryCount += 1
        task.error = nil
        tasks[taskID] = task
        insertIntoQueue(taskID: taskID, priority: task.priority)
        lock.unlock()
        
        eventBus.publish(.downloadStateChanged(taskID: taskID, state: DownloadStateSnapshot(state: task.state.rawValue, progress: task.progress)))
        
        await processQueue()
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
    
    // MARK: - Private
    
    private func insertIntoQueue(taskID: String, priority: DownloadPriority) {
        // Remove if already in queue
        queue.removeAll { $0 == taskID }
        
        // Insert based on priority (higher priority first)
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
        
        let nextID = queue.removeFirst()
        guard var task = tasks[nextID] else {
            lock.unlock()
            return
        }
        
        task.state = .downloading
        task.startedAt = Date()
        tasks[nextID] = task
        activeDownloads.insert(nextID)
        lock.unlock()
        
        eventBus.publish(.downloadStateChanged(taskID: nextID, state: DownloadStateSnapshot(state: task.state.rawValue, progress: task.progress)))
        
        // Simulate download in foundation — real implementation uses URLSession with resume data
        Task {
            await simulateDownload(taskID: nextID)
        }
    }
    
    private func simulateDownload(taskID: String) async {
        // Foundation placeholder: simulate progress
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
        tasks[taskID] = task
        activeDownloads.remove(taskID)
        lock.unlock()
        
        eventBus.publish(.downloadStateChanged(taskID: taskID, state: DownloadStateSnapshot(state: task.state.rawValue, progress: 1.0)))
        eventBus.publish(.downloadCompleted(taskID: taskID, trackID: task.trackID ?? ""))
        
        await processQueue()
    }
}
