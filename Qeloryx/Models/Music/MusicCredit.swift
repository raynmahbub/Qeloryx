// QELORYX — Models/Music
// MusicCredit.swift

import Foundation

/// The kind of contribution a person made to a track.
public enum AstryxCreditRole: String, Sendable, CaseIterable, Codable, Equatable, Hashable {
    case composer
    case lyricist
    case producer
    case arranger
    case performer
    case engineer
    case mixer
    case mastering
    case artwork
    case publisher
    case other

    public var displayName: String {
        switch self {
        case .composer: return "Composer"
        case .lyricist: return "Lyricist"
        case .producer: return "Producer"
        case .arranger: return "Arranger"
        case .performer: return "Performer"
        case .engineer: return "Engineer"
        case .mixer: return "Mixer"
        case .mastering: return "Mastering"
        case .artwork: return "Artwork"
        case .publisher: return "Publisher"
        case .other: return "Other"
        }
    }
}

/// One credited contribution on a track. Separated from `AstryxTrack` so a
/// track can carry an unbounded, open-ended credit list without bloating the
/// hot playback path.
public struct AstryxMusicCredit: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let trackID: String
    public var name: String
    public var role: AstryxCreditRole
    public var additionalInfo: String?

    public init(
        id: String = UUID().uuidString,
        trackID: String,
        name: String,
        role: AstryxCreditRole,
        additionalInfo: String? = nil
    ) {
        self.id = id
        self.trackID = trackID
        self.name = name
        self.role = role
        self.additionalInfo = additionalInfo
    }
}
