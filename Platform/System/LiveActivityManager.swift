// QELORYX — Platform
// LiveActivityManager.swift
// QEL-012 Player — Dynamic Island + Live Activities

import Foundation

#if canImport(ActivityKit)
import ActivityKit

public struct AstryxPlaybackAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var trackTitle: String
        public var artist: String
        public var album: String
        public var artworkData: Data?
        public var isPlaying: Bool
        public var position: TimeInterval
        public var duration: TimeInterval
        public var progress: Double {
            guard duration > 0 else { return 0 }
            return position / duration
        }
        public init(trackTitle: String, artist: String, album: String, artworkData: Data? = nil, isPlaying: Bool, position: TimeInterval, duration: TimeInterval) {
            self.trackTitle = trackTitle
            self.artist = artist
            self.album = album
            self.artworkData = artworkData
            self.isPlaying = isPlaying
            self.position = position
            self.duration = duration
        }
    }
    public var trackID: String
    public init(trackID: String) { self.trackID = trackID }
}

@available(iOS 16.1, *)
public final class AstryxLiveActivityManager: LiveActivityManagerProtocol, @unchecked Sendable {
    public static let shared = AstryxLiveActivityManager()
    private var currentActivity: Activity<AstryxPlaybackAttributes>?
    private let lock = NSLock()
    public init() {}
    public func startLiveActivity(track: AstryxTrack, isPlaying: Bool, position: TimeInterval) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = AstryxPlaybackAttributes(trackID: track.id)
        let state = AstryxPlaybackAttributes.ContentState(trackTitle: track.title, artist: track.artist, album: track.album, artworkData: track.artworkData, isPlaying: isPlaying, position: position, duration: track.duration)
        do {
            lock.lock()
            if let existing = currentActivity { Task { await existing.end(dismissalPolicy: .immediate) } }
            let activity = try Activity.request(attributes: attributes, contentState: state, pushType: nil)
            currentActivity = activity
            lock.unlock()
        } catch {}
    }
    public func updateLiveActivity(track: AstryxTrack?, isPlaying: Bool, position: TimeInterval, duration: TimeInterval?) {
        guard let activity = currentActivity else { return }
        let dur = duration ?? track?.duration ?? 0
        let newState = AstryxPlaybackAttributes.ContentState(trackTitle: track?.title ?? activity.contentState.trackTitle, artist: track?.artist ?? activity.contentState.artist, album: track?.album ?? activity.contentState.album, artworkData: track?.artworkData ?? activity.contentState.artworkData, isPlaying: isPlaying, position: position, duration: dur)
        Task { await activity.update(using: newState) }
    }
    public func endLiveActivity() {
        lock.lock()
        let activity = currentActivity
        currentActivity = nil
        lock.unlock()
        guard let activity = activity else { return }
        Task { await activity.end(dismissalPolicy: .immediate) }
    }
}

#else

public struct AstryxPlaybackAttributes {
    public struct ContentState {
        public var trackTitle: String
        public var artist: String
        public var album: String
        public var isPlaying: Bool
        public var position: TimeInterval
        public var duration: TimeInterval
        public init(trackTitle: String, artist: String, album: String, isPlaying: Bool, position: TimeInterval, duration: TimeInterval) {
            self.trackTitle = trackTitle
            self.artist = artist
            self.album = album
            self.isPlaying = isPlaying
            self.position = position
            self.duration = duration
        }
    }
    public var trackID: String
    public init(trackID: String) { self.trackID = trackID }
}

public final class AstryxLiveActivityManager: LiveActivityManagerProtocol, @unchecked Sendable {
    public static let shared = AstryxLiveActivityManager()
    public init() {}
    public func startLiveActivity(track: AstryxTrack, isPlaying: Bool, position: TimeInterval) {}
    public func updateLiveActivity(track: AstryxTrack?, isPlaying: Bool, position: TimeInterval, duration: TimeInterval?) {}
    public func endLiveActivity() {}
}

#endif
