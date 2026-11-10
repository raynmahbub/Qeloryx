// QELORYX — Models/Music
// Track.swift
// Greenfield — Qeloryx Labs
// Core domain model for audio track

import Foundation

// MARK: - Track

/// Primary entity in QELORYX Library DNA.
/// Represents a single audio file with normalized metadata.
public struct AstryxTrack: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public var title: String
    public var artist: String
    public var album: String
    public var albumArtist: String?
    public var genre: String?
    public var year: Int?
    public var trackNumber: Int?
    public var discNumber: Int?
    public var duration: TimeInterval
    public var fileURL: URL
    public var fileFormat: AudioFormat
    public var fileSize: Int64
    public var bitRate: Int?
    public var sampleRate: Int?
    public var bitDepth: Int?
    public var isLossless: Bool
    public var artworkURL: URL?
    public var artworkData: Data?
    public var dateAdded: Date
    public var dateModified: Date
    public var playCount: Int
    public var lastPlayed: Date?
    public var isFavorite: Bool
    public var lyrics: String?
    public var lrcURL: URL?
    public var folderPath: String?
    public var checksum: String? // Content fingerprint for duplicate detection
    /// Owning library. Previously tracked only in the storage layer, which made
    /// per-library queries impossible (BUG-01 follow-on).
    public var libraryID: String?
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        artist: String,
        album: String,
        albumArtist: String? = nil,
        genre: String? = nil,
        year: Int? = nil,
        trackNumber: Int? = nil,
        discNumber: Int? = nil,
        duration: TimeInterval,
        fileURL: URL,
        fileFormat: AudioFormat,
        fileSize: Int64 = 0,
        bitRate: Int? = nil,
        sampleRate: Int? = nil,
        bitDepth: Int? = nil,
        isLossless: Bool = false,
        artworkURL: URL? = nil,
        artworkData: Data? = nil,
        dateAdded: Date = Date(),
        dateModified: Date = Date(),
        playCount: Int = 0,
        lastPlayed: Date? = nil,
        isFavorite: Bool = false,
        lyrics: String? = nil,
        lrcURL: URL? = nil,
        folderPath: String? = nil,
        checksum: String? = nil,
        libraryID: String? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.albumArtist = albumArtist
        self.genre = genre
        self.year = year
        self.trackNumber = trackNumber
        self.discNumber = discNumber
        self.duration = duration
        self.fileURL = fileURL
        self.fileFormat = fileFormat
        self.fileSize = fileSize
        self.bitRate = bitRate
        self.sampleRate = sampleRate
        self.bitDepth = bitDepth
        self.isLossless = isLossless
        self.artworkURL = artworkURL
        self.artworkData = artworkData
        self.dateAdded = dateAdded
        self.dateModified = dateModified
        self.playCount = playCount
        self.lastPlayed = lastPlayed
        self.isFavorite = isFavorite
        self.lyrics = lyrics
        self.lrcURL = lrcURL
        self.folderPath = folderPath
        self.checksum = checksum
        self.libraryID = libraryID
    }
    
    // MARK: Computed
    
    public var displayTitle: String {
        title.isEmpty ? fileURL.lastPathComponent : title
    }
    
    public var displayArtist: String {
        artist.isEmpty ? "Unknown Artist" : artist
    }
    
    public var displayAlbum: String {
        album.isEmpty ? "Unknown Album" : album
    }
    
    public var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - AudioFormat

public enum AudioFormat: String, Sendable, CaseIterable, Equatable, Hashable {
    case mp3 = "MP3"
    case aac = "AAC"
    case m4a = "M4A"
    case alac = "ALAC"
    case flac = "FLAC"
    case wav = "WAV"
    case aiff = "AIFF"
    case ogg = "OGG"
    case opus = "OPUS"
    case unknown = "UNKNOWN"
    
    public var isLossless: Bool {
        switch self {
        case .alac, .flac, .wav, .aiff:
            return true
        default:
            return false
        }
    }
    
    public var fileExtensions: [String] {
        switch self {
        case .mp3: return ["mp3"]
        case .aac: return ["aac"]
        case .m4a: return ["m4a"]
        case .alac: return ["m4a", "caf"]
        case .flac: return ["flac"]
        case .wav: return ["wav"]
        case .aiff: return ["aiff", "aif"]
        case .ogg: return ["ogg"]
        case .opus: return ["opus"]
        case .unknown: return []
        }
    }
    
    public static func fromExtension(_ ext: String) -> AudioFormat {
        let lower = ext.lowercased()
        for format in AudioFormat.allCases {
            if format.fileExtensions.contains(lower) {
                return format
            }
        }
        return .unknown
    }
    
    /// Formats the current audio path can actually decode on Apple platforms.
    /// Ogg Vorbis and Opus are modelled (so imported files are identified and
    /// reported) but are deliberately excluded here: AVFoundation cannot
    /// decode them without a bundled decoder, and advertising them was a false
    /// capability claim (BUG-21).
    public static var supportedFormats: [AudioFormat] {
        [.mp3, .aac, .m4a, .alac, .flac, .wav, .aiff]
    }

    /// Formats recognised by the scanner but not playable yet.
    public static var recognisedButUndecodableFormats: [AudioFormat] {
        [.ogg, .opus]
    }

    /// True when the built-in AVFoundation path can decode this container.
    public var isDecodable: Bool {
        AudioFormat.supportedFormats.contains(self)
    }

    /// Human-readable reason a file is indexed but cannot be played.
    public var unsupportedReason: String? {
        switch self {
        case .ogg: return "Ogg Vorbis requires an external decoder."
        case .opus: return "Opus requires an external decoder."
        default: return nil
        }
    }
}
