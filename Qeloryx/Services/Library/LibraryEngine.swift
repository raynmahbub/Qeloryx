// QELORYX — Services/Library
// LibraryEngine.swift
// QEL-024 Library DNA — Production with multi-library, grouping, incremental indexing, artwork cache

import Foundation

// MARK: - LibraryEngine Protocol — QEL-024 Enhanced

public protocol LibraryEngineProtocol: Sendable {
    // Tracks
    func fetchAllTracks() async throws -> [AstryxTrack]
    func fetchTrack(id: String) async throws -> AstryxTrack?
    func searchTracks(query: String) async throws -> [AstryxTrack]
    func fetchTracks(forAlbum album: String, artist: String?) async throws -> [AstryxTrack]
    func fetchTracks(forArtist artist: String) async throws -> [AstryxTrack]
    func fetchTracks(forGenre genre: String) async throws -> [AstryxTrack]
    func fetchTracks(inFolder folderPath: String) async throws -> [AstryxTrack]
    
    // Albums, Artists, Genres, Folders
    func fetchAlbums() async throws -> [AstryxAlbum]
    func fetchAlbum(id: String) async throws -> AstryxAlbum?
    func fetchAlbums(forArtist artist: String) async throws -> [AstryxAlbum]
    func fetchArtists() async throws -> [AstryxArtist]
    func fetchGenres() async throws -> [AstryxGenre]
    func fetchFolders(forLibrary libraryID: String) async throws -> [AstryxFolder]
    
    // Libraries
    func fetchLibraries() async throws -> [AstryxLibrary]
    func fetchLibrary(id: String) async throws -> AstryxLibrary?
    func addLibrary(name: String, rootURL: URL, type: LibraryType) async throws -> AstryxLibrary
    func removeLibrary(id: String) async throws
    func enableLibrary(id: String) async throws
    func disableLibrary(id: String) async throws
    
    // Special
    func fetchFavorites() async throws -> [AstryxTrack]
    func fetchRecentlyAdded(limit: Int) async throws -> [AstryxTrack]
    func fetchHistory(limit: Int) async throws -> [AstryxTrack]
    func fetchMostPlayed(limit: Int) async throws -> [AstryxTrack]
    
    func toggleFavorite(trackID: String) async throws
    func recordPlay(trackID: String) async throws

    // Playlists — persisted, not stubbed
    func fetchPlaylists() async throws -> [AstryxPlaylist]
    func createPlaylist(name: String, trackIDs: [String]) async throws -> AstryxPlaylist
    func updatePlaylist(_ playlist: AstryxPlaylist) async throws
    func deletePlaylist(id: String) async throws

    /// Inserts a track that has already been validated (downloads, imports).
    /// Returns the stored track, or the existing one when a duplicate is found.
    func upsertTrack(_ track: AstryxTrack) async throws -> AstryxTrack
    
    // Indexing
    func startIndexing(rootURLs: [URL]) async throws -> IndexingResult
    func startIndexing(libraryID: String) async throws -> IndexingResult
    func startIndexingAllLibraries() async throws -> [IndexingResult]
    func scanForDuplicates() async throws -> [[AstryxTrack]]
    
    // Stats
    func stats() async throws -> LibraryStats
}

// MARK: - AstryxLibraryEngine — QEL-024 Production

public final class AstryxLibraryEngine: LibraryEngineProtocol {
    
    // `internal` (not `private`): playlist/upsert code lives in a sibling
    // extension file after the type_body_length split.
    let storage: any SwiftDataStackProtocol
    let indexer: any LibraryIndexerProtocol
    let fileScanner: any FileScannerProtocol
    let artworkCache: any ArtworkCacheProtocol
    let eventBus: any EventBusProtocol
    let metadataEngine: any MetadataEngineProtocol
    
    // Known files for incremental indexing: path -> modification date
    var knownFiles: [String: Date] = [:]
    let knownFilesLock = NSLock()
    
    /// Storage is a required dependency: the engine must never silently fall
    /// back to an in-memory store in production (BUG-01). Tests inject
    /// `InMemorySwiftDataStack()` explicitly.
    public init(
        storage: any SwiftDataStackProtocol,
        indexer: any LibraryIndexerProtocol = AstryxLibraryIndexer(),
        fileScanner: any FileScannerProtocol = AstryxFileScanner(),
        artworkCache: any ArtworkCacheProtocol = AstryxFileSystemArtworkCache(),
        eventBus: any EventBusProtocol = AstryxEventBus.shared,
        metadataEngine: any MetadataEngineProtocol = AstryxMetadataEngine()
    ) {
        self.storage = storage
        self.indexer = indexer
        self.fileScanner = fileScanner
        self.artworkCache = artworkCache
        self.eventBus = eventBus
        self.metadataEngine = metadataEngine
    }
    
    // MARK: - Tracks
    
    public func fetchAllTracks() async throws -> [AstryxTrack] {
        try await storage.fetchTracks(predicate: nil)
    }
    
    public func fetchTrack(id: String) async throws -> AstryxTrack? {
        try await storage.fetchTrack(id: id)
    }
    
    public func searchTracks(query: String) async throws -> [AstryxTrack] {
        try await storage.fetchTracks(predicate: TrackPredicate(searchText: query))
    }
    
    public func fetchTracks(forAlbum album: String, artist: String?) async throws -> [AstryxTrack] {
        try await storage.fetchTracks(forAlbum: album, artist: artist)
    }
    
    public func fetchTracks(forArtist artist: String) async throws -> [AstryxTrack] {
        try await storage.fetchTracks(forArtist: artist)
    }
    
    public func fetchTracks(forGenre genre: String) async throws -> [AstryxTrack] {
        try await storage.fetchTracks(forGenre: genre)
    }
    
    public func fetchTracks(inFolder folderPath: String) async throws -> [AstryxTrack] {
        try await storage.fetchTracks(inFolder: folderPath)
    }
    
    // MARK: - Albums, Artists, Genres, Folders
    
    public func fetchAlbums() async throws -> [AstryxAlbum] {
        try await storage.fetchAlbums()
    }
    
    public func fetchAlbum(id: String) async throws -> AstryxAlbum? {
        try await storage.fetchAlbum(id: id)
    }
    
    public func fetchAlbums(forArtist artist: String) async throws -> [AstryxAlbum] {
        try await storage.fetchAlbums(forArtist: artist)
    }
    
    public func fetchArtists() async throws -> [AstryxArtist] {
        try await storage.fetchArtists()
    }
    
    public func fetchGenres() async throws -> [AstryxGenre] {
        try await storage.fetchGenres()
    }
    
    public func fetchFolders(forLibrary libraryID: String) async throws -> [AstryxFolder] {
        try await storage.fetchFolders(forLibrary: libraryID)
    }
    
    // MARK: - Libraries
    
    public func fetchLibraries() async throws -> [AstryxLibrary] {
        try await storage.fetchLibraries()
    }
    
    public func fetchLibrary(id: String) async throws -> AstryxLibrary? {
        try await storage.fetchLibrary(id: id)
    }
    
    public func addLibrary(name: String, rootURL: URL, type: LibraryType) async throws -> AstryxLibrary {
        let library = AstryxLibrary(name: name, rootURL: rootURL, type: type)
        try await storage.insertLibrary(library)
        eventBus.publish(.libraryDidChange(changeType: .fullReload))
        return library
    }
    
    public func removeLibrary(id: String) async throws {
        try await storage.deleteLibrary(id: id)
        try await storage.deleteTracks(forLibrary: id)
        eventBus.publish(.libraryDidChange(changeType: .fullReload))
    }
    
    public func enableLibrary(id: String) async throws {
        guard var lib = try await storage.fetchLibrary(id: id) else { return }
        lib.isEnabled = true
        try await storage.updateLibrary(lib)
        eventBus.publish(.libraryDidChange(changeType: .incremental))
    }
    
    public func disableLibrary(id: String) async throws {
        guard var lib = try await storage.fetchLibrary(id: id) else { return }
        lib.isEnabled = false
        try await storage.updateLibrary(lib)
        eventBus.publish(.libraryDidChange(changeType: .incremental))
    }
    
    // MARK: - Special
    
    public func fetchFavorites() async throws -> [AstryxTrack] {
        try await storage.fetchFavorites()
    }
    
    public func fetchRecentlyAdded(limit: Int) async throws -> [AstryxTrack] {
        try await storage.fetchRecentlyAdded(limit: limit)
    }
    
    public func fetchHistory(limit: Int) async throws -> [AstryxTrack] {
        try await storage.fetchHistory(limit: limit)
    }
    
    public func fetchMostPlayed(limit: Int) async throws -> [AstryxTrack] {
        try await storage.fetchMostPlayed(limit: limit)
    }
    
    public func toggleFavorite(trackID: String) async throws {
        guard var track = try await storage.fetchTrack(id: trackID) else { return }
        track.isFavorite.toggle()
        try await storage.updateTrack(track)
        eventBus.publish(.trackUpdated(id: trackID))
        eventBus.publish(.libraryDidChange(changeType: .favorites))
    }
    
    public func recordPlay(trackID: String) async throws {
        guard var track = try await storage.fetchTrack(id: trackID) else { return }
        track.playCount += 1
        track.lastPlayed = Date()
        try await storage.updateTrack(track)
        eventBus.publish(.trackUpdated(id: trackID))
        eventBus.publish(.libraryDidChange(changeType: .history))
    }
    
    // MARK: - Indexing — QEL-024 Production
    
    public func startIndexing(rootURLs: [URL]) async throws -> IndexingResult {
        eventBus.publish(.indexingStarted)
        
        let start = Date()
        
        // Scan files
        let scanResult = try await fileScanner.scan(rootURLs: rootURLs)
        
        var newTracks: [AstryxTrack] = []
        var errors: [String] = []
        
        for (index, discovered) in scanResult.discoveredFiles.enumerated() {
            // Publish progress every 50 files to avoid flooding
            if index % 50 == 0 {
                eventBus.publish(.indexingProgress(completed: index, total: scanResult.discoveredFiles.count))
            }
            
            do {
                // Extract metadata
                let rawMetadata = try await metadataEngine.extractMetadata(from: discovered.url)
                
                // Content-derived fingerprint (BUG-14). The old size+filename
                // value collided across albums and broke on rename.
                let checksum = AstryxContentChecksum.fingerprint(
                    at: discovered.url,
                    fileSize: discovered.fileSize
                )
                
                let track = AstryxTrack(
                    title: rawMetadata.title ?? discovered.url.deletingPathExtension().lastPathComponent,
                    artist: rawMetadata.artist ?? "Unknown Artist",
                    album: rawMetadata.album ?? "Unknown Album",
                    albumArtist: rawMetadata.albumArtist,
                    genre: rawMetadata.genre,
                    year: rawMetadata.year,
                    trackNumber: rawMetadata.trackNumber,
                    discNumber: rawMetadata.discNumber,
                    duration: rawMetadata.duration ?? 0,
                    fileURL: discovered.url,
                    fileFormat: discovered.format,
                    fileSize: discovered.fileSize,
                    bitRate: rawMetadata.bitRate,
                    sampleRate: rawMetadata.sampleRate,
                    isLossless: discovered.format.isLossless,
                    artworkData: rawMetadata.artworkData,
                    dateAdded: Date(),
                    dateModified: discovered.modificationDate,
                    lyrics: rawMetadata.lyrics,
                    folderPath: discovered.url.deletingLastPathComponent().path,
                    checksum: checksum,
                    libraryID: discovered.libraryID
                )
                
                newTracks.append(track)
                
                // Update known files
                knownFilesLock.lock()
                knownFiles[discovered.url.path] = discovered.modificationDate
                knownFilesLock.unlock()
                
                // Batch insert every 100 tracks for performance
                if newTracks.count % 100 == 0 {
                    try await storage.insertTracks(newTracks)
                    newTracks.removeAll()
                    await Task.yield()
                }
                
            } catch {
                errors.append("Failed to index \(discovered.url.path): \(error.localizedDescription)")
            }
        }
        
        // Insert remaining
        if !newTracks.isEmpty {
            try await storage.insertTracks(newTracks)
        }
        
        let duration = Date().timeIntervalSince(start)
        let result = IndexingResult(
            newTracks: scanResult.discoveredFiles.count,
            updatedTracks: 0,
            removedTracks: 0,
            duration: duration,
            errors: errors
        )
        
        eventBus.publish(.indexingCompleted(newTracks: scanResult.discoveredFiles.count))
        eventBus.publish(.libraryDidChange(changeType: .incremental))
        
        return result
    }
    
    public func startIndexing(libraryID: String) async throws -> IndexingResult {
        guard let library = try await storage.fetchLibrary(id: libraryID) else {
            throw LibraryError.libraryNotFound(id: libraryID)
        }
        return try await startIndexing(rootURLs: [library.rootURL])
    }
    
    public func startIndexingAllLibraries() async throws -> [IndexingResult] {
        let libraries = try await storage.fetchLibraries()
        let enabled = libraries.filter { $0.isEnabled }
        
        if enabled.isEmpty {
            // Fallback: try to scan if no libraries defined, return empty
            return []
        }
        
        knownFilesLock.lock()
        let known = knownFiles
        knownFilesLock.unlock()
        
        let scanResult = try await fileScanner.scanIncremental(libraries: enabled, knownFiles: known)
        
        // Handle removed files
        for removedPath in scanResult.removedFiles {
            // Find track by path and delete
            let allTracks = try await storage.fetchTracks(predicate: nil)
            if let track = allTracks.first(where: { $0.fileURL.path == removedPath }) {
                try await storage.deleteTrack(id: track.id)
            }
            knownFilesLock.lock()
            knownFiles.removeValue(forKey: removedPath)
            knownFilesLock.unlock()
        }
        
        // Index new/modified files
        var newTracks: [AstryxTrack] = []
        var errors: [String] = []
        
        for discovered in scanResult.discoveredFiles {
            do {
                let rawMetadata = try await metadataEngine.extractMetadata(from: discovered.url)
                let checksum = AstryxContentChecksum.fingerprint(
                    at: discovered.url,
                    fileSize: discovered.fileSize
                )
                
                let track = AstryxTrack(
                    title: rawMetadata.title ?? discovered.url.deletingPathExtension().lastPathComponent,
                    artist: rawMetadata.artist ?? "Unknown Artist",
                    album: rawMetadata.album ?? "Unknown Album",
                    albumArtist: rawMetadata.albumArtist,
                    genre: rawMetadata.genre,
                    year: rawMetadata.year,
                    trackNumber: rawMetadata.trackNumber,
                    discNumber: rawMetadata.discNumber,
                    duration: rawMetadata.duration ?? 0,
                    fileURL: discovered.url,
                    fileFormat: discovered.format,
                    fileSize: discovered.fileSize,
                    bitRate: rawMetadata.bitRate,
                    sampleRate: rawMetadata.sampleRate,
                    isLossless: discovered.format.isLossless,
                    artworkData: rawMetadata.artworkData,
                    dateAdded: Date(),
                    dateModified: discovered.modificationDate,
                    lyrics: rawMetadata.lyrics,
                    folderPath: discovered.url.deletingLastPathComponent().path,
                    checksum: checksum,
                    libraryID: discovered.libraryID
                )
                
                newTracks.append(track)
                
                knownFilesLock.lock()
                knownFiles[discovered.url.path] = discovered.modificationDate
                knownFilesLock.unlock()
                
            } catch {
                errors.append("Failed: \(discovered.url.path) \(error)")
            }
        }
        
        if !newTracks.isEmpty {
            try await storage.insertTracks(newTracks)
        }
        
        let result = IndexingResult(
            newTracks: scanResult.discoveredFiles.count,
            updatedTracks: 0,
            removedTracks: scanResult.removedFiles.count,
            duration: scanResult.duration,
            errors: errors
        )
        
        eventBus.publish(.indexingCompleted(newTracks: result.newTracks))
        eventBus.publish(.libraryDidChange(changeType: .incremental))
        
        return [result]
    }
    
}
