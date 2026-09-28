// QELORYX — DownloadEngine
// DownloadState.swift
// QEL-041 Downloads — Production State Machine Queued→Downloading→Paused→Retry→Completed→Failed

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
    
    public var canCancel: Bool {
        !isTerminal
    }
    
    // State machine validation per spec: Queued → Downloading → Paused → Retry → Completed → Failed
    public func canTransition(to newState: AstryxDownloadState) -> Bool {
        switch (self, newState) {
        case (.queued, .downloading), (.queued, .paused), (.queued, .cancelled), (.queued, .failed):
            return true
        case (.downloading, .paused), (.downloading, .completed), (.downloading, .failed), (.downloading, .cancelled), (.downloading, .retry):
            return true
        case (.paused, .queued), (.paused, .downloading), (.paused, .cancelled), (.paused, .failed), (.paused, .retry):
            return true
        case (.retry, .queued), (.retry, .downloading), (.retry, .paused), (.retry, .failed), (.retry, .cancelled):
            return true
        case (.failed, .queued), (.failed, .retry), (.failed, .cancelled):
            return true
        case (.completed, _), (.cancelled, _):
            return false // Terminal states cannot transition
        default:
            return false
        }
    }
    
    public var displayName: String {
        rawValue
    }
    
    public var icon: String {
        switch self {
        case .queued: return "clock"
        case .downloading: return "arrow.down.circle.fill"
        case .paused: return "pause.circle"
        case .retry: return "arrow.clockwise.circle"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.circle.fill"
        case .cancelled: return "xmark.circle"
        }
    }
}

public enum DownloadError: Error, Sendable, Equatable {
    case networkError(String)
    case fileSystemError(String)
    case cancelled
    case noSpace
    case invalidURL
    case httpError(Int)
    case resumeDataCorrupted
    case unknown(String)
    
    public var localizedDescription: String {
        switch self {
        case .networkError(let msg): return "Network error: \(msg)"
        case .fileSystemError(let msg): return "File system error: \(msg)"
        case .cancelled: return "Download cancelled"
        case .noSpace: return "Not enough disk space"
        case .invalidURL: return "Invalid URL"
        case .httpError(let code): return "HTTP error: \(code)"
        case .resumeDataCorrupted: return "Resume data corrupted"
        case .unknown(let msg): return "Unknown error: \(msg)"
        }
    }
    
    public var isRetryable: Bool {
        switch self {
        case .networkError, .httpError, .unknown, .resumeDataCorrupted:
            return true
        case .fileSystemError, .cancelled, .noSpace, .invalidURL:
            return false
        }
    }
}
