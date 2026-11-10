// QELORYX — Models/Lyrics
// LyricsDocument.swift
// `AstryxLyrics` is the full timed document; `LyricsMetadata` carries LRC offsets and attribution.

import Foundation

public struct AstryxLyrics: Sendable, Equatable {
    public let trackID: String
    public let lines: [AstryxLyricLine]
    public let isSynced: Bool
    public let language: String
    public let translations: [String: AstryxLyrics] // Language code -> translated lyrics (translation-ready architecture)
    public let source: String
    public let isKaraoke: Bool
    public let metadata: LyricsMetadata
    
    public init(
        trackID: String,
        lines: [AstryxLyricLine],
        isSynced: Bool,
        language: String = "en",
        translations: [String: AstryxLyrics] = [:],
        source: String = "local",
        isKaraoke: Bool = false,
        metadata: LyricsMetadata = LyricsMetadata()
    ) {
        self.trackID = trackID
        self.lines = lines
        self.isSynced = isSynced
        self.language = language
        self.translations = translations
        self.source = source
        self.isKaraoke = isKaraoke || lines.contains { $0.isKaraoke }
        self.metadata = metadata
    }
    
    public func currentLine(at time: TimeInterval) -> AstryxLyricLine? {
        // Find line where startTime <= time < endTime or next line start
        var current: AstryxLyricLine?
        for line in lines {
            if line.startTime <= time {
                current = line
            } else {
                break
            }
        }
        return current
    }
    
    public func currentLineIndex(at time: TimeInterval) -> Int? {
        for (index, line) in lines.enumerated() {
            let nextStart = index + 1 < lines.count ? lines[index + 1].startTime : .infinity
            if line.startTime <= time && time < nextStart {
                return index
            }
        }
        return nil
    }
    
    public func translation(for languageCode: String) -> AstryxLyrics? {
        translations[languageCode]
    }
}

public struct LyricsMetadata: Sendable, Equatable {
    public var title: String?
    public var artist: String?
    public var album: String?
    public var author: String?
    public var offset: TimeInterval // LRC offset in ms
    
    public init(title: String? = nil, artist: String? = nil, album: String? = nil, author: String? = nil, offset: TimeInterval = 0) {
        self.title = title
        self.artist = artist
        self.album = album
        self.author = author
        self.offset = offset
    }
}

// MARK: - Lyrics Provider Protocol — QEL-032 Enhanced
