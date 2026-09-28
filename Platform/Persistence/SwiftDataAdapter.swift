// QELORYX — Platform
// SwiftDataAdapter.swift
// QEL-024 Library — Production SwiftData with ModelContainer, ModelContext, relationships

#if canImport(QeloryxCore)
import QeloryxCore
#endif

import Foundation

#if canImport(SwiftData)
import SwiftData

// MARK: - SwiftData Models — QEL-024 Production

@Model
final class TrackModel {
    @Attribute(.unique) var id: String
    var title: String
    var artist: String
    var album: String
    var albumArtist: String?
    var genre: String?
    var year: Int?
    var trackNumber: Int?
    var discNumber: Int?
    var duration: TimeInterval
    var fileURLString: String
    var fileFormatRaw: String
    var fileSize: Int64
    var dateAdded: Date
    var dateModified: Date
    var playCount: Int
    var lastPlayed: Date?
    var isFavorite: Bool
    var folderPath: String?
    var checksum: String?
    var libraryID: String?
    var isLossless: Bool
    
    init(
        id: String,
        title: String,
        artist: String,
        album: String,
        albumArtist: String? = nil,
        genre: String? = nil,
        year: Int? = nil,
        trackNumber: Int? = nil,
        discNumber: Int? = nil,
        duration: TimeInterval,
        fileURLString: String,
        fileFormatRaw: String,
        fileSize: Int64 = 0,
        dateAdded: Date = Date(),
        dateModified: Date = Date(),
        playCount: Int = 0,
        lastPlayed: Date? = nil,
        isFavorite: Bool = false,
        folderPath: String? = nil,
        checksum: String? = nil,
        libraryID: String? = nil,
        isLossless: Bool = false
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.albumArtist = albumArtist
        self.genre = genre
        self.year = year
        self.trackNumber = trackNumber
        self.discNumber = discNumber
        self.duration = duration
        self.fileURLString = fileURLString
        self.fileFormatRaw = fileFormatRaw
        self.fileSize = fileSize
        self.dateAdded = dateAdded
        self.dateModified = dateModified
        self.playCount = playCount
        self.lastPlayed = lastPlayed
        self.isFavorite = isFavorite
        self.folderPath = folderPath
        self.checksum = checksum
        self.libraryID = libraryID
        self.isLossless = isLossless
    }
    
    func toDomain() -> AstryxTrack {
        AstryxTrack(
            id: id,
            title: title,
            artist: artist,
            album: album,
            albumArtist: albumArtist,
            genre: genre,
            year: year,
            trackNumber: trackNumber,
            discNumber: discNumber,
            duration: duration,
            fileURL: URL(fileURLWithPath: fileURLString),
            fileFormat: AudioFormat(rawValue: fileFormatRaw) ?? .unknown,
            fileSize: fileSize,
            isLossless: isLossless,
            dateAdded: dateAdded,
            dateModified: dateModified,
            playCount: playCount,
            lastPlayed: lastPlayed,
            isFavorite: isFavorite,
            folderPath: folderPath,
            checksum: checksum
        )
    }
    
    static func fromDomain(_ track: AstryxTrack, libraryID: String? = nil) -> TrackModel {
        TrackModel(
            id: track.id,
            title: track.title,
            artist: track.artist,
            album: track.album,
            albumArtist: track.albumArtist,
            genre: track.genre,
            year: track.year,
            trackNumber: track.trackNumber,
            discNumber: track.discNumber,
            duration: track.duration,
            fileURLString: track.fileURL.path,
            fileFormatRaw: track.fileFormat.rawValue,
            fileSize: track.fileSize,
            dateAdded: track.dateAdded,
            dateModified: track.dateModified,
            playCount: track.playCount,
            lastPlayed: track.lastPlayed,
            isFavorite: track.isFavorite,
            folderPath: track.folderPath,
            checksum: track.checksum,
            libraryID: libraryID,
            isLossless: track.isLossless
        )
    }
}

@Model
final class LibraryModel {
    @Attribute(.unique) var id: String
    var name: String
    var rootURLString: String
    var typeRaw: String
    var isEnabled: Bool
    var trackCount: Int
    var lastIndexed: Date?
    var createdAt: Date
    
    init(id: String, name: String, rootURLString: String, typeRaw: String, isEnabled: Bool, trackCount: Int, lastIndexed: Date?, createdAt: Date) {
        self.id = id
        self.name = name
        self.rootURLString = rootURLString
        self.typeRaw = typeRaw
        self.isEnabled = isEnabled
        self.trackCount = trackCount
        self.lastIndexed = lastIndexed
        self.createdAt = createdAt
    }
}

// MARK: - SwiftDataAdapter — Production

public final class SwiftDataAdapter: SwiftDataStackProtocol {
    
    private let container: ModelContainer
    private let context: ModelContext
    
    public init() throws {
        let schema = Schema([TrackModel.self, LibraryModel.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
        context.autosaveEnabled = true
    }
    
    // MARK: Tracks
    
    public func fetchTracks(predicate: TrackPredicate?) async throws -> [AstryxTrack] {
        let descriptor = FetchDescriptor<TrackModel>(sortBy: [SortDescriptor(\.title)])
        let models = try context.fetch(descriptor)
        var tracks = models.map { $0.toDomain() }
        
        if let p = predicate {
            if let search = p.searchText?.lowercased(), !search.isEmpty {
                tracks = tracks.filter {
                    $0.title.lowercased().contains(search) ||
                    $0.artist.lowercased().contains(search) ||
                    $0.album.lowercased().contains(search)
                }
            }
            if let artist = p.artist { tracks = tracks.filter { $0.artist == artist } }
            if let album = p.album { tracks = tracks.filter { $0.album == album } }
            if let genre = p.genre { tracks = tracks.filter { $0.genre == genre } }
            if let fav = p.isFavorite { tracks = tracks.filter { $0.isFavorite == fav } }
            if let folder = p.folderPath { tracks = tracks.filter { $0.folderPath == folder } }
            if let lossless = p.isLossless { tracks = tracks.filter { $0.isLossless == lossless } }
        }
        
        return tracks
    }
    
    public func fetchTrack(id: String) async throws -> AstryxTrack? {
        let predicate = #Predicate<TrackModel> { $0.id == id }
        let descriptor = FetchDescriptor<TrackModel>(predicate: predicate)
        let models = try context.fetch(descriptor)
        return models.first?.toDomain()
    }
    
    public func fetchTracks(forAlbum album: String, artist: String?) async throws -> [AstryxTrack] {
        let all = try await fetchTracks(predicate: nil)
        return all.filter { $0.album == album && (artist == nil || $0.artist == artist) }
    }
    
    public func fetchTracks(forArtist artist: String) async throws -> [AstryxTrack] {
        let all = try await fetchTracks(predicate: nil)
        return all.filter { $0.artist == artist }
    }
    
    public func fetchTracks(forGenre genre: String) async throws -> [AstryxTrack] {
        let all = try await fetchTracks(predicate: nil)
        return all.filter { $0.genre == genre }
    }
    
    public func fetchTracks(inFolder folderPath: String) async throws -> [AstryxTrack] {
        let all = try await fetchTracks(predicate: nil)
        return all.filter { $0.folderPath == folderPath }
    }
    
    public func fetchTracks(forLibrary libraryID: String) async throws -> [AstryxTrack] {
        let predicate = #Predicate<TrackModel> { $0.libraryID == libraryID }
        let descriptor = FetchDescriptor<TrackModel>(predicate: predicate)
        let models = try context.fetch(descriptor)
        return models.map { $0.toDomain() }
    }
    
    public func insertTrack(_ track: AstryxTrack) async throws {
        let model = TrackModel.fromDomain(track)
        context.insert(model)
        try context.save()
    }
    
    public func insertTracks(_ tracks: [AstryxTrack]) async throws {
        for track in tracks {
            let model = TrackModel.fromDomain(track)
            context.insert(model)
        }
        try context.save()
    }
    
    public func updateTrack(_ track: AstryxTrack) async throws {
        let trackID = track.id
        let predicate = #Predicate<TrackModel> { $0.id == trackID }
        let descriptor = FetchDescriptor<TrackModel>(predicate: predicate)
        let models = try context.fetch(descriptor)
        if let existing = models.first {
            existing.title = track.title
            existing.artist = track.artist
            existing.album = track.album
            existing.isFavorite = track.isFavorite
            existing.playCount = track.playCount
            existing.lastPlayed = track.lastPlayed
            try context.save()
        } else {
            try await insertTrack(track)
        }
    }
    
    public func deleteTrack(id: String) async throws {
        let predicate = #Predicate<TrackModel> { $0.id == id }
        try context.delete(model: TrackModel.self, where: predicate)
        try context.save()
    }
    
    public func deleteTracks(forLibrary libraryID: String) async throws {
        let predicate = #Predicate<TrackModel> { $0.libraryID == libraryID }
        try context.delete(model: TrackModel.self, where: predicate)
        try context.save()
    }
    
    // MARK: Albums
    
    public func fetchAlbums() async throws -> [AstryxAlbum] {
        let tracks = try await fetchTracks(predicate: nil)
        let grouped = Dictionary(grouping: tracks) { "\($0.album)|\($0.albumArtist ?? $0.artist)" }
        return grouped.map { (key, tracks) in
            let components = key.components(separatedBy: "|")
            let title = components.first ?? "Unknown"
            let artist = components.count > 1 ? components[1] : tracks.first?.artist ?? "Unknown"
            return AstryxAlbum(title: title, artist: artist, trackCount: tracks.count, duration: tracks.reduce(0) { $0 + $1.duration }, tracks: tracks)
        }
    }
    
    public func fetchAlbum(id: String) async throws -> AstryxAlbum? {
        let albums = try await fetchAlbums()
        return albums.first { $0.id == id }
    }
    
    public func fetchAlbums(forArtist artist: String) async throws -> [AstryxAlbum] {
        let all = try await fetchAlbums()
        return all.filter { $0.artist == artist }
    }
    
    // MARK: Artists
    
    public func fetchArtists() async throws -> [AstryxArtist] {
        let tracks = try await fetchTracks(predicate: nil)
        let grouped = Dictionary(grouping: tracks) { $0.artist }
        return grouped.map { (name, tracks) in
            AstryxArtist(name: name, albumCount: Set(tracks.map { $0.album }).count, trackCount: tracks.count)
        }
    }
    
    public func fetchArtist(id: String) async throws -> AstryxArtist? {
        let artists = try await fetchArtists()
        return artists.first { $0.id == id }
    }
    
    // MARK: Genres
    
    public func fetchGenres() async throws -> [AstryxGenre] {
        let tracks = try await fetchTracks(predicate: nil)
        let grouped = Dictionary(grouping: tracks) { $0.genre ?? "Unknown" }
        return grouped.map { (name, tracks) in
            AstryxGenre(name: name, trackCount: tracks.count, albumCount: Set(tracks.map { $0.album }).count)
        }
    }
    
    // MARK: Folders
    
    public func fetchFolders(forLibrary libraryID: String) async throws -> [AstryxFolder] {
        let tracks = try await fetchTracks(forLibrary: libraryID)
        let grouped = Dictionary(grouping: tracks) { $0.folderPath ?? "Unknown" }
        return grouped.map { (path, tracks) in
            AstryxFolder(name: URL(fileURLWithPath: path).lastPathComponent, path: path, trackCount: tracks.count, libraryID: libraryID)
        }
    }
    
    public func fetchFolder(path: String) async throws -> AstryxFolder? {
        let allTracks = try await fetchTracks(predicate: nil)
        let filtered = allTracks.filter { $0.folderPath == path }
        guard !filtered.isEmpty else { return nil }
        return AstryxFolder(name: URL(fileURLWithPath: path).lastPathComponent, path: path, trackCount: filtered.count, libraryID: "")
    }
    
    // MARK: Libraries
    
    public func fetchLibraries() async throws -> [AstryxLibrary] {
        let descriptor = FetchDescriptor<LibraryModel>()
        let models = try context.fetch(descriptor)
        return models.map { model in
            AstryxLibrary(
                id: model.id,
                name: model.name,
                rootURL: URL(fileURLWithPath: model.rootURLString),
                type: LibraryType(rawValue: model.typeRaw) ?? .local,
                isEnabled: model.isEnabled,
                trackCount: model.trackCount,
                lastIndexed: model.lastIndexed,
                createdAt: model.createdAt
            )
        }
    }
    
    public func fetchLibrary(id: String) async throws -> AstryxLibrary? {
        let predicate = #Predicate<LibraryModel> { $0.id == id }
        let descriptor = FetchDescriptor<LibraryModel>(predicate: predicate)
        let models = try context.fetch(descriptor)
        guard let model = models.first else { return nil }
        return AstryxLibrary(id: model.id, name: model.name, rootURL: URL(fileURLWithPath: model.rootURLString), type: LibraryType(rawValue: model.typeRaw) ?? .local, isEnabled: model.isEnabled, trackCount: model.trackCount, lastIndexed: model.lastIndexed, createdAt: model.createdAt)
    }
    
    public func insertLibrary(_ library: AstryxLibrary) async throws {
        let model = LibraryModel(id: library.id, name: library.name, rootURLString: library.rootURL.path, typeRaw: library.type.rawValue, isEnabled: library.isEnabled, trackCount: library.trackCount, lastIndexed: library.lastIndexed, createdAt: library.createdAt)
        context.insert(model)
        try context.save()
    }
    
    public func updateLibrary(_ library: AstryxLibrary) async throws {
        let libraryID = library.id
        let predicate = #Predicate<LibraryModel> { $0.id == libraryID }
        let descriptor = FetchDescriptor<LibraryModel>(predicate: predicate)
        let models = try context.fetch(descriptor)
        if let existing = models.first {
            existing.name = library.name
            existing.isEnabled = library.isEnabled
            existing.trackCount = library.trackCount
            existing.lastIndexed = library.lastIndexed
            try context.save()
        } else {
            try await insertLibrary(library)
        }
    }
    
    public func deleteLibrary(id: String) async throws {
        let predicate = #Predicate<LibraryModel> { $0.id == id }
        try context.delete(model: LibraryModel.self, where: predicate)
        try context.save()
    }
    
    // MARK: Playlists
    
    public func fetchPlaylists() async throws -> [AstryxPlaylist] { [] }
    
    // MARK: Special
    
    public func fetchRecentlyAdded(limit: Int) async throws -> [AstryxTrack] {
        let all = try await fetchTracks(predicate: nil)
        return Array(all.sorted { $0.dateAdded > $1.dateAdded }.prefix(limit))
    }
    
    public func fetchFavorites() async throws -> [AstryxTrack] {
        let predicate = #Predicate<TrackModel> { $0.isFavorite == true }
        let descriptor = FetchDescriptor<TrackModel>(predicate: predicate)
        let models = try context.fetch(descriptor)
        return models.map { $0.toDomain() }
    }
    
    public func fetchHistory(limit: Int) async throws -> [AstryxTrack] {
        let descriptor = FetchDescriptor<TrackModel>(sortBy: [SortDescriptor(\.lastPlayed, order: .reverse)])
        let models = try context.fetch(descriptor)
        let filtered = models.filter { $0.lastPlayed != nil }
        return Array(filtered.prefix(limit).map { $0.toDomain() })
    }
    
    public func fetchMostPlayed(limit: Int) async throws -> [AstryxTrack] {
        let descriptor = FetchDescriptor<TrackModel>(sortBy: [SortDescriptor(\.playCount, order: .reverse)])
        let models = try context.fetch(descriptor)
        return Array(models.prefix(limit).map { $0.toDomain() })
    }
    
    public func totalTrackCount() async throws -> Int {
        let descriptor = FetchDescriptor<TrackModel>()
        return try context.fetchCount(descriptor)
    }
    
    public func totalDuration() async throws -> TimeInterval {
        let tracks = try await fetchTracks(predicate: nil)
        return tracks.reduce(0) { $0 + $1.duration }
    }
    
    public func totalSize() async throws -> Int64 {
        let tracks = try await fetchTracks(predicate: nil)
        return tracks.reduce(0) { $0 + $1.fileSize }
    }
}

#else

// Fallback for Linux — uses InMemory
public typealias SwiftDataAdapter = InMemorySwiftDataStack

#endif
