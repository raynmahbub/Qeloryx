// QELORYX — DownloadEngine
// DownloadEngine+Queue.swift
//
// Scheduling: priority insertion, concurrency-limited dispatch and the
// state-transition funnel. Split out of `DownloadEngine.swift` to keep
// `AstryxDownloadEngine` inside the 400-line `type_body_length` limit.

import Foundation

extension AstryxDownloadEngine {

    // MARK: - Private Queue Management
    
    func insertIntoQueue(taskID: String, priority: DownloadPriority) {
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
    
    func processQueue() async {
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
        
        // Start the real transfer. With no session there is nothing to do but
        // fail honestly: the old fallback faked ten progress ticks and then
        // reported `.completed`, which ingested a library entry pointing at a
        // file that was never written (BUG-10).
        guard let session = downloadSession else {
            downloadDidFail(
                taskID: taskID,
                error: DownloadError.noDownloadSession,
                resumeData: nil
            )
            return
        }
        session.startDownload(taskID: taskID, from: task.sourceURL, resumeData: task.resumeData)
    }
    
    func publishState(taskID: String, state: AstryxDownloadState, progress: Double, error: String? = nil) {
        // Single funnel for state transitions: persist here so no call site can
        // forget to (BUG-09).
        persist()
        eventBus.publish(.downloadStateChanged(taskID: taskID, state: DownloadStateSnapshot(state: state.rawValue, progress: progress, error: error)))
    }
}
