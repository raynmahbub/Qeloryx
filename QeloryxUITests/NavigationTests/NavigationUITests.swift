// QELORYX — QeloryxUITests/NavigationTests
// NavigationUITests.swift
// Launch invariants: the app opens on a usable tab shell and tab switching
// works. These tests assert navigation structure, not engine behaviour.

import XCTest

final class NavigationUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchShowsTabBarWithAllTabs() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "tab bar should appear on launch")

        for tab in ["Library", "Search", "Discover", "Home", "Downloads"] {
            XCTAssertTrue(tabBar.buttons[tab].exists, "missing tab: \(tab)")
        }
    }

    func testTabSwitchingSelectsDiscoverTab() throws {
        let app = XCUIApplication()
        app.launch()

        let discover = app.tabBars.buttons["Discover"]
        XCTAssertTrue(discover.waitForExistence(timeout: 5))
        discover.tap()

        // The Discover screen renders its navigation title.
        XCTAssertTrue(app.navigationBars["Discover"].waitForExistence(timeout: 5))
    }
}
