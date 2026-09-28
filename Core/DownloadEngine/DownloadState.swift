// QELORYX — DownloadEngine
// DownloadState.swift
// State Machine per spec: Queued → Downloading → Paused → Retry → Completed → Failed

import Foundation

public enum AstryxDownloadState: String, Sendable, Equatable, CaseIterable {
    case queued = "Queued"
    case downloading = "Downloading"
    case paused = "Paused"
    case retry = "Retry"
    case completed = "Completed"
    case failed = "Failed"
    case cancelled = "Cancelled"
    
    public var isTerminal: Bool {
        switch self {
        case .completed, .failed, .cancelled:
            return true
        default:
            return false
        }
    }
    
    public var isActive: Bool {
        switch self {
        case .downloading, .retry:
            return true
        default:
            return false
        }
    }
    
    public var canPause: Bool {
        self == .downloading || self == .queued || self == .retry
    }
    
    public var canResume: Bool {
        self == .paused || self == .failed
    }
    
    public var canRetry: Bool {
        self == .failed || self == .paused
    }
}

public enum DownloadError: Error, Sendable, Equatable {
    case networkError(String)
    case fileSystemError(String)
    case cancelled
    case unknown(String)
    
    public var localizedDescription: String {
        switch self {
        case .networkError(let msg): return "Network error: \(msg)"
        case .fileSystemError(let msg): return "File system error: \(msg)"
        case .cancelled: return "Download cancelled"
        case .unknown(let msg): return "Unknown error: \(msg)"
        }
    }
}
