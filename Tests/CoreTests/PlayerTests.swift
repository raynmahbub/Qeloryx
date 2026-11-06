// QELORYX — Tests
// PlayerTests.swift
// QEL-012 Player Milestone

import XCTest
@testable import QeloryxCore

final class PlayerTests: XCTestCase {
    
    var queueController: AstryxQueueController!
    var eventBus: AstryxEventBus!
    var avAdapter: FallbackAudioPlayerAdapter!
    var sessionManager: FallbackAudioSessionManager!
    var nowPlaying: FallbackNowPlayingManager!
    var liveActivity: FallbackLiveActivityManager!
    var haptics: FallbackHapticEngine!
    var engine: AstryxAudioEngine!
    
    override func setUp() {
        super.setUp()
        eventBus = AstryxEventBus()
        queueController = AstryxQueueController(eventBus: eventBus)
        avAdapter = FallbackAudioPlayerAdapter()
        sessionManager = FallbackAudioSessionManager(eventBus: eventBus)
        nowPlaying = FallbackNowPlayingManager()
        liveActivity = FallbackLiveActivityManager()
        haptics = FallbackHapticEngine()
        engine = AstryxAudioEngine(
            queueController: queueController,
            sessionManager: sessionManager,
            eventBus: eventBus,
            libraryEngine: nil,
            nowPlayingManager: nowPlaying,
            liveActivityManager: liveActivity,
            hapticEngine: haptics,
            avAdapter: avAdapter
        )
    }
    
    override func tearDown() {
        eventBus.removeAllObservers()
        super.tearDown()
    }
    
    func testPlayerWithRealAdapters() async throws {
        let trackIDs = ["track-1", "track-2", "track-3"]
        try await engine.handle(command: .playQueue(queue: trackIDs, startIndex: 0))
        XCTAssertEqual(engine.currentQueue.count, 3)
        XCTAssertTrue(engine.playbackState.isPlaying)
        XCTAssertEqual(engine.playbackState.currentTrackID, "track-1")
    }
    
    func testArtworkTransitionLogic() async throws {
        let trackIDs = ["track-1", "track-2"]
        try await engine.handle(command: .playQueue(queue: trackIDs, startIndex: 0))
        let firstID = engine.playbackState.currentTrackID
        try await engine.handle(command: .next)
        let secondID = engine.playbackState.currentTrackID
        XCTAssertNotEqual(firstID, secondID)
    }
    
    func testBackgroundPlaybackConfiguration() throws {
        XCTAssertNoThrow(try sessionManager.configure(category: .playback))
        XCTAssertNoThrow(try sessionManager.activate())
        XCTAssertNoThrow(try sessionManager.deactivate())
    }
    
    func testNowPlayingUpdates() {
        let track = AstryxTrack(title: "Test", artist: "Artist", album: "Album", duration: 180, fileURL: URL(fileURLWithPath: "/tmp/test.mp3"), fileFormat: .mp3)
        nowPlaying.updateNowPlaying(track: track, isPlaying: true, position: 0, duration: 180, artworkData: nil)
        nowPlaying.updatePlaybackState(isPlaying: true, position: 10)
        nowPlaying.clear()
    }
    
    func testLiveActivityLifecycle() {
        let track = AstryxTrack(title: "Test", artist: "Artist", album: "Album", duration: 180, fileURL: URL(fileURLWithPath: "/tmp/test.mp3"), fileFormat: .mp3)
        liveActivity.startLiveActivity(track: track, isPlaying: true, position: 0)
        liveActivity.updateLiveActivity(track: track, isPlaying: true, position: 10, duration: 180)
        liveActivity.endLiveActivity()
    }
    
    func testHapticFeedback() {
        haptics.trigger(.light)
        haptics.triggerPlay()
        haptics.triggerPause()
        haptics.triggerFavorite()
    }
    
    func testAirPlaySupport() {
        let isActive = avAdapter.isAirPlayActive
        XCTAssertFalse(isActive)
        XCTAssertTrue(avAdapter.allowsExternalPlayback)
    }

    // MARK: - Seamless Playback Sprint (crossfade curves & arming)

    func testCrossfadeCurvesBoundaries() {
        for curve in CrossfadeCurve.allCases {
            XCTAssertEqual(curve.fadeOutLevel(at: 0), 1.0, accuracy: 1e-9, "\(curve) fade out must start at full gain")
            XCTAssertEqual(curve.fadeOutLevel(at: 1), 0.0, accuracy: 1e-9, "\(curve) fade out must end at silence")
            XCTAssertEqual(curve.fadeInLevel(at: 0), 0.0, accuracy: 1e-9, "\(curve) fade in must start at silence")
            XCTAssertEqual(curve.fadeInLevel(at: 1), 1.0, accuracy: 1e-9, "\(curve) fade in must end at full gain")
        }
    }

    func testCrossfadeEqualPowerKeepsConstantPower() {
        // sin^2(t) + cos^2(t) = 1 for every progress point.
        for progress in stride(from: 0.0, through: 1.0, by: 0.1) {
            let out = CrossfadeCurve.equalPower.fadeOutLevel(at: progress)
            let fadeIn = CrossfadeCurve.equalPower.fadeInLevel(at: progress)
            XCTAssertEqual(out * out + fadeIn * fadeIn, 1.0, accuracy: 1e-9, "total power must stay constant at \(progress)")
        }
        XCTAssertEqual(CrossfadeCurve.equalPower.fadeOutLevel(at: 0.5), sqrt(0.5), accuracy: 1e-9)
    }

    func testCrossfadeCurveClampsProgress() {
        XCTAssertEqual(CrossfadeCurve.linear.fadeOutLevel(at: -1), CrossfadeCurve.linear.fadeOutLevel(at: 0))
        XCTAssertEqual(CrossfadeCurve.linear.fadeInLevel(at: 2), CrossfadeCurve.linear.fadeInLevel(at: 1))
        XCTAssertEqual(CrossfadeCurve.sCurve.fadeInLevel(at: .nan), 0)
        XCTAssertTrue(CrossfadeCurve.sCurve.fadeOutLevel(at: .nan).isFinite)
    }

    func testCrossfadeConfigurationClamps() {
        XCTAssertFalse(CrossfadeConfiguration.disabled.isEnabled)
        XCTAssertEqual(CrossfadeConfiguration(duration: 0.2).duration, 0)
        XCTAssertEqual(CrossfadeConfiguration(duration: 30).duration, CrossfadeConfiguration.maximumDuration)
        XCTAssertTrue(CrossfadeConfiguration(duration: 6).isEnabled)
        XCTAssertEqual(CrossfadeConfiguration(duration: .nan).duration, 0)
    }

    private func makeCrossfadeQueue(currentIndex: Int, repeatMode: AstryxRepeatMode = .off, shuffle: Bool = false) -> AstryxQueue {
        let items = [
            AstryxQueueItem(trackID: "track-1", order: 0, isCurrent: currentIndex == 0),
            AstryxQueueItem(trackID: "track-2", order: 1, isCurrent: currentIndex == 1)
        ]
        return AstryxQueue(items: items, currentIndex: currentIndex, shuffleEnabled: shuffle, repeatMode: repeatMode)
    }

    func testGaplessTransitionArmingWindow() {
        let controller = GaplessTransitionController()
        let config = CrossfadeConfiguration(duration: 6)
        let queue = makeCrossfadeQueue(currentIndex: 0)
        XCTAssertEqual(controller.evaluate(position: 170, duration: 180, configuration: config, queue: queue).reason, .outsideFadeWindow)
        XCTAssertTrue(controller.evaluate(position: 174, duration: 180, configuration: config, queue: queue).shouldCrossfade)
        XCTAssertEqual(controller.evaluate(position: 179.9, duration: 180, configuration: config, queue: queue).reason, .armed)
    }

    func testGaplessTransitionGuards() {
        let controller = GaplessTransitionController()
        let config = CrossfadeConfiguration(duration: 6)
        XCTAssertEqual(controller.evaluate(position: 179, duration: 180, configuration: .disabled, queue: makeCrossfadeQueue(currentIndex: 0)).reason, .crossfadeDisabled)
        XCTAssertEqual(controller.evaluate(position: 179, duration: 180, configuration: config, queue: makeCrossfadeQueue(currentIndex: 1)).reason, .noNextItem)
        XCTAssertEqual(controller.evaluate(position: 179, duration: 180, configuration: config, queue: makeCrossfadeQueue(currentIndex: 0, repeatMode: .one)).reason, .repeatOneUnsupported)
        XCTAssertEqual(controller.evaluate(position: 179, duration: 180, configuration: config, queue: makeCrossfadeQueue(currentIndex: 0, shuffle: true)).reason, .shuffledQueueUnsupported)
        XCTAssertEqual(controller.evaluate(position: 9, duration: 10, configuration: CrossfadeConfiguration(duration: 7), queue: makeCrossfadeQueue(currentIndex: 0)).reason, .trackTooShort)
        XCTAssertTrue(controller.evaluate(position: 9, duration: 10, configuration: config, queue: makeCrossfadeQueue(currentIndex: 0)).shouldCrossfade)
        XCTAssertEqual(controller.evaluate(position: .nan, duration: 180, configuration: config, queue: makeCrossfadeQueue(currentIndex: 0)).reason, .invalidTiming)
        XCTAssertEqual(controller.evaluate(position: 0, duration: 180, configuration: config, queue: makeCrossfadeQueue(currentIndex: 0)).reason, .invalidTiming)
    }

    func testCrossfadeAllowsQueueWrapAroundOnRepeatAll() {
        let controller = GaplessTransitionController()
        let config = CrossfadeConfiguration(duration: 6)
        let queue = makeCrossfadeQueue(currentIndex: 1, repeatMode: .all)
        XCTAssertTrue(controller.evaluate(position: 176, duration: 180, configuration: config, queue: queue).shouldCrossfade)
    }

    func testEngineArmsCrossfadeNearTrackEnd() async throws {
        let mock = MockCrossfadeAdapter()
        let crossfadeEngine = AstryxAudioEngine(
            queueController: AstryxQueueController(eventBus: eventBus),
            sessionManager: sessionManager,
            eventBus: eventBus,
            libraryEngine: nil,
            nowPlayingManager: nowPlaying,
            liveActivityManager: liveActivity,
            hapticEngine: haptics,
            avAdapter: mock
        )
        try await crossfadeEngine.handle(command: .playQueue(queue: ["track-1", "track-2"], startIndex: 0))
        try await crossfadeEngine.handle(command: .setCrossfade(CrossfadeConfiguration(duration: 6, curve: .equalPower)))
        XCTAssertTrue(mock.preparedNextURLs.isEmpty, "no fade may be staged before the fade window")
        mock.stubbedCurrentTime = 174.5
        let deadline = Date().addingTimeInterval(5)
        while mock.preparedNextURLs.isEmpty, Date() < deadline {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertEqual(mock.preparedNextURLs.count, 1, "the standby deck must stage exactly one track")
        XCTAssertEqual(mock.activatedFades.first?.duration, 6)
        XCTAssertEqual(mock.activatedFades.first?.curve, .equalPower)
        XCTAssertEqual(crossfadeEngine.playbackState.currentTrackID, "track-2")
        try await crossfadeEngine.handle(command: .stop)
    }

    func testEngineKeepsHardTransitionsWhenCrossfadeDisabled() async throws {
        let mock = MockCrossfadeAdapter()
        let crossfadeEngine = AstryxAudioEngine(
            queueController: AstryxQueueController(eventBus: eventBus),
            sessionManager: sessionManager,
            eventBus: eventBus,
            libraryEngine: nil,
            nowPlayingManager: nowPlaying,
            liveActivityManager: liveActivity,
            hapticEngine: haptics,
            avAdapter: mock
        )
        try await crossfadeEngine.handle(command: .playQueue(queue: ["track-1", "track-2"], startIndex: 0))
        mock.stubbedCurrentTime = 179.5
        try await Task.sleep(nanoseconds: 1_500_000_000)
        XCTAssertTrue(mock.preparedNextURLs.isEmpty, "disabled crossfade must never stage a deck")
        try await crossfadeEngine.handle(command: .stop)
    }
}

// MARK: - Crossfade test doubles

private final class MockCrossfadeAdapter: CrossfadeCapableAudioPlayer, @unchecked Sendable {
    weak var delegate: AVFoundationAdapterDelegate?
    var stubbedCurrentTime: TimeInterval = 0
    var stubbedIsPlaying = true
    private(set) var preparedNextURLs: [URL] = []
    private(set) var activatedFades: [(duration: TimeInterval, curve: CrossfadeCurve)] = []
    var hasPreparedNext: Bool { !preparedNextURLs.isEmpty }
    func load(url: URL) throws {}
    func load(track: AstryxTrack) throws {}
    func play() {}
    func pause() {}
    func stop() {}
    func seek(to time: TimeInterval, completion: ((Bool) -> Void)?) { completion?(true) }
    func setVolume(_ volume: Float) {}
    func setRate(_ rate: Float) {}
    func currentTime() -> TimeInterval { stubbedCurrentTime }
    func duration() -> TimeInterval { 180 }
    func isPlaying() -> Bool { stubbedIsPlaying }
    var isAirPlayActive: Bool { false }
    var allowsExternalPlayback: Bool = true
    func prepareNext(url: URL) throws { preparedNextURLs.append(url) }
    func activatePreparedNext(fadeDuration: TimeInterval, curve: CrossfadeCurve) {
        activatedFades.append((fadeDuration, curve))
        stubbedCurrentTime = 0
    }
    func cancelPreparedNext() { preparedNextURLs.removeAll() }
}
