// QELORYX — Tests
// Discovery_Tests.swift
// QEL-051 Discovery — Taste DNA, recommendations, performance

import XCTest
@testable import QeloryxCore

final class DiscoveryTests: XCTestCase {
    
    var tasteEngine: AstryxTasteDNAEngine!
    
    override func setUp() {
        super.setUp()
        tasteEngine = AstryxTasteDNAEngine()
    }
    
    func testTasteProfileGeneration() async {
        let tracks = [
            AstryxTrack(title: "Song 1", artist: "Artist A", album: "Album X", genre: "Rock", year: 2020, duration: 180, fileURL: URL(fileURLWithPath: "/tmp/1.mp3"), fileFormat: .mp3, playCount: 10, isFavorite: true),
            AstryxTrack(title: "Song 2", artist: "Artist A", album: "Album X", genre: "Rock", year: 2021, duration: 200, fileURL: URL(fileURLWithPath: "/tmp/2.mp3"), fileFormat: .mp3, playCount: 5),
            AstryxTrack(title: "Song 3", artist: "Artist B", album: "Album Y", genre: "Jazz", year: 2019, duration: 210, fileURL: URL(fileURLWithPath: "/tmp/3.mp3"), fileFormat: .mp3, playCount: 3)
        ]
        
        let profile = await tasteEngine.generateProfile(from: tracks)
        
        XCTAssertFalse(profile.topGenres.isEmpty)
        XCTAssertEqual(profile.topGenres.first?.name, "Rock") // Rock has higher playCount
        XCTAssertFalse(profile.topArtists.isEmpty)
        XCTAssertEqual(profile.totalPlays, 18)
        XCTAssertEqual(profile.totalTracks, 3)
        XCTAssertEqual(profile.favoriteCount, 1)
        XCTAssertFalse(profile.mood.primary.isEmpty)
    }
    
    func testTopGenres() async {
        let tracks = [
            AstryxTrack(title: "1", artist: "A", album: "X", genre: "Rock", duration: 180, fileURL: URL(fileURLWithPath: "/tmp/1.mp3"), fileFormat: .mp3, playCount: 10),
            AstryxTrack(title: "2", artist: "B", album: "Y", genre: "Rock", duration: 180, fileURL: URL(fileURLWithPath: "/tmp/2.mp3"), fileFormat: .mp3, playCount: 5),
            AstryxTrack(title: "3", artist: "C", album: "Z", genre: "Jazz", duration: 180, fileURL: URL(fileURLWithPath: "/tmp/3.mp3"), fileFormat: .mp3, playCount: 2)
        ]
        
        let profile = await tasteEngine.generateProfile(from: tracks)
        
        XCTAssertEqual(profile.topGenres.count, 2)
        XCTAssertEqual(profile.topGenres[0].name, "Rock")
        XCTAssertEqual(profile.topGenres[0].playCount, 15)
        XCTAssertGreaterThan(profile.topGenres[0].percentage, 0.5)
    }
    
    func testTopArtists() async {
        let tracks = [
            AstryxTrack(title: "1", artist: "Artist A", album: "X", duration: 180, fileURL: URL(fileURLWithPath: "/tmp/1.mp3"), fileFormat: .mp3, playCount: 20),
            AstryxTrack(title: "2", artist: "Artist A", album: "X", duration: 180, fileURL: URL(fileURLWithPath: "/tmp/2.mp3"), fileFormat: .mp3, playCount: 10),
            AstryxTrack(title: "3", artist: "Artist B", album: "Y", duration: 180, fileURL: URL(fileURLWithPath: "/tmp/3.mp3"), fileFormat: .mp3, playCount: 5)
        ]
        
        let profile = await tasteEngine.generateProfile(from: tracks)
        
        XCTAssertEqual(profile.topArtists.first?.name, "Artist A")
        XCTAssertEqual(profile.topArtists.first?.playCount, 30)
        XCTAssertEqual(profile.topArtists.first?.trackCount, 2)
    }
    
    func testMood() {
        let rockTracks = [
            AstryxTrack(title: "1", artist: "A", album: "X", genre: "Rock", duration: 180, fileURL: URL(fileURLWithPath: "/tmp/1.mp3"), fileFormat: .mp3, playCount: 10)
        ]
        let mood = tasteEngine.mood(for: rockTracks)
        XCTAssertEqual(mood.primary, "Energetic")
        XCTAssertGreaterThan(mood.energy, 0.5)
        
        let jazzTracks = [
            AstryxTrack(title: "1", artist: "A", album: "X", genre: "Jazz", duration: 180, fileURL: URL(fileURLWithPath: "/tmp/1.mp3"), fileFormat: .mp3, playCount: 10)
        ]
        let jazzMood = tasteEngine.mood(for: jazzTracks)
        XCTAssertEqual(jazzMood.primary, "Chill")
    }
    
    func testDiversityScore() {
        // Low diversity: same artist/genre
        let lowDiverse = [
            AstryxTrack(title: "1", artist: "A", album: "X", genre: "Rock", duration: 180, fileURL: URL(fileURLWithPath: "/tmp/1.mp3"), fileFormat: .mp3),
            AstryxTrack(title: "2", artist: "A", album: "X", genre: "Rock", duration: 180, fileURL: URL(fileURLWithPath: "/tmp/2.mp3"), fileFormat: .mp3),
            AstryxTrack(title: "3", artist: "A", album: "X", genre: "Rock", duration: 180, fileURL: URL(fileURLWithPath: "/tmp/3.mp3"), fileFormat: .mp3)
        ]
        let lowScore = tasteEngine.diversityScore(for: lowDiverse)
        
        // High diversity: different artists/genres
        let highDiverse = [
            AstryxTrack(title: "1", artist: "A", album: "X", genre: "Rock", duration: 180, fileURL: URL(fileURLWithPath: "/tmp/1.mp3"), fileFormat: .mp3),
            AstryxTrack(title: "2", artist: "B", album: "Y", genre: "Jazz", duration: 180, fileURL: URL(fileURLWithPath: "/tmp/2.mp3"), fileFormat: .mp3),
            AstryxTrack(title: "3", artist: "C", album: "Z", genre: "Pop", duration: 180, fileURL: URL(fileURLWithPath: "/tmp/3.mp3"), fileFormat: .mp3),
            AstryxTrack(title: "4", artist: "D", album: "W", genre: "Electronic", duration: 180, fileURL: URL(fileURLWithPath: "/tmp/4.mp3"), fileFormat: .mp3)
        ]
        let highScore = tasteEngine.diversityScore(for: highDiverse)
        
        XCTAssertGreaterThan(highScore, lowScore)
        XCTAssertGreaterThanOrEqual(lowScore, 0)
        XCTAssertLessThanOrEqual(highScore, 1.0)
    }
    
    func testRecommendations() async {
        let tracks = [
            AstryxTrack(title: "Fav 1", artist: "Artist A", album: "X", genre: "Rock", duration: 180, fileURL: URL(fileURLWithPath: "/tmp/1.mp3"), fileFormat: .mp3, playCount: 10, isFavorite: true),
            AstryxTrack(title: "Fav 2", artist: "Artist B", album: "Y", genre: "Rock", duration: 180, fileURL: URL(fileURLWithPath: "/tmp/2.mp3"), fileFormat: .mp3, playCount: 8, isFavorite: true),
            AstryxTrack(title: "Not played", artist: "Artist C", album: "Z", genre: "Rock", duration: 180, fileURL: URL(fileURLWithPath: "/tmp/3.mp3"), fileFormat: .mp3, playCount: 0),
            AstryxTrack(title: "Old fav", artist: "Artist D", album: "W", genre: "Jazz", duration: 180, fileURL: URL(fileURLWithPath: "/tmp/4.mp3"), fileFormat: .mp3, playCount: 10, lastPlayed: Date().addingTimeInterval(-40*24*3600))
        ]
        
        let profile = await tasteEngine.generateProfile(from: tracks)
        let recs = await tasteEngine.recommendations(for: profile, from: tracks, limit: 5)
        
        XCTAssertFalse(recs.isEmpty)
        // Should have at least becauseYouLiked or genreDeepDive or rediscover
        XCTAssertTrue(recs.contains { $0.type == .becauseYouLiked || $0.type == .genreDeepDive || $0.type == .rediscover })
    }
    
    func testEmptyLibraryMock() async {
        let empty: [AstryxTrack] = []
        let profile = await tasteEngine.generateProfile(from: empty)
        
        XCTAssertEqual(profile.totalTracks, 0)
        XCTAssertEqual(profile.totalPlays, 0)
        XCTAssertEqual(profile.topGenres.count, 0)
    }
    
    func testPerformance() async {
        // Generate 1000 tracks
        var tracks: [AstryxTrack] = []
        for i in 0..<1000 {
            tracks.append(AstryxTrack(
                title: "Track \(i)",
                artist: "Artist \(i % 100)",
                album: "Album \(i % 50)",
                genre: ["Rock", "Pop", "Jazz", "Electronic", "Indie"][i % 5],
                duration: 180,
                fileURL: URL(fileURLWithPath: "/tmp/\(i).mp3"),
                fileFormat: .mp3,
                playCount: Int.random(in: 0...20),
                year: 2000 + (i % 24)
            ))
        }
        
        let start = Date()
        let profile = await tasteEngine.generateProfile(from: tracks)
        let elapsed = Date().timeIntervalSince(start) * 1000
        
        XCTAssertFalse(profile.topGenres.isEmpty)
        XCTAssertLessThan(elapsed, 200, "Taste DNA generation should be <200ms for 1000 tracks, was \(elapsed)ms")
        
        let recStart = Date()
        let recs = await tasteEngine.recommendations(for: profile, from: tracks, limit: 10)
        let recElapsed = Date().timeIntervalSince(recStart) * 1000
        
        XCTAssertLessThan(recElapsed, 100, "Recommendations should be <100ms, was \(recElapsed)ms")
    }
}
