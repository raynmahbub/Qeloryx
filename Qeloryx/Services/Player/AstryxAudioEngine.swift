// QELORYX — Services/Player
// AstryxAudioEngine.swift
//
// Core playback orchestration. Split across extensions to keep each type body
// readable:
//   • AstryxAudioEngine.swift          — state, transport, session
//   • AstryxAudioEngine+Position.swift — the position clock
//   • AstryxAudioEngine+Actions.swift  — next/previous/crossfade/queue
//   • AstryxAudioEngine+Delegate.swift — adapter delegate + remote commands
//
// Correctness notes (see Docs/BUG_REGISTER.md):
//   BUG-02 no invented `/tmp` URLs and no swallowed load failures.
//   BUG-03 the position clock never advances unless the adapter is playing.
//   BUG-05 interruptions require that we were playing; route loss pauses.
//   BUG-11 repeat-one seeks to zero instead of reloading the file.

import Foundation

public protocol AstryxAudioEngineProtocol: AnyObject, Sendable {
    var playbackState: AstryxPlaybackState { get }
    var currentQueue: AstryxQueue { get }
    func handle(command: AstryxPlaybackCommand) async throws
    /// Replaces the queue without loading or playing anything.
    func restoreQueue(trackIDs: [String], startIndex: Int) async
    /// Restores a paused position without touching the audio adapter.
    ///
    /// Part of the protocol so queue restoration cannot silently vanish behind
    /// an `as?` cast when the engine implementation is substituted.
    func restorePausedState(trackID: String, position: TimeInterval)
    func currentTrack() async -> AstryxTrack?
    func seek(to: TimeInterval) async throws
    func setVolume(_ volume: Float) async throws
}

public final class AstryxAudioEngine: AstryxAudioEngineProtocol, @unchecked Sendable {

    // MARK: Dependencies

    let queueController: any QueueControllerProtocol
    let sessionManager: any AudioSessionManagerProtocol
    let eventBus: any EventBusProtocol
    let libraryEngine: (any LibraryEngineProtocol)?
    let nowPlayingManager: any NowPlayingManagerProtocol
    let liveActivityManager: any LiveActivityManagerProtocol
    let hapticEngine: any HapticEngineProtocol
    let avAdapter: any AudioPlayerAdapterProtocol
    let sourceResolver: (any PlaybackSourceResolving)?

    // MARK: State

    private var _playbackState: AstryxPlaybackState = .idle
    let stateLock = NSLock()
    var positionTimer: Timer?
    var currentTrackCache: AstryxTrack?
    var subscriptionStore = EventSubscriptionStore()
    var crossfadeConfiguration = CrossfadeConfiguration.disabled
    let transitionController = GaplessTransitionController()

    /// Track ID whose crossfade is already committed, so the position timer
    /// arms exactly once per track and never races itself.
    var transitionArmedTrackID: String?

    /// Track whose play has already been counted in this playback session, so
    /// a single listen increments the counter exactly once (BUG-20).
    var playRecordedTrackID: String?

    /// Last whole second pushed to Now Playing / Live Activity, so system
    /// surfaces update at 1 Hz instead of on every tick.
    var lastNowPlayingSecond: Int = -1

    /// True when playback was running at the moment the system interrupted us.
    /// Resume only happens when this is set, so a user who had paused is never
    /// surprised by audio after a phone call.
    var wasPlayingBeforeInterruption = false

    /// Wall-clock length of one position timer tick. Also used as the fallback
    /// increment so a track still advances if the adapter reports nothing.
    static let positionTickInterval: TimeInterval = 0.5

    // MARK: Init

    public init(
        queueController: any QueueControllerProtocol = AstryxQueueController(),
        sessionManager: any AudioSessionManagerProtocol = FallbackAudioSessionManager(),
        eventBus: any EventBusProtocol = AstryxEventBus.shared,
        libraryEngine: (any LibraryEngineProtocol)? = nil,
        nowPlayingManager: any NowPlayingManagerProtocol = FallbackNowPlayingManager(),
        liveActivityManager: any LiveActivityManagerProtocol = FallbackLiveActivityManager(),
        hapticEngine: any HapticEngineProtocol = FallbackHapticEngine(),
        avAdapter: any AudioPlayerAdapterProtocol = FallbackAudioPlayerAdapter(),
        sourceResolver: (any PlaybackSourceResolving)? = nil
    ) {
        self.queueController = queueController
        self.sessionManager = sessionManager
        self.eventBus = eventBus
        self.libraryEngine = libraryEngine
        self.nowPlayingManager = nowPlayingManager
        self.liveActivityManager = liveActivityManager
        self.hapticEngine = hapticEngine
        self.avAdapter = avAdapter
        if let sourceResolver {
            self.sourceResolver = sourceResolver
        } else if let libraryEngine {
            self.sourceResolver = LibraryPlaybackSourceResolver(library: libraryEngine)
        } else {
            self.sourceResolver = nil
        }
        self.avAdapter.delegate = self
        observeEvents()
        setupNowPlayingHandler()
    }

    // MARK: - Observable state

    public var playbackState: AstryxPlaybackState {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _playbackState
    }

    public var currentQueue: AstryxQueue {
        queueController.currentQueue()
    }

    func setState(_ newState: AstryxPlaybackState) -> AstryxPlaybackState {
        stateLock.lock()
        _playbackState = newState
        let state = _playbackState
        stateLock.unlock()
        return state
    }

    // MARK: - Command routing

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
            publishState()
        case .setRepeat(let mode):
            await queueController.setRepeatMode(mode)
            hapticEngine.trigger(.selection)
            publishState()
        case .setVolume(let volume):
            try await setVolume(volume)
        case .setCrossfade(let configuration):
            crossfadeConfiguration = configuration
            // Changing the fade window invalidates any armed transition.
            transitionArmedTrackID = nil
        }
    }

    // MARK: - Transport

    /// `internal` so the delegate / remote-command extension can resume
    /// playback after an interruption.
    func play(trackID: String?) async throws {
        try sessionManager.configure(category: .playback)
        try sessionManager.activate()

        if let trackID {
            let queue = currentQueue
            if let index = queue.items.firstIndex(where: { $0.trackID == trackID }) {
                await queueController.setCurrentIndex(index)
            } else {
                await queueController.setQueue(trackIDs: [trackID], startIndex: 0, source: .manual)
            }
            try await startPlayback(trackID: trackID)
            return
        }

        switch playbackState {
        case .paused(let id, _, _):
            try await resumePlayback(trackID: id)
        case .failed(let id?, _):
            // Retrying a failed track must re-load it, not pretend to resume.
            try await startPlayback(trackID: id)
        default:
            guard !currentQueue.isEmpty else { throw PlaybackError.nothingToResume }
            let id = currentQueue.currentItem?.trackID ?? currentQueue.items[0].trackID
            try await startPlayback(trackID: id)
        }
    }

    private func pause() async throws {
        guard case .playing(let trackID, let pos, let dur) = playbackState else { return }
        avAdapter.pause()
        let state = setState(.paused(trackID: trackID, position: pos, duration: dur))
        hapticEngine.triggerPause()
        nowPlayingManager.updatePlaybackState(isPlaying: false, position: pos)
        liveActivityManager.updateLiveActivity(
            track: currentTrackCache,
            isPlaying: false,
            position: pos,
            duration: dur
        )
        eventBus.publish(.trackPaused(trackID: trackID, position: pos))
        eventBus.publish(.playbackStateChanged(state: snapshot(from: state)))
        stopPositionTimer()
    }

    private func resumePlayback(trackID: String) async throws {
        var position: TimeInterval = 0
        var duration: TimeInterval = 0
        if case .paused(_, let pos, let dur) = playbackState {
            position = pos
            duration = dur
        }
        try sessionManager.activate()
        let state = setState(.playing(trackID: trackID, position: position, duration: duration))
        avAdapter.play()
        hapticEngine.triggerPlay()
        nowPlayingManager.updatePlaybackState(isPlaying: true, position: position)
        liveActivityManager.updateLiveActivity(
            track: currentTrackCache,
            isPlaying: true,
            position: position,
            duration: duration
        )
        eventBus.publish(.trackResumed(trackID: trackID, position: position))
        eventBus.publish(.playbackStateChanged(state: snapshot(from: state)))
        startPositionTimer()
    }

    /// Loads and starts a track. Throws `PlaybackError` instead of pretending.
    func startPlayback(trackID: String) async throws {
        guard let resolver = sourceResolver else {
            let state = fail(trackID: trackID, error: PlaybackError.noPlaybackSource)
            throw PlaybackError.failedState(state)
        }
        guard let source = await resolver.resolvePlaybackSource(trackID: trackID) else {
            let state = fail(trackID: trackID, error: PlaybackError.trackNotResolved(trackID: trackID))
            throw PlaybackError.failedState(state)
        }

        do {
            try avAdapter.load(url: source.url)
        } catch {
            let state = fail(
                trackID: trackID,
                error: PlaybackError.loadFailed(trackID: trackID, reason: error.localizedDescription)
            )
            throw PlaybackError.failedState(state)
        }

        avAdapter.play()
        currentTrackCache = source.track
        transitionArmedTrackID = nil

        let duration = source.track.duration > 0 ? source.track.duration : avAdapter.duration()
        let state = setState(.playing(trackID: trackID, position: 0, duration: duration))

        hapticEngine.triggerPlay()
        nowPlayingManager.updateNowPlaying(
            track: source.track,
            isPlaying: true,
            position: 0,
            duration: duration,
            artworkData: source.track.artworkData
        )
        liveActivityManager.startLiveActivity(track: source.track, isPlaying: true, position: 0)

        let queueID = currentQueue.id
        eventBus.publish(.trackStarted(trackID: trackID, queueID: queueID))
        eventBus.publish(.playbackStateChanged(state: snapshot(from: state)))
        await recordPlay(trackID: trackID)
        startPositionTimer()
    }

    private func togglePlayPause() async throws {
        if playbackState.isPlaying {
            try await pause()
        } else {
            try await play(trackID: nil)
        }
    }

    func stop() async throws {
        avAdapter.stop()
        transitionArmedTrackID = nil
        wasPlayingBeforeInterruption = false
        let state = setState(.stopped)
        nowPlayingManager.clear()
        liveActivityManager.endLiveActivity()
        eventBus.publish(.playbackStateChanged(state: snapshot(from: state)))
        try? sessionManager.deactivate()
        stopPositionTimer()
    }

    public func seek(to: TimeInterval) async throws {
        let clamped = max(0, to)
        let oldPos = playbackState.position
        let trackID = playbackState.currentTrackID
        let duration = playbackState.duration

        var newState = playbackState
        switch playbackState {
        case .playing(let id, _, let dur):
            newState = .playing(trackID: id, position: clamped, duration: dur)
        case .paused(let id, _, let dur):
            newState = .paused(trackID: id, position: clamped, duration: dur)
        default:
            break
        }
        let state = setState(newState)
        avAdapter.seek(to: clamped) { _ in }
        nowPlayingManager.updatePlaybackState(isPlaying: state.isPlaying, position: clamped)
        liveActivityManager.updateLiveActivity(
            track: currentTrackCache,
            isPlaying: state.isPlaying,
            position: clamped,
            duration: duration
        )
        if let trackID {
            eventBus.publish(.trackSeeked(trackID: trackID, from: oldPos, to: clamped))
            eventBus.publish(.playbackStateChanged(state: snapshot(from: state)))
        }
    }

    private func seekForward(interval: TimeInterval) async throws {
        let newPos = min(playbackState.position + interval, playbackState.duration)
        try await seek(to: newPos)
    }

    private func seekBackward(interval: TimeInterval) async throws {
        try await seek(to: max(0, playbackState.position - interval))
    }

    public func setVolume(_ volume: Float) async throws {
        avAdapter.setVolume(volume)
    }

    public func currentTrack() async -> AstryxTrack? {
        if let cached = currentTrackCache, cached.id == playbackState.currentTrackID {
            return cached
        }
        let trackID = playbackState.currentTrackID
        let track: AstryxTrack?
        if let resolver = sourceResolver, let trackID {
            track = await resolver.resolvePlaybackSource(trackID: trackID)?.track
        } else if let libraryEngine, let trackID {
            track = try? await libraryEngine.fetchTrack(id: trackID)
        } else {
            track = nil
        }
        currentTrackCache = track
        return track
    }

    // MARK: - Setup

    private func observeEvents() {
        let queueName = QeloryxEvent.queueChanged(queueID: "", version: 0).name
        let sub1 = eventBus.subscribe(to: queueName) { [weak self] _ in
            self?.preloadNext()
        }
        subscriptionStore.store(sub1)

        let interruptionName = QeloryxEvent.audioSessionInterrupted(interruption: .began).name
        let sub2 = eventBus.subscribe(to: interruptionName) { [weak self] event in
            guard case .audioSessionInterrupted(let interruption) = event else { return }
            self?.handleInterruption(interruption)
        }
        subscriptionStore.store(sub2)
    }

    private func handleInterruption(_ interruption: AudioSessionInterruption) {
        switch interruption {
        case .began:
            wasPlayingBeforeInterruption = playbackState.isPlaying
            Task { [weak self] in
                try? await self?.pause()
            }
        case .ended(let shouldResume):
            let shouldRestart = shouldResume && wasPlayingBeforeInterruption
            wasPlayingBeforeInterruption = false
            guard shouldRestart else { return }
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await self.play(trackID: nil)
                } catch {
                    self.publishError(error, context: "resume-after-interruption")
                }
            }
        case .oldDeviceUnavailable:
            // Headphones were unplugged: pause instead of blasting the speaker.
            wasPlayingBeforeInterruption = false
            Task { [weak self] in
                try? await self?.pause()
            }
        }
    }

    private func preloadNext() {
        guard let next = queueController.previewNext() else { return }
        #if DEBUG
        debugPrint("[AstryxAudioEngine] Preload candidate: \(next.trackID)")
        #endif
    }

    private func setupNowPlayingHandler() {
        nowPlayingManager.configure(handler: RemoteCommandHandler(engine: self))
    }
}

public typealias AstryxPlaybackCoordinator = AstryxAudioEngine
