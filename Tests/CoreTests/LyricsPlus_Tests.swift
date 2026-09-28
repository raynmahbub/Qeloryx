// QELORYX — Tests
// LyricsPlus_Tests.swift
// QEL-032 Lyrics++ — LRC, Synced, Karaoke, Translation-ready, Fullscreen

import XCTest
@testable import QeloryxCore

final class LyricsPlusTests: XCTestCase {
    
    var provider: AstryxLyricsProvider!
    var engine: AstryxLyricsEngine!
    
    override func setUp() {
        super.setUp()
        provider = AstryxLyricsProvider()
        engine = AstryxLyricsEngine(providers: [provider])
    }
    
    func testStandardLRCParsing() {
        let lrc = """
        [ti:Test Song]
        [ar:Test Artist]
        [al:Test Album]
        [00:12.00]First line
        [00:15.30]Second line
        [00:18.50]Third line
        """
        
        let lyrics = provider.parseLRC(lrc, trackID: "test-1")
        
        XCTAssertTrue(lyrics.isSynced)
        XCTAssertEqual(lyrics.lines.count, 3)
        XCTAssertEqual(lyrics.lines[0].text, "First line")
        XCTAssertEqual(lyrics.lines[0].startTime, 12.0, accuracy: 0.01)
        XCTAssertEqual(lyrics.lines[1].startTime, 15.3, accuracy: 0.01)
        XCTAssertEqual(lyrics.metadata.title, "Test Song")
        XCTAssertEqual(lyrics.metadata.artist, "Test Artist")
    }
    
    func testMultipleTimestampsSameLine() {
        let lrc = """
        [00:12.00][00:15.00]Repeated line
        [00:18.00]Next line
        """
        
        let lyrics = provider.parseLRC(lrc, trackID: "test-2")
        
        // Should create 2 lines with same text but different timestamps + 1 next line = 3 total
        XCTAssertEqual(lyrics.lines.count, 3)
        XCTAssertEqual(lyrics.lines[0].text, "Repeated line")
        XCTAssertEqual(lyrics.lines[1].text, "Repeated line")
        XCTAssertEqual(lyrics.lines[0].startTime, 12.0, accuracy: 0.01)
        XCTAssertEqual(lyrics.lines[1].startTime, 15.0, accuracy: 0.01)
    }
    
    func testMetadataAndOffset() {
        let lrc = """
        [ti:Offset Song]
        [offset:500]
        [00:12.00]First line
        """
        
        let lyrics = provider.parseLRC(lrc, trackID: "test-3")
        
        XCTAssertEqual(lyrics.metadata.offset, 0.5, accuracy: 0.01)
        // 12.00 + 0.5 offset = 12.5
        XCTAssertEqual(lyrics.lines[0].startTime, 12.5, accuracy: 0.01)
    }
    
    func testEnhancedLRCKaraokeParsing() {
        let lrc = """
        [00:12.00] <00:12.00>Hello <00:12.50>world <00:13.00>!
        [00:15.00] <00:15.00>This <00:15.30>is <00:15.60>karaoke
        """
        
        let lyrics = provider.parseEnhancedLRC(lrc, trackID: "test-karaoke")
        
        XCTAssertTrue(lyrics.isKaraoke)
        XCTAssertEqual(lyrics.lines.count, 2)
        
        let firstLine = lyrics.lines[0]
        XCTAssertTrue(firstLine.isKaraoke)
        XCTAssertEqual(firstLine.words.count, 3)
        XCTAssertEqual(firstLine.words[0].text, "Hello")
        XCTAssertEqual(firstLine.words[0].startTime, 12.0, accuracy: 0.01)
        XCTAssertEqual(firstLine.words[1].startTime, 12.5, accuracy: 0.01)
        XCTAssertEqual(firstLine.text, "Hello world !")
    }
    
    func testCurrentLineLookup() {
        let lines = [
            AstryxLyricLine(text: "Line 1", startTime: 0),
            AstryxLyricLine(text: "Line 2", startTime: 10),
            AstryxLyricLine(text: "Line 3", startTime: 20)
        ]
        let lyrics = AstryxLyrics(trackID: "test", lines: lines, isSynced: true)
        
        XCTAssertEqual(lyrics.currentLine(at: 5)?.text, "Line 1")
        XCTAssertEqual(lyrics.currentLine(at: 10)?.text, "Line 2")
        XCTAssertEqual(lyrics.currentLine(at: 15)?.text, "Line 2")
        XCTAssertEqual(lyrics.currentLine(at: 25)?.text, "Line 3")
        
        XCTAssertEqual(lyrics.currentLineIndex(at: 5), 0)
        XCTAssertEqual(lyrics.currentLineIndex(at: 12), 1)
        XCTAssertEqual(lyrics.currentLineIndex(at: 22), 2)
    }
    
    func testKaraokeWordLookup() {
        let words = [
            AstryxLyricWord(text: "Hello", startTime: 0),
            AstryxLyricWord(text: "world", startTime: 0.5),
            AstryxLyricWord(text: "!", startTime: 1.0)
        ]
        let line = AstryxLyricLine(text: "Hello world !", startTime: 0, words: words)
        let lyrics = AstryxLyrics(trackID: "test", lines: [line], isSynced: true, isKaraoke: true)
        
        engine.setLyrics(lyrics)
        
        // At time 0.2, should be "Hello"
        let word1 = engine.currentWord(at: 0.2)
        XCTAssertEqual(word1?.text, "Hello")
        
        // At time 0.6, should be "world"
        let word2 = engine.currentWord(at: 0.6)
        XCTAssertEqual(word2?.text, "world")
    }
    
    func testTranslationReadyArchitecture() {
        let baseLines = [AstryxLyricLine(text: "Hello", startTime: 0)]
        let base = AstryxLyrics(trackID: "test", lines: baseLines, isSynced: true, language: "en")
        
        let esLines = [AstryxLyricLine(text: "Hola", startTime: 0)]
        let spanish = AstryxLyrics(trackID: "test", lines: esLines, isSynced: true, language: "es")
        
        let bnLines = [AstryxLyricLine(text: "হ্যালো", startTime: 0)]
        let bengali = AstryxLyrics(trackID: "test", lines: bnLines, isSynced: true, language: "bn")
        
        let withTranslations = AstryxLyrics(
            trackID: "test",
            lines: baseLines,
            isSynced: true,
            language: "en",
            translations: ["es": spanish, "bn": bengali]
        )
        
        XCTAssertEqual(withTranslations.translations.count, 2)
        XCTAssertNotNil(withTranslations.translation(for: "es"))
        XCTAssertEqual(withTranslations.translation(for: "es")?.lines.first?.text, "Hola")
        XCTAssertEqual(withTranslations.translation(for: "bn")?.lines.first?.text, "হ্যালো")
        
        engine.setLyrics(withTranslations)
        let languages = engine.availableLanguages()
        XCTAssertTrue(languages.contains("en"))
        XCTAssertTrue(languages.contains("es"))
        XCTAssertTrue(languages.contains("bn"))
    }
    
    func testLyricsEngineSetAndClear() {
        let lines = [AstryxLyricLine(text: "Test", startTime: 0)]
        let lyrics = AstryxLyrics(trackID: "test", lines: lines, isSynced: true, isKaraoke: true)
        
        engine.setLyrics(lyrics)
        XCTAssertNotNil(engine.currentLyrics())
        XCTAssertTrue(engine.isKaraokeAvailable())
        
        engine.clear()
        XCTAssertNil(engine.currentLyrics())
        XCTAssertFalse(engine.isKaraokeAvailable())
    }
    
    func testLyricsPerformance() {
        // Generate 500 lines (typical album)
        var lines: [AstryxLyricLine] = []
        for i in 0..<500 {
            lines.append(AstryxLyricLine(text: "Line \(i)", startTime: Double(i) * 2.0))
        }
        let lyrics = AstryxLyrics(trackID: "perf-test", lines: lines, isSynced: true)
        
        let start = Date()
        for _ in 0..<1000 {
            _ = lyrics.currentLineIndex(at: 250.5)
        }
        let elapsed = Date().timeIntervalSince(start) * 1000
        
        // 1000 lookups should be <50ms
        XCTAssertLessThan(elapsed, 50, "Lyrics lookup should be <50ms for 1000 queries, was \(elapsed)ms")
    }
}
