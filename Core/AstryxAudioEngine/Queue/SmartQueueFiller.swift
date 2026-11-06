// QELORYX — AstryxAudioEngine
// SmartQueueFiller.swift
// Feature benchmark: AI/smart queue auto-fill (Echo Music "AI queue", TasteDNA-driven)
// Original Qeloryx implementation — ranks library tracks to extend the queue

import Foundation

// MARK: - Smart Queue Filler

/// Suggests tracks to append when the queue is about to run out.
/// Combines TasteDNA recommendations, favorites, and play history — offline-first.
public final class AstryxSmartQueueFiller: @unchecked Sendable {
    
    public init() {}
    
    /// Returns up to `limit` library tracks worth appending to `queue`,
    /// excluding anything already queued. `recommendedTrackIDs` should come
    /// from the TasteDNA engine / RecommendationProvider.
    public func suggestedTracks(
        for queue: AstryxQueue,
        library: [AstryxTrack],
        recommendedTrackIDs: [String] = [],
        limit: Int = 10
    ) -> [AstryxTrack] {
        guard limit > 0 else { return [] }
        let queuedIDs = Set(queue.items.map { $0.trackID })
        let recommendationRank = Dictionary(uniqueKeysWithValues: recommendedTrackIDs.enumerated().map { ($1, $0) })
        
        let candidates = library.filter { !queuedIDs.contains($0.id) }
        let scored = candidates.map { track -> (track: AstryxTrack, score: Double) in
            var score = 0.0
            if let rank = recommendationRank[track.id] {
                score += 100.0 - Double(min(rank, 99)) // earlier recommendation = higher score
            }
            if track.isFavorite { score += 10.0 }
            score += min(Double(track.playCount), 50.0) * 0.2
            if track.lastPlayed != nil { score += 1.0 }
            return (track, score)
        }
        return scored
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0.track }
    }
    
    /// Convenience: track IDs only, in suggestion order.
    public func suggestedTrackIDs(
        for queue: AstryxQueue,
        library: [AstryxTrack],
        recommendedTrackIDs: [String] = [],
        limit: Int = 10
    ) -> [String] {
        suggestedTracks(for: queue, library: library, recommendedTrackIDs: recommendedTrackIDs, limit: limit).map { $0.id }
    }
}
