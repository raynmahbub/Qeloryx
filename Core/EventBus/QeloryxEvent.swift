// QELORYX — EventBus
// QeloryxEvent.swift
// Greenfield — Qeloryx Labs
// All domain events are typed, no UIKit/SwiftUI types allowed

import Foundation

// MARK: - QeloryxEvent

/// Central event enum for QELORYX.
/// Loose coupling: Emitters don't know listeners.
public enum QeloryxEvent: Sendable, Equatable {
    
    // MARK: Playback
    case trackStarted(trackID: String, queueID: String)
    case trackPaused(trackID: String, position: TimeInterval)
    case trackResumed(trackID: String, position: TimeInterval)
    case trackEnded(trackID: String, reason: PlaybackEndReason)
    case trackSeeked(trackID: String, from: TimeInterval, to: TimeInterval)
    case queueChanged(queueID: String, version: Int)
    case playbackStateChanged(state: PlaybackStateSnapshot)
    case audioSessionInterrupted(reason: String)
    
    // MARK: Library
    case libraryDidChange(changeType: LibraryChangeType)
    case trackAdded(id: String)
    case trackRemoved(id: String)
    case trackUpdated(id: String)
    case albumAdded(id: String)
    case artistAdded(id: String)
    case playlistChanged(id: String)
    case artworkUpdated(trackID: String)
    case indexingStarted
    case indexingProgress(completed: Int, total: Int)
    case indexingCompleted(newTracks: Int)
    
    // MARK: Search
    case searchIndexUpdated(version: Int)
    case searchQueryChanged(query: String)
    
    // MARK: Download
    case downloadStateChanged(taskID: String, state: DownloadStateSnapshot)
    case downloadProgress(taskID: String, progress: Double)
    case downloadCompleted(taskID: String, trackID: String)
    case downloadFailed(taskID: String, error: String)
    
    // MARK: System
    case appDidEnterBackground
    case appWillEnterForeground
    case storageLowWarning
    case batteryStateChanged(level: Float)
    
    // MARK: Discovery
    case tasteProfileUpdated(profileID: String)
    case timeCapsuleGenerated(date: Date)
    
    // MARK: Spaces
    case spaceQueueChanged(spaceID: String)
    case djHandoffInitiated(spaceID: String, fromUser: String, toUser: String)
    case liveReaction(spaceID: String, reaction: String)
}

// MARK: - Supporting Types

public enum PlaybackEndReason: String, Sendable, Equatable {
    case natural
    case skipped
    case error
    case queueEnded
}

public enum LibraryChangeType: String, Sendable, Equatable {
    case fullReload
    case incremental
    case favorites
    case history
    case metadata
}

public struct PlaybackStateSnapshot: Sendable, Equatable {
    public let trackID: String?
    public let isPlaying: Bool
    public let position: TimeInterval
    public let duration: TimeInterval
    public let queueVersion: Int
    public let shuffleEnabled: Bool
    public let repeatMode: RepeatModeSnapshot
    
    public init(trackID: String?, isPlaying: Bool, position: TimeInterval, duration: TimeInterval, queueVersion: Int, shuffleEnabled: Bool, repeatMode: RepeatModeSnapshot) {
        self.trackID = trackID
        self.isPlaying = isPlaying
        self.position = position
        self.duration = duration
        self.queueVersion = queueVersion
        self.shuffleEnabled = shuffleEnabled
        self.repeatMode = repeatMode
    }
}

public enum RepeatModeSnapshot: String, Sendable, Equatable {
    case off
    case all
    case one
}

public struct DownloadStateSnapshot: Sendable, Equatable {
    public let state: String
    public let progress: Double
    public let error: String?
    
    public init(state: String, progress: Double, error: String? = nil) {
        self.state = state
        self.progress = progress
        self.error = error
    }
}

// MARK: - Event Metadata

public extension QeloryxEvent {
    var name: String {
        switch self {
        case .trackStarted: return "trackStarted"
        case .trackPaused: return "trackPaused"
        case .trackResumed: return "trackResumed"
        case .trackEnded: return "trackEnded"
        case .trackSeeked: return "trackSeeked"
        case .queueChanged: return "queueChanged"
        case .playbackStateChanged: return "playbackStateChanged"
        case .audioSessionInterrupted: return "audioSessionInterrupted"
        case .libraryDidChange: return "libraryDidChange"
        case .trackAdded: return "trackAdded"
        case .trackRemoved: return "trackRemoved"
        case .trackUpdated: return "trackUpdated"
        case .albumAdded: return "albumAdded"
        case .artistAdded: return "artistAdded"
        case .playlistChanged: return "playlistChanged"
        case .artworkUpdated: return "artworkUpdated"
        case .indexingStarted: return "indexingStarted"
        case .indexingProgress: return "indexingProgress"
        case .indexingCompleted: return "indexingCompleted"
        case .searchIndexUpdated: return "searchIndexUpdated"
        case .searchQueryChanged: return "searchQueryChanged"
        case .downloadStateChanged: return "downloadStateChanged"
        case .downloadProgress: return "downloadProgress"
        case .downloadCompleted: return "downloadCompleted"
        case .downloadFailed: return "downloadFailed"
        case .appDidEnterBackground: return "appDidEnterBackground"
        case .appWillEnterForeground: return "appWillEnterForeground"
        case .storageLowWarning: return "storageLowWarning"
        case .batteryStateChanged: return "batteryStateChanged"
        case .tasteProfileUpdated: return "tasteProfileUpdated"
        case .timeCapsuleGenerated: return "timeCapsuleGenerated"
        case .spaceQueueChanged: return "spaceQueueChanged"
        case .djHandoffInitiated: return "djHandoffInitiated"
        case .liveReaction: return "liveReaction"
        }
    }
}
