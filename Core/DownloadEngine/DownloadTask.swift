// QELORYX — DownloadEngine
// DownloadTask.swift

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
        completedAt: Date? = nil
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
}
