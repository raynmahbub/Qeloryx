// QELORYX — SearchEngine
// IndexedSearch.swift
// Instant search with inverted index, target <50ms

import Foundation

public protocol IndexedSearchProtocol: Sendable {
    func buildIndex(tracks: [AstryxTrack], albums: [AstryxAlbum], artists: [AstryxArtist], playlists: [AstryxPlaylist]) async
    func search(query: SearchQuery) async -> [AstryxSearchResult]
    func incrementalUpdate(track: AstryxTrack) async
    func removeTrack(id: String) async
}

public final class AstryxIndexedSearch: IndexedSearchProtocol, @unchecked Sendable {
    
    // Inverted index: token -> Set of track IDs
    private var invertedIndex: [String: Set<String>] = [:]
    private var trackStore: [String: AstryxTrack] = [:]
    private var albumStore: [String: AstryxAlbum] = [:]
    private var artistStore: [String: AstryxArtist] = [:]
    private var playlistStore: [String: AstryxPlaylist] = [:]
    
    private let lock = NSLock()
    private var version: Int = 0
    private let eventBus: any EventBusProtocol
    
    public init(eventBus: any EventBusProtocol = AstryxEventBus.shared) {
        self.eventBus = eventBus
    }
    
    public func buildIndex(tracks: [AstryxTrack], albums: [AstryxAlbum], artists: [AstryxArtist], playlists: [AstryxPlaylist]) async {
        lock.lock()
        invertedIndex.removeAll()
        trackStore.removeAll()
        albumStore.removeAll()
        artistStore.removeAll()
        playlistStore.removeAll()
        
        for track in tracks {
            trackStore[track.id] = track
            indexTrack(track)
        }
        for album in albums {
            albumStore[album.id] = album
        }
        for artist in artists {
            artistStore[artist.id] = artist
        }
        for playlist in playlists {
            playlistStore[playlist.id] = playlist
        }
        
        version += 1
        let currentVersion = version
        lock.unlock()
        
        eventBus.publish(.searchIndexUpdated(version: currentVersion))
    }
    
    public func search(query: SearchQuery) async -> [AstryxSearchResult] {
        let start = Date()
        
        let tokens = tokenize(query.text)
        guard !tokens.isEmpty else { return [] }
        
        lock.lock()
        let localIndex = invertedIndex
        let localTracks = trackStore
        let localAlbums = albumStore
        let localArtists = artistStore
        lock.unlock()
        
        // Find candidate track IDs that match all tokens (AND), or at least one (OR) for fuzzy
        var candidateIDs: Set<String> = []
        var first = true
        
        for token in tokens {
            let matchingIDs = localIndex[token] ?? Set()
            // Also check prefix matches for instant search
            let prefixMatches = localIndex.filter { $0.key.hasPrefix(token) }.flatMap { $0.value }
            
            var combined = matchingIDs
            combined.formUnion(prefixMatches)
            
            if first {
                candidateIDs = combined
                first = false
            } else {
                candidateIDs.formIntersection(combined)
                // If AND yields nothing, fallback to OR for better UX
                if candidateIDs.isEmpty {
                    candidateIDs.formUnion(combined)
                }
            }
        }
        
        // Score results
        var results: [AstryxSearchResult] = []
        
        for id in candidateIDs {
            guard let track = localTracks[id] else { continue }
            
            let score = calculateScore(track: track, tokens: tokens, query: query.text)
            let result = AstryxSearchResult(
                type: .track,
                title: track.title,
                subtitle: "\(track.artist) • \(track.album)",
                trackID: track.id,
                score: score,
                matchedFields: matchedFields(track: track, tokens: tokens)
            )
            results.append(result)
        }
        
        // Also search albums, artists by name
        if query.filters?.types == nil || query.filters?.types?.contains(.album) == true {
            for album in localAlbums.values {
                if album.title.lowercased().contains(query.text.lowercased()) {
                    results.append(AstryxSearchResult(type: .album, title: album.title, subtitle: album.artist, albumID: album.id, score: 0.8))
                }
            }
        }
        
        if query.filters?.types == nil || query.filters?.types?.contains(.artist) == true {
            for artist in localArtists.values {
                if artist.name.lowercased().contains(query.text.lowercased()) {
                    results.append(AstryxSearchResult(type: .artist, title: artist.name, subtitle: "\(artist.trackCount) tracks", artistID: artist.id, score: 0.8))
                }
            }
        }
        
        let sorted = results.sorted { $0.score > $1.score }
        let limited = Array(sorted.prefix(query.limit))
        
        let elapsed = Date().timeIntervalSince(start) * 1000
        #if DEBUG
        if elapsed > 50 {
            debugPrint("[SearchEngine] Slow query: \(elapsed)ms for '\(query.text)'")
        }
        #endif
        
        return limited
    }
    
    public func incrementalUpdate(track: AstryxTrack) async {
        lock.lock()
        // Remove old tokens
        if let old = trackStore[track.id] {
            removeTrackFromIndex(old)
        }
        trackStore[track.id] = track
        indexTrack(track)
        version += 1
        let currentVersion = version
        lock.unlock()
        
        eventBus.publish(.searchIndexUpdated(version: currentVersion))
    }
    
    public func removeTrack(id: String) async {
        lock.lock()
        if let track = trackStore[id] {
            removeTrackFromIndex(track)
            trackStore.removeValue(forKey: id)
        }
        version += 1
        let currentVersion = version
        lock.unlock()
        
        eventBus.publish(.searchIndexUpdated(version: currentVersion))
    }
    
    // MARK: - Private
    
    private func indexTrack(_ track: AstryxTrack) {
        let text = "\(track.title) \(track.artist) \(track.album) \(track.genre ?? "")"
        let tokens = tokenize(text)
        for token in tokens {
            invertedIndex[token, default: Set()].insert(track.id)
        }
    }
    
    private func removeTrackFromIndex(_ track: AstryxTrack) {
        let text = "\(track.title) \(track.artist) \(track.album) \(track.genre ?? "")"
        let tokens = tokenize(text)
        for token in tokens {
            invertedIndex[token]?.remove(track.id)
            if invertedIndex[token]?.isEmpty == true {
                invertedIndex.removeValue(forKey: token)
            }
        }
    }
    
    private func tokenize(_ text: String) -> [String] {
        let lower = text.lowercased().folding(options: .diacriticInsensitive, locale: .current)
        let components = lower.components(separatedBy: CharacterSet.alphanumerics.inverted)
        return components.filter { $0.count >= 2 } // Ignore single chars
    }
    
    private func calculateScore(track: AstryxTrack, tokens: [String], query: String) -> Double {
        var score = 0.0
        let lowerQuery = query.lowercased()
        
        // Exact title match = highest
        if track.title.lowercased() == lowerQuery {
            score += 10
        } else if track.title.lowercased().hasPrefix(lowerQuery) {
            score += 8
        } else if track.title.lowercased().contains(lowerQuery) {
            score += 5
        }
        
        // Artist match
        if track.artist.lowercased().contains(lowerQuery) {
            score += 3
        }
        
        // Album match
        if track.album.lowercased().contains(lowerQuery) {
            score += 2
        }
        
        // Token coverage
        let trackTokens = tokenize("\(track.title) \(track.artist) \(track.album)")
        let matched = tokens.filter { trackTokens.contains($0) }.count
        score += Double(matched) / Double(max(tokens.count, 1)) * 2
        
        // Boost favorites and recent
        if track.isFavorite { score += 0.5 }
        if track.playCount > 10 { score += 0.3 }
        
        return score
    }
    
    private func matchedFields(track: AstryxTrack, tokens: [String]) -> [String] {
        var fields: [String] = []
        let lowerTokens = tokens.map { $0.lowercased() }
        if lowerTokens.contains(where: { track.title.lowercased().contains($0) }) { fields.append("title") }
        if lowerTokens.contains(where: { track.artist.lowercased().contains($0) }) { fields.append("artist") }
        if lowerTokens.contains(where: { track.album.lowercased().contains($0) }) { fields.append("album") }
        return fields
    }
}
