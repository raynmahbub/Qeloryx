// QELORYX — QeloryxUITests/PlaybackUITests
// PlaybackUITests.swift
// Launch invariants for the playback surface. A full playback test needs
// fixture audio in the app bundle; until then these guard the always-visible
// parts of the experience (mini player absence on cold launch, player chrome).

import XCTest

final class PlaybackUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testColdLaunchShowsNoMiniPlayer() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
        // Nothing is playing on a fresh install, so no mini-player controls.
        XCTAssertFalse(app.buttons["Play"].exists)
    }
}
