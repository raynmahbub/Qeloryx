// QELORYX — Platform
// DownloadSessionManager.swift
// QEL-041 Downloads — Production URLSession with resume, background support, offline optimization

#if canImport(QeloryxCore)
import QeloryxCore
#endif

import Foundation

// MARK: - Download Session Manager — Platform Layer — Implements Core protocol

public final class AstryxDownloadSessionManager: NSObject, DownloadSessionProtocol, @unchecked Sendable {
    
    /// Built in `init`. `!` was a latent crash if `setupSession` ever failed to
    /// run; the implicitly-unwrapped optional is replaced by a lazy closure-free
    /// assignment that the compiler can verify.
    private var session: URLSession
    private var allowsCellularAccess = true
    private var activeTasks: [String: URLSessionDownloadTask] = [:] // taskID -> URLSessionTask
    private var taskIDMap: [Int: String] = [:] // URLSession taskIdentifier -> taskID
    private let lock = NSLock()
    
    public weak var delegate: (any DownloadSessionDelegate)?
    
    /// Stable identifier. A background `URLSession` is reattached to the app by
    /// this string, so it must never be random: a per-launch UUID orphaned every
    /// in-flight download (BUG-08).
    public static let backgroundSessionIdentifier = "com.qeloryx.downloads"

    public override init() {
        session = URLSession(configuration: .default)
        super.init()
        setupSession()
    }

    private func setupSession() {
        let config = URLSessionConfiguration.background(withIdentifier: Self.backgroundSessionIdentifier)
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        // Cellular access is a user preference; the engine sets this through
        // `setAllowsCellularAccess` rather than hard-coding `true` (BUG: no
        // Wi-Fi-only setting existed).
        config.allowsCellularAccess = allowsCellularAccess
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300

        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    /// Wi-Fi-only downloads. Applies to new tasks; iOS does not allow mutating
    /// an in-flight background task's policy.
    public func setAllowsCellularAccess(_ allowed: Bool) {
        guard allowsCellularAccess != allowed else { return }
        allowsCellularAccess = allowed
        setupSession()
    }
    
    public func startDownload(taskID: String, from url: URL, resumeData: Data? = nil) {
        lock.lock()
        defer { lock.unlock() }
        
        let downloadTask: URLSessionDownloadTask
        
        if let resumeData = resumeData {
            downloadTask = session.downloadTask(withResumeData: resumeData)
        } else {
            downloadTask = session.downloadTask(with: url)
        }
        
        activeTasks[taskID] = downloadTask
        taskIDMap[downloadTask.taskIdentifier] = taskID
        downloadTask.resume()
        
        #if DEBUG
        debugPrint("[DownloadSession] Started \(taskID) from \(url.absoluteString)")
        #endif
    }
    
    public func pauseDownload(taskID: String, completion: @escaping (Data?) -> Void) {
        lock.lock()
        guard let task = activeTasks[taskID] else {
            lock.unlock()
            completion(nil)
            return
        }
        lock.unlock()
        
        task.cancel { resumeData in
            self.lock.lock()
            self.activeTasks.removeValue(forKey: taskID)
            self.taskIDMap.removeValue(forKey: task.taskIdentifier)
            self.lock.unlock()
            
            completion(resumeData)
            
            #if DEBUG
            debugPrint("[DownloadSession] Paused \(taskID), resumeData: \(resumeData != nil)")
            #endif
        }
    }
    
    public func cancelDownload(taskID: String) {
        lock.lock()
        guard let task = activeTasks[taskID] else {
            lock.unlock()
            return
        }
        activeTasks.removeValue(forKey: taskID)
        taskIDMap.removeValue(forKey: task.taskIdentifier)
        lock.unlock()
        
        task.cancel()
        
        #if DEBUG
        debugPrint("[DownloadSession] Cancelled \(taskID)")
        #endif
    }
    
    public func checkDiskSpace(requiredBytes: Int64) -> Bool {
        // Offline optimization: check available disk space
        do {
            let fileURL = URL(fileURLWithPath: NSHomeDirectory())
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            if let available = values.volumeAvailableCapacity {
                return Int64(available) > requiredBytes + 100_000_000 // Keep 100MB buffer
            }
        } catch {
            #if DEBUG
            debugPrint("[DownloadSession] Disk space check failed: \(error)")
            #endif
        }
        return true // Assume ok if check fails
    }
}

// MARK: - URLSessionDownloadDelegate

extension AstryxDownloadSessionManager: URLSessionDownloadDelegate {
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        lock.lock()
        guard let taskID = taskIDMap[downloadTask.taskIdentifier] else {
            lock.unlock()
            return
        }
        lock.unlock()
        
        delegate?.downloadDidProgress(taskID: taskID, bytesWritten: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpected: totalBytesExpectedToWrite)
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        lock.lock()
        guard let taskID = taskIDMap[downloadTask.taskIdentifier] else {
            lock.unlock()
            return
        }
        activeTasks.removeValue(forKey: taskID)
        taskIDMap.removeValue(forKey: downloadTask.taskIdentifier)
        lock.unlock()
        
        delegate?.downloadDidComplete(taskID: taskID, location: location)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else { return }
        
        lock.lock()
        guard let taskID = taskIDMap[task.taskIdentifier] else {
            lock.unlock()
            return
        }
        activeTasks.removeValue(forKey: taskID)
        taskIDMap.removeValue(forKey: task.taskIdentifier)
        lock.unlock()
        
        // Extract resume data if available
        var resumeData: Data?
        if let nsError = error as NSError?, let data = nsError.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
            resumeData = data
        }
        
        delegate?.downloadDidFail(taskID: taskID, error: error, resumeData: resumeData)
    }
    
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        // Background session finished — could call completion handler stored from AppDelegate
        #if DEBUG
        debugPrint("[DownloadSession] Background events finished")
        #endif
    }
}
