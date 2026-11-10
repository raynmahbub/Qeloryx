// QELORYX — CoreTests
// PlaybackRestorerTests.swift
//
// Playback restoration was advertised but nothing was persisted, so every
// launch started empty. These tests pin the contract that made it real:
// snapshot → restore → **paused**, never auto-playing.

import XCTest
#if canImport(QeloryxCore)
@testable import QeloryxCore
#else
// The XcodeGen app target is a single module named `Qeloryx` (App + Core +
// Features + Platform + DesignSystem compiled together), so `QeloryxCore` does
// not exist there. `swift test` uses the multi-module SPM targets above.
@testable import Qeloryx
#endif

final class PlaybackRestorerTests: XCTestCase {

    private var store: InMemoryPlaybackResumeStore!
    private var restorer: PlaybackRestorer!
    private var eventBus: AstryxEventBus!
    private var queueController: AstryxQueueController!
    private var adapter: StubPlayerAdapter!
    private var engine: AstryxAudioEngine!

    override func setUp() async throws {
        super.setUp()
        store = InMemoryPlaybackResumeStore()
        restorer = PlaybackRestorer(store: store)

        eventBus = AstryxEventBus()
        queueController = AstryxQueueController(eventBus: eventBus)
        // Restoring never touches the resolver or the adapter; supplying both
        // keeps the engine honest about not reaching for audio.
        adapter = StubPlayerAdapter()
        engine = AstryxAudioEngine(
            queueController: queueController,
            sessionManager: StubAudioSessionManager(),
            eventBus: eventBus,
            avAdapter: adapter,
            sourceResolver: DictionaryPlaybackSourceResolver(tracks: [
                Self.track("a"), Self.track("b"), Self.track("c")
            ])
        )
    }

    private static func track(_ id: String) -> AstryxTrack {
        AstryxTrack(
            id: id,
            title: "Track \(id)",
            artist: "Artist",
            album: "Album",
            duration: 180,
            fileURL: URL(fileURLWithPath: "/library/\(id).m4a"),
            fileFormat: .m4a
        )
    }

    private func makePoint(index: Int = 1, position: TimeInterval = 42) -> PlaybackResumePoint {
        PlaybackResumePoint(
            trackIDs: ["a", "b", "c"],
            startIndex: index,
            position: position,
            shuffleEnabled: true,
            repeatMode: .all
        )
    }

    // MARK: - Round trip

    func testResumePointRoundTripsThroughCodable() throws {
        let point = makePoint()
        let data = try JSONEncoder().encode(point)
        let decoded = try JSONDecoder().decode(PlaybackResumePoint.self, from: data)

        XCTAssertEqual(decoded.trackIDs, point.trackIDs)
        XCTAssertEqual(decoded.startIndex, point.startIndex)
        XCTAssertEqual(decoded.position, point.position, accuracy: 0.001)
        XCTAssertTrue(decoded.shuffleEnabled)
        XCTAssertEqual(decoded.repeatMode, .all)
    }

    func testUnknownRepeatModeFallsBackToOff() throws {
        let json = """
        {"trackIDs":["a"],"startIndex":0,"position":1,"shuffleEnabled":false,
         "repeatMode":"bogus","savedAt":0}
        """
        let decoded = try JSONDecoder().decode(
            PlaybackResumePoint.self,
            from: Data(json.utf8)
        )
        XCTAssertEqual(decoded.repeatMode, .off)
    }

    func testClearRemovesTheResumePoint() {
        store.save(makePoint())
        XCTAssertNotNil(restorer.resumePoint)
        restorer.clear()
        XCTAssertNil(restorer.resumePoint, "an explicit stop must not resurrect on next launch")
    }

    // MARK: - Restore

    func testRestoreRebuildsTheQueue() async {
        store.save(makePoint())

        await restorer.restore(into: engine, paused: true)

        let queue = engine.currentQueue
        XCTAssertEqual(queue.items.map(\.trackID), ["a", "b", "c"])
        XCTAssertEqual(queue.currentIndex, 1)
        XCTAssertTrue(queue.shuffleEnabled)
        XCTAssertEqual(queue.repeatMode, .all)
    }

    /// The critical regression guard: restoring must never start audio.
    ///
    /// An earlier implementation called `.playQueue`, which loads the file into
    /// the adapter and calls `play()`, then overwrote the state to `.paused`
    /// while sound kept coming out. Asserting the *state* alone would not have
    /// caught that — the adapter must never be touched at all.
    func testRestoreDoesNotStartPlayback() async {
        store.save(makePoint())

        await restorer.restore(into: engine, paused: true)

        XCTAssertTrue(
            adapter.loadedURLs.isEmpty,
            "restoration must not load audio into the adapter; loaded \(adapter.loadedURLs)"
        )
        XCTAssertFalse(adapter.played, "restoration must never call play() on the adapter")

        switch engine.playbackState {
        case .paused(let trackID, let position, _):
            XCTAssertEqual(trackID, "b")
            XCTAssertEqual(position, 42, accuracy: 0.001)
        default:
            XCTFail("restored state must be .paused, got \(engine.playbackState)")
        }
    }

    func testRestoreWithEmptyStoreIsANoOp() async {
        await restorer.restore(into: engine, paused: true)
        XCTAssertTrue(engine.currentQueue.items.isEmpty)
        XCTAssertEqual(engine.playbackState, .idle)
    }

    func testRestoreClampsAnOutOfRangeStartIndex() async {
        store.save(makePoint(index: 99))

        await restorer.restore(into: engine, paused: true)

        XCTAssertEqual(engine.currentQueue.currentIndex, 2, "index is clamped to the last item")
    }
}

// MARK: - Doubles

private final class StubAudioSessionManager: AudioSessionManagerProtocol, @unchecked Sendable {
    func configure(category: AudioSessionCategory) throws {}
    func activate() throws {}
    func deactivate() throws {}
    func handleInterruption(_ interruption: AudioSessionInterruption) {}
}

/// Records loads and never fails, so the engine's queue/state logic is
/// exercised without AVFoundation.
private final class StubPlayerAdapter: AudioPlayerAdapterProtocol, @unchecked Sendable {
    private(set) var loadedURLs: [URL] = []
    private(set) var played = false
    weak var delegate: (any AVFoundationAdapterDelegate)?

    var isAirPlayActive: Bool = false
    var allowsExternalPlayback: Bool = false

    func load(url: URL) throws { loadedURLs.append(url) }
    func load(track: AstryxTrack) throws { loadedURLs.append(track.fileURL) }
    func play() { played = true }
    func pause() {}
    func stop() {}
    func seek(to time: TimeInterval, completion: ((Bool) -> Void)?) { completion?(true) }
    func setVolume(_ volume: Float) {}
    func setRate(_ rate: Float) {}
    func currentTime() -> TimeInterval { 0 }
    func duration() -> TimeInterval { 0 }
    func isPlaying() -> Bool { false }
}
