// QELORYX — Services/Providers
// ScrobbleProvider.swift
// Feature benchmark: Last.fm scrobbling (Last Wave, Petrichor, Feishin)
// Original Qeloryx implementation — Last.fm scrobble rules + offline pending queue

import Foundation

// MARK: - Scrobble Entry

/// One playback event eligible for scrobbling.
public struct ScrobbleEntry: Sendable, Equatable, Identifiable {
    public let id: String
    public var trackID: String
    public var title: String
    public var artist: String
    public var album: String
    public var duration: TimeInterval
    /// When playback of this track started.
    public var startedAt: Date
    /// How long the track was actually played.
    public var playDuration: TimeInterval
    
    public init(
        id: String = UUID().uuidString,
        trackID: String,
        title: String,
        artist: String,
        album: String = "",
        duration: TimeInterval,
        startedAt: Date = Date(),
        playDuration: TimeInterval = 0
    ) {
        self.id = id
        self.trackID = trackID
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.startedAt = startedAt
        self.playDuration = playDuration
    }
    
    public init(track: AstryxTrack, startedAt: Date = Date(), playDuration: TimeInterval = 0) {
        self.init(
            trackID: track.id,
            title: track.title,
            artist: track.artist,
            album: track.album,
            duration: track.duration,
            startedAt: startedAt,
            playDuration: playDuration
        )
    }
}

// MARK: - Scrobble Rules (Last.fm compatible)

public enum ScrobbleRules {
    /// Tracks shorter than this are never scrobbled (Last.fm: 30 seconds).
    public static let minimumTrackDuration: TimeInterval = 30
    /// Hard cap: scrobble after 4 minutes regardless of track length (Last.fm rule).
    public static let maxPlayDuration: TimeInterval = 240
    /// Fraction of the track that must be played (Last.fm: 50%).
    public static let requiredFraction: Double = 0.5
    
    /// Last.fm rule: scrobble when the track has been played for at least half
    /// its duration, or for 4 minutes — whichever occurs first. Tracks under 30s never count.
    public static func shouldScrobble(_ entry: ScrobbleEntry) -> Bool {
        guard entry.duration >= minimumTrackDuration else { return false }
        let threshold = min(entry.duration * requiredFraction, maxPlayDuration)
        return entry.playDuration >= threshold
    }
}

// MARK: - Scrobble Provider

public protocol ScrobbleProviderProtocol: Provider {
    /// Announce the currently playing track ("now playing").
    func nowPlaying(_ entry: ScrobbleEntry) async
    /// Submit a completed play. Returns true when the entry qualifies and was accepted.
    func scrobble(_ entry: ScrobbleEntry) async -> Bool
    /// Entries accepted but not yet delivered (offline buffer).
    func pendingScrobbles() async -> [ScrobbleEntry]
    /// Attempt to deliver pending scrobbles; returns how many were delivered.
    func flush() async -> Int
}

/// Offline-first scrobble provider: applies Last.fm rules, buffers accepted
/// scrobbles locally, and delivers them when a transport is attached.
public final class AstryxScrobbleProvider: ScrobbleProviderProtocol, @unchecked Sendable {
    
    public let id = "com.qeloryx.provider.scrobble.local"
    public let name = "Local Scrobble Provider"
    
    private var pending: [ScrobbleEntry] = []
    private var nowPlayingEntry: ScrobbleEntry?
    private let lock = NSLock()
    /// Optional transport: called for each accepted scrobble during flush.
    public var transport: (@Sendable (ScrobbleEntry) async -> Bool)?
    
    public init() {}
    
    public func nowPlaying(_ entry: ScrobbleEntry) async {
        lock.lock()
        nowPlayingEntry = entry
        lock.unlock()
    }
    
    public func scrobble(_ entry: ScrobbleEntry) async -> Bool {
        guard ScrobbleRules.shouldScrobble(entry) else { return false }
        lock.lock()
        pending.append(entry)
        lock.unlock()
        return true
    }
    
    public func pendingScrobbles() async -> [ScrobbleEntry] {
        lock.lock()
        defer { lock.unlock() }
        return pending
    }
    
    public func flush() async -> Int {
        let batch: [ScrobbleEntry]
        lock.lock()
        batch = pending
        lock.unlock()
        guard let transport else { return 0 }
        var delivered = 0
        for entry in batch {
            if await transport(entry) { delivered += 1 }
        }
        if delivered == batch.count {
            lock.lock()
            pending.removeAll()
            lock.unlock()
        }
        return delivered
    }
}
