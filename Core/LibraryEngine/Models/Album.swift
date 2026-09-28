// QELORYX — LibraryEngine
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

public struct AstryxArtist: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public var name: String
    public var albumCount: Int
    public var trackCount: Int
    public var artworkURL: URL?
    public var dateAdded: Date
    
    public init(id: String = UUID().uuidString, name: String, albumCount: Int = 0, trackCount: Int = 0, artworkURL: URL? = nil, dateAdded: Date = Date()) {
        self.id = id
        self.name = name
        self.albumCount = albumCount
        self.trackCount = trackCount
        self.artworkURL = artworkURL
        self.dateAdded = dateAdded
    }
}

public struct AstryxPlaylist: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public var name: String
    public var description: String?
    public var trackIDs: [String]
    public var artworkURL: URL?
    public var dateCreated: Date
    public var dateModified: Date
    public var isSmart: Bool
    
    public init(id: String = UUID().uuidString, name: String, description: String? = nil, trackIDs: [String] = [], artworkURL: URL? = nil, dateCreated: Date = Date(), dateModified: Date = Date(), isSmart: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.trackIDs = trackIDs
        self.artworkURL = artworkURL
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.isSmart = isSmart
    }
}
