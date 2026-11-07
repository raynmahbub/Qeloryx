// QELORYX — App
// UnconfiguredDependencies.swift
//
// Inert stand-ins for the environment defaults.
//
// These exist so a missing `.environment(\.someEngine, …)` injection is
// *visible* rather than plausible. The previous defaults constructed real
// engines, so a view that never received its dependency got a working engine
// with its own empty store and simply rendered nothing — indistinguishable from
// an empty library. Everything here refuses to do work instead of pretending.

import Foundation

// MARK: - Audio

/// An `AstryxAudioEngineProtocol` that refuses every command.
///
/// Reports `.stopped` and throws `PlaybackError.noPlaybackSource` for anything
/// that would produce audio, so a mis-wired player surfaces an error instead of
/// silently playing nothing.
public final class UnconfiguredAudioEngine: AstryxAudioEngineProtocol, @unchecked Sendable {

    public init() {}

    public var playbackState: AstryxPlaybackState { .stopped }

    public var currentQueue: AstryxQueue { AstryxQueue() }

    public func handle(command: AstryxPlaybackCommand) async throws {
        throw PlaybackError.noPlaybackSource
    }

    public func restoreQueue(trackIDs: [String], startIndex: Int) async {
        // Restoring nothing is the honest result: there is no engine to restore.
    }

    public func restorePausedState(trackID: String, position: TimeInterval) {
        // No-op for the same reason.
    }

    public func currentTrack() async -> AstryxTrack? { nil }

    public func seek(to: TimeInterval) async throws {
        throw PlaybackError.noPlaybackSource
    }

    public func setVolume(_ volume: Float) async throws {
        throw PlaybackError.noPlaybackSource
    }
}

// MARK: - Library

/// A `LibraryEngineProtocol` that holds nothing and indexes nothing.
///
/// Read-only calls return empty collections; mutations do nothing. Deliberately
/// does **not** throw on reads: an un-injected library should look empty, and
/// the console warning is what tells you why.
public final class UnconfiguredLibraryEngine: LibraryEngineProtocol, @unchecked Sendable {

    public init() {}

    // MARK: Reads

    public func fetchAllTracks() async throws -> [AstryxTrack] { [] }
    public func fetchTrack(id: String) async throws -> AstryxTrack? { nil }
    public func searchTracks(query: String) async throws -> [AstryxTrack] { [] }
    public func fetchTracks(forAlbum album: String, artist: String?) async throws -> [AstryxTrack] { [] }
    public func fetchTracks(forArtist artist: String) async throws -> [AstryxTrack] { [] }
    public func fetchTracks(forGenre genre: String) async throws -> [AstryxTrack] { [] }
    public func fetchTracks(inFolder folderPath: String) async throws -> [AstryxTrack] { [] }
    public func fetchAlbums() async throws -> [AstryxAlbum] { [] }
    public func fetchAlbum(id: String) async throws -> AstryxAlbum? { nil }
    public func fetchAlbums(forArtist artist: String) async throws -> [AstryxAlbum] { [] }
    public func fetchArtists() async throws -> [AstryxArtist] { [] }
    public func fetchGenres() async throws -> [AstryxGenre] { [] }
    public func fetchFolders(forLibrary libraryID: String) async throws -> [AstryxFolder] { [] }
    public func fetchLibraries() async throws -> [AstryxLibrary] { [] }
    public func fetchLibrary(id: String) async throws -> AstryxLibrary? { nil }
    public func fetchFavorites() async throws -> [AstryxTrack] { [] }
    public func fetchRecentlyAdded(limit: Int) async throws -> [AstryxTrack] { [] }
    public func fetchHistory(limit: Int) async throws -> [AstryxTrack] { [] }
    public func fetchMostPlayed(limit: Int) async throws -> [AstryxTrack] { [] }
    public func fetchPlaylists() async throws -> [AstryxPlaylist] { [] }

    // MARK: Libraries

    public func addLibrary(name: String, rootURL: URL, type: LibraryType) async throws -> AstryxLibrary {
        throw LibraryError.indexingFailed("no library engine was injected")
    }

    public func removeLibrary(id: String) async throws {}
    public func enableLibrary(id: String) async throws {}
    public func disableLibrary(id: String) async throws {}

    // MARK: Mutations

    public func toggleFavorite(trackID: String) async throws {}
    public func recordPlay(trackID: String) async throws {}

    public func createPlaylist(name: String, trackIDs: [String]) async throws -> AstryxPlaylist {
        throw LibraryError.indexingFailed("no library engine was injected")
    }

    public func updatePlaylist(_ playlist: AstryxPlaylist) async throws {}
    public func deletePlaylist(id: String) async throws {}

    public func upsertTrack(_ track: AstryxTrack) async throws -> AstryxTrack {
        throw LibraryError.indexingFailed("no library engine was injected")
    }

    // MARK: Indexing

    public func startIndexing(rootURLs: [URL]) async throws -> IndexingResult {
        throw LibraryError.indexingFailed("no library engine was injected")
    }

    public func startIndexing(libraryID: String) async throws -> IndexingResult {
        throw LibraryError.indexingFailed("no library engine was injected")
    }

    public func startIndexingAllLibraries() async throws -> [IndexingResult] { [] }

    public func scanForDuplicates() async throws -> [[AstryxTrack]] { [] }

    public func stats() async throws -> LibraryStats {
        LibraryStats(
            trackCount: 0,
            albumCount: 0,
            artistCount: 0,
            totalDuration: 0,
            totalSize: 0,
            favoriteCount: 0
        )
    }
}

// MARK: - Downloads

/// A `DownloadSessionProtocol` that never starts a transfer.
///
/// Reports zero disk space available so the engine refuses the download rather
/// than queueing work that can never progress.
public final class UnconfiguredDownloadSession: DownloadSessionProtocol, @unchecked Sendable {

    public init() {}

    public weak var delegate: (any DownloadSessionDelegate)?

    public func startDownload(taskID: String, from url: URL, resumeData: Data?) {}

    public func pauseDownload(taskID: String, completion: @escaping (Data?) -> Void) {
        completion(nil)
    }

    public func cancelDownload(taskID: String) {}

    public func checkDiskSpace(requiredBytes: Int64) -> Bool { false }
}
