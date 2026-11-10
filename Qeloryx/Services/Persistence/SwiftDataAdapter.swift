// QELORYX — Services/Persistence
// SwiftDataAdapter.swift
//
// The production library store.
//
// Fixes relative to the previous implementation:
//   • BUG-01  A real persistent store, wired by the composition root. This file
//             no longer degrades into `typealias SwiftDataAdapter = InMemory…`
//             on non-SwiftData platforms: the type simply does not compile
//             there, which is correct — a platform that cannot persist must not
//             silently discard the user's library.
//   • BUG-01  Schema is versioned (`QeloryxSchemaV1`) with a migration plan, so
//             the first shipped database can evolve without data loss.
//   •          Missing fields (artwork, lyrics, bit depth, ISRC-style identifiers,
//             library ownership) are now persisted instead of dropped on save.
//   •          `ModelContext` is guarded by an actor: SwiftData contexts are not
//             thread-safe and every access here is `await`-serialised.

#if canImport(QeloryxCore)
import QeloryxCore
#endif

import Foundation

#if canImport(SwiftData)
import SwiftData

// MARK: - Schema V1

enum QeloryxSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [TrackModel.self, LibraryModel.self, PlaylistModel.self]
    }
}

/// Migration plan placeholder. There is only one schema version today; when V2
/// lands, add it here with a lightweight or custom stage rather than deleting
/// the store (the previous code had no versioning at all).
enum QeloryxMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [QeloryxSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

// MARK: - TrackModel

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
    var bitRate: Int?
    var sampleRate: Int?
    var bitDepth: Int?
    var isLossless: Bool
    var artworkData: Data?
    var lyrics: String?
    var dateAdded: Date
    var dateModified: Date
    var playCount: Int
    var lastPlayed: Date?
    var isFavorite: Bool
    var folderPath: String?
    var checksum: String?
    var libraryID: String?

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
        bitRate: Int? = nil,
        sampleRate: Int? = nil,
        bitDepth: Int? = nil,
        isLossless: Bool = false,
        artworkData: Data? = nil,
        lyrics: String? = nil,
        dateAdded: Date = Date(),
        dateModified: Date = Date(),
        playCount: Int = 0,
        lastPlayed: Date? = nil,
        isFavorite: Bool = false,
        folderPath: String? = nil,
        checksum: String? = nil,
        libraryID: String? = nil
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
        self.bitRate = bitRate
        self.sampleRate = sampleRate
        self.bitDepth = bitDepth
        self.isLossless = isLossless
        self.artworkData = artworkData
        self.lyrics = lyrics
        self.dateAdded = dateAdded
        self.dateModified = dateModified
        self.playCount = playCount
        self.lastPlayed = lastPlayed
        self.isFavorite = isFavorite
        self.folderPath = folderPath
        self.checksum = checksum
        self.libraryID = libraryID
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
            bitRate: bitRate,
            sampleRate: sampleRate,
            bitDepth: bitDepth,
            isLossless: isLossless,
            artworkData: artworkData,
            dateAdded: dateAdded,
            dateModified: dateModified,
            playCount: playCount,
            lastPlayed: lastPlayed,
            isFavorite: isFavorite,
            lyrics: lyrics,
            folderPath: folderPath,
            checksum: checksum,
            libraryID: libraryID
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
            bitRate: track.bitRate,
            sampleRate: track.sampleRate,
            bitDepth: track.bitDepth,
            isLossless: track.isLossless,
            artworkData: track.artworkData,
            lyrics: track.lyrics,
            dateAdded: track.dateAdded,
            dateModified: track.dateModified,
            playCount: track.playCount,
            lastPlayed: track.lastPlayed,
            isFavorite: track.isFavorite,
            folderPath: track.folderPath,
            checksum: track.checksum,
            libraryID: libraryID ?? track.libraryID
        )
    }

    func apply(_ track: AstryxTrack) {
        title = track.title
        artist = track.artist
        album = track.album
        albumArtist = track.albumArtist
        genre = track.genre
        year = track.year
        trackNumber = track.trackNumber
        discNumber = track.discNumber
        duration = track.duration
        fileURLString = track.fileURL.path
        fileFormatRaw = track.fileFormat.rawValue
        fileSize = track.fileSize
        bitRate = track.bitRate
        sampleRate = track.sampleRate
        bitDepth = track.bitDepth
        isLossless = track.isLossless
        artworkData = track.artworkData
        lyrics = track.lyrics
        dateModified = track.dateModified
        playCount = track.playCount
        lastPlayed = track.lastPlayed
        isFavorite = track.isFavorite
        folderPath = track.folderPath
        checksum = track.checksum
        if let libraryID = track.libraryID { self.libraryID = libraryID }
    }
}

// MARK: - LibraryModel

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

    init(
        id: String,
        name: String,
        rootURLString: String,
        typeRaw: String,
        isEnabled: Bool,
        trackCount: Int,
        lastIndexed: Date?,
        createdAt: Date
    ) {
        self.id = id
        self.name = name
        self.rootURLString = rootURLString
        self.typeRaw = typeRaw
        self.isEnabled = isEnabled
        self.trackCount = trackCount
        self.lastIndexed = lastIndexed
        self.createdAt = createdAt
    }

    func toDomain() -> AstryxLibrary {
        AstryxLibrary(
            id: id,
            name: name,
            rootURL: URL(fileURLWithPath: rootURLString),
            type: LibraryType(rawValue: typeRaw) ?? .local,
            isEnabled: isEnabled,
            trackCount: trackCount,
            lastIndexed: lastIndexed,
            createdAt: createdAt
        )
    }
}

// MARK: - PlaylistModel

@Model
final class PlaylistModel {
    @Attribute(.unique) var id: String
    var name: String
    var playlistDescription: String?
    var trackIDs: [String]
    var isSmart: Bool
    var dateCreated: Date
    var dateModified: Date

    init(
        id: String,
        name: String,
        playlistDescription: String? = nil,
        trackIDs: [String] = [],
        isSmart: Bool = false,
        dateCreated: Date = Date(),
        dateModified: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.playlistDescription = playlistDescription
        self.trackIDs = trackIDs
        self.isSmart = isSmart
        self.dateCreated = dateCreated
        self.dateModified = dateModified
    }

    func toDomain() -> AstryxPlaylist {
        AstryxPlaylist(
            id: id,
            name: name,
            description: playlistDescription,
            trackIDs: trackIDs,
            dateCreated: dateCreated,
            dateModified: dateModified,
            isSmart: isSmart
        )
    }

    static func fromDomain(_ playlist: AstryxPlaylist) -> PlaylistModel {
        PlaylistModel(
            id: playlist.id,
            name: playlist.name,
            playlistDescription: playlist.description,
            trackIDs: playlist.trackIDs,
            isSmart: playlist.isSmart,
            dateCreated: playlist.dateCreated,
            dateModified: playlist.dateModified
        )
    }
}

// MARK: - SwiftDataAdapter

/// Persistent implementation of `SwiftDataStackProtocol`.
///
/// Isolation: the class is an `actor`, so every `ModelContext` access is
/// serialised. `SwiftDataStackProtocol` is `Sendable`; the actor satisfies that
/// and the protocol requirements are fulfilled by `async` methods.
public actor SwiftDataAdapter: SwiftDataStackProtocol {

    private let container: ModelContainer
    private let context: ModelContext
    private let persistent: Bool

    /// An in-memory adapter is not persistent; the app always uses disk.
    ///
    /// `nonisolated` because `SwiftDataStackProtocol` declares the getter as a
    /// plain, non-async requirement, which an actor can only satisfy by
    /// reading state that needs no isolation hop. `persistent` is an immutable
    /// `let` assigned in `init`, so that read is safe from any thread.
    public nonisolated var isPersistent: Bool { persistent }

    /// - Parameter inMemory: tests pass `true`; the app always uses `false`.
    public init(inMemory: Bool = false) throws {
        self.persistent = !inMemory
        // Built from the versioned schema's model list so the container and the
        // migration plan stay in sync.
        let schema = Schema(QeloryxSchemaV1.models)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        container = try ModelContainer(
            for: schema,
            migrationPlan: QeloryxMigrationPlan.self,
            configurations: [configuration]
        )
        context = ModelContext(container)
        context.autosaveEnabled = true
    }

    // MARK: Tracks

    public func fetchTracks(predicate: TrackPredicate?) async throws -> [AstryxTrack] {
        let models = try context.fetch(FetchDescriptor<TrackModel>(sortBy: [SortDescriptor(\.title)]))
        return models.map { $0.toDomain() }.filter { matches($0, predicate) }
    }

    private func matches(_ track: AstryxTrack, _ predicate: TrackPredicate?) -> Bool {
        guard let predicate else { return true }
        if let search = predicate.searchText?.lowercased(), !search.isEmpty {
            let haystack = "\(track.title) \(track.artist) \(track.album)".lowercased()
            if !haystack.contains(search) { return false }
        }
        if let artist = predicate.artist, track.artist != artist { return false }
        if let album = predicate.album, track.album != album { return false }
        if let genre = predicate.genre, track.genre != genre { return false }
        if let favorite = predicate.isFavorite, track.isFavorite != favorite { return false }
        if let folder = predicate.folderPath, track.folderPath != folder { return false }
        if let libraryID = predicate.libraryID, track.libraryID != libraryID { return false }
        if let lossless = predicate.isLossless, track.isLossless != lossless { return false }
        return true
    }

    public func fetchTrack(id: String) async throws -> AstryxTrack? {
        try model(id: id)?.toDomain()
    }

    public func fetchTracks(forAlbum album: String, artist: String?) async throws -> [AstryxTrack] {
        // Sorting relies only on stored properties: `#Predicate` cannot call
        // free functions, so album matching is exact and case-sensitive here
        // and fuzzy matching is the search layer's job.
        let descriptor = FetchDescriptor<TrackModel>(sortBy: [SortDescriptor(\.trackNumber)])
        return try context.fetch(descriptor)
            .filter { $0.album == album && (artist == nil || $0.artist == artist) }
            .map { $0.toDomain() }
    }

    public func fetchTracks(forArtist artist: String) async throws -> [AstryxTrack] {
        let descriptor = FetchDescriptor<TrackModel>(
            predicate: #Predicate { $0.artist == artist },
            sortBy: [SortDescriptor(\.album), SortDescriptor(\.trackNumber)]
        )
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    public func fetchTracks(forGenre genre: String) async throws -> [AstryxTrack] {
        let descriptor = FetchDescriptor<TrackModel>(predicate: #Predicate { $0.genre == genre })
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    public func fetchTracks(inFolder folderPath: String) async throws -> [AstryxTrack] {
        let descriptor = FetchDescriptor<TrackModel>(predicate: #Predicate { $0.folderPath == folderPath })
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    public func fetchTracks(forLibrary libraryID: String) async throws -> [AstryxTrack] {
        let descriptor = FetchDescriptor<TrackModel>(predicate: #Predicate { $0.libraryID == libraryID })
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    public func insertTrack(_ track: AstryxTrack) async throws {
        context.insert(TrackModel.fromDomain(track))
        try context.save()
    }

    public func insertTracks(_ tracks: [AstryxTrack]) async throws {
        for track in tracks {
            // Upsert semantics: re-indexing a known file must update it, not
            // duplicate it.
            if let existing = try model(id: track.id) {
                existing.apply(track)
            } else {
                context.insert(TrackModel.fromDomain(track))
            }
        }
        try context.save()
    }

    public func updateTrack(_ track: AstryxTrack) async throws {
        guard let existing = try model(id: track.id) else {
            context.insert(TrackModel.fromDomain(track))
            try context.save()
            return
        }
        existing.apply(track)
        try context.save()
    }

    public func deleteTrack(id: String) async throws {
        guard let existing = try model(id: id) else { return }
        context.delete(existing)
        try context.save()
    }

    public func deleteTracks(forLibrary libraryID: String) async throws {
        let descriptor = FetchDescriptor<TrackModel>(predicate: #Predicate { $0.libraryID == libraryID })
        for model in try context.fetch(descriptor) {
            context.delete(model)
        }
        try context.save()
    }

    // MARK: Albums / Artists / Genres

    public func fetchAlbums() async throws -> [AstryxAlbum] {
        let tracks = try await fetchTracks(predicate: nil)
        return AstryxGrouping.albums(from: tracks)
    }

    public func fetchAlbum(id: String) async throws -> AstryxAlbum? {
        let albums = try await fetchAlbums()
        return albums.first { $0.id == id }
    }

    public func fetchAlbums(forArtist artist: String) async throws -> [AstryxAlbum] {
        let tracks = try await fetchTracks(forArtist: artist)
        return AstryxGrouping.albums(from: tracks)
    }

    public func fetchArtists() async throws -> [AstryxArtist] {
        let tracks = try await fetchTracks(predicate: nil)
        return AstryxGrouping.artists(from: tracks)
    }

    public func fetchArtist(id: String) async throws -> AstryxArtist? {
        let artists = try await fetchArtists()
        return artists.first { $0.id == id }
    }

    public func fetchGenres() async throws -> [AstryxGenre] {
        let tracks = try await fetchTracks(predicate: nil)
        return AstryxGrouping.genres(from: tracks)
    }

    // MARK: Folders

    public func fetchFolders(forLibrary libraryID: String) async throws -> [AstryxFolder] {
        let tracks = try await fetchTracks(forLibrary: libraryID)
        return Dictionary(grouping: tracks) { $0.folderPath ?? "Unknown" }
            .map { path, tracks in
                AstryxFolder(
                    name: URL(fileURLWithPath: path).lastPathComponent,
                    path: path,
                    trackCount: tracks.count,
                    libraryID: libraryID
                )
            }
            .sorted { $0.name < $1.name }
    }

    public func fetchFolder(path: String) async throws -> AstryxFolder? {
        let tracks = try await fetchTracks(inFolder: path)
        guard let first = tracks.first else { return nil }
        return AstryxFolder(
            name: URL(fileURLWithPath: path).lastPathComponent,
            path: path,
            trackCount: tracks.count,
            libraryID: first.libraryID ?? ""
        )
    }

    // MARK: Libraries

    public func fetchLibraries() async throws -> [AstryxLibrary] {
        try context.fetch(FetchDescriptor<LibraryModel>()).map { $0.toDomain() }
    }

    public func fetchLibrary(id: String) async throws -> AstryxLibrary? {
        let libraryID = id
        let descriptor = FetchDescriptor<LibraryModel>(predicate: #Predicate { $0.id == libraryID })
        return try context.fetch(descriptor).first?.toDomain()
    }

    public func insertLibrary(_ library: AstryxLibrary) async throws {
        context.insert(
            LibraryModel(
                id: library.id,
                name: library.name,
                rootURLString: library.rootURL.path,
                typeRaw: library.type.rawValue,
                isEnabled: library.isEnabled,
                trackCount: library.trackCount,
                lastIndexed: library.lastIndexed,
                createdAt: library.createdAt
            )
        )
        try context.save()
    }

    public func updateLibrary(_ library: AstryxLibrary) async throws {
        let libraryID = library.id
        let descriptor = FetchDescriptor<LibraryModel>(predicate: #Predicate { $0.id == libraryID })
        guard let existing = try context.fetch(descriptor).first else {
            try await insertLibrary(library)
            return
        }
        existing.name = library.name
        existing.isEnabled = library.isEnabled
        existing.trackCount = library.trackCount
        existing.lastIndexed = library.lastIndexed
        try context.save()
    }

    public func deleteLibrary(id: String) async throws {
        let libraryID = id
        let descriptor = FetchDescriptor<LibraryModel>(predicate: #Predicate { $0.id == libraryID })
        for model in try context.fetch(descriptor) {
            context.delete(model)
        }
        try context.save()
    }

    // MARK: Playlists

    public func fetchPlaylists() async throws -> [AstryxPlaylist] {
        try context.fetch(FetchDescriptor<PlaylistModel>(sortBy: [SortDescriptor(\.dateModified, order: .reverse)]))
            .map { $0.toDomain() }
    }

    public func insertPlaylist(_ playlist: AstryxPlaylist) async throws {
        context.insert(PlaylistModel.fromDomain(playlist))
        try context.save()
    }

    public func updatePlaylist(_ playlist: AstryxPlaylist) async throws {
        let playlistID = playlist.id
        let descriptor = FetchDescriptor<PlaylistModel>(predicate: #Predicate { $0.id == playlistID })
        guard let existing = try context.fetch(descriptor).first else {
            try await insertPlaylist(playlist)
            return
        }
        existing.name = playlist.name
        existing.playlistDescription = playlist.description
        existing.trackIDs = playlist.trackIDs
        existing.isSmart = playlist.isSmart
        existing.dateModified = playlist.dateModified
        try context.save()
    }

    public func deletePlaylist(id: String) async throws {
        let playlistID = id
        let descriptor = FetchDescriptor<PlaylistModel>(predicate: #Predicate { $0.id == playlistID })
        for model in try context.fetch(descriptor) {
            context.delete(model)
        }
        try context.save()
    }

    // MARK: Special queries

    public func fetchRecentlyAdded(limit: Int) async throws -> [AstryxTrack] {
        let descriptor = FetchDescriptor<TrackModel>(sortBy: [SortDescriptor(\.dateAdded, order: .reverse)])
        return try context.fetch(descriptor).prefix(limit).map { $0.toDomain() }
    }

    public func fetchFavorites() async throws -> [AstryxTrack] {
        let descriptor = FetchDescriptor<TrackModel>(predicate: #Predicate { $0.isFavorite == true })
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    public func fetchHistory(limit: Int) async throws -> [AstryxTrack] {
        let descriptor = FetchDescriptor<TrackModel>(sortBy: [SortDescriptor(\.lastPlayed, order: .reverse)])
        return try context.fetch(descriptor).filter { $0.lastPlayed != nil }.prefix(limit).map { $0.toDomain() }
    }

    public func fetchMostPlayed(limit: Int) async throws -> [AstryxTrack] {
        let descriptor = FetchDescriptor<TrackModel>(sortBy: [SortDescriptor(\.playCount, order: .reverse)])
        return try context.fetch(descriptor).prefix(limit).map { $0.toDomain() }
    }

    // MARK: Stats

    public func totalTrackCount() async throws -> Int {
        try context.fetchCount(FetchDescriptor<TrackModel>())
    }

    public func totalDuration() async throws -> TimeInterval {
        try context.fetch(FetchDescriptor<TrackModel>()).reduce(0) { $0 + $1.duration }
    }

    public func totalSize() async throws -> Int64 {
        try context.fetch(FetchDescriptor<TrackModel>()).reduce(0) { $0 + $1.fileSize }
    }

    // MARK: Private

    private func model(id: String) throws -> TrackModel? {
        let trackID = id
        var descriptor = FetchDescriptor<TrackModel>(predicate: #Predicate { $0.id == trackID })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

// MARK: - Grouping

/// Shared album/artist/genre aggregation so the in-memory store and the
/// persistent store cannot drift apart (they previously had separate copies).
public enum AstryxGrouping {

    public static func albums(from tracks: [AstryxTrack]) -> [AstryxAlbum] {
        let grouped = Dictionary(grouping: tracks) { "\($0.album)\u{1F}\($0.albumArtist ?? $0.artist)" }
        return grouped.map { key, tracks in
            let parts = key.components(separatedBy: "\u{1F}")
            let title = parts.first ?? "Unknown Album"
            let artist = parts.count > 1 ? parts[1] : "Unknown Artist"
            return AstryxAlbum(
                id: stableID("album", title, artist),
                title: title,
                artist: artist,
                albumArtist: tracks.first?.albumArtist,
                year: tracks.first?.year,
                genre: tracks.first?.genre,
                trackCount: tracks.count,
                duration: tracks.reduce(0) { $0 + $1.duration },
                artworkURL: tracks.first?.artworkURL,
                tracks: tracks.sorted {
                    let left = ($0.discNumber ?? 0) * 1000 + ($0.trackNumber ?? 0)
                    let right = ($1.discNumber ?? 0) * 1000 + ($1.trackNumber ?? 0)
                    return left < right
                },
                dateAdded: tracks.map(\.dateAdded).min() ?? Date()
            )
        }
        .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    public static func artists(from tracks: [AstryxTrack]) -> [AstryxArtist] {
        Dictionary(grouping: tracks) { $0.artist }
            .map { name, tracks in
                AstryxArtist(
                    id: stableID("artist", name),
                    name: name,
                    albumCount: Set(tracks.map(\.album)).count,
                    trackCount: tracks.count,
                    artworkURL: tracks.first?.artworkURL,
                    dateAdded: tracks.map(\.dateAdded).min() ?? Date()
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    public static func genres(from tracks: [AstryxTrack]) -> [AstryxGenre] {
        Dictionary(grouping: tracks) { $0.genre ?? "Unknown" }
            .map { name, tracks in
                AstryxGenre(
                    id: stableID("genre", name),
                    name: name,
                    trackCount: tracks.count,
                    albumCount: Set(tracks.map(\.album)).count
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Deterministic identifier so album/artist rows keep a stable identity
    /// across launches. The previous implementation derived identity from a
    /// fresh `UUID()`, which broke navigation and diffing on every reload.
    static func stableID(_ kind: String, _ parts: String...) -> String {
        let joined = parts.joined(separator: "\u{1F}")
        var hash = UInt64(0xcbf2_9ce4_8422_2325)
        for byte in "\(kind)\u{1F}\(joined)".utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return "\(kind)-\(String(hash, radix: 16))"
    }
}

#else

// SwiftData is unavailable (Linux / non-Apple). There is intentionally no
// in-memory aliasing here: `AppDependencies` refuses to construct a persistent
// library on such a platform. See BUG-01 in Docs/BUG_REGISTER.md.

#endif
