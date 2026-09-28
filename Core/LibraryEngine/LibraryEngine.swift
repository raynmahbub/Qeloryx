// QELORYX — LibraryEngine
// LibraryEngine.swift
// Central engine for Library DNA

import Foundation

// MARK: - LibraryEngine Protocol

public protocol LibraryEngineProtocol: Sendable {
    func fetchAllTracks() async throws -> [AstryxTrack]
    func fetchTrack(id: String) async throws -> AstryxTrack?
    func searchTracks(query: String) async throws -> [AstryxTrack]
    func fetchAlbums() async throws -> [AstryxAlbum]
    func fetchArtists() async throws -> [AstryxArtist]
    func fetchFavorites() async throws -> [AstryxTrack]
    func fetchRecentlyAdded(limit: Int) async throws -> [AstryxTrack]
    func toggleFavorite(trackID: String) async throws
    func recordPlay(trackID: String) async throws
    func startIndexing(rootURLs: [URL]) async throws -> IndexingResult
}

// MARK: - AstryxLibraryEngine

public final class AstryxLibraryEngine: LibraryEngineProtocol {
    
    private let storage: any SwiftDataStackProtocol
    private let indexer: any LibraryIndexerProtocol
    private let artworkCache: any ArtworkCacheProtocol
    private let eventBus: any EventBusProtocol
    
    public init(
        storage: any SwiftDataStackProtocol = InMemorySwiftDataStack(),
        indexer: any LibraryIndexerProtocol = AstryxLibraryIndexer(),
        artworkCache: any ArtworkCacheProtocol = AstryxArtworkCache(),
        eventBus: any EventBusProtocol = AstryxEventBus.shared
    ) {
        self.storage = storage
        self.indexer = indexer
        self.artworkCache = artworkCache
        self.eventBus = eventBus
    }
    
    public func fetchAllTracks() async throws -> [AstryxTrack] {
        try await storage.fetchTracks(predicate: nil)
    }
    
    public func fetchTrack(id: String) async throws -> AstryxTrack? {
        let tracks = try await storage.fetchTracks(predicate: nil)
        return tracks.first { $0.id == id }
    }
    
    public func searchTracks(query: String) async throws -> [AstryxTrack] {
        try await storage.fetchTracks(predicate: TrackPredicate(searchText: query))
    }
    
    public func fetchAlbums() async throws -> [AstryxAlbum] {
        try await storage.fetchAlbums()
    }
    
    public func fetchArtists() async throws -> [AstryxArtist] {
        try await storage.fetchArtists()
    }
    
    public func fetchFavorites() async throws -> [AstryxTrack] {
        try await storage.fetchFavorites()
    }
    
    public func fetchRecentlyAdded(limit: Int) async throws -> [AstryxTrack] {
        try await storage.fetchRecentlyAdded(limit: limit)
    }
    
    public func toggleFavorite(trackID: String) async throws {
        guard var track = try await fetchTrack(id: trackID) else { return }
        track.isFavorite.toggle()
        try await storage.updateTrack(track)
        eventBus.publish(.trackUpdated(id: trackID))
        eventBus.publish(.libraryDidChange(changeType: .favorites))
    }
    
    public func recordPlay(trackID: String) async throws {
        guard var track = try await fetchTrack(id: trackID) else { return }
        track.playCount += 1
        track.lastPlayed = Date()
        try await storage.updateTrack(track)
        eventBus.publish(.trackUpdated(id: trackID))
        eventBus.publish(.libraryDidChange(changeType: .history))
    }
    
    public func startIndexing(rootURLs: [URL]) async throws -> IndexingResult {
        try await indexer.startIncrementalIndex(rootURLs: rootURLs)
    }
}
