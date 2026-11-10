// QELORYX — Models/Recommendations
// TasteProfile.swift
// The evolving Taste DNA model: genres, artists, moods, eras and a
// full profile snapshot. Offline-first — all analysis is local.

import Foundation

public struct TasteGenre: Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let playCount: Int
    public let percentage: Double // 0-1
    public let color: String // Hex for visualization
    
    public init(id: String = UUID().uuidString, name: String, playCount: Int, percentage: Double, color: String = "#3B82F6") {
        self.id = id
        self.name = name
        self.playCount = playCount
        self.percentage = percentage
        self.color = color
    }
}

public struct TasteArtist: Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let playCount: Int
    public let trackCount: Int
    public let percentage: Double
    
    public init(id: String = UUID().uuidString, name: String, playCount: Int, trackCount: Int, percentage: Double) {
        self.id = id
        self.name = name
        self.playCount = playCount
        self.trackCount = trackCount
        self.percentage = percentage
    }
}

public struct TasteMood: Sendable, Equatable {
    public let primary: String
    public let secondary: String?
    public let energy: Double // 0-1 low to high energy
    public let valence: Double // 0-1 sad to happy
    
    public init(primary: String, secondary: String? = nil, energy: Double, valence: Double) {
        self.primary = primary
        self.secondary = secondary
        self.energy = energy
        self.valence = valence
    }
    
    public static let moods = ["Chill", "Energetic", "Melancholic", "Euphoric", "Focused", "Nostalgic", "Romantic", "Dark", "Bright", "Introspective"]
}

public struct TasteEra: Sendable, Equatable {
    public let decade: String // e.g., "2020s", "2010s", "2000s"
    public let count: Int
    public let percentage: Double
    
    public init(decade: String, count: Int, percentage: Double) {
        self.decade = decade
        self.count = count
        self.percentage = percentage
    }
}

public struct AstryxTasteProfile: Sendable, Equatable {
    public let id: String
    public let topGenres: [TasteGenre]
    public let topArtists: [TasteArtist]
    public let mood: TasteMood
    public let topEras: [TasteEra]
    public let totalPlays: Int
    public let totalTracks: Int
    public let totalDuration: TimeInterval
    public let favoriteCount: Int
    public let listeningTime: TimeInterval // Total time listened
    public let diversityScore: Double // 0-1 how diverse taste is
    public let lastUpdated: Date
    public let evolution: [TasteSnapshot] // History of taste over time
    
    public init(
        id: String = UUID().uuidString,
        topGenres: [TasteGenre],
        topArtists: [TasteArtist],
        mood: TasteMood,
        topEras: [TasteEra] = [],
        totalPlays: Int,
        totalTracks: Int,
        totalDuration: TimeInterval,
        favoriteCount: Int,
        listeningTime: TimeInterval,
        diversityScore: Double,
        lastUpdated: Date = Date(),
        evolution: [TasteSnapshot] = []
    ) {
        self.id = id
        self.topGenres = topGenres
        self.topArtists = topArtists
        self.mood = mood
        self.topEras = topEras
        self.totalPlays = totalPlays
        self.totalTracks = totalTracks
        self.totalDuration = totalDuration
        self.favoriteCount = favoriteCount
        self.listeningTime = listeningTime
        self.diversityScore = diversityScore
        self.lastUpdated = lastUpdated
        self.evolution = evolution
    }
    
    public var summary: String {
        let topGenre = topGenres.first?.name ?? "Unknown"
        let topArtist = topArtists.first?.name ?? "Unknown"
        return "\(topGenre) • \(topArtist) • \(mood.primary)"
    }
    
    public var formattedListeningTime: String {
        let hours = Int(listeningTime) / 3600
        let minutes = (Int(listeningTime) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

public struct TasteSnapshot: Sendable, Equatable, Identifiable {
    public let id: String
    public let date: Date
    public let topGenre: String
    public let topArtist: String
    public let mood: String
    public let playCount: Int
    
    public init(id: String = UUID().uuidString, date: Date, topGenre: String, topArtist: String, mood: String, playCount: Int) {
        self.id = id
        self.date = date
        self.topGenre = topGenre
        self.topArtist = topArtist
        self.mood = mood
        self.playCount = playCount
    }
}

// MARK: - Recommendation Models

// MARK: - Legacy compatibility profile (moved from RecommendationProvider.swift)

public struct TasteProfile: Sendable {
    public let topGenres: [String]
    public let topArtists: [String]
    public let mood: String
    public init(topGenres: [String], topArtists: [String], mood: String) {
        self.topGenres = topGenres
        self.topArtists = topArtists
        self.mood = mood
    }
}
