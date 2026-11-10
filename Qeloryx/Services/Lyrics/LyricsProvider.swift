// QELORYX — Services/Lyrics
// LyricsProvider.swift
// QEL-032 Lyrics++ — Production with LRC, Synced, Karaoke word-level, Translation-ready, Fullscreen

import Foundation

// Models moved to `Qeloryx/Models/Lyrics/` (LyricLine.swift, LyricsDocument.swift).

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
                        
                        Self.applyMetadata(key: key, value: value, to: &metadata)
                        offset = metadata.offset
                        
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
                    
                    if let startTime = Self.timestamp(
                        minutes: String(trimmed[minRange]),
                        seconds: String(trimmed[secRange]),
                        fraction: String(trimmed[msRange])
                    ) {
                        lines.append(AstryxLyricLine(text: lyricText, startTime: startTime + offset))
                    }
                }
            }
        }
        
        let withEndTimes = Self.sortedWithEndTimes(lines)
        return AstryxLyrics(trackID: trackID, lines: withEndTimes, isSynced: !withEndTimes.isEmpty, metadata: metadata)
    }
    
    // MARK: - Parsing helpers

    /// Applies one `[key:value]` metadata tag. `offset` is in milliseconds and
    /// is converted to seconds, which is the unit `startTime` uses.
    private static func applyMetadata(key: String, value: String, to metadata: inout LyricsMetadata) {
        switch key {
        case "ti": metadata.title = value
        case "ar": metadata.artist = value
        case "al": metadata.album = value
        case "au": metadata.author = value
        case "offset":
            if let ms = Double(value) {
                metadata.offset = ms / 1000.0
            }
        default: break
        }
    }

    /// Converts an LRC `[mm:ss.xx]` triple into seconds.
    ///
    /// The fraction is 2 or 3 digits; 2 digits are hundredths, 3 are
    /// thousandths. Anything that is not a number yields `nil` so the caller
    /// drops the line rather than emitting a bogus `0:00` cue.
    private static func timestamp(minutes: String, seconds: String, fraction: String) -> TimeInterval? {
        guard let m = Double(minutes), let s = Double(seconds), let f = Double(fraction) else {
            return nil
        }
        let divisor: Double = fraction.count == 2 ? 100.0 : 1000.0
        return m * 60 + s + f / divisor
    }

    /// Extracts karaoke `<mm:ss.xx>` words from one line.
    ///
    /// Returns the words (with end times filled from the next word) plus the
    /// plain text to show when a renderer ignores word-level timing. When the
    /// line carries no word timings, the plain text is the line itself.
    private static func parseWords(
        in lineText: String,
        regex: NSRegularExpression?,
        offset: TimeInterval
    ) -> ([AstryxLyricWord], String) {
        guard let regex else { return ([], lineText) }

        let range = NSRange(lineText.startIndex..., in: lineText)
        let matches = regex.matches(in: lineText, range: range)
        guard !matches.isEmpty else { return ([], lineText) }

        var words: [AstryxLyricWord] = []
        var plain = ""

        for match in matches {
            guard let minRange = Range(match.range(at: 1), in: lineText),
                  let secRange = Range(match.range(at: 2), in: lineText),
                  let msRange = Range(match.range(at: 3), in: lineText),
                  let textRange = Range(match.range(at: 4), in: lineText),
                  let start = timestamp(
                      minutes: String(lineText[minRange]),
                      seconds: String(lineText[secRange]),
                      fraction: String(lineText[msRange])
                  ) else { continue }

            let wordText = String(lineText[textRange]).trimmingCharacters(in: .whitespaces)
            guard !wordText.isEmpty else { continue }

            words.append(AstryxLyricWord(text: wordText, startTime: start + offset))
            plain += wordText + " "
        }

        // Word end time is the next word's start; the last word stays open.
        let withEnds = words.enumerated().map { index, word in
            AstryxLyricWord(
                text: word.text,
                startTime: word.startTime,
                endTime: index + 1 < words.count ? words[index + 1].startTime : nil
            )
        }
        return (withEnds, plain.trimmingCharacters(in: .whitespaces))
    }

    /// Sorts cues and fills in each line's end time from the next line's start.
    private static func sortedWithEndTimes(_ lines: [AstryxLyricLine]) -> [AstryxLyricLine] {
        let sorted = lines.sorted { $0.startTime < $1.startTime }
        return sorted.enumerated().map { index, line in
            AstryxLyricLine(
                text: line.text,
                startTime: line.startTime,
                endTime: index + 1 < sorted.count ? sorted[index + 1].startTime : nil,
                words: line.words,
                isTranslation: line.isTranslation,
                translation: line.translation
            )
        }
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
            
            // Metadata check (same keys as the standard parser)
            if trimmed.hasPrefix("[ti:") || trimmed.hasPrefix("[ar:") || trimmed.hasPrefix("[al:")
                || trimmed.hasPrefix("[au:") || trimmed.hasPrefix("[offset:") {
                if let key = trimmed.dropFirst().split(separator: ":").first.map(String.init) {
                    let value = trimmed
                        .replacingOccurrences(of: "[\(key):", with: "")
                        .replacingOccurrences(of: "]", with: "")
                    Self.applyMetadata(key: key.lowercased(), value: value, to: &metadata)
                    offset = metadata.offset
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
            
            guard let parsedStart = Self.timestamp(
                minutes: String(trimmed[minRange]),
                seconds: String(trimmed[secRange]),
                fraction: String(trimmed[msRange])
            ) else { return }
            let lineStartTime = parsedStart + offset
            
            let lineText = String(trimmed[textRange]).trimmingCharacters(in: .whitespaces)
            if lineText.isEmpty { return }
            
            let (words, plainText) = Self.parseWords(in: lineText, regex: wordRegex, offset: offset)

            let finalText = plainText.isEmpty ? lineText : plainText
            lines.append(AstryxLyricLine(text: finalText, startTime: lineStartTime, words: words))
        }
        
        let withEndTimes = Self.sortedWithEndTimes(lines)
        return AstryxLyrics(
            trackID: trackID,
            lines: withEndTimes,
            isSynced: !withEndTimes.isEmpty,
            isKaraoke: withEndTimes.contains { $0.isKaraoke },
            metadata: metadata
        )
    }
}
