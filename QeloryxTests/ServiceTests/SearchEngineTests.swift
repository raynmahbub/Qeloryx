// QELORYX — CoreTests
// SearchEngineTests.swift
//
// BUG-14. The search index observed exactly one change type and rebuilt with a
// hard-coded empty playlist list, so:
//   • adding a library (`.fullReload`) left the index stale
//   • playlists never appeared in results
// These tests pin the subscriptions and the coalescing behaviour.

import XCTest
#if canImport(QeloryxCore)
@testable import QeloryxCore
#else
// The XcodeGen app target is a single module named `Qeloryx` (App + Core +
// Features + Platform + DesignSystem compiled together), so `QeloryxCore` does
// not exist there. `swift test` uses the multi-module SPM targets above.
@testable import Qeloryx
#endif

final class SearchEngineTests: XCTestCase {

    private var eventBus: AstryxEventBus!
    private var library: StubLibraryEngine!
    private var index: RecordingIndex!
    private var engine: AstryxSearchEngine!

    override func setUp() async throws {
        super.setUp()
        eventBus = AstryxEventBus()
        library = StubLibraryEngine()
        index = RecordingIndex()
        engine = AstryxSearchEngine(
            indexedSearch: index,
            libraryEngine: library,
            eventBus: eventBus
        )
    }

    // MARK: - Rebuild subscriptions

    func testIncrementalChangeTriggersRebuild() async {
        eventBus.publish(.libraryDidChange(changeType: .incremental))
        await waitForRebuilds(atLeast: 1)
        XCTAssertGreaterThanOrEqual(await index.rebuildCount, 1)
    }

    /// The original bug: `.fullReload` was not observed.
    func testFullReloadTriggersRebuild() async {
        eventBus.publish(.libraryDidChange(changeType: .fullReload))
        await waitForRebuilds(atLeast: 1)
        XCTAssertGreaterThanOrEqual(await index.rebuildCount, 1)
    }

    func testFavoritesChangeTriggersRebuild() async {
        eventBus.publish(.libraryDidChange(changeType: .favorites))
        await waitForRebuilds(atLeast: 1)
        XCTAssertGreaterThanOrEqual(await index.rebuildCount, 1)
    }

    func testTrackUpdateTriggersRebuild() async {
        eventBus.publish(.trackUpdated(id: "t1"))
        await waitForRebuilds(atLeast: 1)
        XCTAssertGreaterThanOrEqual(await index.rebuildCount, 1)
    }

    /// Unrelated traffic must not cause full library reads.
    func testPlaybackEventsDoNotRebuild() async {
        eventBus.publish(.trackStarted(trackID: "t1", queueID: "q1"))
        eventBus.publish(.playbackStateChanged(state: PlaybackStateSnapshot(
            trackID: "t1",
            isPlaying: true,
            position: 1,
            duration: 10,
            queueVersion: 1,
            shuffleEnabled: false,
            repeatMode: .off
        )))
        // Give a wrongly-scheduled rebuild time to appear.
        try? await Task.sleep(nanoseconds: 120_000_000)
        XCTAssertEqual(await index.rebuildCount, 0)
    }

    /// A burst of events must not become a burst of O(library) reads.
    func testEventBurstIsCoalesced() async {
        for _ in 0..<25 {
            eventBus.publish(.libraryDidChange(changeType: .incremental))
        }
        await waitForRebuilds(atLeast: 1)
        try? await Task.sleep(nanoseconds: 150_000_000)
        let count = await index.rebuildCount
        XCTAssertLessThanOrEqual(count, 3, "25 events produced \(count) full rebuilds")
    }

    // MARK: - Index contents

    func testPlaylistsReachTheIndex() async {
        library.playlists = [AstryxPlaylist(id: "p1", name: "Night Drive", trackIDs: ["t1"])]

        await engine.rebuildIndex()

        XCTAssertEqual(await index.lastPlaylists.map(\.id), ["p1"],
                       "playlists were replaced with a hard-coded empty array")
    }

    func testEmptyLibraryStillBuilds() async {
        await engine.rebuildIndex()
        XCTAssertEqual(await index.lastTracks.count, 0)
        XCTAssertGreaterThanOrEqual(await index.rebuildCount, 1)
    }

    // MARK: - Helpers

    private func waitForRebuilds(atLeast target: Int, timeout: TimeInterval = 2) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if await index.rebuildCount >= target { return }
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
    }
}

// MARK: - Doubles

private final class RecordingIndex: IndexedSearchProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var _rebuildCount = 0
    private var _lastTracks: [AstryxTrack] = []
    private var _lastPlaylists: [AstryxPlaylist] = []

    var rebuildCount: Int { lock.lock(); defer { lock.unlock() }; return _rebuildCount }
    var lastTracks: [AstryxTrack] { lock.lock(); defer { lock.unlock() }; return _lastTracks }
    var lastPlaylists: [AstryxPlaylist] { lock.lock(); defer { lock.unlock() }; return _lastPlaylists }

    func buildIndex(
        tracks: [AstryxTrack],
        albums: [AstryxAlbum],
        artists: [AstryxArtist],
        playlists: [AstryxPlaylist]
    ) async {
        lock.lock()
        _rebuildCount += 1
        _lastTracks = tracks
        _lastPlaylists = playlists
        lock.unlock()
    }

    func search(query: SearchQuery) async -> [AstryxSearchResult] { [] }
    func incrementalUpdate(track: AstryxTrack) async {}
    func removeTrack(id: String) async {}
}

/// Implements only what `SearchEngine` reads during a rebuild; the rest of the
/// protocol is inert so the stub stays honest about what is exercised.
private final class StubLibraryEngine: LibraryEngineProtocol, @unchecked Sendable {
    var tracks: [AstryxTrack] = []
    var playlists: [AstryxPlaylist] = []

    func fetchAllTracks() async throws -> [AstryxTrack] { tracks }
    func fetchAlbums() async throws -> [AstryxAlbum] { [] }
    func fetchArtists() async throws -> [AstryxArtist] { [] }
    func fetchPlaylists() async throws -> [AstryxPlaylist] { playlists }
    func fetchGenres() async throws -> [AstryxGenre] { [] }

    // MARK: Unused surface

    func fetchTrack(id: String) async throws -> AstryxTrack? { tracks.first { $0.id == id } }
    func searchTracks(query: String) async throws -> [AstryxTrack] { [] }
    func fetchTracks(forAlbum album: String, artist: String?) async throws -> [AstryxTrack] { [] }
    func fetchTracks(forArtist artist: String) async throws -> [AstryxTrack] { [] }
    func fetchTracks(forGenre genre: String) async throws -> [AstryxTrack] { [] }
    func fetchTracks(inFolder folderPath: String) async throws -> [AstryxTrack] { [] }
    func fetchAlbum(id: String) async throws -> AstryxAlbum? { nil }
    func fetchAlbums(forArtist artist: String) async throws -> [AstryxAlbum] { [] }
    func fetchFolders(forLibrary libraryID: String) async throws -> [AstryxFolder] { [] }
    func fetchLibraries() async throws -> [AstryxLibrary] { [] }
    func fetchLibrary(id: String) async throws -> AstryxLibrary? { nil }
    func addLibrary(name: String, rootURL: URL, type: LibraryType) async throws -> AstryxLibrary {
        AstryxLibrary(name: name, rootURL: rootURL, type: type)
    }
    func removeLibrary(id: String) async throws {}
    func enableLibrary(id: String) async throws {}
    func disableLibrary(id: String) async throws {}
    func fetchFavorites() async throws -> [AstryxTrack] { [] }
    func fetchRecentlyAdded(limit: Int) async throws -> [AstryxTrack] { [] }
    func fetchHistory(limit: Int) async throws -> [AstryxTrack] { [] }
    func fetchMostPlayed(limit: Int) async throws -> [AstryxTrack] { [] }
    func toggleFavorite(trackID: String) async throws {}
    func recordPlay(trackID: String) async throws {}
    func createPlaylist(name: String, trackIDs: [String]) async throws -> AstryxPlaylist {
        AstryxPlaylist(name: name, trackIDs: trackIDs)
    }
    func updatePlaylist(_ playlist: AstryxPlaylist) async throws {}
    func deletePlaylist(id: String) async throws {}
    func upsertTrack(_ track: AstryxTrack) async throws -> AstryxTrack { track }
    func startIndexing(rootURLs: [URL]) async throws -> IndexingResult {
        IndexingResult(newTracks: 0, updatedTracks: 0, removedTracks: 0, duration: 0)
    }
    func startIndexing(libraryID: String) async throws -> IndexingResult {
        IndexingResult(newTracks: 0, updatedTracks: 0, removedTracks: 0, duration: 0)
    }
    func startIndexingAllLibraries() async throws -> [IndexingResult] { [] }
    func scanForDuplicates() async throws -> [[AstryxTrack]] { [] }
    func stats() async throws -> LibraryStats {
        LibraryStats(
            trackCount: tracks.count,
            albumCount: 0,
            artistCount: 0,
            totalDuration: 0,
            totalSize: 0,
            favoriteCount: 0
        )
    }
}
