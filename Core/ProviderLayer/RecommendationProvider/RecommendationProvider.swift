import Foundation

public protocol RecommendationProviderProtocol: Provider {
    func recommendations(for track: AstryxTrack) async throws -> [AstryxTrack]
    func tasteProfile() async -> TasteProfile?
}

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
