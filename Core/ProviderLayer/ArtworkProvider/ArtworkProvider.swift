// QELORYX — ProviderLayer
// ArtworkProvider.swift

import Foundation

public protocol ArtworkProviderProtocol: Provider {
    func fetchArtwork(for track: AstryxTrack) async throws -> Data?
    func fetchArtwork(for album: AstryxAlbum) async throws -> Data?
}

public final class AstryxArtworkProvider: ArtworkProviderProtocol {
    
    public let id = "com.qeloryx.provider.artwork.local"
    public let name = "Local Artwork Provider"
    
    private let cache: any ArtworkCacheProtocol
    
    public init(cache: any ArtworkCacheProtocol = AstryxArtworkCache()) {
        self.cache = cache
    }
    
    public func fetchArtwork(for track: AstryxTrack) async throws -> Data? {
        // Check cache first
        if let cached = cache.cachedArtwork(for: track.id) {
            return cached
        }
        
        // Check embedded artwork
        if let data = track.artworkData {
            cache.cacheArtwork(data, for: track.id)
            return data
        }
        
        // Check file URL for cover.jpg in same folder
        let folder = track.fileURL.deletingLastPathComponent()
        let possibleNames = ["cover.jpg", "cover.png", "folder.jpg", "artwork.jpg"]
        for name in possibleNames {
            let url = folder.appendingPathComponent(name)
            if let data = try? Data(contentsOf: url) {
                cache.cacheArtwork(data, for: track.id)
                return data
            }
        }
        
        return nil
    }
    
    public func fetchArtwork(for album: AstryxAlbum) async throws -> Data? {
        // Try first track's artwork
        if let firstTrack = album.tracks.first {
            return try await fetchArtwork(for: firstTrack)
        }
        return nil
    }
}
