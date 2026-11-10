// QELORYX — Models/Music
// Album.swift

import Foundation

public struct AstryxAlbum: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public var title: String
    public var artist: String
    public var albumArtist: String?
    public var year: Int?
    public var genre: String?
    public var trackCount: Int
    public var duration: TimeInterval
    public var artworkURL: URL?
    public var tracks: [AstryxTrack] // Could be IDs for large libs, but struct for simplicity in foundation
    public var dateAdded: Date
    public var isFavorite: Bool
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        artist: String,
        albumArtist: String? = nil,
        year: Int? = nil,
        genre: String? = nil,
        trackCount: Int = 0,
        duration: TimeInterval = 0,
        artworkURL: URL? = nil,
        tracks: [AstryxTrack] = [],
        dateAdded: Date = Date(),
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.albumArtist = albumArtist
        self.year = year
        self.genre = genre
        self.trackCount = trackCount
        self.duration = duration
        self.artworkURL = artworkURL
        self.tracks = tracks
        self.dateAdded = dateAdded
        self.isFavorite = isFavorite
    }
    
    public var displayTitle: String { title.isEmpty ? "Unknown Album" : title }
}
