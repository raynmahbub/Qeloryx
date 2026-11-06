// QELORYX — LibraryEngine
// SmartPlaylist.swift
// Feature benchmark: smart playlists with conditional/negative/regex rules (Petrichor, Feishin)
// Original Qeloryx implementation — rule model + evaluator over AstryxTrack

import Foundation

// MARK: - Field

public enum SmartPlaylistField: String, Sendable, CaseIterable, Equatable {
    case title
    case artist
    case album
    case albumArtist
    case genre
    case year
    case trackNumber
    case duration      // seconds
    case playCount
    case bitRate       // kbps
    case fileFormat
    case isFavorite
    case isLossless
    case lastPlayed    // date
    case dateAdded     // date
    
    public var displayName: String {
        switch self {
        case .title: return "Title"
        case .artist: return "Artist"
        case .album: return "Album"
        case .albumArtist: return "Album Artist"
        case .genre: return "Genre"
        case .year: return "Year"
        case .trackNumber: return "Track Number"
        case .duration: return "Duration"
        case .playCount: return "Play Count"
        case .bitRate: return "Bitrate"
        case .fileFormat: return "Format"
        case .isFavorite: return "Favorite"
        case .isLossless: return "Lossless"
        case .lastPlayed: return "Last Played"
        case .dateAdded: return "Date Added"
        }
    }
    
    var isNumeric: Bool {
        switch self {
        case .year, .trackNumber, .duration, .playCount, .bitRate: return true
        default: return false
        }
    }
    
    var isBoolean: Bool {
        switch self {
        case .isFavorite, .isLossless: return true
        default: return false
        }
    }
    
    var isDate: Bool {
        switch self {
        case .lastPlayed, .dateAdded: return true
        default: return false
        }
    }
}

// MARK: - Operator

public enum SmartPlaylistOperator: String, Sendable, CaseIterable, Equatable {
    case contains
    case notContains
    case equals
    case notEquals
    case startsWith
    case endsWith
    case greaterThan
    case lessThan
    case between        // numeric/date; value formatted "min,max"
    case matchesRegex
    case isTrue         // boolean fields
    case isFalse        // boolean fields
    
    public var displayName: String {
        switch self {
        case .contains: return "contains"
        case .notContains: return "does not contain"
        case .equals: return "is"
        case .notEquals: return "is not"
        case .startsWith: return "starts with"
        case .endsWith: return "ends with"
        case .greaterThan: return "is greater than"
        case .lessThan: return "is less than"
        case .between: return "is between"
        case .matchesRegex: return "matches regex"
        case .isTrue: return "is true"
        case .isFalse: return "is false"
        }
    }
}

// MARK: - Rule

/// A single smart-playlist rule. `negate` inverts the result (Petrichor-style negative rules).
public struct SmartPlaylistRule: Identifiable, Sendable, Equatable {
    public let id: String
    public var field: SmartPlaylistField
    public var op: SmartPlaylistOperator
    public var value: String
    public var negate: Bool
    
    public init(
        id: String = UUID().uuidString,
        field: SmartPlaylistField,
        op: SmartPlaylistOperator,
        value: String = "",
        negate: Bool = false
    ) {
        self.id = id
        self.field = field
        self.op = op
        self.value = value
        self.negate = negate
    }
    
    public func matches(_ track: AstryxTrack) -> Bool {
        let result = rawMatch(track)
        return negate ? !result : result
    }
    
    private func rawMatch(_ track: AstryxTrack) -> Bool {
        switch field {
        case .isFavorite:
            return booleanMatch(track.isFavorite)
        case .isLossless:
            return booleanMatch(track.isLossless)
        case .lastPlayed:
            return dateMatch(track.lastPlayed ?? Date.distantPast)
        case .dateAdded:
            return dateMatch(track.dateAdded)
        default:
            break
        }
        
        if field.isNumeric {
            return numericMatch(numericValue(of: track))
        }
        return stringMatch(stringValue(of: track))
    }
    
    private func stringValue(of track: AstryxTrack) -> String {
        switch field {
        case .title: return track.title
        case .artist: return track.artist
        case .album: return track.album
        case .albumArtist: return track.albumArtist ?? ""
        case .genre: return track.genre ?? ""
        case .fileFormat: return track.fileFormat.rawValue
        default: return ""
        }
    }
    
    private func numericValue(of track: AstryxTrack) -> Double {
        switch field {
        case .year: return Double(track.year ?? 0)
        case .trackNumber: return Double(track.trackNumber ?? 0)
        case .duration: return track.duration
        case .playCount: return Double(track.playCount)
        case .bitRate: return Double(track.bitRate ?? 0)
        default: return 0
        }
    }
    
    private func stringMatch(_ fieldValue: String) -> Bool {
        let needle = value
        switch op {
        case .contains: return fieldValue.localizedCaseInsensitiveContains(needle)
        case .notContains: return !fieldValue.localizedCaseInsensitiveContains(needle)
        case .equals: return fieldValue.caseInsensitiveCompare(needle) == .orderedSame
        case .notEquals: return fieldValue.caseInsensitiveCompare(needle) != .orderedSame
        case .startsWith: return fieldValue.lowercased().hasPrefix(needle.lowercased())
        case .endsWith: return fieldValue.lowercased().hasSuffix(needle.lowercased())
        case .matchesRegex:
            return fieldValue.range(of: needle, options: .regularExpression) != nil
        case .isTrue, .isFalse:
            return false // handled by boolean path
        default:
            return false
        }
    }
    
    private func numericMatch(_ fieldValue: Double) -> Bool {
        guard let target = Double(value) else { return false }
        switch op {
        case .equals: return fieldValue == target
        case .notEquals: return fieldValue != target
        case .greaterThan: return fieldValue > target
        case .lessThan: return fieldValue < target
        case .between:
            let parts = value.split(separator: ",").map { Double($0.trimmingCharacters(in: .whitespaces)) }
            guard parts.count == 2, let lo = parts[0], let hi = parts[1] else { return false }
            return fieldValue >= min(lo, hi) && fieldValue <= max(lo, hi)
        default:
            return false
        }
    }
    
    private func dateMatch(_ fieldValue: Date) -> Bool {
        // Dates are compared as ISO-8601 day strings unless the rule value is numeric (epoch).
        if let epoch = Double(value) {
            switch op {
            case .greaterThan: return fieldValue.timeIntervalSince1970 > epoch
            case .lessThan: return fieldValue.timeIntervalSince1970 < epoch
            default: return false
            }
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let fieldDay = formatter.string(from: fieldValue)
        switch op {
        case .equals: return fieldDay == value
        case .notEquals: return fieldDay != value
        case .greaterThan: return fieldDay > value
        case .lessThan: return fieldDay < value
        case .between:
            let parts = value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 else { return false }
            return fieldDay >= parts[0] && fieldDay <= parts[1]
        default: return false
        }
    }
    
    private func booleanMatch(_ fieldValue: Bool) -> Bool {
        switch op {
        case .isTrue: return fieldValue
        case .isFalse: return !fieldValue
        case .equals: return fieldValue == (value.lowercased() == "true" || value == "1")
        default: return false
        }
    }
}

// MARK: - Smart Playlist

public enum SmartPlaylistLogic: String, Sendable, CaseIterable, Equatable {
    case and
    case or
}

public enum SmartPlaylistSort: String, Sendable, CaseIterable, Equatable {
    case title
    case artist
    case album
    case duration
    case playCount
    case dateAdded
    case random
}

/// A rule-driven playlist that re-evaluates against the library on demand.
public struct AstryxSmartPlaylist: Identifiable, Sendable, Equatable {
    public let id: String
    public var name: String
    public var logic: SmartPlaylistLogic
    public var rules: [SmartPlaylistRule]
    public var sort: SmartPlaylistSort
    public var limit: Int?
    public var dateCreated: Date
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        logic: SmartPlaylistLogic = .and,
        rules: [SmartPlaylistRule] = [],
        sort: SmartPlaylistSort = .title,
        limit: Int? = nil,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.logic = logic
        self.rules = rules
        self.sort = sort
        self.limit = limit
        self.dateCreated = dateCreated
    }
    
    /// Evaluates the playlist against a set of tracks and returns matching, sorted tracks.
    public func evaluate(_ tracks: [AstryxTrack]) -> [AstryxTrack] {
        var matched = tracks.filter { track in
            guard !rules.isEmpty else { return false }
            switch logic {
            case .and: return rules.allSatisfy { $0.matches(track) }
            case .or: return rules.contains { $0.matches(track) }
            }
        }
        matched = sortTracks(matched)
        if let limit, limit > 0, matched.count > limit {
            matched = Array(matched.prefix(limit))
        }
        return matched
    }
    
    private func sortTracks(_ tracks: [AstryxTrack]) -> [AstryxTrack] {
        switch sort {
        case .title: return tracks.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .artist: return tracks.sorted { $0.artist.localizedCaseInsensitiveCompare($1.artist) == .orderedAscending }
        case .album: return tracks.sorted { $0.album.localizedCaseInsensitiveCompare($1.album) == .orderedAscending }
        case .duration: return tracks.sorted { $0.duration < $1.duration }
        case .playCount: return tracks.sorted { $0.playCount > $1.playCount }
        case .dateAdded: return tracks.sorted { $0.dateAdded > $1.dateAdded }
        case .random: return tracks.shuffled()
        }
    }
}
