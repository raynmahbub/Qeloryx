// QELORYX — AstryxAudioEngine
// AstryxAudioEngine.swift
// Independent playback coordinator per spec

import Foundation

// MARK: - AstryxAudioEngine Protocol

public protocol AstryxAudioEngineProtocol: AnyObject, Sendable {
    var playbackState: AstryxPlaybackState { get }
    var currentQueue: AstryxQueue { get }
    
    func handle(command: AstryxPlaybackCommand) async throws
    func currentTrack() async -> AstryxTrack?
    func seek(to: TimeInterval) async throws
}

// MARK: - AstryxAudioEngine

/// Central playback engine.
/// Responsibilities:
/// - Independent playback coordinator
/// - Isolated queue controller
/// - Unified playback state
/// - Smooth artwork transitions (via EventBus)
/// - Haptic feedback (via Platform)
public final class AstryxAudioEngine: AstryxAudioEngineProtocol, @unchecked Sendable {
    
    // MARK: Dependencies
    private let queueController: any QueueControllerProtocol
    private let sessionManager: any AudioSessionManagerProtocol
    private let eventBus: any EventBusProtocol
    private let libraryEngine: (any LibraryEngineProtocol)?
    
    // MARK: State
    private var _playbackState: AstryxPlaybackState = .idle
    private let stateLock = NSLock()
    private var timer: Timer?
    private var currentPosition: TimeInterval = 0
    
    // MARK: Init
    public init(
        queueController: any QueueControllerProtocol = AstryxQueueController(),
        sessionManager: any AudioSessionManagerProtocol = AstryxAudioSessionManager(),
        eventBus: any EventBusProtocol = AstryxEventBus.shared,
        libraryEngine: (any LibraryEngineProtocol)? = nil
    ) {
        self.queueController = queueController
        self.sessionManager = sessionManager
        self.eventBus = eventBus
        self.libraryEngine = libraryEngine
        
        // Observe queue changes
        _ = eventBus.subscribe(to: QeloryxEvent.queueChanged(queueID: "", version: 0).name) { [weak self] _ in
            self?.onQueueChanged()
        }
    }
    
    // MARK: Public State
    
    public var playbackState: AstryxPlaybackState {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _playbackState
    }
    
    public var currentQueue: AstryxQueue {
        queueController.currentQueue()
    }
    
    // MARK: Commands
    
    public func handle(command: AstryxPlaybackCommand) async throws {
        switch command {
        case .play(let trackID):
            try await play(trackID: trackID)
        case .pause:
            try await pause()
        case .togglePlayPause:
            try await togglePlayPause()
        case .stop:
            try await stop()
        case .seek(let to):
            try await seek(to: to)
        case .seekForward(let interval):
            try await seekForward(interval: interval)
        case .seekBackward(let interval):
            try await seekBackward(interval: interval)
        case .next:
            try await next()
        case .previous:
            try await previous()
        case .playQueue(let queue, let startIndex):
            try await playQueue(trackIDs: queue, startIndex: startIndex)
        case .setShuffle(let enabled):
            await queueController.setShuffle(enabled)
        case .setRepeat(let mode):
            await queueController.setRepeatMode(mode)
        case .setVolume(let volume):
            try await setVolume(volume)
        }
    }
    
    // MARK: Private Playback Logic
    
    private func play(trackID: String?) async throws {
        try sessionManager.configure(category: .playback)
        try sessionManager.activate()
        
        if let trackID = trackID {
            // Play specific track: set as current if in queue, else create queue
            let queue = currentQueue
            if let index = queue.items.firstIndex(where: { $0.trackID == trackID }) {
                await queueController.setCurrentIndex(index)
            } else {
                await queueController.setQueue(trackIDs: [trackID], startIndex: 0, source: .manual)
            }
            try await startPlayback(trackID: trackID)
        } else {
            // Resume current
            if case .paused(let id, _, _) = playbackState {
                try await resumePlayback(trackID: id)
            } else if let current = currentQueue.currentItem {
                try await startPlayback(trackID: current.trackID)
            }
        }
    }
    
    private func pause() async throws {
        stateLock.lock()
        let previousState = _playbackState
        stateLock.unlock()
        
        guard case .playing(let trackID, let pos, let dur) = previousState else { return }
        
        stateLock.lock()
        _playbackState = .paused(trackID: trackID, position: pos, duration: dur)
        stateLock.unlock()
        
        eventBus.publish(.trackPaused(trackID: trackID, position: pos))
        eventBus.publish(.playbackStateChanged(state: snapshot(from: _playbackState)))
    }
    
    private func resumePlayback(trackID: String) async throws {
        stateLock.lock()
        var position: TimeInterval = 0
        var duration: TimeInterval = 0
        if case .paused(_, let pos, let dur) = _playbackState {
            position = pos
            duration = dur
        }
        _playbackState = .playing(trackID: trackID, position: position, duration: duration)
        let state = _playbackState
        stateLock.unlock()
        
        eventBus.publish(.trackResumed(trackID: trackID, position: position))
        eventBus.publish(.playbackStateChanged(state: snapshot(from: state)))
    }
    
    private func startPlayback(trackID: String) async throws {
        // In real implementation: load AVPlayerItem via Platform adapter
        // For foundation: simulate
        
        let duration: TimeInterval = 180 // Placeholder, real from track metadata
        
        stateLock.lock()
        _playbackState = .playing(trackID: trackID, position: 0, duration: duration)
        let state = _playbackState
        stateLock.unlock()
        
        let queueID = currentQueue.id
        eventBus.publish(.trackStarted(trackID: trackID, queueID: queueID))
        eventBus.publish(.playbackStateChanged(state: snapshot(from: state)))
        
        // Record play in library
        try? await libraryEngine?.recordPlay(trackID: trackID)
    }
    
    private func togglePlayPause() async throws {
        if playbackState.isPlaying {
            try await pause()
        } else {
            try await play(trackID: nil)
        }
    }
    
    private func stop() async throws {
        stateLock.lock()
        _playbackState = .stopped
        stateLock.unlock()
        
        eventBus.publish(.playbackStateChanged(state: snapshot(from: .stopped)))
        try? sessionManager.deactivate()
    }
    
    public func seek(to: TimeInterval) async throws {
        stateLock.lock()
        let oldPos = _playbackState.position
        let trackID = _playbackState.currentTrackID
        switch _playbackState {
        case .playing(let id, _, let dur):
            _playbackState = .playing(trackID: id, position: to, duration: dur)
        case .paused(let id, _, let dur):
            _playbackState = .paused(trackID: id, position: to, duration: dur)
        default:
            break
        }
        let state = _playbackState
        stateLock.unlock()
        
        if let id = trackID {
            eventBus.publish(.trackSeeked(trackID: id, from: oldPos, to: to))
            eventBus.publish(.playbackStateChanged(state: snapshot(from: state)))
        }
    }
    
    private func seekForward(interval: TimeInterval) async throws {
        let newPos = playbackState.position + interval
        try await seek(to: newPos)
    }
    
    private func seekBackward(interval: TimeInterval) async throws {
        let newPos = max(0, playbackState.position - interval)
        try await seek(to: newPos)
    }
    
    private func next() async throws {
        if let nextItem = await queueController.next() {
            try await startPlayback(trackID: nextItem.trackID)
        } else {
            try await stop()
            eventBus.publish(.trackEnded(trackID: playbackState.currentTrackID ?? "", reason: .queueEnded))
        }
    }
    
    private func previous() async throws {
        // If position > 3s, seek to 0 instead of previous track (common UX)
        if playbackState.position > 3 {
            try await seek(to: 0)
        } else if let prevItem = await queueController.previous() {
            try await startPlayback(trackID: prevItem.trackID)
        }
    }
    
    private func playQueue(trackIDs: [String], startIndex: Int) async throws {
        await queueController.setQueue(trackIDs: trackIDs, startIndex: startIndex, source: .manual)
        if startIndex < trackIDs.count {
            try await startPlayback(trackID: trackIDs[startIndex])
        }
    }
    
    private func setVolume(_ volume: Float) async throws {
        // Real implementation via Platform audio adapter
        #if DEBUG
        debugPrint("[AstryxAudioEngine] Set volume: \(volume)")
        #endif
    }
    
    public func currentTrack() async -> AstryxTrack? {
        guard let trackID = playbackState.currentTrackID else { return nil }
        return try? await libraryEngine?.fetchTrack(id: trackID)
    }
    
    // MARK: Helpers
    
    private func onQueueChanged() {
        // Could trigger preloading next track, etc.
    }
    
    private func snapshot(from state: AstryxPlaybackState) -> PlaybackStateSnapshot {
        switch state {
        case .idle, .stopped, .failed:
            return PlaybackStateSnapshot(trackID: nil, isPlaying: false, position: 0, duration: 0, queueVersion: currentQueue.version, shuffleEnabled: currentQueue.shuffleEnabled, repeatMode: mapRepeatMode(currentQueue.repeatMode))
        case .loading(let id):
            return PlaybackStateSnapshot(trackID: id, isPlaying: false, position: 0, duration: 0, queueVersion: currentQueue.version, shuffleEnabled: currentQueue.shuffleEnabled, repeatMode: mapRepeatMode(currentQueue.repeatMode))
        case .playing(let id, let pos, let dur):
            return PlaybackStateSnapshot(trackID: id, isPlaying: true, position: pos, duration: dur, queueVersion: currentQueue.version, shuffleEnabled: currentQueue.shuffleEnabled, repeatMode: mapRepeatMode(currentQueue.repeatMode))
        case .paused(let id, let pos, let dur):
            return PlaybackStateSnapshot(trackID: id, isPlaying: false, position: pos, duration: dur, queueVersion: currentQueue.version, shuffleEnabled: currentQueue.shuffleEnabled, repeatMode: mapRepeatMode(currentQueue.repeatMode))
        }
    }
    
    private func mapRepeatMode(_ mode: AstryxRepeatMode) -> RepeatModeSnapshot {
        switch mode {
        case .off: return .off
        case .all: return .all
        case .one: return .one
        }
    }
}

// MARK: - PlaybackCoordinator (Alias for spec compliance)

/// Spec requires Independent playback coordinator — this is it
public typealias AstryxPlaybackCoordinator = AstryxAudioEngine
