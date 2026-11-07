// QELORYX — LibraryEngine
// SwiftDataStack.swift
// QEL-024 Library — Production abstraction with multi-library, grouping, folder view, SwiftData concrete

import Foundation

// MARK: - SwiftDataStack Protocol (Portable) — QEL-024 Enhanced

public protocol SwiftDataStackProtocol: Sendable {
    /// `false` for the in-memory store. The UI shows a persistent banner when
    /// the library will not survive relaunch, instead of silently appearing to
    /// save (BUG-01).
    var isPersistent: Bool { get }

    // Tracks
    func fetchTracks(predicate: TrackPredicate?) async throws -> [AstryxTrack]
    func fetchTrack(id: String) async throws -> AstryxTrack?
    func fetchTracks(forAlbum album: String, artist: String?) async throws -> [AstryxTrack]
    func fetchTracks(forArtist artist: String) async throws -> [AstryxTrack]
    func fetchTracks(forGenre genre: String) async throws -> [AstryxTrack]
    func fetchTracks(inFolder folderPath: String) async throws -> [AstryxTrack]
    func fetchTracks(forLibrary libraryID: String) async throws -> [AstryxTrack]
    
    func insertTrack(_ track: AstryxTrack) async throws
    func insertTracks(_ tracks: [AstryxTrack]) async throws
    func updateTrack(_ track: AstryxTrack) async throws
    func deleteTrack(id: String) async throws
    func deleteTracks(forLibrary libraryID: String) async throws
    
    // Albums
    func fetchAlbums() async throws -> [AstryxAlbum]
    func fetchAlbum(id: String) async throws -> AstryxAlbum?
    func fetchAlbums(forArtist artist: String) async throws -> [AstryxAlbum]
    
    // Artists
    func fetchArtists() async throws -> [AstryxArtist]
    func fetchArtist(id: String) async throws -> AstryxArtist?
    
    // Genres
    func fetchGenres() async throws -> [AstryxGenre]
    
    // Folders
    func fetchFolders(forLibrary libraryID: String) async throws -> [AstryxFolder]
    func fetchFolder(path: String) async throws -> AstryxFolder?
    
    // Libraries
    func fetchLibraries() async throws -> [AstryxLibrary]
    func fetchLibrary(id: String) async throws -> AstryxLibrary?
    func insertLibrary(_ library: AstryxLibrary) async throws
    func updateLibrary(_ library: AstryxLibrary) async throws
    func deleteLibrary(id: String) async throws
    
    // Playlists
    func fetchPlaylists() async throws -> [AstryxPlaylist]
    func insertPlaylist(_ playlist: AstryxPlaylist) async throws
    func updatePlaylist(_ playlist: AstryxPlaylist) async throws
    func deletePlaylist(id: String) async throws
    
    // Special queries
    func fetchRecentlyAdded(limit: Int) async throws -> [AstryxTrack]
    func fetchFavorites() async throws -> [AstryxTrack]
    func fetchHistory(limit: Int) async throws -> [AstryxTrack]
    func fetchMostPlayed(limit: Int) async throws -> [AstryxTrack]
    
    // Stats
    func totalTrackCount() async throws -> Int
    func totalDuration() async throws -> TimeInterval
    func totalSize() async throws -> Int64
}

public struct TrackPredicate: Sendable {
    public var searchText: String?
    public var artist: String?
    public var album: String?
    public var genre: String?
    public var isFavorite: Bool?
    public var folderPath: String?
    public var libraryID: String?
    public var isLossless: Bool?
    
    public init(
        searchText: String? = nil,
        artist: String? = nil,
        album: String? = nil,
        genre: String? = nil,
        isFavorite: Bool? = nil,
        folderPath: String? = nil,
        libraryID: String? = nil,
        isLossless: Bool? = nil
    ) {
        self.searchText = searchText
        self.artist = artist
        self.album = album
        self.genre = genre
        self.isFavorite = isFavorite
        self.folderPath = folderPath
        self.libraryID = libraryID
        self.isLossless = isLossless
    }
}

// MARK: - In-Memory Implementation — QEL-024 Production

public final class InMemorySwiftDataStack: SwiftDataStackProtocol, @unchecked Sendable {
    /// Never survives relaunch — by definition.
    public let isPersistent = false

    private var tracks: [String: AstryxTrack] = [:]
    private var libraries: [String: AstryxLibrary] = [:]
    private var playlists: [String: AstryxPlaylist] = [:]
    private let lock = NSLock()
    
    public init() {}
    
    // MARK: Tracks
    
    public func fetchTracks(predicate: TrackPredicate?) async throws -> [AstryxTrack] {
        lock.lock()
        defer { lock.unlock() }
        var result = Array(tracks.values)
        
        if let p = predicate {
            if let search = p.searchText?.lowercased(), !search.isEmpty {
                result = result.filter {
                    $0.title.lowercased().contains(search) ||
                    $0.artist.lowercased().contains(search) ||
                    $0.album.lowercased().contains(search)
                }
            }
            if let artist = p.artist { result = result.filter { $0.artist == artist } }
            if let album = p.album { result = result.filter { $0.album == album } }
            if let genre = p.genre { result = result.filter { $0.genre == genre } }
            if let fav = p.isFavorite { result = result.filter { $0.isFavorite == fav } }
            if let folder = p.folderPath { result = result.filter { $0.folderPath == folder } }
            // Previously `|| true`, which made every per-library query return
            // the whole library. Track now carries its owning library ID.
            if let libID = p.libraryID { result = result.filter { $0.libraryID == libID } }
            if let lossless = p.isLossless { result = result.filter { $0.isLossless == lossless } }
        }
        
        return result
    }
    
    public func fetchTrack(id: String) async throws -> AstryxTrack? {
        lock.lock()
        defer { lock.unlock() }
        return tracks[id]
    }
    
    public func fetchTracks(forAlbum album: String, artist: String?) async throws -> [AstryxTrack] {
        lock.lock()
        defer { lock.unlock() }
        return tracks.values.filter {
            $0.album == album && (artist == nil || $0.artist == artist)
        }.sorted { ($0.trackNumber ?? 0) < ($1.trackNumber ?? 0) }
    }
    
    public func fetchTracks(forArtist artist: String) async throws -> [AstryxTrack] {
        lock.lock()
        defer { lock.unlock() }
        return tracks.values.filter { $0.artist == artist }
    }
    
    public func fetchTracks(forGenre genre: String) async throws -> [AstryxTrack] {
        lock.lock()
        defer { lock.unlock() }
        return tracks.values.filter { $0.genre == genre }
    }
    
    public func fetchTracks(inFolder folderPath: String) async throws -> [AstryxTrack] {
        lock.lock()
        defer { lock.unlock() }
        return tracks.values.filter { $0.folderPath == folderPath }
    }
    
    public func fetchTracks(forLibrary libraryID: String) async throws -> [AstryxTrack] {
        lock.lock()
        defer { lock.unlock() }
        return tracks.values.filter { $0.libraryID == libraryID }
    }
    
    public func insertTrack(_ track: AstryxTrack) async throws {
        lock.lock()
        tracks[track.id] = track
        lock.unlock()
    }
    
    public func insertTracks(_ tracks: [AstryxTrack]) async throws {
        lock.lock()
        for track in tracks { self.tracks[track.id] = track }
        lock.unlock()
    }
    
    public func updateTrack(_ track: AstryxTrack) async throws {
        try await insertTrack(track)
    }
    
    public func deleteTrack(id: String) async throws {
        lock.lock()
        tracks.removeValue(forKey: id)
        lock.unlock()
    }
    
    public func deleteTracks(forLibrary libraryID: String) async throws {
        lock.lock()
        // Only remove entries that belong to this library — the previous
        // implementation wiped the entire store.
        tracks = tracks.filter { $0.value.libraryID != libraryID }
        lock.unlock()
    }
    
    // MARK: Albums
    
    public func fetchAlbums() async throws -> [AstryxAlbum] {
        let allTracks = try await fetchTracks(predicate: nil)
        let grouped = Dictionary(grouping: allTracks) { "\($0.album)|\($0.albumArtist ?? $0.artist)" }
        return grouped.map { (key, tracks) in
            let components = key.components(separatedBy: "|")
            let albumTitle = components.first ?? "Unknown Album"
            let albumArtist = components.count > 1 ? components[1] : tracks.first?.artist ?? "Unknown"
            return AstryxAlbum(
                title: albumTitle,
                artist: albumArtist,
                albumArtist: tracks.first?.albumArtist,
                year: tracks.first?.year,
                genre: tracks.first?.genre,
                trackCount: tracks.count,
                duration: tracks.reduce(0) { $0 + $1.duration },
                artworkURL: tracks.first?.artworkURL,
                tracks: tracks.sorted { ($0.trackNumber ?? 0) < ($1.trackNumber ?? 0) }
            )
        }.sorted { $0.title < $1.title }
    }
    
    public func fetchAlbum(id: String) async throws -> AstryxAlbum? {
        let albums = try await fetchAlbums()
        return albums.first { $0.id == id }
    }
    
    public func fetchAlbums(forArtist artist: String) async throws -> [AstryxAlbum] {
        let all = try await fetchAlbums()
        return all.filter { $0.artist == artist || $0.albumArtist == artist }
    }
    
    // MARK: Artists
    
    public func fetchArtists() async throws -> [AstryxArtist] {
        let allTracks = try await fetchTracks(predicate: nil)
        let grouped = Dictionary(grouping: allTracks) { $0.artist }
        return grouped.map { (artistName, tracks) in
            let albums = Set(tracks.map { $0.album }).count
            return AstryxArtist(name: artistName, albumCount: albums, trackCount: tracks.count)
        }.sorted { $0.name < $1.name }
    }
    
    public func fetchArtist(id: String) async throws -> AstryxArtist? {
        let artists = try await fetchArtists()
        return artists.first { $0.id == id }
    }
    
    // MARK: Genres
    
    public func fetchGenres() async throws -> [AstryxGenre] {
        let allTracks = try await fetchTracks(predicate: nil)
        let grouped = Dictionary(grouping: allTracks) { $0.genre ?? "Unknown" }
        return grouped.map { (genreName, tracks) in
            let albums = Set(tracks.map { $0.album }).count
            return AstryxGenre(name: genreName, trackCount: tracks.count, albumCount: albums)
        }.sorted { $0.name < $1.name }
    }
    
    // MARK: Folders
    
    public func fetchFolders(forLibrary libraryID: String) async throws -> [AstryxFolder] {
        let allTracks = try await fetchTracks(predicate: nil)
        let grouped = Dictionary(grouping: allTracks) { $0.folderPath ?? "Unknown" }
        return grouped.map { (folderPath, tracks) in
            let name = URL(fileURLWithPath: folderPath).lastPathComponent
            return AstryxFolder(name: name, path: folderPath, trackCount: tracks.count, folderCount: 0, libraryID: libraryID)
        }
    }
    
    public func fetchFolder(path: String) async throws -> AstryxFolder? {
        let folders = try await fetchFolders(forLibrary: "")
        return folders.first { $0.path == path }
    }
    
    // MARK: Libraries
    
    public func fetchLibraries() async throws -> [AstryxLibrary] {
        lock.lock()
        defer { lock.unlock() }
        return Array(libraries.values)
    }
    
    public func fetchLibrary(id: String) async throws -> AstryxLibrary? {
        lock.lock()
        defer { lock.unlock() }
        return libraries[id]
    }
    
    public func insertLibrary(_ library: AstryxLibrary) async throws {
        lock.lock()
        libraries[library.id] = library
        lock.unlock()
    }
    
    public func updateLibrary(_ library: AstryxLibrary) async throws {
        try await insertLibrary(library)
    }
    
    public func deleteLibrary(id: String) async throws {
        lock.lock()
        libraries.removeValue(forKey: id)
        lock.unlock()
    }
    
    // MARK: Playlists
    
    public func fetchPlaylists() async throws -> [AstryxPlaylist] {
        lock.lock()
        defer { lock.unlock() }
        return playlists.values.sorted { $0.dateModified > $1.dateModified }
    }

    public func insertPlaylist(_ playlist: AstryxPlaylist) async throws {
        lock.lock()
        playlists[playlist.id] = playlist
        lock.unlock()
    }

    public func updatePlaylist(_ playlist: AstryxPlaylist) async throws {
        lock.lock()
        playlists[playlist.id] = playlist
        lock.unlock()
    }

    public func deletePlaylist(id: String) async throws {
        lock.lock()
        playlists.removeValue(forKey: id)
        lock.unlock()
    }
    
    // MARK: Special Queries
    
    public func fetchRecentlyAdded(limit: Int) async throws -> [AstryxTrack] {
        let all = try await fetchTracks(predicate: nil)
        return Array(all.sorted { $0.dateAdded > $1.dateAdded }.prefix(limit))
    }
    
    public func fetchFavorites() async throws -> [AstryxTrack] {
        try await fetchTracks(predicate: TrackPredicate(isFavorite: true))
    }
    
    public func fetchHistory(limit: Int) async throws -> [AstryxTrack] {
        let all = try await fetchTracks(predicate: nil)
        return Array(all.filter { $0.lastPlayed != nil }.sorted { ($0.lastPlayed ?? .distantPast) > ($1.lastPlayed ?? .distantPast) }.prefix(limit))
    }
    
    public func fetchMostPlayed(limit: Int) async throws -> [AstryxTrack] {
        let all = try await fetchTracks(predicate: nil)
        return Array(all.sorted { $0.playCount > $1.playCount }.prefix(limit))
    }
    
    // MARK: Stats
    
    public func totalTrackCount() async throws -> Int {
        lock.lock()
        defer { lock.unlock() }
        return tracks.count
    }
    
    public func totalDuration() async throws -> TimeInterval {
        lock.lock()
        defer { lock.unlock() }
        return tracks.values.reduce(0) { $0 + $1.duration }
    }
    
    public func totalSize() async throws -> Int64 {
        lock.lock()
        defer { lock.unlock() }
        return tracks.values.reduce(0) { $0 + $1.fileSize }
    }
}

// MARK: - Production implementation
//
// This type is the *test/preview* store only. The persistent store lives in
// `Platform/Persistence/SwiftDataAdapter.swift` and is injected by the
// composition root (see `App/Composition/AppDependencies.swift`).
//
// There is deliberately no `SwiftData` fallback here: a platform that cannot
// persist must fail loudly in the composition root rather than quietly run on
// an in-memory store and lose the user's library on relaunch (BUG-01).
