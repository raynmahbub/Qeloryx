// QELORYX — Models/Library
// LibrarySnapshot.swift
// A library's persisted configuration plus point-in-time counts.

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

// MARK: - Library stats (moved from LibraryEngine.swift)

public struct LibraryStats: Sendable {
    public let trackCount: Int
    public let albumCount: Int
    public let artistCount: Int
    public let totalDuration: TimeInterval
    public let totalSize: Int64
    public let favoriteCount: Int
    
    public init(trackCount: Int, albumCount: Int, artistCount: Int, totalDuration: TimeInterval, totalSize: Int64, favoriteCount: Int) {
        self.trackCount = trackCount
        self.albumCount = albumCount
        self.artistCount = artistCount
        self.totalDuration = totalDuration
        self.totalSize = totalSize
        self.favoriteCount = favoriteCount
    }
}

// MARK: - Library snapshot

/// A serialisable, point-in-time summary of a library. Suitable for widgets,
/// diagnostics export and cache invalidation — no live file references.
public struct AstryxLibrarySnapshot: Sendable, Equatable, Codable {
    public let generatedAt: Date
    public let libraryID: String
    public let trackCount: Int
    public let albumCount: Int
    public let artistCount: Int
    public let totalDuration: TimeInterval
    public let totalSize: Int64

    public init(
        generatedAt: Date = Date(),
        libraryID: String,
        trackCount: Int = 0,
        albumCount: Int = 0,
        artistCount: Int = 0,
        totalDuration: TimeInterval = 0,
        totalSize: Int64 = 0
    ) {
        self.generatedAt = generatedAt
        self.libraryID = libraryID
        self.trackCount = trackCount
        self.albumCount = albumCount
        self.artistCount = artistCount
        self.totalDuration = totalDuration
        self.totalSize = totalSize
    }
}
