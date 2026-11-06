// QELORYX — LibraryEngine
// M3UPlaylist.swift
// Feature benchmark: playlist import/export in M3U/M3U8 (Petrichor, Nuclear)
// Original Qeloryx implementation — writer + tolerant parser

import Foundation

// MARK: - M3U Entry

/// One parsed line of an M3U playlist file.
public struct M3UEntry: Sendable, Equatable {
    /// Duration in seconds from `#EXTINF` (-1 when unknown).
    public var duration: TimeInterval
    /// Artist parsed from `#EXTINF:<dur>,<artist> - <title>` (-1 split on first " - ").
    public var artist: String?
    /// Title parsed from `#EXTINF`.
    public var title: String
    /// Raw path/URL as written in the file.
    public var path: String
    
    public init(duration: TimeInterval = -1, artist: String? = nil, title: String = "", path: String) {
        self.duration = duration
        self.artist = artist
        self.title = title
        self.path = path
    }
}

// MARK: - M3U Writer / Parser

public enum M3UPlaylist {
    
    /// Serializes tracks to an extended M3U (`#EXTM3U` + `#EXTINF`) document.
    public static func export(tracks: [AstryxTrack], playlistName: String) -> String {
        var lines = ["#EXTM3U", "#PLAYLIST:\(playlistName)"]
        for track in tracks {
            let artistTitle = "\(track.artist) - \(track.title)"
            let duration = track.duration > 0 ? Int(track.duration) : -1
            lines.append("#EXTINF:\(duration),\(artistTitle)")
            lines.append(track.fileURL.path)
        }
        return lines.joined(separator: "\n") + "\n"
    }
    
    /// Tolerant parser: understands `#EXTM3U`, `#EXTINF`, ignores other `#EXT-X` directives,
    /// and accepts plain path lines (basic M3U). Relative paths are returned as-is.
    public static func parse(_ content: String) -> [M3UEntry] {
        var entries: [M3UEntry] = []
        var pendingDuration: TimeInterval = -1
        var pendingTitle: String = ""
        var pendingArtist: String?
        
        for rawLine in content.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }
            
            if line.hasPrefix("#") {
                if line.hasPrefix("#EXTINF:") {
                    let payload = String(line.dropFirst("#EXTINF:".count))
                    let parts = payload.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false)
                    if let dur = Double(parts.first?.trimmingCharacters(in: .whitespaces) ?? "") {
                        pendingDuration = dur
                    }
                    if parts.count > 1 {
                        let name = String(parts[1])
                        if let dash = name.firstIndex(of: "-") {
                            let artistPart = name[..<dash].trimmingCharacters(in: .whitespaces)
                            let titlePart = name[name.index(after: dash)...].trimmingCharacters(in: .whitespaces)
                            pendingArtist = artistPart.isEmpty ? nil : artistPart
                            pendingTitle = titlePart
                        } else {
                            pendingTitle = name.trimmingCharacters(in: .whitespaces)
                            pendingArtist = nil
                        }
                    }
                }
                // All other directives (#EXTM3U, #PLAYLIST, #EXT-X-*) are ignored.
                continue
            }
            
            entries.append(M3UEntry(
                duration: pendingDuration,
                artist: pendingArtist,
                title: pendingTitle,
                path: line
            ))
            pendingDuration = -1
            pendingTitle = ""
            pendingArtist = nil
        }
        return entries
    }
    
    /// Resolves parsed entries against library tracks by file path, preserving playlist order.
    public static func resolve(_ entries: [M3UEntry], against tracks: [AstryxTrack]) -> [AstryxTrack] {
        let byPath = Dictionary(grouping: tracks, by: { $0.fileURL.path })
        return entries.compactMap { byPath[$0.path]?.first }
    }
}
