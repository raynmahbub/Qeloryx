// QELORYX — CoreTests
// DownloadEngineHonestyTests.swift
//
// BUG-10. With no download session configured, the engine used to fake ten
// progress ticks and report `.completed` — which then ingested a library track
// pointing at a file that was never written. These tests pin the replacement
// behaviour: fail loudly, never claim success, never retry a non-retryable
// condition.

import XCTest
#if canImport(QeloryxCore)
@testable import QeloryxCore
#else
// The XcodeGen app target is a single module named `Qeloryx` (App + Core +
// Features + Platform + DesignSystem compiled together), so `QeloryxCore` does
// not exist there. `swift test` uses the multi-module SPM targets above.
@testable import Qeloryx
#endif

final class DownloadEngineHonestyTests: XCTestCase {

    private var engine: AstryxDownloadEngine!
    private var store: InMemoryDownloadTaskStore!
    private var directory: URL!

    override func setUp() {
        super.setUp()
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("QeloryxDL-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        store = InMemoryDownloadTaskStore()
        // No downloadSession: exactly the state that used to simulate success.
        engine = AstryxDownloadEngine(maxConcurrent: 2, taskStore: store)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        super.tearDown()
    }

    private func enqueue(_ id: String) async {
        await engine.enqueue(
            task: AstryxDownloadTask(
                id: id,
                trackID: "track-\(id)",
                sourceURL: URL(string: "https://example.com/\(id).m4a")!,
                destinationURL: directory.appendingPathComponent("\(id).m4a")
            )
        )
    }

    func testDownloadWithoutSessionFailsInsteadOfPretendingToComplete() async {
        await enqueue("a")

        // Give the queue a moment to attempt the transfer.
        try? await Task.sleep(nanoseconds: 300_000_000)

        let task = await engine.task(id: "a")
        XCTAssertNotNil(task)
        XCTAssertNotEqual(task?.state, .completed, "a download that never ran must not report success")
        XCTAssertEqual(task?.state, .failed)
        XCTAssertEqual(task?.error, .noDownloadSession)
    }

    func testNoDownloadSessionIsNotRetried() async {
        await enqueue("a")
        try? await Task.sleep(nanoseconds: 500_000_000)

        let task = await engine.task(id: "a")
        XCTAssertEqual(task?.retryCount, 0, "a missing session is permanent; retrying burns the budget")
    }

    func testFailureIsPersistedSoItSurvivesRelaunch() async {
        await enqueue("a")
        try? await Task.sleep(nanoseconds: 300_000_000)

        let persisted = store.load()
        XCTAssertEqual(persisted.count, 1, "the failed task must be durable, not only in memory")
        XCTAssertEqual(persisted.first?.state, .failed)
    }

    func testErrorClassification() {
        XCTAssertFalse(DownloadError.noDownloadSession.isRetryable)
        XCTAssertTrue(DownloadError.networkError("timeout").isRetryable)
        XCTAssertFalse(DownloadError.invalidURL.isRetryable)
        XCTAssertFalse(DownloadError.cancelled.isRetryable)
    }

    func testFailedTaskDoesNotCreateALibraryTrack() async {
        let library = RecordingLibrary()
        let engineWithLibrary = AstryxDownloadEngine(
            maxConcurrent: 1,
            taskStore: InMemoryDownloadTaskStore(),
            library: library
        )
        await engineWithLibrary.enqueue(
            task: AstryxDownloadTask(
                id: "b",
                trackID: "track-b",
                sourceURL: URL(string: "https://example.com/b.m4a")!,
                destinationURL: directory.appendingPathComponent("b.m4a")
            )
        )
        try? await Task.sleep(nanoseconds: 400_000_000)

        XCTAssertEqual(library.upserted.count, 0,
                       "a failed download must never be indexed as a track")
    }
}

// MARK: - Doubles

private final class RecordingLibrary: LibraryEngineProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var _upserted: [AstryxTrack] = []
    var upserted: [AstryxTrack] { lock.lock(); defer { lock.unlock() }; return _upserted }

    func upsertTrack(_ track: AstryxTrack) async throws -> AstryxTrack {
        lock.lock(); _upserted.append(track); lock.unlock()
        return track
    }

    func fetchAllTracks() async throws -> [AstryxTrack] { [] }
    func fetchTrack(id: String) async throws -> AstryxTrack? { nil }
    func searchTracks(query: String) async throws -> [AstryxTrack] { [] }
    func fetchTracks(forAlbum album: String, artist: String?) async throws -> [AstryxTrack] { [] }
    func fetchTracks(forArtist artist: String) async throws -> [AstryxTrack] { [] }
    func fetchTracks(forGenre genre: String) async throws -> [AstryxTrack] { [] }
    func fetchTracks(inFolder folderPath: String) async throws -> [AstryxTrack] { [] }
    func fetchAlbums() async throws -> [AstryxAlbum] { [] }
    func fetchAlbum(id: String) async throws -> AstryxAlbum? { nil }
    func fetchAlbums(forArtist artist: String) async throws -> [AstryxAlbum] { [] }
    func fetchArtists() async throws -> [AstryxArtist] { [] }
    func fetchGenres() async throws -> [AstryxGenre] { [] }
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
    func fetchPlaylists() async throws -> [AstryxPlaylist] { [] }
    func createPlaylist(name: String, trackIDs: [String]) async throws -> AstryxPlaylist {
        AstryxPlaylist(name: name, trackIDs: trackIDs)
    }
    func updatePlaylist(_ playlist: AstryxPlaylist) async throws {}
    func deletePlaylist(id: String) async throws {}
    func startIndexing(rootURLs: [URL]) async throws -> IndexingResult {
        IndexingResult(newTracks: 0, updatedTracks: 0, removedTracks: 0, duration: 0)
    }
    func startIndexing(libraryID: String) async throws -> IndexingResult {
        IndexingResult(newTracks: 0, updatedTracks: 0, removedTracks: 0, duration: 0)
    }
    func startIndexingAllLibraries() async throws -> [IndexingResult] { [] }
    func scanForDuplicates() async throws -> [[AstryxTrack]] { [] }
    func stats() async throws -> LibraryStats {
        LibraryStats(trackCount: 0, albumCount: 0, artistCount: 0,
                     totalDuration: 0, totalSize: 0, favoriteCount: 0)
    }
}
