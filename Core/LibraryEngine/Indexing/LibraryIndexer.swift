// QELORYX — LibraryEngine
// LibraryIndexer.swift
// Incremental indexing for offline-first library

import Foundation

// MARK: - LibraryIndexer Protocol

public protocol LibraryIndexerProtocol: Sendable {
    func startIncrementalIndex(rootURLs: [URL]) async throws -> IndexingResult
    func scanFile(at url: URL) async throws -> AstryxTrack?
    func detectDuplicates(in tracks: [AstryxTrack]) -> [[AstryxTrack]]
}

// MARK: - IndexingResult

public struct IndexingResult: Sendable, Equatable {
    public let newTracks: Int
    public let updatedTracks: Int
    public let removedTracks: Int
    public let duration: TimeInterval
    public let errors: [String]
    
    public init(newTracks: Int, updatedTracks: Int, removedTracks: Int, duration: TimeInterval, errors: [String] = []) {
        self.newTracks = newTracks
        self.updatedTracks = updatedTracks
        self.removedTracks = removedTracks
        self.duration = duration
        self.errors = errors
    }
}

// MARK: - AstryxLibraryIndexer

public final class AstryxLibraryIndexer: LibraryIndexerProtocol {
    
    private let eventBus: any EventBusProtocol
    private let metadataNormalizer: MetadataNormalizerProtocol
    
    public init(eventBus: any EventBusProtocol = AstryxEventBus.shared, metadataNormalizer: MetadataNormalizerProtocol = AstryxMetadataNormalizer()) {
        self.eventBus = eventBus
        self.metadataNormalizer = metadataNormalizer
    }
    
    public func startIncrementalIndex(rootURLs: [URL]) async throws -> IndexingResult {
        let start = Date()
        eventBus.publish(.indexingStarted)
        
        var newTracks = 0
        var errors: [String] = []
        
        // Foundation: placeholder scanning logic
        // Real implementation would use FileManager enumerator + metadata parsing
        for (index, url) in rootURLs.enumerated() {
            eventBus.publish(.indexingProgress(completed: index, total: rootURLs.count))
            
            // Simulate file discovery
            // In real implementation: recursive directory scan, filter by AudioFormat.supportedFormats
            do {
                // Placeholder
                _ = try await scanFile(at: url)
                newTracks += 1
            } catch {
                errors.append("Failed to scan \(url): \(error.localizedDescription)")
            }
        }
        
        let duration = Date().timeIntervalSince(start)
        let result = IndexingResult(newTracks: newTracks, updatedTracks: 0, removedTracks: 0, duration: duration, errors: errors)
        
        eventBus.publish(.indexingCompleted(newTracks: newTracks))
        eventBus.publish(.libraryDidChange(changeType: .incremental))
        
        return result
    }
    
    public func scanFile(at url: URL) async throws -> AstryxTrack? {
        // Check if file extension is supported
        let ext = url.pathExtension.lowercased()
        let format = AudioFormat.fromExtension(ext)
        guard format != .unknown else { return nil }
        
        // In real implementation:
        // - Use AVAsset to get duration
        // - Use MetadataEngine to extract title/artist/album
        // - Calculate checksum for duplicate detection
        // - Extract artwork
        
        let track = AstryxTrack(
            title: url.deletingPathExtension().lastPathComponent,
            artist: "Unknown Artist",
            album: "Unknown Album",
            duration: 0,
            fileURL: url,
            fileFormat: format,
            folderPath: url.deletingLastPathComponent().path
        )
        
        let normalized = metadataNormalizer.normalize(track: track)
        return normalized
    }
    
    public func detectDuplicates(in tracks: [AstryxTrack]) -> [[AstryxTrack]] {
        // Group by checksum, or by title+artist+duration proximity
        var groups: [String: [AstryxTrack]] = [:]
        
        for track in tracks {
            let key: String
            if let checksum = track.checksum {
                key = checksum
            } else {
                // Fallback: normalized title + artist + duration bucket
                let titleKey = track.title.lowercased().trimmingCharacters(in: .whitespaces)
                let artistKey = track.artist.lowercased().trimmingCharacters(in: .whitespaces)
                let durationBucket = Int(track.duration / 2) // 2 second buckets
                key = "\(titleKey)|\(artistKey)|\(durationBucket)"
            }
            groups[key, default: []].append(track)
        }
        
        return groups.values.filter { $0.count > 1 }
    }
}

// MARK: - MetadataNormalizer

public protocol MetadataNormalizerProtocol: Sendable {
    func normalize(track: AstryxTrack) -> AstryxTrack
}

public final class AstryxMetadataNormalizer: MetadataNormalizerProtocol {
    public init() {}
    
    public func normalize(track: AstryxTrack) -> AstryxTrack {
        var normalized = track
        
        // Trim whitespace
        normalized.title = normalized.title.trimmingCharacters(in: .whitespacesAndNewlines)
        normalized.artist = normalized.artist.trimmingCharacters(in: .whitespacesAndNewlines)
        normalized.album = normalized.album.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Fallbacks
        if normalized.title.isEmpty {
            normalized.title = normalized.fileURL.deletingPathExtension().lastPathComponent
        }
        if normalized.artist.isEmpty {
            normalized.artist = "Unknown Artist"
        }
        if normalized.album.isEmpty {
            normalized.album = "Unknown Album"
        }
        
        // Normalize genre capitalization
        if let genre = normalized.genre {
            normalized.genre = genre.capitalized
        }
        
        return normalized
    }
}
