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

    /// Find element by accessibility identifier using descendant query (handles all element types)
    func findElement(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    /// Dismiss any import dialog that may appear from leftover test files
    func dismissImportDialogIfPresent() {
        let importCancelButton = app.buttons["Cancel"]
        if importCancelButton.waitForExistence(timeout: 2) {
            importCancelButton.tap()
            Thread.sleep(forTimeInterval: 0.3)
        }
    }

    /// Confirm the import dialog to import files (tap "Done")
    /// Returns true if import dialog was found and confirmed
    @discardableResult
    func confirmImportDialogIfPresent(timeout: TimeInterval = 3) -> Bool {
        // Wait a moment for the import dialog to appear
        Thread.sleep(forTimeInterval: 1.0)

        // Look for the Import navigation bar
        let importNavBar = app.navigationBars["Import"]
        if importNavBar.waitForExistence(timeout: timeout) {
            // Tap Done to confirm import
            let doneButton = app.buttons["Done"]
            if doneButton.exists {
                doneButton.tap()

                // Handle the "Import 1 file into" alert
                // We need to tap "Library" to import directly into the library
                Thread.sleep(forTimeInterval: 0.5)
                let importAlert = app.alerts.firstMatch
                if importAlert.waitForExistence(timeout: 3) {
                    // Look for the Library button in the alert
                    let libraryButton = importAlert.buttons["Library"]
                    if libraryButton.exists {
                        libraryButton.tap()
                    }
                }

                // Wait for import to complete
                Thread.sleep(forTimeInterval: 2.0)
                return true
            }
        }
        return false
    }

    /// Wait for books to appear in the library after import
    func waitForBooksInLibrary(timeout: TimeInterval = 10) -> Bool {
        let listView = app.collectionViews[ScreenIdentifiers.Library.listItems]
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if listView.exists && listView.cells.count > 0 {
                return true
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
        return false
    }

    /// Start playing the first book in the library
    /// Returns true if playback started successfully
    @discardableResult
    func startPlayback() -> Bool {
        app.navigateToTab(.library)

        let listView = app.collectionViews[ScreenIdentifiers.Library.listItems]
        guard listView.waitForExistence(timeout: 5), listView.cells.count > 0 else {
            return false
        }

        // Tap the first book to start playing
        let firstCell = listView.cells.element(boundBy: 0)
        if firstCell.exists {
            firstCell.tap()
            // Wait for player to start
            Thread.sleep(forTimeInterval: 2.0)
            return true
        }
        return false
    }

    /// Wait for the mini player to appear (indicating playback started)
    func waitForMiniPlayer(timeout: TimeInterval = 10) -> Bool {
        let miniPlayer = findElement(ScreenIdentifiers.Library.miniPlayer)
        return miniPlayer.waitForExistence(timeout: timeout)
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

        // Reset launch arguments to base set plus the new state
        app.launchArguments = [
            "--uitesting",
            "--squabble-enabled",
            "--disable-animations",
            state.rawValue
        ]
        app.launchEnvironment["UITEST_MODE"] = "1"

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
