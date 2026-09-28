// QELORYX — MetadataEngine
// MetadataEngine.swift

import Foundation

public struct RawMetadata: Sendable {
    public var title: String?
    public var artist: String?
    public var album: String?
    public var albumArtist: String?
    public var genre: String?
    public var year: Int?
    public var trackNumber: Int?
    public var discNumber: Int?
    public var duration: TimeInterval?
    public var artworkData: Data?
    public var lyrics: String?
    
    public init(title: String? = nil, artist: String? = nil, album: String? = nil, albumArtist: String? = nil, genre: String? = nil, year: Int? = nil, trackNumber: Int? = nil, discNumber: Int? = nil, duration: TimeInterval? = nil, artworkData: Data? = nil, lyrics: String? = nil) {
        self.title = title
        self.artist = artist
        self.album = album
        self.albumArtist = albumArtist
        self.genre = genre
        self.year = year
        self.trackNumber = trackNumber
        self.discNumber = discNumber
        self.duration = duration
        self.artworkData = artworkData
        self.lyrics = lyrics
    }
}

public protocol MetadataEngineProtocol: Sendable {
    func extractMetadata(from url: URL) async throws -> RawMetadata
    func supportedFormats() -> [AudioFormat]
    func isSupported(url: URL) -> Bool
}

public final class AstryxMetadataEngine: MetadataEngineProtocol {
    
    public init() {}
    
    public func supportedFormats() -> [AudioFormat] {
        AudioFormat.supportedFormats
    }
    
    public func isSupported(url: URL) -> Bool {
        let format = AudioFormat.fromExtension(url.pathExtension)
        return format != .unknown
    }
    
    public func extractMetadata(from url: URL) async throws -> RawMetadata {
        // Foundation: placeholder implementation
        // Real implementation in Platform layer uses AVAsset for metadata
        // This engine just defines the contract
        
        // Simulate extracting from file name
        let fileName = url.deletingPathExtension().lastPathComponent
        
        // Try to parse "Artist - Title" pattern
        let components = fileName.components(separatedBy: " - ")
        var title: String?
        var artist: String?
        
        if components.count >= 2 {
            artist = components[0].trimmingCharacters(in: .whitespaces)
            title = components[1].trimmingCharacters(in: .whitespaces)
        } else {
            title = fileName
        }
        
        return RawMetadata(
            title: title,
            artist: artist,
            album: nil,
            duration: nil,
            artworkData: nil
        )
    }
}
