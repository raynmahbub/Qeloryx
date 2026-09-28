// QELORYX — SearchEngine
// SearchResult.swift

import Foundation

public enum SearchResultType: String, Sendable, Equatable {
    case track
    case album
    case artist
    case playlist
    case folder
    case lyrics
}

public struct AstryxSearchResult: Identifiable, Sendable, Equatable {
    public let id: String
    public let type: SearchResultType
    public let title: String
    public let subtitle: String
    public let trackID: String?
    public let albumID: String?
    public let artistID: String?
    public let score: Double
    public let matchedFields: [String]
    
    public init(id: String = UUID().uuidString, type: SearchResultType, title: String, subtitle: String, trackID: String? = nil, albumID: String? = nil, artistID: String? = nil, score: Double, matchedFields: [String] = []) {
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.trackID = trackID
        self.albumID = albumID
        self.artistID = artistID
        self.score = score
        self.matchedFields = matchedFields
    }
}

public struct SearchQuery: Sendable, Equatable {
    public let text: String
    public let filters: SearchFilters
    public let limit: Int
    
    public init(text: String, filters: SearchFilters = SearchFilters(), limit: Int = 50) {
        self.text = text
        self.filters = filters
        self.limit = limit
    }
}

public struct SearchFilters: Sendable, Equatable {
    public var types: Set<SearchResultType>?
    public var artist: String?
    public var album: String?
    public var genre: String?
    
    public init(types: Set<SearchResultType>? = nil, artist: String? = nil, album: String? = nil, genre: String? = nil) {
        self.types = types
        self.artist = artist
        self.album = album
        self.genre = genre
    }
    
    public static var all: SearchFilters { SearchFilters() }
}
