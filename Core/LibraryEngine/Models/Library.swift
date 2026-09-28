// QELORYX — LibraryEngine
// Library.swift
// QEL-024 Library DNA — Multi-library support

import Foundation

public enum LibraryType: String, Sendable, CaseIterable {
    case local = "Local"
    case external = "External"
    case nas = "NAS"
    case cloud = "Cloud"
    case webDAV = "WebDAV"
}

public struct AstryxLibrary: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public var name: String
    public var rootURL: URL
    public var type: LibraryType
    public var isEnabled: Bool
    public var trackCount: Int
    public var totalDuration: TimeInterval
    public var totalSize: Int64
    public var lastIndexed: Date?
    public var createdAt: Date
    public var isIndexing: Bool
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        rootURL: URL,
        type: LibraryType = .local,
        isEnabled: Bool = true,
        trackCount: Int = 0,
        totalDuration: TimeInterval = 0,
        totalSize: Int64 = 0,
        lastIndexed: Date? = nil,
        createdAt: Date = Date(),
        isIndexing: Bool = false
    ) {
        self.id = id
        self.name = name
        self.rootURL = rootURL
        self.type = type
        self.isEnabled = isEnabled
        self.trackCount = trackCount
        self.totalDuration = totalDuration
        self.totalSize = totalSize
        self.lastIndexed = lastIndexed
        self.createdAt = createdAt
        self.isIndexing = isIndexing
    }
    
    public var displayName: String {
        name.isEmpty ? rootURL.lastPathComponent : name
    }
    
    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    public var formattedDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Folder View

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

public struct AstryxGenre: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public var name: String
    public var trackCount: Int
    public var albumCount: Int
    public var artworkData: Data?
    
    public init(id: String = UUID().uuidString, name: String, trackCount: Int = 0, albumCount: Int = 0, artworkData: Data? = nil) {
        self.id = id
        self.name = name
        self.trackCount = trackCount
        self.albumCount = albumCount
        self.artworkData = artworkData
    }
}
