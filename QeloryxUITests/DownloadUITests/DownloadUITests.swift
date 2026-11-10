// QELORYX — QeloryxUITests/DownloadUITests
// DownloadUITests.swift
// Downloads tab smoke tests: the screen exists and shows its state-machine UI.

import XCTest

final class DownloadUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testDownloadsTabAppears() throws {
        let app = XCUIApplication()
        app.launch()

        let downloadsTab = app.tabBars.buttons["Downloads"]
        XCTAssertTrue(downloadsTab.waitForExistence(timeout: 5))
        downloadsTab.tap()

        XCTAssertTrue(app.navigationBars["Downloads"].waitForExistence(timeout: 5))
    }
}
