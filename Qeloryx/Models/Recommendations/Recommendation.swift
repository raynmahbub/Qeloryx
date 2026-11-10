// QELORYX — Models/Recommendations
// Recommendation.swift

import Foundation

public struct AstryxRecommendation: Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let reason: String
    public let tracks: [AstryxTrack]
    public let type: RecommendationType
    public let score: Double
    
    public init(id: String = UUID().uuidString, title: String, reason: String, tracks: [AstryxTrack], type: RecommendationType, score: Double) {
        self.id = id
        self.title = title
        self.reason = reason
        self.tracks = tracks
        self.type = type
        self.score = score
    }
}

public enum RecommendationType: String, Sendable, CaseIterable {
    case becauseYouLiked = "Because you liked"
    case similarArtist = "Similar artist"
    case genreDeepDive = "Genre deep dive"
    case rediscover = "Rediscover"
    case moodMatch = "Mood match"
    case newReleases = "New releases"
    case favoritesMix = "Favorites mix"
    case statistics = "Time capsule"
    
    public var icon: String {
        switch self {
        case .becauseYouLiked: return "heart.fill"
        case .similarArtist: return "person.2.fill"
        case .genreDeepDive: return "guitars.fill"
        case .rediscover: return "clock.arrow.circlepath"
        case .moodMatch: return "face.smiling"
        case .newReleases: return "sparkles"
        case .favoritesMix: return "star.fill"
        case .statistics: return "hourglass"
        }
    }
}

// MARK: - TasteDNA Engine Protocol
