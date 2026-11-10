// QELORYX — Models/Lyrics
// LyricLine.swift

import Foundation

public struct AstryxLyricWord: Sendable, Equatable, Identifiable {
    public let id: String
    public let text: String
    public let startTime: TimeInterval
    public let endTime: TimeInterval?
    
    public init(id: String = UUID().uuidString, text: String, startTime: TimeInterval, endTime: TimeInterval? = nil) {
        self.id = id
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
    }
}

public struct AstryxLyricLine: Sendable, Equatable, Identifiable {
    public let id: String
    public let text: String
    public let startTime: TimeInterval
    public let endTime: TimeInterval?
    public let words: [AstryxLyricWord] // For karaoke word-level timing
    public let isTranslation: Bool
    public let translation: String? // Translation text if available
    
    public init(
        id: String = UUID().uuidString,
        text: String,
        startTime: TimeInterval,
        endTime: TimeInterval? = nil,
        words: [AstryxLyricWord] = [],
        isTranslation: Bool = false,
        translation: String? = nil
    ) {
        self.id = id
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
        self.words = words
        self.isTranslation = isTranslation
        self.translation = translation
    }
    
    public var isKaraoke: Bool { !words.isEmpty }
}
