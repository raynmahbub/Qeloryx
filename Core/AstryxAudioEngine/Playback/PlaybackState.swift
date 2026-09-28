// QELORYX — AstryxAudioEngine
// PlaybackState.swift

import Foundation

// MARK: - PlaybackState

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

public enum AstryxRepeatMode: String, Sendable, CaseIterable, Equatable {
    case off
    case all
    case one
    
    public var next: AstryxRepeatMode {
        switch self {
        case .off: return .all
        case .all: return .one
        case .one: return .off
        }
    }
    
    public var systemImage: String {
        switch self {
        case .off: return "repeat"
        case .all: return "repeat"
        case .one: return "repeat.1"
        }
    }
}

// MARK: - ShuffleMode

public enum AstryxShuffleMode: Sendable, Equatable {
    case off
    case on(seed: Int? = nil)
    
    public var isEnabled: Bool {
        if case .on = self { return true }
        return false
    }
}
