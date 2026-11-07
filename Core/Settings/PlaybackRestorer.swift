// QELORYX — Settings
// PlaybackRestorer.swift
//
// BUG: "playback restoration" was listed as a feature but no queue, track or
// position was ever persisted, so every launch started empty.
//
// The queue and position are snapshotted on a timer and on lifecycle events,
// then restored **paused** — never auto-playing. An app that starts making
// noise on launch is worse than one that forgot where it was.

import Foundation

public struct PlaybackResumePoint: Sendable, Equatable {
    public var trackIDs: [String]
    public var startIndex: Int
    public var position: TimeInterval
    public var shuffleEnabled: Bool
    public var repeatMode: AstryxRepeatMode
    public var savedAt: Date

    public init(
        trackIDs: [String],
        startIndex: Int,
        position: TimeInterval,
        shuffleEnabled: Bool,
        repeatMode: AstryxRepeatMode,
        savedAt: Date = Date()
    ) {
        self.trackIDs = trackIDs
        self.startIndex = startIndex
        self.position = position
        self.shuffleEnabled = shuffleEnabled
        self.repeatMode = repeatMode
        self.savedAt = savedAt
    }
}

public protocol PlaybackResumeStore: Sendable {
    func load() -> PlaybackResumePoint?
    func save(_ point: PlaybackResumePoint)
    func clear()
}

public final class UserDefaultsPlaybackResumeStore: PlaybackResumeStore, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = "qeloryx.playback.resumePoint") {
        self.defaults = defaults
        self.key = key
    }

    public func load() -> PlaybackResumePoint? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(PlaybackResumePoint.self, from: data)
    }

    public func save(_ point: PlaybackResumePoint) {
        guard let data = try? JSONEncoder().encode(point) else { return }
        defaults.set(data, forKey: key)
    }

    public func clear() {
        defaults.removeObject(forKey: key)
    }
}

public final class InMemoryPlaybackResumeStore: PlaybackResumeStore, @unchecked Sendable {
    private var point: PlaybackResumePoint?
    private let lock = NSLock()

    public init() {}

    public func load() -> PlaybackResumePoint? {
        lock.lock(); defer { lock.unlock() }
        return point
    }

    public func save(_ point: PlaybackResumePoint) {
        lock.lock(); self.point = point; lock.unlock()
    }

    public func clear() {
        lock.lock(); point = nil; lock.unlock()
    }
}

/// `Codable` shim so `AstryxRepeatMode` survives a round-trip.
extension PlaybackResumePoint: Codable {
    private enum CodingKeys: String, CodingKey {
        case trackIDs, startIndex, position, shuffleEnabled, repeatMode, savedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        trackIDs = try container.decode([String].self, forKey: .trackIDs)
        startIndex = try container.decode(Int.self, forKey: .startIndex)
        position = try container.decode(TimeInterval.self, forKey: .position)
        shuffleEnabled = try container.decode(Bool.self, forKey: .shuffleEnabled)
        let rawRepeat = try container.decode(String.self, forKey: .repeatMode)
        repeatMode = AstryxRepeatMode(rawValue: rawRepeat) ?? .off
        savedAt = try container.decode(Date.self, forKey: .savedAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(trackIDs, forKey: .trackIDs)
        try container.encode(startIndex, forKey: .startIndex)
        try container.encode(position, forKey: .position)
        try container.encode(shuffleEnabled, forKey: .shuffleEnabled)
        try container.encode(repeatMode.rawValue, forKey: .repeatMode)
        try container.encode(savedAt, forKey: .savedAt)
    }
}

public final class PlaybackRestorer: @unchecked Sendable {

    private let store: any PlaybackResumeStore
    private let lock = NSLock()

    public init(store: any PlaybackResumeStore = UserDefaultsPlaybackResumeStore()) {
        self.store = store
    }

    /// Captures the current queue so the next launch can offer to resume.
    public func capture(from engine: any AstryxAudioEngineProtocol) {
        let queue = engine.currentQueue
        guard !queue.items.isEmpty else { return }
        let point = PlaybackResumePoint(
            trackIDs: queue.items.map(\.trackID),
            startIndex: queue.currentIndex ?? 0,
            position: engine.playbackState.position,
            shuffleEnabled: queue.shuffleEnabled,
            repeatMode: queue.repeatMode
        )
        lock.lock()
        store.save(point)
        lock.unlock()
    }

    public var resumePoint: PlaybackResumePoint? {
        lock.lock(); defer { lock.unlock() }
        return store.load()
    }

    /// Rebuilds the queue without starting playback.
    ///
    /// The engine is put into `.paused` at the saved position so the first tap
    /// in the mini player resumes where the listener left off.
    public func restore(into engine: any AstryxAudioEngineProtocol, paused: Bool = true) async {
        guard let point = resumePoint, !point.trackIDs.isEmpty else { return }
        // Clamp rather than bail: a stale index (queue edited since the snapshot)
        // must still restore the queue, not silently skip restoration entirely.
        let startIndex = min(max(point.startIndex, 0), point.trackIDs.count - 1)
        let trackID = point.trackIDs[startIndex]

        // Rebuild the queue *without* starting playback.
        //
        // This used to call `.playQueue`, which loads the file into the adapter
        // and calls `play()` — the state was then overwritten to `.paused`
        // while audio kept running. `restoreQueue` is a queue-only operation
        // that never touches the adapter.
        await engine.restoreQueue(trackIDs: point.trackIDs, startIndex: startIndex)
        if point.shuffleEnabled {
            try? await engine.handle(command: .setShuffle(true))
        }
        if point.repeatMode != .off {
            try? await engine.handle(command: .setRepeat(point.repeatMode))
        }

        if paused {
            // Deliberately does not load audio: nothing plays until the user asks.
            engine.restorePausedState(trackID: trackID, position: point.position)
        } else {
            try? await engine.handle(command: .play(trackID: trackID))
            try? await engine.handle(command: .seek(to: point.position))
        }
    }

    public func clear() {
        lock.lock()
        store.clear()
        lock.unlock()
    }
}
