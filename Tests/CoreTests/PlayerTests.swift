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
}
