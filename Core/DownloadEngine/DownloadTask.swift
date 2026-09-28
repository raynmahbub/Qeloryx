// QELORYX — DownloadEngine
// DownloadTask.swift
// QEL-041 Downloads — Production with resume, retry, priority, offline optimization

import Foundation

public struct AstryxDownloadTask: Identifiable, Sendable, Equatable {
    public let id: String
    public let trackID: String?
    public let sourceURL: URL
    public let destinationURL: URL
    public var state: AstryxDownloadState
    public var progress: Double // 0.0 - 1.0
    public var bytesDownloaded: Int64
    public var totalBytes: Int64?
    public var priority: DownloadPriority
    public var retryCount: Int
    public var maxRetries: Int
    public var error: DownloadError?
    public var resumeData: Data?
    public var createdAt: Date
    public var startedAt: Date?
    public var completedAt: Date?
    public var artworkURL: URL?
    public var title: String?
    public var artist: String?
    
    public init(
        id: String = UUID().uuidString,
        trackID: String? = nil,
        sourceURL: URL,
        destinationURL: URL,
        state: AstryxDownloadState = .queued,
        progress: Double = 0,
        bytesDownloaded: Int64 = 0,
        totalBytes: Int64? = nil,
        priority: DownloadPriority = .normal,
        retryCount: Int = 0,
        maxRetries: Int = 3,
        error: DownloadError? = nil,
        resumeData: Data? = nil,
        createdAt: Date = Date(),
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        artworkURL: URL? = nil,
        title: String? = nil,
        artist: String? = nil
    ) {
        self.id = id
        self.trackID = trackID
        self.sourceURL = sourceURL
        self.destinationURL = destinationURL
        self.state = state
        self.progress = progress
        self.bytesDownloaded = bytesDownloaded
        self.totalBytes = totalBytes
        self.priority = priority
        self.retryCount = retryCount
        self.maxRetries = maxRetries
        self.error = error
        self.resumeData = resumeData
        self.createdAt = createdAt
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.artworkURL = artworkURL
        self.title = title
        self.artist = artist
    }
    
    public var formattedProgress: String {
        String(format: "%.0f%%", progress * 100)
    }
    
    public var formattedBytes: String {
        let downloaded = ByteCountFormatter.string(fromByteCount: bytesDownloaded, countStyle: .file)
        if let total = totalBytes {
            let totalStr = ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
            return "\(downloaded) / \(totalStr)"
        }
        return downloaded
    }
    
    public var isCompleted: Bool {
        state == .completed
    }
    
    public var canBeRetried: Bool {
        state.canRetry && retryCount < maxRetries
    }
}

public enum DownloadPriority: Int, Sendable, Comparable, CaseIterable {
    case low = 0
    case normal = 1
    case high = 2
    case immediate = 3
    
    public static func < (lhs: DownloadPriority, rhs: DownloadPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    public var displayName: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .immediate: return "Immediate"
        }
    }
}

// MARK: - Download Stats

public struct DownloadStats: Sendable, Equatable {
    public var total: Int
    public var queued: Int
    public var downloading: Int
    public var paused: Int
    public var completed: Int
    public var failed: Int
    public var totalBytes: Int64
    public var downloadedBytes: Int64
    
    public init(total: Int = 0, queued: Int = 0, downloading: Int = 0, paused: Int = 0, completed: Int = 0, failed: Int = 0, totalBytes: Int64 = 0, downloadedBytes: Int64 = 0) {
        self.total = total
        self.queued = queued
        self.downloading = downloading
        self.paused = paused
        self.completed = completed
        self.failed = failed
        self.totalBytes = totalBytes
        self.downloadedBytes = downloadedBytes
    }
    
    public var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }
    
    public var formattedDownloadedSize: String {
        ByteCountFormatter.string(fromByteCount: downloadedBytes, countStyle: .file)
    }
}
