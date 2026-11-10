// QELORYX — Models/Music
// Genre.swift

import Foundation

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
