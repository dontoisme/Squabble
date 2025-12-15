//
//  ScreenshotTests.swift
//  BookPlayerUITests
//
//  Automated screenshot capture for app timelapse documentation.
//  Run with: ./scripts/capture-screenshots.sh
//
//  Test States:
//  - Default: Fresh app, not logged in
//  - --logged-in: Logged in to Squabble but no guild
//  - --with-guild: Logged in with a guild and members
//  - --with-books: Library has books
//  - --with-player: A book is currently playing
//

import XCTest

final class ScreenshotTests: BookPlayerUITests {

    // MARK: - Library Tab Screenshots

    func test01_LibraryEmpty() throws {
        dismissImportDialogIfPresent()
        app.navigateToTab(.library)

        // Wait for empty view or list to appear
        let emptyView = findElement(ScreenIdentifiers.Library.viewEmpty)
        let listView = app.collectionViews[ScreenIdentifiers.Library.listItems]

        _ = emptyView.waitForExistence(timeout: 3) || listView.waitForExistence(timeout: 3)

        takeScreenshot("01-library-empty")
    }

    func test02_LibraryWithBooks() throws {
        // Relaunch with books in library
        relaunchWithState(.withBooks)

        // The app copies test audiobook to Inbox, which triggers import dialog
        // Confirm the import to add the book to the library
        confirmImportDialogIfPresent(timeout: 5)

        // Wait for the book to appear in the library
        app.navigateToTab(.library)

        guard waitForBooksInLibrary(timeout: 10) else {
            throw XCTSkip("No books in library - skipping screenshot")
        }

        takeScreenshot("02-library-with-books")
    }

    func test03_LibraryFolder() throws {
        dismissImportDialogIfPresent()
        app.navigateToTab(.library)

        // Try to tap on a folder if one exists
        let listView = app.collectionViews[ScreenIdentifiers.Library.listItems]
        guard listView.waitForExistence(timeout: 3) else {
            throw XCTSkip("Library list not found")
        }

        // Look for a folder cell and tap it
        let folderCell = listView.cells.element(boundBy: 0)
        if folderCell.exists {
            folderCell.tap()
            Thread.sleep(forTimeInterval: 0.5)
            takeScreenshot("03-library-folder")
            app.navigateBack()
        } else {
            throw XCTSkip("No folders to navigate into")
        }
    }

    func test04_LibrarySearch() throws {
        // Import a book so search has content
        relaunchWithState(.withBooks)
        confirmImportDialogIfPresent(timeout: 5)
        app.navigateToTab(.library)

        guard waitForBooksInLibrary(timeout: 10) else {
            throw XCTSkip("No books in library")
        }

        // On iOS 26 iPhone, search is a dedicated tab
        // Try the Search tab first (iOS 26+)
        let searchTabButton = app.tabBars.buttons["Search"]
        if searchTabButton.waitForExistence(timeout: 2) {
            searchTabButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
            takeScreenshot("04-library-search")
            return
        }

        // Fallback: try searchable field in library (iOS 18)
        let searchField = app.searchFields.firstMatch
        if searchField.waitForExistence(timeout: 3) {
            searchField.tap()
            Thread.sleep(forTimeInterval: 0.5)
            takeScreenshot("04-library-search")
            // Dismiss keyboard
            let cancelButton = app.buttons["Cancel"]
            if cancelButton.exists {
                cancelButton.tap()
            }
        } else {
            throw XCTSkip("Search not available (no tab or search field found)")
        }
    }

    func test05_LibraryMiniPlayer() throws {
        // Import book and start playback
        relaunchWithState(.withBooks)
        confirmImportDialogIfPresent(timeout: 5)
        app.navigateToTab(.library)

        guard waitForBooksInLibrary(timeout: 10) else {
            throw XCTSkip("No books in library")
        }

        // Start playing
        startPlayback()
        app.navigateToTab(.library)

        let miniPlayer = findElement(ScreenIdentifiers.Library.miniPlayer)
        guard miniPlayer.waitForExistence(timeout: 5) else {
            throw XCTSkip("Mini player not visible - playback may not have started")
        }

        takeScreenshot("05-library-miniplayer")
    }

    func test06_ItemDetails() throws {
        // Relaunch with books to have an item to edit
        relaunchWithState(.withBooks)
        confirmImportDialogIfPresent(timeout: 5)

        app.navigateToTab(.library)

        guard waitForBooksInLibrary(timeout: 10) else {
            throw XCTSkip("No books in library - cannot show item details")
        }
        let listView = app.collectionViews[ScreenIdentifiers.Library.listItems]

        // Tap the more menu to access edit mode
        let moreMenu = findElement(ScreenIdentifiers.Library.menuMore)
        guard moreMenu.waitForExistence(timeout: 3) else {
            throw XCTSkip("More menu not found")
        }
        moreMenu.tap()

        // Tap Select to enter edit mode
        let selectButton = app.buttons["Select"]
        guard selectButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("Select button not found in menu")
        }
        selectButton.tap()

        Thread.sleep(forTimeInterval: 0.5)

        // Select the first item
        let firstCell = listView.cells.element(boundBy: 0)
        if firstCell.exists {
            firstCell.tap()
        }

        Thread.sleep(forTimeInterval: 0.3)

        // Tap the edit button (square.and.pencil) in bottom toolbar
        let editButton = app.buttons["square.and.pencil"]
        guard editButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("Edit button not found")
        }
        editButton.tap()

        // Wait for item details sheet
        let detailsView = findElement(ScreenIdentifiers.ItemDetails.viewMain)
        _ = detailsView.waitForExistence(timeout: 3)

        takeScreenshot("06-item-details")
        app.dismissSheet()
    }

    func test07_LibrarySelectionMode() throws {
        // Relaunch with books
        relaunchWithState(.withBooks)
        confirmImportDialogIfPresent(timeout: 5)

        app.navigateToTab(.library)

        guard waitForBooksInLibrary(timeout: 10) else {
            throw XCTSkip("No books in library - cannot show selection mode")
        }
        let listView = app.collectionViews[ScreenIdentifiers.Library.listItems]

        // Tap the more menu
        let moreMenu = findElement(ScreenIdentifiers.Library.menuMore)
        guard moreMenu.waitForExistence(timeout: 3) else {
            throw XCTSkip("More menu not found")
        }
        moreMenu.tap()

        // Tap Select to enter edit mode
        let selectButton = app.buttons["Select"]
        guard selectButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("Select button not found in menu")
        }
        selectButton.tap()

        Thread.sleep(forTimeInterval: 0.5)

        // Select a couple items to show selection state
        let firstCell = listView.cells.element(boundBy: 0)
        if firstCell.exists {
            firstCell.tap()
        }

        takeScreenshot("07-library-selection-mode")

        // Exit edit mode
        let doneButton = app.buttons["Done"]
        if doneButton.exists {
            doneButton.tap()
        }
    }

    func test08_LibraryAddMenu() throws {
        dismissImportDialogIfPresent()
        app.navigateToTab(.library)

        // Tap the more menu to show add/sort options
        let moreMenu = findElement(ScreenIdentifiers.Library.menuMore)
        guard moreMenu.waitForExistence(timeout: 3) else {
            throw XCTSkip("More menu not found")
        }
        moreMenu.tap()

        // Wait for menu to appear
        Thread.sleep(forTimeInterval: 0.5)

        takeScreenshot("08-library-add-menu")

        // Dismiss menu by tapping elsewhere
        app.tap()
    }

    // MARK: - Player Screenshots

    func test09_PlayerMain() throws {
        // Import book and start playback
        relaunchWithState(.withBooks)
        confirmImportDialogIfPresent(timeout: 5)
        app.navigateToTab(.library)

        guard waitForBooksInLibrary(timeout: 10) else {
            throw XCTSkip("No books in library")
        }

        // Start playing - this opens the full player
        startPlayback()

        // Wait for full player to appear
        Thread.sleep(forTimeInterval: 1.0)

        takeScreenshot("09-player-main")
    }

    func test10_PlayerChapters() throws {
        // Import book and start playback
        relaunchWithState(.withBooks)
        confirmImportDialogIfPresent(timeout: 5)
        app.navigateToTab(.library)

        guard waitForBooksInLibrary(timeout: 10) else {
            throw XCTSkip("No books in library")
        }

        // Start playing to open player
        startPlayback()
        Thread.sleep(forTimeInterval: 1.0)

        // The list button shows chapters or bookmarks (depending on user preference)
        let listButton = findElement(ScreenIdentifiers.Player.buttonChapters)
        guard listButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("List button not found - player may not be open")
        }

        listButton.tap()
        Thread.sleep(forTimeInterval: 0.5)

        takeScreenshot("10-player-chapters")
        app.dismissSheet()
    }

    func test11_PlayerBookmarks() throws {
        // Import book and start playback
        relaunchWithState(.withBooks)
        confirmImportDialogIfPresent(timeout: 5)
        app.navigateToTab(.library)

        guard waitForBooksInLibrary(timeout: 10) else {
            throw XCTSkip("No books in library")
        }

        // Start playing to open player
        startPlayback()
        Thread.sleep(forTimeInterval: 1.0)

        // First create a bookmark, then show bookmarks list
        let bookmarkButton = findElement(ScreenIdentifiers.Player.buttonBookmarks)
        guard bookmarkButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("Bookmark button not found - player may not be open")
        }

        // Create a bookmark first so the list has content
        bookmarkButton.tap()
        Thread.sleep(forTimeInterval: 0.5)

        // Now tap the list button to show bookmarks (toggle to bookmarks view)
        let listButton = findElement(ScreenIdentifiers.Player.buttonChapters)
        if listButton.exists {
            listButton.tap()
            Thread.sleep(forTimeInterval: 0.5)

            // If we're showing chapters, tap again to switch to bookmarks
            // The list button cycles between the two
            listButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }

        takeScreenshot("11-player-bookmarks")
        app.dismissSheet()
    }

    func test12_PlayerControls() throws {
        // Import book and start playback
        relaunchWithState(.withBooks)
        confirmImportDialogIfPresent(timeout: 5)
        app.navigateToTab(.library)

        guard waitForBooksInLibrary(timeout: 10) else {
            throw XCTSkip("No books in library")
        }

        // Start playing to open player
        startPlayback()
        Thread.sleep(forTimeInterval: 1.0)

        let speedButton = findElement(ScreenIdentifiers.Player.buttonSpeed)
        guard speedButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("Speed button not found - player may not be open")
        }

        speedButton.tap()
        Thread.sleep(forTimeInterval: 0.5)

        takeScreenshot("12-player-controls")
        app.dismissSheet()
    }

    func test13_PlayerSleepTimer() throws {
        // Import book and start playback
        relaunchWithState(.withBooks)
        confirmImportDialogIfPresent(timeout: 5)
        app.navigateToTab(.library)

        guard waitForBooksInLibrary(timeout: 10) else {
            throw XCTSkip("No books in library")
        }

        // Start playing to open player
        startPlayback()
        Thread.sleep(forTimeInterval: 1.0)

        let sleepButton = findElement(ScreenIdentifiers.Player.buttonSleep)
        guard sleepButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("Sleep button not found - player may not be open")
        }

        sleepButton.tap()

        // Sleep timer shows as an action sheet
        let actionSheet = app.sheets.firstMatch
        _ = actionSheet.waitForExistence(timeout: 3)

        takeScreenshot("13-player-sleep-timer")

        // Dismiss the action sheet
        let cancelButton = actionSheet.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()
        } else {
            app.tap() // Tap outside to dismiss
        }
    }

    // MARK: - Profile Tab Screenshots (Squabble)
    //
    // These tests capture various profile states.
    // Use launch arguments to control state:
    // - Default: Not logged in
    // - --logged-in: Logged in but no guild
    // - --with-guild: Has a guild with members

    func test14_ProfileNotLoggedIn() throws {
        // Relaunch fresh to ensure not logged in state
        relaunchWithState(.fresh)
        dismissImportDialogIfPresent()
        app.navigateToTab(.profile)

        let notLoggedInView = findElement(ScreenIdentifiers.Profile.stateNotLoggedIn)
        guard notLoggedInView.waitForExistence(timeout: 5) else {
            throw XCTSkip("User appears to be logged in already")
        }

        takeScreenshot("14-profile-not-logged-in")
    }

    func test15_ProfileLoginSheet() throws {
        // Relaunch fresh to ensure not logged in state
        relaunchWithState(.fresh)
        dismissImportDialogIfPresent()
        app.navigateToTab(.profile)

        // Use button label instead of identifier (SwiftUI parent identifiers can override)
        let signInButton = app.buttons["Sign In / Sign Up"]
        guard signInButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("Sign in button not found")
        }

        signInButton.tap()
        Thread.sleep(forTimeInterval: 0.5)

        takeScreenshot("15-profile-login-sheet")
        app.dismissSheet()
    }

    func test16_ProfileNoGuild() throws {
        // Relaunch with logged-in state (no guild)
        relaunchWithState(.loggedIn)
        dismissImportDialogIfPresent()
        app.navigateToTab(.profile)

        let noGuildView = findElement(ScreenIdentifiers.Profile.stateNoGuild)
        guard noGuildView.waitForExistence(timeout: 5) else {
            throw XCTSkip("User is not in no-guild state")
        }

        takeScreenshot("16-profile-no-guild")
    }

    func test17_GuildCreateSheet() throws {
        // Relaunch with logged-in state (no guild)
        relaunchWithState(.loggedIn)
        dismissImportDialogIfPresent()
        app.navigateToTab(.profile)

        // Use button label instead of identifier (SwiftUI parent identifiers can override)
        let createButton = app.buttons["Create Guild"]
        guard createButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("Create guild button not found")
        }

        createButton.tap()
        Thread.sleep(forTimeInterval: 0.5)

        takeScreenshot("17-guild-create-sheet")
        app.dismissSheet()
    }

    func test18_GuildJoinSheet() throws {
        // Relaunch with logged-in state (no guild)
        relaunchWithState(.loggedIn)
        dismissImportDialogIfPresent()
        app.navigateToTab(.profile)

        // Use button label instead of identifier (SwiftUI parent identifiers can override)
        let joinButton = app.buttons["Join with Code"]
        guard joinButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("Join guild button not found")
        }

        joinButton.tap()
        Thread.sleep(forTimeInterval: 0.5)

        takeScreenshot("18-guild-join-sheet")
        app.dismissSheet()
    }

    func test19_GuildView() throws {
        // Relaunch with guild state
        relaunchWithState(.withGuild)
        dismissImportDialogIfPresent()
        app.navigateToTab(.profile)

        let guildView = findElement(ScreenIdentifiers.Profile.stateGuild)
        guard guildView.waitForExistence(timeout: 5) else {
            throw XCTSkip("User is not in a guild")
        }

        takeScreenshot("19-guild-view")
    }

    func test20_GuildInviteCode() throws {
        // Relaunch with guild state
        relaunchWithState(.withGuild)
        dismissImportDialogIfPresent()
        app.navigateToTab(.profile)

        let inviteButton = findElement(ScreenIdentifiers.Guild.buttonInvite)
        guard inviteButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("Invite button not found")
        }

        inviteButton.tap()

        let inviteSheet = findElement(ScreenIdentifiers.Guild.sheetInviteCode)
        _ = inviteSheet.waitForExistence(timeout: 3)

        takeScreenshot("20-guild-invite-code")
        app.dismissSheet()
    }

    // MARK: - Settings Tab Screenshots

    func test21_SettingsMain() throws {
        dismissImportDialogIfPresent()
        app.navigateToTab(.settings)

        let settingsView = findElement(ScreenIdentifiers.Settings.viewMain)
        _ = settingsView.waitForExistence(timeout: 3)

        takeScreenshot("21-settings-main")
    }

    func test22_SettingsThemes() throws {
        dismissImportDialogIfPresent()
        app.navigateToSettingsScreenByLabel("Theme")

        Thread.sleep(forTimeInterval: 0.5)
        takeScreenshot("22-settings-themes")
        app.navigateBack()
    }

    func test23_SettingsIcons() throws {
        dismissImportDialogIfPresent()
        app.navigateToSettingsScreenByLabel("App Icon")

        Thread.sleep(forTimeInterval: 0.5)
        takeScreenshot("23-settings-icons")
        app.navigateBack()
    }

    func test24_SettingsControls() throws {
        dismissImportDialogIfPresent()
        app.navigateToSettingsScreenByLabel("Player Controls")

        Thread.sleep(forTimeInterval: 0.5)
        takeScreenshot("24-settings-controls")
        app.navigateBack()
    }

    func test25_SettingsStorage() throws {
        dismissImportDialogIfPresent()
        app.navigateToSettingsScreenByLabel("Manage your files")

        Thread.sleep(forTimeInterval: 0.5)
        takeScreenshot("25-settings-storage")
        app.navigateBack()
    }

    func test26_SettingsIntegrations() throws {
        dismissImportDialogIfPresent()
        // Integrations section contains Jellyfin - tap that to show integrations
        app.navigateToSettingsScreenByLabel("Jellyfin")

        Thread.sleep(forTimeInterval: 0.5)
        takeScreenshot("26-settings-integrations")
        app.navigateBack()
    }

    func test27_SettingsHardcover() throws {
        dismissImportDialogIfPresent()
        app.navigateToSettingsScreenByLabel("Hardcover")

        Thread.sleep(forTimeInterval: 0.5)
        takeScreenshot("27-settings-hardcover")
        app.navigateBack()
    }

    func test28_SettingsDebug() throws {
        dismissImportDialogIfPresent()
        app.navigateToSettingsScreenByLabel("Squabble Debug")

        Thread.sleep(forTimeInterval: 0.5)
        takeScreenshot("28-settings-debug")
        app.navigateBack()
    }

    // MARK: - Player Comment Screenshots (Squabble)

    func test30_PlayerCommentInput() throws {
        // Launch with guild state (includes mock auth + guild)
        relaunchWithState(.withGuild)
        confirmImportDialogIfPresent(timeout: 5)
        app.navigateToTab(.library)

        guard waitForBooksInLibrary(timeout: 10) else {
            throw XCTSkip("No books in library - withGuild state should include books")
        }

        // Start playing to open player
        startPlayback()
        Thread.sleep(forTimeInterval: 1.0)

        // Find and tap the "Add Comment" button
        let addCommentButton = app.buttons[ScreenIdentifiers.Player.buttonAddComment]
        guard addCommentButton.waitForExistence(timeout: 3) else {
            // Button may not appear if auth/guild not properly mocked
            throw XCTSkip("Add Comment button not found - need guild membership")
        }

        addCommentButton.tap()
        Thread.sleep(forTimeInterval: 0.5)

        // Wait for comment input sheet to appear
        let commentSheet = app.otherElements[ScreenIdentifiers.PlayerComment.sheetInput]
        _ = commentSheet.waitForExistence(timeout: 2)

        takeScreenshot("30-player-comment-input")

        // Dismiss the sheet
        app.dismissSheet()
    }
}
