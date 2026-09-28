// QELORYX — ProviderLayer
// LyricsProvider.swift

import Foundation

public struct AstryxLyricLine: Sendable, Equatable, Identifiable {
    public let id: String
    public let text: String
    public let startTime: TimeInterval
    public let endTime: TimeInterval?
    public let isTranslation: Bool
    
    public init(id: String = UUID().uuidString, text: String, startTime: TimeInterval, endTime: TimeInterval? = nil, isTranslation: Bool = false) {
        self.id = id
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
        self.isTranslation = isTranslation
    }
}

public struct AstryxLyrics: Sendable, Equatable {
    public let trackID: String
    public let lines: [AstryxLyricLine]
    public let isSynced: Bool
    public let language: String
    public let source: String
    
    public init(trackID: String, lines: [AstryxLyricLine], isSynced: Bool, language: String = "en", source: String = "local") {
        self.trackID = trackID
        self.lines = lines
        self.isSynced = isSynced
        self.language = language
        self.source = source
    }
}

public protocol LyricsProviderProtocol: Provider {
    func fetchLyrics(for track: AstryxTrack) async throws -> AstryxLyrics?
    func parseLRC(_ lrcString: String, trackID: String) -> AstryxLyrics
}

public final class AstryxLyricsProvider: LyricsProviderProtocol {
    
    public let id = "com.qeloryx.provider.lyrics.local"
    public let name = "Local Lyrics Provider"
    
    public init() {}
    
    public func fetchLyrics(for track: AstryxTrack) async throws -> AstryxLyrics? {
        // Foundation: check if track has embedded lyrics or LRC file
        if let lyrics = track.lyrics, !lyrics.isEmpty {
            // Check if LRC format
            if lyrics.contains("[") && lyrics.contains("]") {
                return parseLRC(lyrics, trackID: track.id)
            } else {
                // Unsynced
                let line = AstryxLyricLine(text: lyrics, startTime: 0)
                return AstryxLyrics(trackID: track.id, lines: [line], isSynced: false)
            }
        }
        
        // Try LRC file
        if let lrcURL = track.lrcURL, let lrcString = try? String(contentsOf: lrcURL) {
            return parseLRC(lrcString, trackID: track.id)
        }
        
        return nil
    }
    
    public func parseLRC(_ lrcString: String, trackID: String) -> AstryxLyrics {
        // LRC format: [mm:ss.xx] lyric text
        let pattern = #"\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)"#
        let regex = try? NSRegularExpression(pattern: pattern)
        
        var lines: [AstryxLyricLine] = []
        
        lrcString.enumerateLines { line, _ in
            guard let regex = regex else { return }
            let range = NSRange(line.startIndex..., in: line)
            if let match = regex.firstMatch(in: line, range: range) {
                if let minRange = Range(match.range(at: 1), in: line),
                   let secRange = Range(match.range(at: 2), in: line),
                   let msRange = Range(match.range(at: 3), in: line),
                   let textRange = Range(match.range(at: 4), in: line) {
                    
                    let minutes = Double(line[minRange]) ?? 0
                    let seconds = Double(line[secRange]) ?? 0
                    let milliseconds = Double(line[msRange]) ?? 0
                    let msDivisor = line[msRange].count == 2 ? 100.0 : 1000.0
                    
                    let startTime = minutes * 60 + seconds + milliseconds / msDivisor
                    let text = String(line[textRange]).trimmingCharacters(in: .whitespaces)
                    
                    if !text.isEmpty {
                        lines.append(AstryxLyricLine(text: text, startTime: startTime))
                    }
                }
            }
        }
        
        // Sort by start time and calculate end times
        lines.sort { $0.startTime < $1.startTime }
        var withEndTimes: [AstryxLyricLine] = []
        for (index, line) in lines.enumerated() {
            let endTime = index + 1 < lines.count ? lines[index + 1].startTime : nil
            withEndTimes.append(AstryxLyricLine(text: line.text, startTime: line.startTime, endTime: endTime))
        }
        
        return AstryxLyrics(trackID: trackID, lines: withEndTimes, isSynced: !withEndTimes.isEmpty)
    }
}
