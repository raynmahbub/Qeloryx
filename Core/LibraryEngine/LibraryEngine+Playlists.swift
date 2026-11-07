// QELORYX — LibraryEngine
// LibraryEngine+Playlists.swift
//
// Playlist CRUD and `upsertTrack`. Split out of `LibraryEngine.swift` to keep
// `AstryxLibraryEngine` inside the 400-line `type_body_length` limit.

import Foundation

extension AstryxLibraryEngine {

    // MARK: - Playlists (BUG: fetchPlaylists() used to return [])

    public func fetchPlaylists() async throws -> [AstryxPlaylist] {
        try await storage.fetchPlaylists()
    }

    public func createPlaylist(name: String, trackIDs: [String]) async throws -> AstryxPlaylist {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let playlist = AstryxPlaylist(
            name: trimmed.isEmpty ? "New Playlist" : trimmed,
            trackIDs: trackIDs
        )
        try await storage.insertPlaylist(playlist)
        eventBus.publish(.playlistChanged(id: playlist.id))
        return playlist
    }

    public func updatePlaylist(_ playlist: AstryxPlaylist) async throws {
        var updated = playlist
        updated.dateModified = Date()
        try await storage.updatePlaylist(updated)
        eventBus.publish(.playlistChanged(id: updated.id))
    }

    public func deletePlaylist(id: String) async throws {
        try await storage.deletePlaylist(id: id)
        eventBus.publish(.playlistChanged(id: id))
    }

    // MARK: - Upsert (downloads, duplicate resolution)

    /// Stores a pre-validated track. If a track with the same content
    /// fingerprint already exists, the existing record is returned and nothing
    /// is inserted, so imports and downloads cannot create hidden duplicates.
    @discardableResult
    public func upsertTrack(_ track: AstryxTrack) async throws -> AstryxTrack {
        if let checksum = track.checksum, !checksum.isEmpty {
            let existing = try await storage.fetchTracks(predicate: nil)
            if let duplicate = existing.first(where: { $0.checksum == checksum }) {
                return duplicate
            }
        }
        try await storage.insertTrack(track)
        eventBus.publish(.trackAdded(id: track.id))
        eventBus.publish(.libraryDidChange(changeType: .incremental))
        return track
    }

    public func scanForDuplicates() async throws -> [[AstryxTrack]] {
        let allTracks = try await storage.fetchTracks(predicate: nil)
        let indexer = AstryxLibraryIndexer()
        return indexer.detectDuplicates(in: allTracks)
    }
    
    public func stats() async throws -> LibraryStats {
        let trackCount = try await storage.totalTrackCount()
        let albums = try await storage.fetchAlbums()
        let artists = try await storage.fetchArtists()
        let totalDuration = try await storage.totalDuration()
        let totalSize = try await storage.totalSize()
        let favorites = try await storage.fetchFavorites()
        
        return LibraryStats(
            trackCount: trackCount,
            albumCount: albums.count,
            artistCount: artists.count,
            totalDuration: totalDuration,
            totalSize: totalSize,
            favoriteCount: favorites.count
        )
    }
}

public enum LibraryError: Error, LocalizedError {
    case libraryNotFound(id: String)
    case indexingFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .libraryNotFound(let id): return "Library not found: \(id)"
        case .indexingFailed(let msg): return "Indexing failed: \(msg)"
        }
    }

}
