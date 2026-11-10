// QELORYX — Models/Playback
// PlaybackState.swift
// Domain playback state + typed playback errors.

import Foundation

public enum AstryxPlaybackState: Sendable, Equatable {
    case idle
    case loading(trackID: String)
    case playing(trackID: String, position: TimeInterval, duration: TimeInterval)
    case paused(trackID: String, position: TimeInterval, duration: TimeInterval)
    case stopped
    case failed(trackID: String?, error: String)

    public var isPlaying: Bool {
        if case .playing = self { return true }
        return false
    }

    public var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }

    public var currentTrackID: String? {
        switch self {
        case .loading(let id): return id
        case .playing(let id, _, _): return id
        case .paused(let id, _, _): return id
        case .failed(let id, _): return id
        default: return nil
        }
    }

    public var position: TimeInterval {
        switch self {
        case .playing(_, let pos, _): return pos
        case .paused(_, let pos, _): return pos
        default: return 0
        }
    }

    public var duration: TimeInterval {
        switch self {
        case .playing(_, _, let dur): return dur
        case .paused(_, _, let dur): return dur
        default: return 0
        }
    }
}

// MARK: - RepeatMode

public enum PlaybackError: Error, LocalizedError, Equatable {
    /// No resolver was configured and no library engine was supplied.
    case noPlaybackSource
    /// The track ID could not be resolved to a file.
    case trackNotResolved(trackID: String)
    /// The audio adapter rejected the file (missing, corrupt, unsupported).
    case loadFailed(trackID: String, reason: String)
    /// Nothing is loaded, so there is nothing to resume.
    case nothingToResume
    /// A remote command did not complete within its deadline.
    case commandTimedOut

    public var errorDescription: String? {
        switch self {
        case .noPlaybackSource:
            return "No playback source is configured."
        case .trackNotResolved(let trackID):
            return "Track could not be resolved: \(trackID)"
        case .loadFailed(_, let reason):
            return "Audio file could not be loaded: \(reason)"
        case .nothingToResume:
            return "Nothing is loaded to resume."
        case .commandTimedOut:
            return "The playback command timed out."
        }
    }
}
