//
//  XCUIApplication+Navigation.swift
//  BookPlayerUITests
//
//  Navigation helpers for UI tests.
//

import XCTest

/// Main app tabs
enum AppTab: String {
    case library = "mainview_tab_library"
    case profile = "mainview_tab_profile"
    case settings = "mainview_tab_settings"

    var tabBarButtonLabel: String {
        switch self {
        case .library: return "Library"
        case .profile: return "Profile"
        case .settings: return "Settings"
        }
    }
}

extension XCUIApplication {

    // MARK: - Tab Navigation

    /// Navigate to a specific tab
    func navigateToTab(_ tab: AppTab) {
        let tabButton = tabBars.buttons[tab.tabBarButtonLabel]
        if tabButton.waitForExistence(timeout: 5) {
            tabButton.tap()
        }
    }

    // MARK: - Settings Navigation

    /// Navigate to a settings sub-screen
    func navigateToSettingsScreen(_ identifier: String) {
        navigateToTab(.settings)
        let row = cells[identifier]
        if row.waitForExistence(timeout: 3) {
            row.tap()
        }
    }

    // MARK: - Sheet Handling

    /// Dismiss any presented sheet
    func dismissSheet() {
        // Try cancel button first
        let cancelButton = buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()
            return
        }

        // Try close button
        let closeButton = buttons["Close"]
        if closeButton.exists {
            closeButton.tap()
            return
        }

        // Try done button
        let doneButton = buttons["Done"]
        if doneButton.exists {
            doneButton.tap()
            return
        }

        // Fall back to swipe down
        swipeDown(velocity: .fast)
    }

    /// Navigate back in a navigation stack
    func navigateBack() {
        let backButton = navigationBars.buttons.element(boundBy: 0)
        if backButton.exists {
            backButton.tap()
        }
    }

    // MARK: - Wait Helpers

    /// Wait for an element to exist
    @discardableResult
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }

    /// Wait for element and tap it
    func waitAndTap(_ element: XCUIElement, timeout: TimeInterval = 5) {
        if element.waitForExistence(timeout: timeout) {
            element.tap()
        }
    }

    // MARK: - Profile/Guild State Navigation

    /// Navigate to the profile tab and wait for a specific state
    func navigateToProfileState(_ stateIdentifier: String) {
        navigateToTab(.profile)
        let stateView = otherElements[stateIdentifier]
        _ = stateView.waitForExistence(timeout: 5)
    }

    /// Open a sheet from the profile tab
    func openProfileSheet(_ buttonIdentifier: String) {
        navigateToTab(.profile)
        let button = buttons[buttonIdentifier]
        if button.waitForExistence(timeout: 3) {
            button.tap()
        }
    }

    // MARK: - Player Navigation

    /// Open the full player (assumes mini player is visible)
    func openFullPlayer() {
        let miniPlayer = otherElements[ScreenIdentifiers.Library.miniPlayer]
        if miniPlayer.waitForExistence(timeout: 3) {
            miniPlayer.tap()
        }
    }

    /// Navigate to player sub-screen
    func openPlayerScreen(_ buttonIdentifier: String) {
        let button = buttons[buttonIdentifier]
        if button.waitForExistence(timeout: 3) {
            button.tap()
        }
    }
}
