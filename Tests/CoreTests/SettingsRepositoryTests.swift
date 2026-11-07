// QELORYX — CoreTests
// SettingsRepositoryTests.swift
//
// Covers the settings store that used to not exist: values are validated,
// clamped and persisted, and clearing the store returns documented defaults.

import XCTest
#if canImport(QeloryxCore)
@testable import QeloryxCore
#else
// The XcodeGen app target is a single module named `Qeloryx` (App + Core +
// Features + Platform + DesignSystem compiled together), so `QeloryxCore` does
// not exist there. `swift test` uses the multi-module SPM targets above.
@testable import Qeloryx
#endif

final class SettingsRepositoryTests: XCTestCase {

    private var store: InMemorySettingsStore!
    private var repository: SettingsRepository!

    override func setUp() {
        super.setUp()
        store = InMemorySettingsStore()
        repository = SettingsRepository(store: store)
    }

    // MARK: - Defaults

    func testDefaultsAreDocumentedValues() {
        XCTAssertEqual(repository.audio.crossfadeSeconds, 0, "crossfade must default off")
        XCTAssertTrue(repository.audio.gaplessEnabled)
        XCTAssertFalse(repository.audio.replayGainEnabled)
        XCTAssertEqual(repository.downloads.maxConcurrent, 3)
        XCTAssertTrue(repository.downloads.allowsCellular)
        XCTAssertFalse(repository.privacy.analyticsEnabled, "analytics is opt-in")
        XCTAssertTrue(repository.playback.restoreQueueOnLaunch)
        XCTAssertEqual(repository.appearance.mode, .system)
    }

    // MARK: - Clamping

    func testCrossfadeIsClampedToSupportedRange() {
        repository.setCrossfadeSeconds(-5)
        XCTAssertEqual(repository.audio.crossfadeSeconds, 0)

        repository.setCrossfadeSeconds(500)
        XCTAssertEqual(repository.audio.crossfadeSeconds, SettingsRepository.maximumCrossfadeSeconds)

        repository.setCrossfadeSeconds(.nan)
        XCTAssertEqual(repository.audio.crossfadeSeconds, 0, "NaN must not survive a write")
    }

    func testConcurrentDownloadsAreClamped() {
        repository.setMaxConcurrentDownloads(0)
        XCTAssertEqual(repository.downloads.maxConcurrent, 1)

        repository.setMaxConcurrentDownloads(99)
        XCTAssertEqual(repository.downloads.maxConcurrent, SettingsRepository.maximumConcurrentDownloads)
    }

    // MARK: - Validation

    func testAccentHexRejectsMalformedValues() {
        let original = repository.appearance.accentHex
        for invalid in ["red", "#FFF", "#GGGGGG", "4C8DFF"] {
            repository.setAccentHex(invalid)
            XCTAssertEqual(repository.appearance.accentHex, original, "\(invalid) must be rejected")
        }
        repository.setAccentHex("#123ABC")
        XCTAssertEqual(repository.appearance.accentHex, "#123ABC")
    }

    // MARK: - Persistence

    func testValuesSurviveANewRepositoryInstance() {
        repository.setCrossfadeSeconds(6)
        repository.setAllowsCellular(false)
        repository.setAppearanceMode(.dark)
        repository.setMaxConcurrentDownloads(2)

        let reloaded = SettingsRepository(store: store)
        XCTAssertEqual(reloaded.audio.crossfadeSeconds, 6)
        XCTAssertFalse(reloaded.downloads.allowsCellular)
        XCTAssertTrue(reloaded.downloads.wifiOnly)
        XCTAssertEqual(reloaded.appearance.mode, .dark)
        XCTAssertEqual(reloaded.downloads.maxConcurrent, 2)
    }

    func testCorruptStoredValuesFallBackToDefaults() {
        store.set("not-a-mode", forKey: SettingsRepository.Key.appearanceMode)
        store.set(999.0, forKey: SettingsRepository.Key.crossfadeSeconds)

        let reloaded = SettingsRepository(store: store)
        XCTAssertEqual(reloaded.appearance.mode, .system)
        XCTAssertEqual(
            reloaded.audio.crossfadeSeconds,
            SettingsRepository.maximumCrossfadeSeconds,
            "an out-of-range stored value is clamped, never trusted"
        )
    }

    // MARK: - Crossfade translation

    func testCrossfadeConfigurationIsDisabledAtZero() {
        XCTAssertFalse(repository.crossfadeConfiguration().isEnabled)
    }

    func testCrossfadeConfigurationCarriesCurve() {
        repository.setCrossfadeSeconds(4)
        repository.setCrossfadeCurve(.sCurve)
        let configuration = repository.crossfadeConfiguration()
        XCTAssertTrue(configuration.isEnabled)
        XCTAssertEqual(configuration.duration, 4)
        XCTAssertEqual(configuration.curve, .sCurve)
    }

    func testSubMinimumCrossfadeCollapsesToDisabled() {
        // CrossfadeConfiguration treats < 1 s as meaningless.
        repository.setCrossfadeSeconds(0.4)
        XCTAssertFalse(repository.crossfadeConfiguration().isEnabled)
    }
}
