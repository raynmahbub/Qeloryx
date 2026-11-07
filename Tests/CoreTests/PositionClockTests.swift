// QELORYX — CoreTests
// PositionClockTests.swift
//
// BUG-03. The position clock used to advance 0.5 s per tick whenever the
// adapter was not playing, so the progress bar crawled over silence and
// auto-advanced through a queue that never played. Only the adapter may move
// the clock now.

import XCTest
#if canImport(QeloryxCore)
@testable import QeloryxCore
#else
// The XcodeGen app target is a single module named `Qeloryx` (App + Core +
// Features + Platform + DesignSystem compiled together), so `QeloryxCore` does
// not exist there. `swift test` uses the multi-module SPM targets above.
@testable import Qeloryx
#endif

final class PositionClockTests: XCTestCase {

    private var eventBus: AstryxEventBus!
    private var adapter: ControllableAdapter!
    private var engine: AstryxAudioEngine!

    override func setUp() {
        super.setUp()
        eventBus = AstryxEventBus()
        adapter = ControllableAdapter()
        engine = AstryxAudioEngine(
            queueController: AstryxQueueController(eventBus: eventBus),
            eventBus: eventBus,
            avAdapter: adapter,
            sourceResolver: DictionaryPlaybackSourceResolver(tracks: [
                AstryxTrack(id: "t1", title: "One", artist: "A", album: "B",
                            duration: 180, fileURL: URL(fileURLWithPath: "/lib/t1.m4a"),
                            fileFormat: .m4a)
            ])
        )
    }

    override func tearDown() {
        eventBus.removeAllObservers()
        super.tearDown()
    }

    /// A paused/stalled adapter must not move the reported position.
    func testPositionFreezesWhenAdapterIsNotPlaying() async throws {
        try await engine.handle(command: .playQueue(queue: ["t1"], startIndex: 0))
        let before = engine.playbackState.position

        adapter.playing = false
        for _ in 0..<10 { engine.positionTick() }

        XCTAssertEqual(engine.playbackState.position, before, accuracy: 0.0001,
                       "10 ticks over a stopped adapter must not advance the clock")
    }

    /// The adapter reporting 0 while nominally playing is buffering — hold.
    func testZeroAdapterTimeDoesNotFabricateProgress() async throws {
        try await engine.handle(command: .playQueue(queue: ["t1"], startIndex: 0))
        let before = engine.playbackState.position

        adapter.playing = true
        adapter.time = 0
        for _ in 0..<10 { engine.positionTick() }

        XCTAssertEqual(engine.playbackState.position, before, accuracy: 0.0001,
                       "no synthetic +0.5s steps are allowed")
    }

    /// Real adapter progress is still honoured.
    func testAdapterTimeDrivesPosition() async throws {
        try await engine.handle(command: .playQueue(queue: ["t1"], startIndex: 0))

        adapter.playing = true
        adapter.time = 42.5
        engine.positionTick()

        XCTAssertEqual(engine.playbackState.position, 42.5, accuracy: 0.001)
    }

    /// Non-finite adapter readings must never reach published state.
    func testNonFiniteAdapterTimeIsIgnored() async throws {
        try await engine.handle(command: .playQueue(queue: ["t1"], startIndex: 0))
        let before = engine.playbackState.position

        adapter.playing = true
        adapter.time = .nan
        engine.positionTick()

        XCTAssertEqual(engine.playbackState.position, before, accuracy: 0.0001)
    }
}

private final class ControllableAdapter: AudioPlayerAdapterProtocol, @unchecked Sendable {
    weak var delegate: (any AVFoundationAdapterDelegate)?
    var playing = false
    var time: TimeInterval = 0

    var isAirPlayActive: Bool = false
    var allowsExternalPlayback: Bool = false

    func load(url: URL) throws {}
    func load(track: AstryxTrack) throws {}
    func play() { playing = true }
    func pause() { playing = false }
    func stop() { playing = false }
    func seek(to time: TimeInterval, completion: ((Bool) -> Void)?) { completion?(true) }
    func setVolume(_ volume: Float) {}
    func setRate(_ rate: Float) {}
    func currentTime() -> TimeInterval { time }
    func duration() -> TimeInterval { 180 }
    func isPlaying() -> Bool { playing }
}
