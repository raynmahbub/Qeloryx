// QELORYX — Tests
// OSSIntegrationTests.swift
// Tests for second OSS benchmark batch: scrobbling, smart queue, tag editor, bit-perfect output

import XCTest
#if canImport(QeloryxCore)
@testable import QeloryxCore
#else
// The XcodeGen app target is a single module named `Qeloryx` (App + Core +
// Features + Platform + DesignSystem compiled together), so `QeloryxCore` does
// not exist there. `swift test` uses the multi-module SPM targets above.
@testable import Qeloryx
#endif

final class OSSIntegrationTests: XCTestCase {
    
    private func track(id: String = UUID().uuidString, title: String = "Song", artist: String = "Artist", duration: TimeInterval = 200, playCount: Int = 0, isFavorite: Bool = false) -> AstryxTrack {
        AstryxTrack(
            id: id,
            title: title,
            artist: artist,
            album: "Album",
            duration: duration,
            fileURL: URL(fileURLWithPath: "/tmp/\(id).mp3"),
            fileFormat: .mp3,
            playCount: playCount,
            isFavorite: isFavorite
        )
    }
    
    // MARK: - Scrobbling (Last.fm rules)
    
    func testScrobbleRuleHalfDuration() {
        let entry = ScrobbleEntry(track: track(duration: 200), playDuration: 100)
        XCTAssertTrue(ScrobbleRules.shouldScrobble(entry))
        XCTAssertFalse(ScrobbleRules.shouldScrobble(ScrobbleEntry(track: track(duration: 200), playDuration: 99)))
    }
    
    func testScrobbleRuleFourMinuteCap() {
        // 10-minute track scrobbles at 4 minutes, not at 50% (5 min)
        XCTAssertTrue(ScrobbleRules.shouldScrobble(ScrobbleEntry(track: track(duration: 600), playDuration: 240)))
        XCTAssertFalse(ScrobbleRules.shouldScrobble(ScrobbleEntry(track: track(duration: 600), playDuration: 239)))
    }
    
    func testScrobbleRuleRejectsShortTracks() {
        XCTAssertFalse(ScrobbleRules.shouldScrobble(ScrobbleEntry(track: track(duration: 20), playDuration: 20)))
    }
    
    func testScrobbleProviderBuffersAndFlushes() async {
        let provider = AstryxScrobbleProvider()
        let entry = ScrobbleEntry(track: track(duration: 200), playDuration: 150)
        XCTAssertTrue(await provider.scrobble(entry))
        XCTAssertEqual((await provider.pendingScrobbles()).count, 1)
        
        var delivered: [ScrobbleEntry] = []
        provider.transport = { e in delivered.append(e); return true }
        let count = await provider.flush()
        XCTAssertEqual(count, 1)
        XCTAssertEqual(delivered.first?.trackID, entry.trackID)
        XCTAssertTrue((await provider.pendingScrobbles()).isEmpty)
    }
    
    func testScrobbleProviderRejectsNonQualifying() async {
        let provider = AstryxScrobbleProvider()
        XCTAssertFalse(await provider.scrobble(ScrobbleEntry(track: track(duration: 200), playDuration: 10)))
        XCTAssertTrue((await provider.pendingScrobbles()).isEmpty)
    }
    
    // MARK: - Smart Queue Filler
    
    func testSmartQueueExcludesQueuedTracks() {
        let a = track(id: "a"), b = track(id: "b"), c = track(id: "c")
        let queue = AstryxQueue(items: [AstryxQueueItem(trackID: "a", order: 0), AstryxQueueItem(trackID: "b", order: 1)], currentIndex: 0)
        let filler = AstryxSmartQueueFiller()
        let suggestions = filler.suggestedTracks(for: queue, library: [a, b, c], limit: 10)
        XCTAssertEqual(suggestions.map { $0.id }, ["c"])
    }
    
    func testSmartQueueRanksRecommendationsFirst() {
        let a = track(id: "a", playCount: 100)
        let b = track(id: "b", isFavorite: true)
        let c = track(id: "c")
        let queue = AstryxQueue(items: [], currentIndex: nil)
        let filler = AstryxSmartQueueFiller()
        let suggestions = filler.suggestedTrackIDs(for: queue, library: [a, b, c], recommendedTrackIDs: ["c", "b"], limit: 3)
        XCTAssertEqual(suggestions.first, "c")
        XCTAssertEqual(suggestions.count, 3)
    }
    
    func testSmartQueueRespectsLimit() {
        let library = (0..<20).map { track(id: "t\($0)") }
        let filler = AstryxSmartQueueFiller()
        XCTAssertEqual(filler.suggestedTracks(for: AstryxQueue(), library: library, limit: 5).count, 5)
        XCTAssertTrue(filler.suggestedTracks(for: AstryxQueue(), library: library, limit: 0).isEmpty)
    }
    
    // MARK: - Tag Editor
    
    func testTagEditorApply() {
        let editor = AstryxTagEditor()
        let original = track(title: "Old", artist: "Old Artist")
        let updated = editor.apply(TrackTagEdit(title: "New", year: 2024), to: original)
        XCTAssertEqual(updated.title, "New")
        XCTAssertEqual(updated.year, 2024)
        XCTAssertEqual(updated.artist, "Old Artist", "Untouched fields must be preserved")
    }
    
    func testTagEditorValidation() {
        let editor = AstryxTagEditor()
        let t = track()
        XCTAssertFalse(editor.validate(TrackTagEdit(title: "  "), for: t).isEmpty)
        XCTAssertFalse(editor.validate(TrackTagEdit(year: 1200), for: t).isEmpty)
        XCTAssertFalse(editor.validate(TrackTagEdit(trackNumber: 0), for: t).isEmpty)
        XCTAssertTrue(editor.validate(TrackTagEdit(title: "OK", year: 2020), for: t).isEmpty)
        XCTAssertTrue(TrackTagEdit().isEmpty)
    }
    
    // MARK: - Bit-Perfect Output
    
    func testBitPerfectSettings() {
        let settings = AstryxAudioOutputSettings(bitPerfectEnabled: true, preferredSampleRate: 96000, exclusiveMode: true)
        XCTAssertEqual(settings.effectiveSampleRate, 96000)
        XCTAssertEqual(AstryxAudioOutputSettings(bitPerfectEnabled: false, preferredSampleRate: 96000).effectiveSampleRate, 0)
        // Non-standard rates fall back to device default (0)
        XCTAssertEqual(AstryxAudioOutputSettings(bitPerfectEnabled: true, preferredSampleRate: 12345).preferredSampleRate, 0)
        XCTAssertEqual(AstryxOutputMode.bitPerfectDAC.settings.bitPerfectEnabled, true)
        XCTAssertEqual(AstryxOutputMode.standard.settings.bitPerfectEnabled, false)
    }
}
