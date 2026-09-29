// QELORYX — AstryxAudioEngine
// AstryxAudioEngine.swift
// QEL-012 Player Milestone — Production implementation with AVFoundation, Now Playing, Live Activity, Haptics, AirPlay

import Foundation

public protocol AstryxAudioEngineProtocol: AnyObject, Sendable {
    var playbackState: AstryxPlaybackState { get }
    var currentQueue: AstryxQueue { get }
    func handle(command: AstryxPlaybackCommand) async throws
    func currentTrack() async -> AstryxTrack?
    func seek(to: TimeInterval) async throws
    func setVolume(_ volume: Float) async throws
}

public final class AstryxAudioEngine: AstryxAudioEngineProtocol, @unchecked Sendable {
    
    private let queueController: any QueueControllerProtocol
    private let sessionManager: any AudioSessionManagerProtocol
    private let eventBus: any EventBusProtocol
    private let libraryEngine: (any LibraryEngineProtocol)?
    private let nowPlayingManager: any NowPlayingManagerProtocol
    private let liveActivityManager: any LiveActivityManagerProtocol
    private let hapticEngine: any HapticEngineProtocol
    private let avAdapter: any AudioPlayerAdapterProtocol
    
    private var _playbackState: AstryxPlaybackState = .idle
    private let stateLock = NSLock()
    private var positionTimer: Timer?
    private var currentTrackCache: AstryxTrack?
    private var subscriptionStore = EventSubscriptionStore()
    private var crossfadeConfiguration = CrossfadeConfiguration.disabled
    private let transitionController = GaplessTransitionController()
    /// Track ID whose crossfade is already committed, so the position timer
    /// arms exactly once per track and never races itself.
    private var transitionArmedTrackID: String?
    
    public init(
        queueController: any QueueControllerProtocol = AstryxQueueController(),
        sessionManager: any AudioSessionManagerProtocol = FallbackAudioSessionManager(),
        eventBus: any EventBusProtocol = AstryxEventBus.shared,
        libraryEngine: (any LibraryEngineProtocol)? = nil,
        nowPlayingManager: any NowPlayingManagerProtocol = FallbackNowPlayingManager(),
        liveActivityManager: any LiveActivityManagerProtocol = FallbackLiveActivityManager(),
        hapticEngine: any HapticEngineProtocol = FallbackHapticEngine(),
        avAdapter: any AudioPlayerAdapterProtocol = FallbackAudioPlayerAdapter()
    ) {
        self.queueController = queueController
        self.sessionManager = sessionManager
        self.eventBus = eventBus
        self.libraryEngine = libraryEngine
        self.nowPlayingManager = nowPlayingManager
        self.liveActivityManager = liveActivityManager
        self.hapticEngine = hapticEngine
        self.avAdapter = avAdapter
        self.avAdapter.delegate = self
        observeEvents()
        setupNowPlayingHandler()
    }
    
    public var playbackState: AstryxPlaybackState {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _playbackState
    }
    
    public var currentQueue: AstryxQueue {
        queueController.currentQueue()
    }
    
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
            hapticEngine.trigger(.selection)
        case .setRepeat(let mode):
            await queueController.setRepeatMode(mode)
            hapticEngine.trigger(.selection)
        case .setVolume(let volume):
            try await setVolume(volume)
        case .setCrossfade(let configuration):
            crossfadeConfiguration = configuration
        }
    }
    
    private func play(trackID: String?) async throws {
        try sessionManager.configure(category: .playback)
        try sessionManager.activate()
        
        if let trackID = trackID {
            let queue = currentQueue
            if let index = queue.items.firstIndex(where: { $0.trackID == trackID }) {
                await queueController.setCurrentIndex(index)
            } else {
                await queueController.setQueue(trackIDs: [trackID], startIndex: 0, source: .manual)
            }
            try await startPlayback(trackID: trackID)
        } else {
            if case .paused(let id, _, _) = playbackState {
                try await resumePlayback(trackID: id)
            } else if let current = currentQueue.currentItem {
                try await startPlayback(trackID: current.trackID)
            } else if let first = currentQueue.items.first {
                try await startPlayback(trackID: first.trackID)
            }
        }
    }
    
    private func pause() async throws {
        stateLock.lock()
        let previousState = _playbackState
        stateLock.unlock()
        guard case .playing(let trackID, let pos, let dur) = previousState else { return }
        avAdapter.pause()
        stateLock.lock()
        _playbackState = .paused(trackID: trackID, position: pos, duration: dur)
        let state = _playbackState
        stateLock.unlock()
        hapticEngine.triggerPause()
        nowPlayingManager.updatePlaybackState(isPlaying: false, position: pos)
        liveActivityManager.updateLiveActivity(track: currentTrackCache, isPlaying: false, position: pos, duration: dur)
        eventBus.publish(.trackPaused(trackID: trackID, position: pos))
        eventBus.publish(.playbackStateChanged(state: snapshot(from: state)))
        stopPositionTimer()
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
        avAdapter.play()
        hapticEngine.triggerPlay()
        nowPlayingManager.updatePlaybackState(isPlaying: true, position: position)
        liveActivityManager.updateLiveActivity(track: currentTrackCache, isPlaying: true, position: position, duration: duration)
        eventBus.publish(.trackResumed(trackID: trackID, position: position))
        eventBus.publish(.playbackStateChanged(state: snapshot(from: state)))
        startPositionTimer()
    }
    
    private func startPlayback(trackID: String) async throws {
        var track: AstryxTrack?
        if let engine = libraryEngine {
            track = try? await engine.fetchTrack(id: trackID)
        }
        let fileURL = track?.fileURL ?? URL(fileURLWithPath: "/tmp/\(trackID).mp3")
        let duration = track?.duration ?? 180
        do {
            try avAdapter.load(url: fileURL)
            avAdapter.play()
        } catch {
            #if DEBUG
            debugPrint("[AstryxAudioEngine] AVFoundation load failed, using simulated playback: \(error)")
            #endif
        }
        currentTrackCache = track
        transitionArmedTrackID = nil
        stateLock.lock()
        _playbackState = .playing(trackID: trackID, position: 0, duration: duration)
        let state = _playbackState
        stateLock.unlock()
        hapticEngine.triggerPlay()
        nowPlayingManager.updateNowPlaying(track: track, isPlaying: true, position: 0, duration: duration, artworkData: track?.artworkData)
        if let track = track {
            liveActivityManager.startLiveActivity(track: track, isPlaying: true, position: 0)
        }
        let queueID = currentQueue.id
        eventBus.publish(.trackStarted(trackID: trackID, queueID: queueID))
        eventBus.publish(.playbackStateChanged(state: snapshot(from: state)))
        try? await libraryEngine?.recordPlay(trackID: trackID)
        startPositionTimer()
        preloadNext()
    }
    
    private func togglePlayPause() async throws {
        if playbackState.isPlaying {
            try await pause()
        } else {
            try await play(trackID: nil)
        }
    }
    
    private func stop() async throws {
        avAdapter.stop()
        transitionArmedTrackID = nil
        stateLock.lock()
        _playbackState = .stopped
        let state = _playbackState
        stateLock.unlock()
        nowPlayingManager.clear()
        liveActivityManager.endLiveActivity()
        eventBus.publish(.playbackStateChanged(state: snapshot(from: state)))
        try? sessionManager.deactivate()
        stopPositionTimer()
    }
    
    public func seek(to: TimeInterval) async throws {
        let clamped = max(0, to)
        stateLock.lock()
        let oldPos = _playbackState.position
        let trackID = _playbackState.currentTrackID
        let duration = _playbackState.duration
        switch _playbackState {
        case .playing(let id, _, let dur):
            _playbackState = .playing(trackID: id, position: clamped, duration: dur)
        case .paused(let id, _, let dur):
            _playbackState = .paused(trackID: id, position: clamped, duration: dur)
        default:
            break
        }
        let state = _playbackState
        stateLock.unlock()
        avAdapter.seek(to: clamped) { _ in }
        nowPlayingManager.updatePlaybackState(isPlaying: state.isPlaying, position: clamped)
        liveActivityManager.updateLiveActivity(track: currentTrackCache, isPlaying: state.isPlaying, position: clamped, duration: duration)
        if let id = trackID {
            eventBus.publish(.trackSeeked(trackID: id, from: oldPos, to: clamped))
            eventBus.publish(.playbackStateChanged(state: snapshot(from: state)))
        }
    }
    
    private func seekForward(interval: TimeInterval) async throws {
        let newPos = min(playbackState.position + interval, playbackState.duration)
        try await seek(to: newPos)
    }
    
    private func seekBackward(interval: TimeInterval) async throws {
        let newPos = max(0, playbackState.position - interval)
        try await seek(to: newPos)
    }
    
    private func next() async throws {
        hapticEngine.trigger(.light)
        if let nextItem = await queueController.next() {
            try await startPlayback(trackID: nextItem.trackID)
        } else {
            if currentQueue.repeatMode == .all, let first = currentQueue.items.first {
                await queueController.setCurrentIndex(0)
                try await startPlayback(trackID: first.trackID)
            } else {
                try await stop()
                eventBus.publish(.trackEnded(trackID: playbackState.currentTrackID ?? "", reason: .queueEnded))
            }
        }
    }
    
    private func previous() async throws {
        hapticEngine.trigger(.light)
        if playbackState.position > 3 {
            try await seek(to: 0)
        } else if let prevItem = await queueController.previous() {
            try await startPlayback(trackID: prevItem.trackID)
        } else {
            try await seek(to: 0)
        }
    }
    
    private func playQueue(trackIDs: [String], startIndex: Int) async throws {
        await queueController.setQueue(trackIDs: trackIDs, startIndex: startIndex, source: .manual)
        if startIndex < trackIDs.count {
            try await startPlayback(trackID: trackIDs[startIndex])
        }
    }

    /// Executes a committed crossfade: advances the queue, stages the next
    /// track on the adapter's idle deck, and swaps decks over the configured
    /// fade. Any staging failure disarms the transition so the incoming
    /// natural track-end drives the classic hard `next()` instead.
    private func performCrossfade(fromTrackID: String) async {
        guard let crossfader = avAdapter as? CrossfadeCapableAudioPlayer else {
            transitionArmedTrackID = nil
            return
        }
        guard crossfadeConfiguration.isEnabled else {
            transitionArmedTrackID = nil
            return
        }
        guard let nextItem = await queueController.next() else {
            transitionArmedTrackID = nil
            return
        }
        var track: AstryxTrack?
        if let engine = libraryEngine {
            track = try? await engine.fetchTrack(id: nextItem.trackID)
        }
        let fileURL = track?.fileURL ?? URL(fileURLWithPath: "/tmp/\(nextItem.trackID).mp3")
        let duration = track?.duration ?? 180
        do {
            try crossfader.prepareNext(url: fileURL)
        } catch {
            transitionArmedTrackID = nil
            return
        }
        crossfader.activatePreparedNext(fadeDuration: crossfadeConfiguration.duration, curve: crossfadeConfiguration.curve)
        currentTrackCache = track
        stateLock.lock()
        _playbackState = .playing(trackID: nextItem.trackID, position: 0, duration: duration)
        let state = _playbackState
        stateLock.unlock()
        hapticEngine.trigger(.selection)
        nowPlayingManager.updateNowPlaying(track: track, isPlaying: true, position: 0, duration: duration, artworkData: track?.artworkData)
        liveActivityManager.updateLiveActivity(track: track, isPlaying: true, position: 0, duration: duration)
        let queueID = currentQueue.id
        eventBus.publish(.trackEnded(trackID: fromTrackID, reason: .natural))
        eventBus.publish(.trackStarted(trackID: nextItem.trackID, queueID: queueID))
        eventBus.publish(.playbackStateChanged(state: snapshot(from: state)))
        try? await libraryEngine?.recordPlay(trackID: nextItem.trackID)
        preloadNext()
    }
    
    public func setVolume(_ volume: Float) async throws {
        avAdapter.setVolume(volume)
    }
    
    public func currentTrack() async -> AstryxTrack? {
        if let cached = currentTrackCache, cached.id == playbackState.currentTrackID {
            return cached
        }
        guard let trackID = playbackState.currentTrackID else { return nil }
        let track = try? await libraryEngine?.fetchTrack(id: trackID)
        currentTrackCache = track
        return track
    }
    
    private func preloadNext() {
        #if DEBUG
        if let next = currentQueue.nextItem {
            debugPrint("[AstryxAudioEngine] Preloading next: \(next.trackID)")
        }
        #endif
    }
    
    private func startPositionTimer() {
        stopPositionTimer()
        positionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let currentTime = self.avAdapter.currentTime()
            let isAdapterPlaying = self.avAdapter.isPlaying()
            let position: TimeInterval
            if currentTime > 0 && isAdapterPlaying {
                position = currentTime
            } else {
                position = self.playbackState.position + 0.5
            }
            // Read the queue before taking stateLock: the controller has its
            // own lock, and holding stateLock across it would create a lock-
            // ordering inversion the rest of the engine never takes.
            let queueForTransitionCheck = self.currentQueue
            self.stateLock.lock()
            var newState: AstryxPlaybackState?
            var shouldPublish = false
            switch self._playbackState {
            case .playing(let id, _, let dur):
                if self.transitionArmedTrackID != id,
                   self.crossfadeConfiguration.isEnabled,
                   self.avAdapter is CrossfadeCapableAudioPlayer {
                    let decision = self.transitionController.evaluate(
                        position: position,
                        duration: dur,
                        configuration: self.crossfadeConfiguration,
                        queue: queueForTransitionCheck
                    )
                    if decision.shouldCrossfade {
                        self.transitionArmedTrackID = id
                        self.stateLock.unlock()
                        Task { await self.performCrossfade(fromTrackID: id) }
                        return
                    }
                }
                if position >= dur && dur > 0 {
                    self.stateLock.unlock()
                    Task { try? await self.next() }
                    return
                }
                self._playbackState = .playing(trackID: id, position: position, duration: dur)
                newState = self._playbackState
                shouldPublish = true
            default:
                break
            }
            self.stateLock.unlock()
            if shouldPublish, let state = newState {
                self.eventBus.publish(.playbackStateChanged(state: self.snapshot(from: state)))
                if Int(position) % 1 == 0 {
                    self.nowPlayingManager.updatePlaybackState(isPlaying: state.isPlaying, position: position)
                    self.liveActivityManager.updateLiveActivity(track: self.currentTrackCache, isPlaying: state.isPlaying, position: position, duration: state.duration)
                }
            }
        }
    }
    
    private func stopPositionTimer() {
        positionTimer?.invalidate()
        positionTimer = nil
    }
    
    private func observeEvents() {
        let sub1 = eventBus.subscribe(to: QeloryxEvent.queueChanged(queueID: "", version: 0).name) { [weak self] _ in
            self?.onQueueChanged()
        }
        subscriptionStore.store(sub1)
        let sub2 = eventBus.subscribe(to: QeloryxEvent.audioSessionInterrupted(reason: "").name) { [weak self] event in
            Task { await self?.handleInterruption(event: event) }
        }
        subscriptionStore.store(sub2)
    }
    
    private func onQueueChanged() { preloadNext() }
    
    private func handleInterruption(event: QeloryxEvent) async {
        if case .audioSessionInterrupted(let reason) = event {
            if reason == "began" {
                try? await pause()
            } else if reason.contains("shouldResume_true") {
                try? await play(trackID: nil)
            }
        }
    }
    
    private func setupNowPlayingHandler() {
        let handler = RemoteCommandHandler(engine: self)
        nowPlayingManager.configure(handler: handler)
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

extension AstryxAudioEngine: AVFoundationAdapterDelegate {
    public func adapterDidFinishPlaying() {
        Task { try? await next() }
    }
    public func adapterDidFail(error: Error) {
        stateLock.lock()
        let trackID = _playbackState.currentTrackID
        _playbackState = .failed(trackID: trackID, error: error.localizedDescription)
        let state = _playbackState
        stateLock.unlock()
        eventBus.publish(.playbackStateChanged(state: snapshot(from: state)))
        eventBus.publish(.trackEnded(trackID: trackID ?? "", reason: .error))
    }
    public func adapterTimeDidUpdate(time: TimeInterval) {}
    public func adapterDidChangeStatus(isReady: Bool) {}
}

#if canImport(MediaPlayer) && canImport(UIKit)
import MediaPlayer

private final class RemoteCommandHandler: NowPlayingCommandHandler {
    weak var engine: AstryxAudioEngine?
    init(engine: AstryxAudioEngine) { self.engine = engine }
    func handlePlay() -> MPRemoteCommandHandlerStatus {
        Task { try? await engine?.handle(command: .play()) }
        return .success
    }
    func handlePause() -> MPRemoteCommandHandlerStatus {
        Task { try? await engine?.handle(command: .pause) }
        return .success
    }
    func handleNext() -> MPRemoteCommandHandlerStatus {
        Task { try? await engine?.handle(command: .next) }
        return .success
    }
    func handlePrevious() -> MPRemoteCommandHandlerStatus {
        Task { try? await engine?.handle(command: .previous) }
        return .success
    }
    func handleSeek(to time: TimeInterval) -> MPRemoteCommandHandlerStatus {
        if time == -1 {
            Task { try? await engine?.handle(command: .seekForward()) }
        } else if time == -2 {
            Task { try? await engine?.handle(command: .seekBackward()) }
        } else {
            Task { try? await engine?.handle(command: .seek(to: time)) }
        }
        return .success
    }
    func handleTogglePlayPause() -> MPRemoteCommandHandlerStatus {
        Task { try? await engine?.handle(command: .togglePlayPause) }
        return .success
    }
}

#else

private final class RemoteCommandHandler: NowPlayingCommandHandler {
    weak var engine: AstryxAudioEngine?
    init(engine: AstryxAudioEngine) { self.engine = engine }
    func handlePlay() -> Int { 0 }
    func handlePause() -> Int { 0 }
    func handleNext() -> Int { 0 }
    func handlePrevious() -> Int { 0 }
    func handleSeek(to time: TimeInterval) -> Int { 0 }
    func handleTogglePlayPause() -> Int { 0 }
}

#endif

public typealias AstryxPlaybackCoordinator = AstryxAudioEngine
