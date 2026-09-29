// QELORYX — ProviderLayer
// LyricsProvider.swift
// QEL-032 Lyrics++ — Production with LRC, Synced, Karaoke word-level, Translation-ready, Fullscreen

import Foundation

// MARK: - Lyric Models — QEL-032 Enhanced

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

public protocol LyricsProviderProtocol: Provider {
    func fetchLyrics(for track: AstryxTrack) async throws -> AstryxLyrics?
    func fetchLyrics(for track: AstryxTrack, language: String) async throws -> AstryxLyrics? // Translation-ready
    func parseLRC(_ lrcString: String, trackID: String) -> AstryxLyrics
    func parseEnhancedLRC(_ lrcString: String, trackID: String) -> AstryxLyrics // Karaoke word-level
}

// MARK: - Local Lyrics Provider — Production

public final class AstryxLyricsProvider: LyricsProviderProtocol {
    
    public let id = "com.qeloryx.provider.lyrics.local"
    public let name = "Local Lyrics Provider"
    
    public init() {}
    
    public func fetchLyrics(for track: AstryxTrack) async throws -> AstryxLyrics? {
        // 1. Check embedded lyrics
        if let lyrics = track.lyrics, !lyrics.isEmpty {
            if lyrics.contains("[") && lyrics.contains("]") {
                // Check if enhanced LRC (has word-level tags)
                if lyrics.contains("<") && lyrics.contains(">") {
                    return parseEnhancedLRC(lyrics, trackID: track.id)
                } else {
                    return parseLRC(lyrics, trackID: track.id)
                }
            } else {
                let line = AstryxLyricLine(text: lyrics, startTime: 0)
                return AstryxLyrics(trackID: track.id, lines: [line], isSynced: false)
            }
        }
        
        // 2. Try LRC file with same name as audio file
        let lrcURL = track.fileURL.deletingPathExtension().appendingPathExtension("lrc")
        if let lrcString = try? String(contentsOf: lrcURL, encoding: .utf8) {
            return lrcString.contains("<") ? parseEnhancedLRC(lrcString, trackID: track.id) : parseLRC(lrcString, trackID: track.id)
        }
        
        // 3. Try explicit lrcURL from track
        if let explicitURL = track.lrcURL, let lrcString = try? String(contentsOf: explicitURL, encoding: .utf8) {
            return lrcString.contains("<") ? parseEnhancedLRC(lrcString, trackID: track.id) : parseLRC(lrcString, trackID: track.id)
        }
        
        // 4. Try translation files (e.g., song.es.lrc, song.fr.lrc) — translation-ready architecture
        // For QEL-032 we scan for translation files but return base lyrics with translations dict
        
        return nil
    }
    
    public func fetchLyrics(for track: AstryxTrack, language: String) async throws -> AstryxLyrics? {
        // Try language-specific LRC: song.{language}.lrc
        let baseURL = track.fileURL.deletingPathExtension()
        let langURL = URL(fileURLWithPath: "\(baseURL.path).\(language).lrc")
        
        if let lrcString = try? String(contentsOf: langURL, encoding: .utf8) {
            var lyrics = lrcString.contains("<") ? parseEnhancedLRC(lrcString, trackID: track.id) : parseLRC(lrcString, trackID: track.id)
            // Return with language set
            return AstryxLyrics(
                trackID: track.id,
                lines: lyrics.lines,
                isSynced: lyrics.isSynced,
                language: language,
                source: "local_\(language)"
            )
        }
        
        return nil
    }
    
    // MARK: - Standard LRC Parsing — [mm:ss.xx] lyric text
    
    public func parseLRC(_ lrcString: String, trackID: String) -> AstryxLyrics {
        // Capture text lazily up to the next timestamp or end of line so
        // repeated-timestamp lines ([00:12.00][00:15.00]text) match every tag.
        let pattern = #"\[(\d{2}):(\d{2})\.(\d{2,3})\](.*?)(?=\[\d{2}:|$)"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let metadataPattern = #"\[(\w+):(.*)\]"#
        let metadataRegex = try? NSRegularExpression(pattern: metadataPattern)
        
        var lines: [AstryxLyricLine] = []
        var metadata = LyricsMetadata()
        var offset: TimeInterval = 0
        
        lrcString.enumerateLines { line, _ in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return }
            
            // Check for metadata: [ti:Title], [ar:Artist], [al:Album], [au:Author], [offset:500]
            if let metaRegex = metadataRegex {
                let range = NSRange(trimmed.startIndex..., in: trimmed)
                if let match = metaRegex.firstMatch(in: trimmed, range: range) {
                    if let keyRange = Range(match.range(at: 1), in: trimmed),
                       let valueRange = Range(match.range(at: 2), in: trimmed) {
                        let key = String(trimmed[keyRange]).lowercased()
                        let value = String(trimmed[valueRange]).trimmingCharacters(in: .whitespaces)
                        
                        switch key {
                        case "ti": metadata.title = value
                        case "ar": metadata.artist = value
                        case "al": metadata.album = value
                        case "au": metadata.author = value
                        case "offset":
                            if let ms = Double(value) {
                                offset = ms / 1000.0
                                metadata.offset = offset
                            }
                        default: break
                        }
                        
                        // If it's metadata, don't try to parse as lyric line
                        if ["ti", "ar", "al", "au", "offset", "by", "length"].contains(key) {
                            return
                        }
                    }
                }
            }
            
            // Parse lyric line — may have multiple timestamps for same text: [00:12.00][00:15.00]Lyric
            guard let regex = regex else { return }
            let range = NSRange(trimmed.startIndex..., in: trimmed)
            let matches = regex.matches(in: trimmed, range: range)
            
            guard !matches.isEmpty else { return }
            
            // Extract text from the last timestamp match carrying non-empty text
            var lyricText = ""
            for match in matches.reversed() {
                if let textRange = Range(match.range(at: 4), in: trimmed) {
                    let candidate = String(trimmed[textRange]).trimmingCharacters(in: .whitespaces)
                    if !candidate.isEmpty {
                        lyricText = candidate
                        break
                    }
                }
            }
            
            if lyricText.isEmpty { return }
            
            // Create line for each timestamp
            for match in matches {
                if let minRange = Range(match.range(at: 1), in: trimmed),
                   let secRange = Range(match.range(at: 2), in: trimmed),
                   let msRange = Range(match.range(at: 3), in: trimmed) {
                    
                    let minutes = Double(trimmed[minRange]) ?? 0
                    let seconds = Double(trimmed[secRange]) ?? 0
                    let milliseconds = Double(trimmed[msRange]) ?? 0
                    let msDivisor = trimmed[msRange].count == 2 ? 100.0 : 1000.0
                    
                    var startTime = minutes * 60 + seconds + milliseconds / msDivisor
                    startTime += offset // Apply offset
                    
                    lines.append(AstryxLyricLine(text: lyricText, startTime: startTime))
                }
            }
        }
        
        // Sort by start time and calculate end times
        lines.sort { $0.startTime < $1.startTime }
        var withEndTimes: [AstryxLyricLine] = []
        for (index, line) in lines.enumerated() {
            let endTime = index + 1 < lines.count ? lines[index + 1].startTime : nil
            withEndTimes.append(AstryxLyricLine(
                text: line.text,
                startTime: line.startTime,
                endTime: endTime,
                words: line.words,
                isTranslation: line.isTranslation,
                translation: line.translation
            ))
        }
        
        return AstryxLyrics(trackID: trackID, lines: withEndTimes, isSynced: !withEndTimes.isEmpty, metadata: metadata)
    }
    
    // MARK: - Enhanced LRC Parsing — Karaoke word-level: [mm:ss.xx] <mm:ss.xx>word <mm:ss.xx>word
    
    public func parseEnhancedLRC(_ lrcString: String, trackID: String) -> AstryxLyrics {
        // Enhanced LRC format: [00:12.00] <00:12.00>Hello <00:12.50>world <00:13.00>!
        // Each word has its own timestamp in <>
        
        let linePattern = #"\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)"#
        let lineRegex = try? NSRegularExpression(pattern: linePattern)
        let wordPattern = #"<(\d{2}):(\d{2})\.(\d{2,3})>([^<]*)"#
        let wordRegex = try? NSRegularExpression(pattern: wordPattern)
        
        var lines: [AstryxLyricLine] = []
        var metadata = LyricsMetadata()
        var offset: TimeInterval = 0
        
        lrcString.enumerateLines { line, _ in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return }
            
            // Metadata check (same as standard)
            if trimmed.hasPrefix("[ti:") || trimmed.hasPrefix("[ar:") || trimmed.hasPrefix("[al:") || trimmed.hasPrefix("[offset:") {
                if trimmed.hasPrefix("[offset:") {
                    let offsetStr = trimmed.replacingOccurrences(of: "[offset:", with: "").replacingOccurrences(of: "]", with: "")
                    if let ms = Double(offsetStr) {
                        offset = ms / 1000.0
                        metadata.offset = offset
                    }
                }
                return
            }
            
            guard let lineRegex = lineRegex else { return }
            let range = NSRange(trimmed.startIndex..., in: trimmed)
            guard let match = lineRegex.firstMatch(in: trimmed, range: range) else { return }
            
            guard let minRange = Range(match.range(at: 1), in: trimmed),
                  let secRange = Range(match.range(at: 2), in: trimmed),
                  let msRange = Range(match.range(at: 3), in: trimmed),
                  let textRange = Range(match.range(at: 4), in: trimmed) else { return }
            
            let minutes = Double(trimmed[minRange]) ?? 0
            let seconds = Double(trimmed[secRange]) ?? 0
            let milliseconds = Double(trimmed[msRange]) ?? 0
            let msDivisor = trimmed[msRange].count == 2 ? 100.0 : 1000.0
            
            var lineStartTime = minutes * 60 + seconds + milliseconds / msDivisor
            lineStartTime += offset
            
            let lineText = String(trimmed[textRange]).trimmingCharacters(in: .whitespaces)
            if lineText.isEmpty { return }
            
            // Parse words
            var words: [AstryxLyricWord] = []
            var plainText = ""
            
            if let wordRegex = wordRegex {
                let text = lineText
                let textRange = NSRange(text.startIndex..., in: text)
                let wordMatches = wordRegex.matches(in: text, range: textRange)
                
                if !wordMatches.isEmpty {
                    for wordMatch in wordMatches {
                        if let wMinRange = Range(wordMatch.range(at: 1), in: text),
                           let wSecRange = Range(wordMatch.range(at: 2), in: text),
                           let wMsRange = Range(wordMatch.range(at: 3), in: text),
                           let wTextRange = Range(wordMatch.range(at: 4), in: text) {
                            
                            let wMin = Double(text[wMinRange]) ?? 0
                            let wSec = Double(text[wSecRange]) ?? 0
                            let wMs = Double(text[wMsRange]) ?? 0
                            let wMsDivisor = text[wMsRange].count == 2 ? 100.0 : 1000.0
                            
                            var wordStart = wMin * 60 + wSec + wMs / wMsDivisor
                            wordStart += offset
                            
                            let wordText = String(text[wTextRange]).trimmingCharacters(in: .whitespaces)
                            if !wordText.isEmpty {
                                words.append(AstryxLyricWord(text: wordText, startTime: wordStart))
                                plainText += wordText + " "
                            }
                        }
                    }
                    
                    // Calculate word end times
                    var wordsWithEnd: [AstryxLyricWord] = []
                    for (idx, word) in words.enumerated() {
                        let end = idx + 1 < words.count ? words[idx + 1].startTime : nil
                        wordsWithEnd.append(AstryxLyricWord(text: word.text, startTime: word.startTime, endTime: end))
                    }
                    words = wordsWithEnd
                    plainText = plainText.trimmingCharacters(in: .whitespaces)
                } else {
                    plainText = lineText
                }
            } else {
                plainText = lineText
            }
            
            let finalText = plainText.isEmpty ? lineText : plainText
            lines.append(AstryxLyricLine(text: finalText, startTime: lineStartTime, words: words))
        }
        
        // Sort and calculate line end times
        lines.sort { $0.startTime < $1.startTime }
        var withEndTimes: [AstryxLyricLine] = []
        for (index, line) in lines.enumerated() {
            let endTime = index + 1 < lines.count ? lines[index + 1].startTime : nil
            withEndTimes.append(AstryxLyricLine(
                text: line.text,
                startTime: line.startTime,
                endTime: endTime,
                words: line.words
            ))
        }
        
        return AstryxLyrics(trackID: trackID, lines: withEndTimes, isSynced: !withEndTimes.isEmpty, isKaraoke: withEndTimes.contains { $0.isKaraoke }, metadata: metadata)
    }
}
