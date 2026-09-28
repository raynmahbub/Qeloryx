// QELORYX — TasteDNA
// TasteDNAEngine.swift
// QEL-051 Discovery — Production Taste DNA, evolving listening profile, offline-first

import Foundation

// MARK: - Taste DNA Models — QEL-051 Production

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
    case timeCapsule = "Time capsule"
    
    public var icon: String {
        switch self {
        case .becauseYouLiked: return "heart.fill"
        case .similarArtist: return "person.2.fill"
        case .genreDeepDive: return "guitars.fill"
        case .rediscover: return "clock.arrow.circlepath"
        case .moodMatch: return "face.smiling"
        case .newReleases: return "sparkles"
        case .favoritesMix: return "star.fill"
        case .timeCapsule: return "hourglass"
        }
    }
}

// MARK: - TasteDNA Engine Protocol

public protocol TasteDNAEngineProtocol: Sendable {
    func generateProfile(from tracks: [AstryxTrack]) async -> AstryxTasteProfile
    func currentProfile() async -> AstryxTasteProfile?
    func recommendations(for profile: AstryxTasteProfile, from library: [AstryxTrack], limit: Int) async -> [AstryxRecommendation]
    func mood(for tracks: [AstryxTrack]) -> TasteMood
    func diversityScore(for tracks: [AstryxTrack]) -> Double
}

// MARK: - Production TasteDNA Engine — QEL-051

public final class AstryxTasteDNAEngine: TasteDNAEngineProtocol, @unchecked Sendable {
    
    private var _currentProfile: AstryxTasteProfile?
    private let lock = NSLock()
    private let eventBus: any EventBusProtocol
    
    public init(eventBus: any EventBusProtocol = AstryxEventBus.shared) {
        self.eventBus = eventBus
    }
    
    public func generateProfile(from tracks: [AstryxTrack]) async -> AstryxTasteProfile {
        // Offline-first: all analysis local, no network
        
        // Top genres by playCount
        let genreGroups = Dictionary(grouping: tracks) { $0.genre ?? "Unknown" }
        var genreStats: [(name: String, playCount: Int, trackCount: Int)] = []
        for (genre, genreTracks) in genreGroups {
            let playCount = genreTracks.reduce(0) { $0 + $1.playCount }
            genreStats.append((genre, playCount, genreTracks.count))
        }
        genreStats.sort { $0.playCount > $1.playCount }
        
        let totalGenrePlays = genreStats.reduce(0) { $0 + $1.playCount }
        let topGenres = genreStats.prefix(5).map { stat in
            let percentage = totalGenrePlays > 0 ? Double(stat.playCount) / Double(totalGenrePlays) : 0
            return TasteGenre(name: stat.name, playCount: stat.playCount, percentage: percentage, color: colorForGenre(stat.name))
        }
        
        // Top artists by playCount
        let artistGroups = Dictionary(grouping: tracks) { $0.artist }
        var artistStats: [(name: String, playCount: Int, trackCount: Int)] = []
        for (artist, artistTracks) in artistGroups {
            let playCount = artistTracks.reduce(0) { $0 + $1.playCount }
            artistStats.append((artist, playCount, artistTracks.count))
        }
        artistStats.sort { $0.playCount > $1.playCount }
        
        let totalArtistPlays = artistStats.reduce(0) { $0 + $1.playCount }
        let topArtists = artistStats.prefix(5).map { stat in
            let percentage = totalArtistPlays > 0 ? Double(stat.playCount) / Double(totalArtistPlays) : 0
            return TasteArtist(name: stat.name, playCount: stat.playCount, trackCount: stat.trackCount, percentage: percentage)
        }
        
        // Mood based on genres and play patterns
        let mood = self.mood(for: tracks)
        
        // Eras based on year
        let eraGroups = Dictionary(grouping: tracks) { track -> String in
            guard let year = track.year else { return "Unknown" }
            let decade = (year / 10) * 10
            return "\(decade)s"
        }
        var eraStats: [(decade: String, count: Int)] = []
        for (decade, eraTracks) in eraGroups {
            eraStats.append((decade, eraTracks.count))
        }
        eraStats.sort { $0.count > $1.count }
        let totalEraCount = eraStats.reduce(0) { $0 + $1.count }
        let topEras = eraStats.prefix(3).map { stat in
            let percentage = totalEraCount > 0 ? Double(stat.count) / Double(totalEraCount) : 0
            return TasteEra(decade: stat.decade, count: stat.count, percentage: percentage)
        }
        
        // Stats
        let totalPlays = tracks.reduce(0) { $0 + $1.playCount }
        let totalDuration = tracks.reduce(0) { $0 + $1.duration }
        let favoriteCount = tracks.filter { $0.isFavorite }.count
        let listeningTime = tracks.reduce(0) { $0 + (Double($1.playCount) * $1.duration) }
        let diversity = diversityScore(for: tracks)
        
        let profile = AstryxTasteProfile(
            topGenres: Array(topGenres),
            topArtists: Array(topArtists),
            mood: mood,
            topEras: Array(topEras),
            totalPlays: totalPlays,
            totalTracks: tracks.count,
            totalDuration: totalDuration,
            favoriteCount: favoriteCount,
            listeningTime: listeningTime,
            diversityScore: diversity,
            lastUpdated: Date()
        )
        
        lock.lock()
        _currentProfile = profile
        lock.unlock()
        
        return profile
    }
    
    public func currentProfile() async -> AstryxTasteProfile? {
        lock.lock()
        defer { lock.unlock() }
        return _currentProfile
    }
    
    public func recommendations(for profile: AstryxTasteProfile, from library: [AstryxTrack], limit: Int = 10) async -> [AstryxRecommendation] {
        var recs: [AstryxRecommendation] = []
        
        // Because you liked — tracks similar to favorites
        let favorites = library.filter { $0.isFavorite }
        if !favorites.isEmpty {
            let favoriteGenres = Set(favorites.compactMap { $0.genre })
            let similar = library.filter { track in
                !track.isFavorite && favoriteGenres.contains(track.genre ?? "") && track.playCount < 3
            }.prefix(limit)
            
            if !similar.isEmpty {
                recs.append(AstryxRecommendation(
                    title: "Because you liked \(favorites.first?.artist ?? "favorites")",
                    reason: "Based on your favorites",
                    tracks: Array(similar),
                    type: .becauseYouLiked,
                    score: 0.9
                ))
            }
        }
        
        // Genre deep dive — more from top genre
        if let topGenre = profile.topGenres.first {
            let genreTracks = library.filter { $0.genre == topGenre.name && $0.playCount < 5 }.shuffled().prefix(limit)
            if !genreTracks.isEmpty {
                recs.append(AstryxRecommendation(
                    title: "More \(topGenre.name)",
                    reason: "Deep dive into your top genre",
                    tracks: Array(genreTracks),
                    type: .genreDeepDive,
                    score: 0.8
                ))
            }
        }
        
        // Rediscover — tracks not played in long time but high playCount historically
        let rediscover = library.filter { track in
            track.playCount > 5 && (track.lastPlayed == nil || track.lastPlayed! < Date().addingTimeInterval(-30*24*3600))
        }.sorted { $0.playCount > $1.playCount }.prefix(limit)
        
        if !rediscover.isEmpty {
            recs.append(AstryxRecommendation(
                title: "Rediscover",
                reason: "You haven't played these in a while",
                tracks: Array(rediscover),
                type: .rediscover,
                score: 0.7
            ))
        }
        
        // Mood match — tracks matching current mood
        let moodTracks = library.filter { track in
            // Simple mood matching via genre
            let moodGenres = genresForMood(profile.mood.primary)
            return moodGenres.contains(track.genre ?? "")
        }.shuffled().prefix(limit)
        
        if !moodTracks.isEmpty {
            recs.append(AstryxRecommendation(
                title: "\(profile.mood.primary) Vibes",
                reason: "Matching your current mood",
                tracks: Array(moodTracks),
                type: .moodMatch,
                score: 0.75
            ))
        }
        
        // Favorites mix
        if favorites.count >= 3 {
            let mix = favorites.shuffled().prefix(limit)
            recs.append(AstryxRecommendation(
                title: "Favorites Mix",
                reason: "Your all-time favorites",
                tracks: Array(mix),
                type: .favoritesMix,
                score: 0.85
            ))
        }
        
        // New releases — recently added with low playCount
        let newReleases = library.filter { $0.dateAdded > Date().addingTimeInterval(-14*24*3600) }.sorted { $0.dateAdded > $1.dateAdded }.prefix(limit)
        if !newReleases.isEmpty {
            recs.append(AstryxRecommendation(
                title: "New to Your Library",
                reason: "Recently added",
                tracks: Array(newReleases),
                type: .newReleases,
                score: 0.6
            ))
        }
        
        return recs
    }
    
    public func mood(for tracks: [AstryxTrack]) -> TasteMood {
        // Simple heuristic: based on genres
        let genreCounts = Dictionary(grouping: tracks) { $0.genre ?? "Unknown" }.mapValues { $0.count }
        let topGenre = genreCounts.max { $0.value < $1.value }?.key ?? "Unknown"
        
        // Map genre to mood
        let moodMap: [String: (String, Double, Double)] = [
            "Rock": ("Energetic", 0.8, 0.6),
            "Pop": ("Bright", 0.7, 0.8),
            "Jazz": ("Chill", 0.3, 0.5),
            "Classical": ("Focused", 0.2, 0.4),
            "Hip-Hop": ("Energetic", 0.75, 0.6),
            "Electronic": ("Euphoric", 0.85, 0.7),
            "Indie": ("Introspective", 0.5, 0.5),
            "Lo-Fi": ("Chill", 0.25, 0.4),
            "Metal": ("Dark", 0.9, 0.3),
            "R&B": ("Romantic", 0.5, 0.6),
            "Folk": ("Nostalgic", 0.4, 0.5)
        ]
        
        if let (moodName, energy, valence) = moodMap[topGenre] {
            return TasteMood(primary: moodName, energy: energy, valence: valence)
        }
        
        // Default based on play patterns
        let avgPlays = tracks.isEmpty ? 0 : Double(tracks.reduce(0) { $0 + $1.playCount }) / Double(tracks.count)
        if avgPlays > 10 {
            return TasteMood(primary: "Energetic", energy: 0.7, valence: 0.6)
        } else {
            return TasteMood(primary: "Chill", energy: 0.4, valence: 0.5)
        }
    }
    
    public func diversityScore(for tracks: [AstryxTrack]) -> Double {
        // Diversity based on number of unique genres/artists vs total
        let uniqueGenres = Set(tracks.compactMap { $0.genre }).count
        let uniqueArtists = Set(tracks.map { $0.artist }).count
        let total = tracks.count
        
        guard total > 0 else { return 0 }
        
        let genreDiversity = Double(uniqueGenres) / Double(min(total, 20)) // Normalize to 20 genres max
        let artistDiversity = Double(uniqueArtists) / Double(min(total, 50)) // Normalize to 50 artists max
        
        return min(1.0, (genreDiversity * 0.5 + artistDiversity * 0.5))
    }
    
    // MARK: - Helpers
    
    private func colorForGenre(_ genre: String) -> String {
        let colors: [String: String] = [
            "Rock": "#EF4444",
            "Pop": "#EC4899",
            "Jazz": "#8B5CF6",
            "Classical": "#6366F1",
            "Hip-Hop": "#F59E0B",
            "Electronic": "#06B6D4",
            "Indie": "#10B981",
            "Lo-Fi": "#6B7280",
            "Metal": "#1F2937",
            "R&B": "#F97316",
            "Folk": "#84CC16"
        ]
        return colors[genre] ?? "#3B82F6"
    }
    
    private func genresForMood(_ mood: String) -> [String] {
        let map: [String: [String]] = [
            "Energetic": ["Rock", "Hip-Hop", "Electronic", "Metal"],
            "Chill": ["Jazz", "Lo-Fi", "Classical", "Folk"],
            "Bright": ["Pop", "Electronic", "Indie"],
            "Dark": ["Metal", "Electronic"],
            "Focused": ["Classical", "Lo-Fi", "Jazz"],
            "Romantic": ["R&B", "Pop", "Jazz"],
            "Nostalgic": ["Folk", "Indie", "Rock"],
            "Euphoric": ["Electronic", "Pop"],
            "Introspective": ["Indie", "Folk", "Jazz"],
            "Melancholic": ["Indie", "Folk"]
        ]
        return map[mood] ?? []
    }
}
