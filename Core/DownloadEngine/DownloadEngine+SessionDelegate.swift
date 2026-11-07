// QELORYX — DownloadEngine
// DownloadEngine+SessionDelegate.swift
//
// The `DownloadSessionProtocol` callbacks. Split out of `DownloadEngine.swift`
// purely to keep `AstryxDownloadEngine` inside the 400-line
// `type_body_length` limit; no state moved.

import Foundation

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
        
        // Move the file from the temp location to the destination.
        // BUG-13: the old delete-then-move could lose both files if the process
        // died in between. Stage next to the destination, validate, then
        // replace atomically on the same volume.
        do {
            let destDir = task.destinationURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)

            let stagedURL = destDir.appendingPathComponent(
                ".qeloryx-incoming-\(task.id)-\(UUID().uuidString)"
            )
            if FileManager.default.fileExists(atPath: stagedURL.path) {
                try FileManager.default.removeItem(at: stagedURL)
            }
            try FileManager.default.moveItem(at: location, to: stagedURL)

            // Integrity check: a zero-byte or truncated file is not a download.
            let stagedSize = (try? FileManager.default.attributesOfItem(atPath: stagedURL.path)[.size]) as? Int64 ?? 0
            guard stagedSize > 0 else {
                try? FileManager.default.removeItem(at: stagedURL)
                throw DownloadError.fileSystemError("Downloaded file was empty")
            }
            if let expected = task.totalBytes, expected > 0, stagedSize < expected {
                try? FileManager.default.removeItem(at: stagedURL)
                throw DownloadError.fileSystemError("Downloaded file was truncated")
            }

            if FileManager.default.fileExists(atPath: task.destinationURL.path) {
                _ = try FileManager.default.replaceItemAt(task.destinationURL, withItemAt: stagedURL)
            } else {
                try FileManager.default.moveItem(at: stagedURL, to: task.destinationURL)
            }

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
            persist()
            eventBus.publish(.downloadCompleted(taskID: taskID, trackID: task.trackID ?? ""))

            Task {
                await self.ingestCompletedDownload(task)
                await self.processQueue()
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
        if let typed = error as? DownloadError {
            // Preserve the engine's own classification. Coercing everything to
            // `.networkError` marked non-retryable failures (no session, invalid
            // URL) as retryable and burned the whole retry budget on them.
            downloadError = typed
        } else if let urlError = error as? URLError {
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
