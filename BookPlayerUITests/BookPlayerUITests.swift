//
//  BookPlayerUITests.swift
//  BookPlayerUITests
//
//  Base test class for UI tests with common setup and utilities.
//

import XCTest

class BookPlayerUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        // Stop immediately when a test fails
        continueAfterFailure = false

        app = XCUIApplication()

        // Configure launch arguments for test mode
        app.launchArguments = [
            "--uitesting",           // Enable UI test mode
            "--squabble-enabled",    // Force Squabble features on
            "--disable-animations"   // Speed up tests
        ]

        // Configure environment variables
        app.launchEnvironment["UITEST_MODE"] = "1"

        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Convenience Accessors

    /// Quick access to tab bar
    var tabBar: XCUIElement {
        app.tabBars.firstMatch
    }

    /// Quick access to navigation bar
    var navBar: XCUIElement {
        app.navigationBars.firstMatch
    }

    /// Check if an element exists without waiting
    func exists(_ element: XCUIElement) -> Bool {
        element.exists
    }

    /// Check if we're on a specific tab
    func isOnTab(_ tab: AppTab) -> Bool {
        let tabButton = app.tabBars.buttons[tab.tabBarButtonLabel]
        return tabButton.exists && tabButton.isSelected
    }
}

// MARK: - Test Modes

extension BookPlayerUITests {

    /// Launch app in a specific test state
    enum TestState: String {
        case fresh = "--fresh-install"
        case loggedIn = "--logged-in"
        case withGuild = "--with-guild"
        case withBooks = "--with-books"
    }

    /// Relaunch the app with additional state configuration
    func relaunchWithState(_ state: TestState) {
        app.terminate()
        app.launchArguments.append(state.rawValue)
        app.launch()
    }

    /// Relaunch in light mode
    func relaunchInLightMode() {
        app.terminate()
        app.launchArguments.append("--appearance-light")
        app.launch()
    }

    /// Relaunch in dark mode
    func relaunchInDarkMode() {
        app.terminate()
        app.launchArguments.append("--appearance-dark")
        app.launch()
    }
}
