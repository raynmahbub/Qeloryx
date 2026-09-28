// QELORYX — Platform
// SwiftDataAdapter.swift
// Isolates SwiftData — only place where SwiftData is imported

import Foundation
#if canImport(SwiftData)
import SwiftData

// MARK: - SwiftData Models (real implementation)

@Model
final class TrackModel {
    @Attribute(.unique) var id: String
    var title: String
    var artist: String
    var album: String
    var duration: TimeInterval
    var fileURLString: String
    var fileFormatRaw: String
    var dateAdded: Date
    var isFavorite: Bool
    var playCount: Int
    
    init(id: String, title: String, artist: String, album: String, duration: TimeInterval, fileURLString: String, fileFormatRaw: String, dateAdded: Date, isFavorite: Bool, playCount: Int) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.fileURLString = fileURLString
        self.fileFormatRaw = fileFormatRaw
        self.dateAdded = dateAdded
        self.isFavorite = isFavorite
        self.playCount = playCount
    }
}

public final class SwiftDataAdapter: SwiftDataStackProtocol {
    
    private let container: ModelContainer
    private let context: ModelContext
    
    public init() throws {
        let schema = Schema([TrackModel.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }
    
    // Implement protocol by mapping between AstryxTrack and TrackModel
    public func fetchTracks(predicate: TrackPredicate?) async throws -> [AstryxTrack] {
        // Real implementation would use #Predicate and FetchDescriptor
        // Foundation placeholder returns empty, to be implemented in Library milestone
        return []
    }
    
    public func fetchAlbums() async throws -> [AstryxAlbum] { [] }
    public func fetchArtists() async throws -> [AstryxArtist] { [] }
    public func fetchPlaylists() async throws -> [AstryxPlaylist] { [] }
    public func insertTrack(_ track: AstryxTrack) async throws {}
    public func insertTracks(_ tracks: [AstryxTrack]) async throws {}
    public func updateTrack(_ track: AstryxTrack) async throws {}
    public func deleteTrack(id: String) async throws {}
    public func fetchRecentlyAdded(limit: Int) async throws -> [AstryxTrack] { [] }
    public func fetchFavorites() async throws -> [AstryxTrack] { [] }
    public func fetchHistory(limit: Int) async throws -> [AstryxTrack] { [] }
}

#else

// Fallback for Linux / non-Apple — uses InMemory stack
public typealias SwiftDataAdapter = InMemorySwiftDataStack

#endif
