// QELORYX — Tests
// SearchEngineTests.swift

import XCTest
@testable import QeloryxCore

final class SearchEngineTests: XCTestCase {
    
    var indexedSearch: AstryxIndexedSearch!
    
    override func setUp() {
        super.setUp()
        indexedSearch = AstryxIndexedSearch()
    }
    
    func testBuildIndexAndSearch() async {
        let tracks = [
            AstryxTrack(title: "Bohemian Rhapsody", artist: "Queen", album: "A Night at the Opera", duration: 354, fileURL: URL(fileURLWithPath: "/tmp/1.mp3"), fileFormat: .mp3),
            AstryxTrack(title: "Stairway to Heaven", artist: "Led Zeppelin", album: "Led Zeppelin IV", duration: 482, fileURL: URL(fileURLWithPath: "/tmp/2.mp3"), fileFormat: .mp3),
            AstryxTrack(title: "Hotel California", artist: "Eagles", album: "Hotel California", duration: 391, fileURL: URL(fileURLWithPath: "/tmp/3.mp3"), fileFormat: .mp3)
        ]
        
        await indexedSearch.buildIndex(tracks: tracks, albums: [], artists: [], playlists: [])
        
        let results = await indexedSearch.search(query: SearchQuery(text: "Queen"))
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Bohemian Rhapsody")
    }
    
    func testPrefixSearch() async {
        let tracks = [
            AstryxTrack(title: "Hello", artist: "Adele", album: "25", duration: 200, fileURL: URL(fileURLWithPath: "/tmp/1.mp3"), fileFormat: .mp3)
        ]
        
        await indexedSearch.buildIndex(tracks: tracks, albums: [], artists: [], playlists: [])
        
        let results = await indexedSearch.search(query: SearchQuery(text: "Hel"))
        XCTAssertEqual(results.count, 1)
    }
    
    func testInstantSearchPerformance() async {
        // Generate 1000 tracks
        var tracks: [AstryxTrack] = []
        for i in 0..<1000 {
            tracks.append(AstryxTrack(title: "Track \(i)", artist: "Artist \(i % 100)", album: "Album \(i % 50)", duration: 180, fileURL: URL(fileURLWithPath: "/tmp/\(i).mp3"), fileFormat: .mp3))
        }
        
        await indexedSearch.buildIndex(tracks: tracks, albums: [], artists: [], playlists: [])
        
        let start = Date()
        let results = await indexedSearch.search(query: SearchQuery(text: "Track 500"))
        let elapsed = Date().timeIntervalSince(start) * 1000
        
        XCTAssertFalse(results.isEmpty)
        XCTAssertLessThan(elapsed, 50, "Search should be <50ms, was \(elapsed)ms")
    }
}
