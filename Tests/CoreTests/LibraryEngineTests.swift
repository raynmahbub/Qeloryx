// QELORYX — Tests
// LibraryEngineTests.swift

import XCTest
@testable import QeloryxCore

final class LibraryEngineTests: XCTestCase {
    
    var storage: InMemorySwiftDataStack!
    var libraryEngine: AstryxLibraryEngine!
    
    override func setUp() {
        super.setUp()
        storage = InMemorySwiftDataStack()
        libraryEngine = AstryxLibraryEngine(storage: storage)
    }
    
    func testInsertAndFetchTracks() async throws {
        let track = AstryxTrack(
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180,
            fileURL: URL(fileURLWithPath: "/tmp/test.mp3"),
            fileFormat: .mp3
        )
        
        try await storage.insertTrack(track)
        
        let all = try await libraryEngine.fetchAllTracks()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.title, "Test Song")
    }
    
    func testSearchTracks() async throws {
        let tracks = [
            AstryxTrack(title: "Hello", artist: "Adele", album: "25", duration: 200, fileURL: URL(fileURLWithPath: "/tmp/1.mp3"), fileFormat: .mp3),
            AstryxTrack(title: "Rolling in the Deep", artist: "Adele", album: "21", duration: 200, fileURL: URL(fileURLWithPath: "/tmp/2.mp3"), fileFormat: .mp3),
            AstryxTrack(title: "Shape of You", artist: "Ed Sheeran", album: "Divide", duration: 200, fileURL: URL(fileURLWithPath: "/tmp/3.mp3"), fileFormat: .mp3)
        ]
        
        try await storage.insertTracks(tracks)
        
        let adeleTracks = try await libraryEngine.searchTracks(query: "Adele")
        XCTAssertEqual(adeleTracks.count, 2)
        
        let helloTracks = try await libraryEngine.searchTracks(query: "Hello")
        XCTAssertEqual(helloTracks.count, 1)
    }
    
    func testToggleFavorite() async throws {
        let track = AstryxTrack(
            title: "Fav Song",
            artist: "Artist",
            album: "Album",
            duration: 180,
            fileURL: URL(fileURLWithPath: "/tmp/fav.mp3"),
            fileFormat: .mp3,
            isFavorite: false
        )
        
        try await storage.insertTrack(track)
        
        try await libraryEngine.toggleFavorite(trackID: track.id)
        
        let updated = try await libraryEngine.fetchTrack(id: track.id)
        XCTAssertEqual(updated?.isFavorite, true)
    }
    
    func testDuplicateDetection() async throws {
        let indexer = AstryxLibraryIndexer()
        
        let track1 = AstryxTrack(title: "Same Song", artist: "Same Artist", album: "Album", duration: 180, fileURL: URL(fileURLWithPath: "/tmp/1.mp3"), fileFormat: .mp3, checksum: "abc123")
        let track2 = AstryxTrack(title: "Same Song", artist: "Same Artist", album: "Album", duration: 180, fileURL: URL(fileURLWithPath: "/tmp/2.mp3"), fileFormat: .mp3, checksum: "abc123")
        let track3 = AstryxTrack(title: "Different", artist: "Artist", album: "Album", duration: 200, fileURL: URL(fileURLWithPath: "/tmp/3.mp3"), fileFormat: .mp3, checksum: "xyz")
        
        let duplicates = indexer.detectDuplicates(in: [track1, track2, track3])
        
        XCTAssertEqual(duplicates.count, 1)
        XCTAssertEqual(duplicates.first?.count, 2)
    }
}
