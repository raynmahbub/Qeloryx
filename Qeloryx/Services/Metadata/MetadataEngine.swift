// QELORYX — Services/Metadata
// MetadataEngine.swift
// QEL-024 Library — Production metadata extraction with AVAsset + fallback

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
    public var bitRate: Int?
    public var sampleRate: Int?
    public var bitDepth: Int?

    public init(
        title: String? = nil,
        artist: String? = nil,
        album: String? = nil,
        albumArtist: String? = nil,
        genre: String? = nil,
        year: Int? = nil,
        trackNumber: Int? = nil,
        discNumber: Int? = nil,
        duration: TimeInterval? = nil,
        artworkData: Data? = nil,
        lyrics: String? = nil,
        bitRate: Int? = nil,
        sampleRate: Int? = nil,
        bitDepth: Int? = nil
    ) {
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
        self.bitRate = bitRate
        self.sampleRate = sampleRate
        self.bitDepth = bitDepth
    }
}

public protocol MetadataEngineProtocol: Sendable {
    func extractMetadata(from url: URL) async throws -> RawMetadata
    func supportedFormats() -> [AudioFormat]
    func isSupported(url: URL) -> Bool
}

// MARK: - AstryxMetadataEngine — QEL-024 Production

public final class AstryxMetadataEngine: MetadataEngineProtocol {
    
    public init() {}
    
    public func supportedFormats() -> [AudioFormat] {
        AudioFormat.supportedFormats
    }
    
    public func isSupported(url: URL) -> Bool {
        let format = AudioFormat.fromExtension(url.pathExtension)
        return format != .unknown
    }
    
    /// Filename-only fallback.
    ///
    /// The real AVAsset extraction lives in
    /// `Qeloryx/Platform/Audio/MetadataExtractor.swift` (`AstryxMetadataExtractor`) and
    /// must be injected by the composition root. This Core type deliberately
    /// does **not** pretend to read tags: the previous implementation returned
    /// `nil` from a stub and silently fell back to guessing from filenames,
    /// which is why imported tracks had no artist, artwork or duration (BUG-25).
    public func extractMetadata(from url: URL) async throws -> RawMetadata {
        return extractViaFileName(url: url)
    }
    
    private func extractViaFileName(url: URL) -> RawMetadata {
        let fileName = url.deletingPathExtension().lastPathComponent
        
        // Try to parse "Artist - Album - Title" or "Artist - Title" or "TrackNumber Title"
        var title: String?
        var artist: String?
        var album: String?
        
        // Pattern: "Artist - Title"
        let dashComponents = fileName.components(separatedBy: " - ")
        if dashComponents.count >= 2 {
            // Check if first component is track number
            let first = dashComponents[0].trimmingCharacters(in: .whitespaces)
            if let _ = Int(first) {
                // Track number + title
                title = dashComponents[1...].joined(separator: " - ").trimmingCharacters(in: .whitespaces)
            } else {
                artist = first
                if dashComponents.count >= 3 {
                    album = dashComponents[1].trimmingCharacters(in: .whitespaces)
                    title = dashComponents[2...].joined(separator: " - ").trimmingCharacters(in: .whitespaces)
                } else {
                    title = dashComponents[1...].joined(separator: " - ").trimmingCharacters(in: .whitespaces)
                }
            }
        } else {
            // Try "Artist_Title" or just file name
            title = fileName
        }
        
        // Clean up title: remove track number prefix like "01 - " or "01."
        if let t = title {
            let cleaned = t.replacingOccurrences(of: #"^\d+\s*[-.]\s*"#, with: "", options: .regularExpression)
            title = cleaned
        }
        
        return RawMetadata(
            title: title,
            artist: artist,
            album: album,
            duration: nil,
            artworkData: nil
        )
    }
}

// MARK: - Platform Metadata Extractor (Real AVFoundation implementation would be here)
// For QEL-024 we create a separate file in Platform for real extraction
