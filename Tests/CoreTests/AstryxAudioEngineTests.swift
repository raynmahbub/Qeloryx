// QELORYX — Tests
// AstryxAudioEngineTests.swift

import XCTest
@testable import QeloryxCore

final class AstryxAudioEngineTests: XCTestCase {
    
    var queueController: AstryxQueueController!
    var eventBus: AstryxEventBus!
    var engine: AstryxAudioEngine!
    
    override func setUp() {
        super.setUp()
        eventBus = AstryxEventBus()
        queueController = AstryxQueueController(eventBus: eventBus)
        engine = AstryxAudioEngine(queueController: queueController, eventBus: eventBus)
    }
    
    override func tearDown() {
        eventBus.removeAllObservers()
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertEqual(engine.playbackState, .idle)
        XCTAssertTrue(engine.currentQueue.isEmpty)
    }
    
    func testPlayQueue() async throws {
        let trackIDs = ["track-1", "track-2", "track-3"]
        
        try await engine.handle(command: .playQueue(queue: trackIDs, startIndex: 0))
        
        XCTAssertEqual(engine.currentQueue.count, 3)
        XCTAssertEqual(engine.currentQueue.currentIndex, 0)
        XCTAssertEqual(engine.playbackState.currentTrackID, "track-1")
        XCTAssertTrue(engine.playbackState.isPlaying)
    }
    
    func testPlayPauseToggle() async throws {
        let trackIDs = ["track-1"]
        try await engine.handle(command: .playQueue(queue: trackIDs, startIndex: 0))
        
        XCTAssertTrue(engine.playbackState.isPlaying)
        
        try await engine.handle(command: .pause)
        XCTAssertFalse(engine.playbackState.isPlaying)
        
        try await engine.handle(command: .togglePlayPause)
        XCTAssertTrue(engine.playbackState.isPlaying)
    }
    
    func testNextPrevious() async throws {
        let trackIDs = ["track-1", "track-2", "track-3"]
        try await engine.handle(command: .playQueue(queue: trackIDs, startIndex: 0))
        
        try await engine.handle(command: .next)
        XCTAssertEqual(engine.playbackState.currentTrackID, "track-2")
        
        try await engine.handle(command: .previous)
        XCTAssertEqual(engine.playbackState.currentTrackID, "track-1")
    }
    
    func testShuffle() async throws {
        let trackIDs = ["track-1", "track-2", "track-3", "track-4", "track-5"]
        try await engine.handle(command: .playQueue(queue: trackIDs, startIndex: 0))
        
        let originalOrder = engine.currentQueue.items.map { $0.trackID }
        
        try await engine.handle(command: .setShuffle(true))
        XCTAssertTrue(engine.currentQueue.shuffleEnabled)
        
        // Current track should stay same when shuffling
        XCTAssertEqual(engine.playbackState.currentTrackID, "track-1")
        
        try await engine.handle(command: .setShuffle(false))
        XCTAssertFalse(engine.currentQueue.shuffleEnabled)
    }
    
    func testSeek() async throws {
        let trackIDs = ["track-1"]
        try await engine.handle(command: .playQueue(queue: trackIDs, startIndex: 0))
        
        try await engine.handle(command: .seek(to: 60))
        XCTAssertEqual(engine.playbackState.position, 60, accuracy: 0.1)
    }
}
