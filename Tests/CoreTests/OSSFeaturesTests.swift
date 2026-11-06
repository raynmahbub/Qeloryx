// QELORYX — Tests
// OSSFeaturesTests.swift
// Tests for OSS-benchmarked features: ReplayGain, gapless/crossfade, smart playlists, M3U

import XCTest
@testable import QeloryxCore

final class OSSFeaturesTests: XCTestCase {
    
    private func sampleTrack(
        title: String = "Song",
        artist: String = "Artist",
        album: String = "Album",
        genre: String? = "Rock",
        year: Int? = 2020,
        duration: TimeInterval = 200,
        playCount: Int = 0,
        isFavorite: Bool = false,
        isLossless: Bool = false
    ) -> AstryxTrack {
        AstryxTrack(
            title: title,
            artist: artist,
            album: album,
            genre: genre,
            year: year,
            duration: duration,
            fileURL: URL(fileURLWithPath: "/tmp/\(title).mp3"),
            fileFormat: isLossless ? .flac : .mp3,
            isLossless: isLossless,
            playCount: playCount,
            isFavorite: isFavorite
        )
    }
    
    // MARK: - ReplayGain
    
    func testReplayGainLinearGain() {
        let normalizer = AstryxReplayGainNormalizer()
        let tags = ReplayGainTags(trackGain: -6.0, trackPeak: 0.9, albumGain: -8.0, albumPeak: 1.0)
        // -6 dB → 10^(-6/20) ≈ 0.501
        XCTAssertEqual(normalizer.linearGain(for: tags, mode: .track), pow(10.0, -6.0 / 20.0), accuracy: 1e-9)
        XCTAssertEqual(normalizer.gainDB(for: tags, mode: .album), -8.0)
        XCTAssertEqual(normalizer.gainDB(for: tags, mode: .off), 0)
    }
    
    func testReplayGainClippingPrevention() {
        let normalizer = AstryxReplayGainNormalizer(preventClipping: true)
        // +12 dB gain on a peak of 0.9 would clip → must be capped at 1/0.9
        let tags = ReplayGainTags(trackGain: 12.0, trackPeak: 0.9)
        let linear = normalizer.safeLinearGain(for: tags, mode: .track)
        XCTAssertEqual(linear, 1.0 / 0.9, accuracy: 1e-9)
        XCTAssertLessThanOrEqual(linear * 0.9, 1.0)
    }
    
    func testReplayGainApplyClampsVolume() {
        let normalizer = AstryxReplayGainNormalizer(preventClipping: false)
        let tags = ReplayGainTags(trackGain: 20.0, trackPeak: 0.5)
        let result = normalizer.apply(to: 1.0, tags: tags, mode: .track)
        XCTAssertEqual(result, 1.0, "Volume must be clamped to 1.0")
        XCTAssertEqual(normalizer.apply(to: 0.5, tags: nil, mode: .off), 0.5)
    }
    
    func testReplayGainFallsBackToAlbumGain() {
        let normalizer = AstryxReplayGainNormalizer()
        let tags = ReplayGainTags(albumGain: -3.0, albumPeak: 0.8)
        XCTAssertEqual(normalizer.gainDB(for: tags, mode: .track), -3.0, "Track mode falls back to album gain")
    }
    
    // MARK: - Gapless / Crossfade
    
    func testCrossfadePlanCreation() {
        let settings = AstryxPlaybackSettings(gaplessEnabled: true, crossfadeDuration: 4)
        XCTAssertNotNil(AstryxCrossfadePlan.plan(settings: settings))
        XCTAssertNil(AstryxCrossfadePlan.plan(settings: AstryxPlaybackSettings(gaplessEnabled: true, crossfadeDuration: 0)))
        XCTAssertNil(AstryxCrossfadePlan.plan(settings: AstryxPlaybackSettings(gaplessEnabled: false, crossfadeDuration: 4)))
    }
    
    func testCrossfadeDurationClamped() {
        let settings = AstryxPlaybackSettings(crossfadeDuration: 999)
        XCTAssertEqual(settings.crossfadeDuration, AstryxPlaybackSettings.maxCrossfadeDuration)
    }
    
    func testEqualPowerGainsAreConstantPower() {
        let plan = AstryxCrossfadePlan(overlap: 4, curve: .equalPower)
        for t in stride(from: 0.0, through: 4.0, by: 0.5) {
            let (outgoing, incoming) = plan.gains(at: t)
            let power = Double(outgoing) * Double(outgoing) + Double(incoming) * Double(incoming)
            XCTAssertEqual(power, 1.0, accuracy: 1e-6, "Equal-power fade keeps constant power at t=\(t)")
        }
    }
    
    func testLinearGainsEndpoints() {
        let plan = AstryxCrossfadePlan(overlap: 4, curve: .linear)
        XCTAssertEqual(plan.gains(at: 0).outgoing, 1.0)
        XCTAssertEqual(plan.gains(at: 0).incoming, 0.0)
        XCTAssertEqual(plan.gains(at: 4).outgoing, 0.0, accuracy: 1e-6)
        XCTAssertEqual(plan.gains(at: 4).incoming, 1.0, accuracy: 1e-6)
        XCTAssertEqual(plan.gains(at: 99).incoming, 1.0, "Progress clamps past the end")
    }
    
    // MARK: - Smart Playlists
    
    func testSmartPlaylistContainsAndNegation() {
        let rule = SmartPlaylistRule(field: .artist, op: .contains, value: "queen")
        XCTAssertTrue(rule.matches(sampleTrack(artist: "Queen")))
        XCTAssertFalse(rule.matches(sampleTrack(artist: "Eagles")))
        let negated = SmartPlaylistRule(field: .artist, op: .contains, value: "queen", negate: true)
        XCTAssertTrue(negated.matches(sampleTrack(artist: "Eagles")))
    }
    
    func testSmartPlaylistNumericAndBetween() {
        let rule = SmartPlaylistRule(field: .duration, op: .greaterThan, value: "180")
        XCTAssertTrue(rule.matches(sampleTrack(duration: 200)))
        XCTAssertFalse(rule.matches(sampleTrack(duration: 100)))
        let between = SmartPlaylistRule(field: .year, op: .between, value: "2015,2021")
        XCTAssertTrue(between.matches(sampleTrack(year: 2020)))
        XCTAssertFalse(between.matches(sampleTrack(year: 1999)))
    }
    
    func testSmartPlaylistRegexAndBoolean() {
        let regex = SmartPlaylistRule(field: .title, op: .matchesRegex, value: "^Stairway")
        XCTAssertTrue(regex.matches(sampleTrack(title: "Stairway to Heaven")))
        XCTAssertFalse(regex.matches(sampleTrack(title: "Hello")))
        let fav = SmartPlaylistRule(field: .isFavorite, op: .isTrue)
        XCTAssertTrue(fav.matches(sampleTrack(isFavorite: true)))
        XCTAssertFalse(fav.matches(sampleTrack(isFavorite: false)))
    }
    
    func testSmartPlaylistEvaluateAndSortLimit() {
        let tracks = [
            sampleTrack(title: "B Song", artist: "Queen", duration: 100, playCount: 5),
            sampleTrack(title: "A Song", artist: "Queen", duration: 300, playCount: 1),
            sampleTrack(title: "C Song", artist: "Eagles", duration: 200, playCount: 9)
        ]
        let playlist = AstryxSmartPlaylist(
            name: "Queen songs",
            logic: .and,
            rules: [SmartPlaylistRule(field: .artist, op: .equals, value: "queen")],
            sort: .title,
            limit: 1
        )
        let result = playlist.evaluate(tracks)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "A Song")
    }
    
    func testSmartPlaylistOrLogic() {
        let tracks = [
            sampleTrack(title: "One", genre: "Rock"),
            sampleTrack(title: "Two", genre: "Jazz"),
            sampleTrack(title: "Three", genre: "Metal")
        ]
        let playlist = AstryxSmartPlaylist(
            name: "Rock or Metal",
            logic: .or,
            rules: [
                SmartPlaylistRule(field: .genre, op: .equals, value: "rock"),
                SmartPlaylistRule(field: .genre, op: .equals, value: "metal")
            ]
        )
        XCTAssertEqual(playlist.evaluate(tracks).count, 2)
        XCTAssertTrue(AstryxSmartPlaylist(name: "Empty", rules: []).evaluate(tracks).isEmpty)
    }
    
    // MARK: - M3U
    
    func testM3UExportParseRoundTrip() {
        let tracks = [
            sampleTrack(title: "Bohemian Rhapsody", artist: "Queen"),
            sampleTrack(title: "Hotel California", artist: "Eagles", duration: 391)
        ]
        let exported = M3UPlaylist.export(tracks: tracks, playlistName: "Favorites")
        XCTAssertTrue(exported.hasPrefix("#EXTM3U"))
        XCTAssertTrue(exported.contains("#PLAYLIST:Favorites"))
        
        let parsed = M3UPlaylist.parse(exported)
        XCTAssertEqual(parsed.count, 2)
        XCTAssertEqual(parsed[0].title, "Bohemian Rhapsody")
        XCTAssertEqual(parsed[0].artist, "Queen")
        XCTAssertEqual(parsed[1].duration, 391)
        XCTAssertEqual(parsed[1].path, tracks[1].fileURL.path)
    }
    
    func testM3UParseBasicAndDirectives() {
        let content = """
        #EXTM3U
        #EXT-X-KEY:METHOD=AES-128,URI="key"
        /music/a.mp3
        #EXTINF:180,Artist - Title
        /music/b.flac
        """
        let parsed = M3UPlaylist.parse(content)
        XCTAssertEqual(parsed.count, 2)
        XCTAssertEqual(parsed[0].path, "/music/a.mp3")
        XCTAssertEqual(parsed[0].duration, -1)
        XCTAssertEqual(parsed[1].title, "Title")
        XCTAssertEqual(parsed[1].artist, "Artist")
    }
    
    func testM3UResolveAgainstLibrary() {
        let track = sampleTrack(title: "Song")
        let entries = [M3UEntry(path: track.fileURL.path), M3UEntry(path: "/missing.mp3")]
        let resolved = M3UPlaylist.resolve(entries, against: [track])
        XCTAssertEqual(resolved.count, 1)
        XCTAssertEqual(resolved.first?.title, "Song")
    }
}
