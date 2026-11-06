// QELORYX — MetadataEngine
// TagEditor.swift
// Feature benchmark: precise metadata tag management (Auxio)
// Original Qeloryx implementation — edit model + pure apply/validate logic

import Foundation

// MARK: - Tag Edit

/// A set of optional metadata edits. `nil` fields are left untouched.
public struct TrackTagEdit: Sendable, Equatable {
    public var title: String?
    public var artist: String?
    public var album: String?
    public var albumArtist: String?
    public var genre: String?
    public var year: Int?
    public var trackNumber: Int?
    public var discNumber: Int?
    public var lyrics: String?
    
    public init(
        title: String? = nil,
        artist: String? = nil,
        album: String? = nil,
        albumArtist: String? = nil,
        genre: String? = nil,
        year: Int? = nil,
        trackNumber: Int? = nil,
        discNumber: Int? = nil,
        lyrics: String? = nil
    ) {
        self.title = title
        self.artist = artist
        self.album = album
        self.albumArtist = albumArtist
        self.genre = genre
        self.year = year
        self.trackNumber = trackNumber
        self.discNumber = discNumber
        self.lyrics = lyrics
    }
    
    public var isEmpty: Bool {
        title == nil && artist == nil && album == nil && albumArtist == nil
            && genre == nil && year == nil && trackNumber == nil && discNumber == nil && lyrics == nil
    }
}

// MARK: - Tag Editor

public protocol TagEditorProtocol: Sendable {
    /// Validates an edit against a track (e.g. year range, non-empty title).
    func validate(_ edit: TrackTagEdit, for track: AstryxTrack) -> [String]
    /// Applies an edit to a track model, returning a new track.
    func apply(_ edit: TrackTagEdit, to track: AstryxTrack) -> AstryxTrack
    /// Persists an edit to the audio file on disk (platform adapter responsibility).
    func save(_ edit: TrackTagEdit, for track: AstryxTrack) async throws
}

/// Offline-first tag editor: validation + pure model application.
/// Actual file writing is delegated to a platform adapter via `save`.
public final class AstryxTagEditor: TagEditorProtocol, @unchecked Sendable {
    
    public init() {}
    
    public func validate(_ edit: TrackTagEdit, for track: AstryxTrack) -> [String] {
        var problems: [String] = []
        if let title = edit.title, title.trimmingCharacters(in: .whitespaces).isEmpty {
            problems.append("Title must not be empty")
        }
        if let year = edit.year, !(1900...2100).contains(year) {
            problems.append("Year must be between 1900 and 2100")
        }
        if let trackNumber = edit.trackNumber, trackNumber < 1 {
            problems.append("Track number must be >= 1")
        }
        if let discNumber = edit.discNumber, discNumber < 1 {
            problems.append("Disc number must be >= 1")
        }
        return problems
    }
    
    public func apply(_ edit: TrackTagEdit, to track: AstryxTrack) -> AstryxTrack {
        var updated = track
        if let title = edit.title { updated.title = title }
        if let artist = edit.artist { updated.artist = artist }
        if let album = edit.album { updated.album = album }
        if let albumArtist = edit.albumArtist { updated.albumArtist = albumArtist }
        if let genre = edit.genre { updated.genre = genre }
        if let year = edit.year { updated.year = year }
        if let trackNumber = edit.trackNumber { updated.trackNumber = trackNumber }
        if let discNumber = edit.discNumber { updated.discNumber = discNumber }
        if let lyrics = edit.lyrics { updated.lyrics = lyrics }
        updated.dateModified = Date()
        return updated
    }
    
    public func save(_ edit: TrackTagEdit, for track: AstryxTrack) async throws {
        let problems = validate(edit, for: track)
        guard problems.isEmpty else {
            throw TagEditorError.validationFailed(problems)
        }
        // Platform adapter (AVAssetWriter / taglib) performs the actual write.
        // Core stays portable: no file I/O here.
    }
}

public enum TagEditorError: Error, Sendable, Equatable {
    case validationFailed([String])
}
