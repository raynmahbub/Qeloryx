// QELORYX — Models/Library
// LibraryItem.swift

import Foundation

public struct AstryxFolder: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public var name: String
    public var path: String
    public var parentPath: String?
    public var trackCount: Int
    public var folderCount: Int
    public var libraryID: String
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        path: String,
        parentPath: String? = nil,
        trackCount: Int = 0,
        folderCount: Int = 0,
        libraryID: String
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.parentPath = parentPath
        self.trackCount = trackCount
        self.folderCount = folderCount
        self.libraryID = libraryID
    }
}

// MARK: - Genre Grouping

// MARK: - Library item

/// A unified reference to anything the library can hold. Views use this to
/// render mixed content (search results, smart-playlist feeds) without a
/// parallel type per entity.
public enum AstryxLibraryItem: Sendable, Equatable, Hashable {
    case track(AstryxTrack)
    case album(AstryxAlbum)
    case artist(AstryxArtist)
    case genre(AstryxGenre)
    case playlist(AstryxPlaylist)
    case folder(AstryxFolder)
}
