// QELORYX — ProviderLayer
// RecommendationProvider.swift
// QEL-051 Discovery — Production with TasteDNA integration, offline-first

import Foundation

public protocol RecommendationProviderProtocol: Provider {
    func recommendations(for track: AstryxTrack) async throws -> [AstryxTrack]
    func recommendations(for profile: AstryxTasteProfile, from library: [AstryxTrack]) async throws -> [AstryxRecommendation]
    func tasteProfile() async -> AstryxTasteProfile?
    func generateProfile(from tracks: [AstryxTrack]) async -> AstryxTasteProfile
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

// MARK: - Production Recommendation Provider — QEL-051

public final class AstryxRecommendationProvider: RecommendationProviderProtocol {
    
    public let id = "com.qeloryx.provider.recommendation.local"
    public let name = "Local Recommendation Provider"
    
    private let tasteEngine: any TasteDNAEngineProtocol
    private var _currentProfile: AstryxTasteProfile?
    private let lock = NSLock()
    
    public init(tasteEngine: any TasteDNAEngineProtocol = AstryxTasteDNAEngine()) {
        self.tasteEngine = tasteEngine
    }
    
    public func recommendations(for track: AstryxTrack) async throws -> [AstryxTrack] {
        // For single track, return similar tracks — offline-first local
        // This would need library access, so return empty for now, real implementation via library injection
        return []
    }
    
    public func recommendations(for profile: AstryxTasteProfile, from library: [AstryxTrack]) async throws -> [AstryxRecommendation] {
        return await tasteEngine.recommendations(for: profile, from: library, limit: 10)
    }
    
    public func tasteProfile() async -> AstryxTasteProfile? {
        lock.lock()
        defer { lock.unlock() }
        return _currentProfile
    }
    
    public func generateProfile(from tracks: [AstryxTrack]) async -> AstryxTasteProfile {
        let profile = await tasteEngine.generateProfile(from: tracks)
        lock.lock()
        _currentProfile = profile
        lock.unlock()
        return profile
    }
    
    // Legacy compatibility
    public func tasteProfileLegacy() async -> TasteProfile? {
        guard let profile = await tasteProfile() else { return nil }
        return TasteProfile(
            topGenres: profile.topGenres.map { $0.name },
            topArtists: profile.topArtists.map { $0.name },
            mood: profile.mood.primary
        )
    }
}
