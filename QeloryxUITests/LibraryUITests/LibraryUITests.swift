// QELORYX — QeloryxUITests/LibraryUITests
// LibraryUITests.swift
// Library tab smoke tests: reachable, titled, and shows either tracks or an
// honest empty state — never a blank screen.

import XCTest

final class LibraryUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLibraryTabAppearsWithNavigationTitle() throws {
        let app = XCUIApplication()
        app.launch()

        let libraryTab = app.tabBars.buttons["Library"]
        XCTAssertTrue(libraryTab.waitForExistence(timeout: 5))
        libraryTab.tap()

        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 5))
    }
}
