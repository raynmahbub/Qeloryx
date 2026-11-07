// QELORYX — Tests
// AstryxAudioEngineTests.swift

import XCTest
#if canImport(QeloryxCore)
@testable import QeloryxCore
#else
// The XcodeGen app target is a single module named `Qeloryx` (App + Core +
// Features + Platform + DesignSystem compiled together), so `QeloryxCore` does
// not exist there. `swift test` uses the multi-module SPM targets above.
@testable import Qeloryx
#endif

final class AstryxAudioEngineTests: XCTestCase {
    
    var queueController: AstryxQueueController!
    var eventBus: AstryxEventBus!
    var engine: AstryxAudioEngine!
    
    override func setUp() {
        super.setUp()
        eventBus = AstryxEventBus()
        queueController = AstryxQueueController(eventBus: eventBus)
        // BUG-02: without a resolver the engine now (correctly) refuses to
        // claim it is playing. Tests supply a deterministic one.
        engine = AstryxAudioEngine(
            queueController: queueController,
            eventBus: eventBus,
            sourceResolver: Self.resolver(for: ["track-1", "track-2", "track-3"])
        )
    }
    
    static func resolver(for trackIDs: [String]) -> DictionaryPlaybackSourceResolver {
        DictionaryPlaybackSourceResolver(tracks: trackIDs.map { id in
            AstryxTrack(
                id: id,
                title: "Track \(id)",
                artist: "Artist",
                album: "Album",
                duration: 180,
                fileURL: URL(fileURLWithPath: "/library/\(id).m4a"),
                fileFormat: .m4a
            )
        })
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
