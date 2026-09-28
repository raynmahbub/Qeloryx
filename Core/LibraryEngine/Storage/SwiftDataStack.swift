// QELORYX — LibraryEngine
// SwiftDataStack.swift
// Abstraction over SwiftData for offline-first persistence

import Foundation

// MARK: - SwiftDataStack Protocol (Portable)

public protocol SwiftDataStackProtocol: Sendable {
    func fetchTracks(predicate: TrackPredicate?) async throws -> [AstryxTrack]
    func fetchAlbums() async throws -> [AstryxAlbum]
    func fetchArtists() async throws -> [AstryxArtist]
    func fetchPlaylists() async throws -> [AstryxPlaylist]
    
    func insertTrack(_ track: AstryxTrack) async throws
    func insertTracks(_ tracks: [AstryxTrack]) async throws
    func updateTrack(_ track: AstryxTrack) async throws
    func deleteTrack(id: String) async throws
    
    func fetchRecentlyAdded(limit: Int) async throws -> [AstryxTrack]
    func fetchFavorites() async throws -> [AstryxTrack]
    func fetchHistory(limit: Int) async throws -> [AstryxTrack]
}

public struct TrackPredicate: Sendable {
    public var searchText: String?
    public var artist: String?
    public var album: String?
    public var genre: String?
    public var isFavorite: Bool?
    public var folderPath: String?
    
    public init(searchText: String? = nil, artist: String? = nil, album: String? = nil, genre: String? = nil, isFavorite: Bool? = nil, folderPath: String? = nil) {
        self.searchText = searchText
        self.artist = artist
        self.album = album
        self.genre = genre
        self.isFavorite = isFavorite
        self.folderPath = folderPath
    }
}

// MARK: - In-Memory Implementation (Foundation)

public final class InMemorySwiftDataStack: SwiftDataStackProtocol, @unchecked Sendable {
    private var tracks: [String: AstryxTrack] = [:]
    private let lock = NSLock()
    
    public init() {}
    
    public func fetchTracks(predicate: TrackPredicate?) async throws -> [AstryxTrack] {
        lock.lock()
        defer { lock.unlock() }
        var result = Array(tracks.values)
        
        if let p = predicate {
            if let search = p.searchText?.lowercased(), !search.isEmpty {
                result = result.filter {
                    $0.title.lowercased().contains(search) ||
                    $0.artist.lowercased().contains(search) ||
                    $0.album.lowercased().contains(search)
                }
            }
            if let artist = p.artist {
                result = result.filter { $0.artist == artist }
            }
            if let album = p.album {
                result = result.filter { $0.album == album }
            }
            if let genre = p.genre {
                result = result.filter { $0.genre == genre }
            }
            if let fav = p.isFavorite {
                result = result.filter { $0.isFavorite == fav }
            }
            if let folder = p.folderPath {
                result = result.filter { $0.folderPath == folder }
            }
        }
        
        return result
    }
    
    public func fetchAlbums() async throws -> [AstryxAlbum] {
        let allTracks = try await fetchTracks(predicate: nil)
        let grouped = Dictionary(grouping: allTracks) { $0.album }
        return grouped.map { (albumName, tracks) in
            AstryxAlbum(
                title: albumName,
                artist: tracks.first?.artist ?? "Unknown",
                trackCount: tracks.count,
                duration: tracks.reduce(0) { $0 + $1.duration },
                tracks: tracks
            )
        }
    }
    
    public func fetchArtists() async throws -> [AstryxArtist] {
        let allTracks = try await fetchTracks(predicate: nil)
        let grouped = Dictionary(grouping: allTracks) { $0.artist }
        return grouped.map { (artistName, tracks) in
            let albums = Set(tracks.map { $0.album }).count
            return AstryxArtist(name: artistName, albumCount: albums, trackCount: tracks.count)
        }
    }
    
    public func fetchPlaylists() async throws -> [AstryxPlaylist] {
        return [] // Foundation: no playlists yet
    }
    
    public func insertTrack(_ track: AstryxTrack) async throws {
        lock.lock()
        tracks[track.id] = track
        lock.unlock()
    }
    
    public func insertTracks(_ tracks: [AstryxTrack]) async throws {
        lock.lock()
        for track in tracks {
            self.tracks[track.id] = track
        }
        lock.unlock()
    }
    
    public func updateTrack(_ track: AstryxTrack) async throws {
        try await insertTrack(track)
    }
    
    public func deleteTrack(id: String) async throws {
        lock.lock()
        tracks.removeValue(forKey: id)
        lock.unlock()
    }
    
    public func fetchRecentlyAdded(limit: Int) async throws -> [AstryxTrack] {
        let all = try await fetchTracks(predicate: nil)
        return Array(all.sorted { $0.dateAdded > $1.dateAdded }.prefix(limit))
    }
    
    public func fetchFavorites() async throws -> [AstryxTrack] {
        try await fetchTracks(predicate: TrackPredicate(isFavorite: true))
    }
    
    public func fetchHistory(limit: Int) async throws -> [AstryxTrack] {
        let all = try await fetchTracks(predicate: nil)
        return Array(all.filter { $0.lastPlayed != nil }.sorted { ($0.lastPlayed ?? .distantPast) > ($1.lastPlayed ?? .distantPast) }.prefix(limit))
    }
}
