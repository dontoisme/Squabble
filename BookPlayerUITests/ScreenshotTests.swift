//
//  ScreenshotTests.swift
//  BookPlayerUITests
//
//  Automated screenshot capture for app timelapse documentation.
//  Run with: ./scripts/capture-screenshots.sh
//

import XCTest

final class ScreenshotTests: BookPlayerUITests {

    // MARK: - Library Tab Screenshots

    func test01_LibraryEmpty() throws {
        app.navigateToTab(.library)

        // Wait for empty view or list to appear
        let emptyView = app.otherElements[ScreenIdentifiers.Library.viewEmpty]
        let listView = app.collectionViews[ScreenIdentifiers.Library.listItems]

        _ = emptyView.waitForExistence(timeout: 3) || listView.waitForExistence(timeout: 3)

        takeScreenshot("01-library-empty")
    }

    func test02_LibraryWithBooks() throws {
        // This test requires books to be present
        // Skip if library is empty
        app.navigateToTab(.library)

        let listView = app.collectionViews[ScreenIdentifiers.Library.listItems]
        guard listView.waitForExistence(timeout: 3), listView.cells.count > 0 else {
            throw XCTSkip("No books in library - skipping screenshot")
        }

        takeScreenshot("02-library-with-books")
    }

    func test03_LibraryFolder() throws {
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
        app.navigateToTab(.library)

        // Activate search
        let searchField = app.searchFields.firstMatch
        if searchField.waitForExistence(timeout: 3) {
            searchField.tap()
            takeScreenshot("04-library-search")
            // Dismiss keyboard
            app.keyboards.buttons["Cancel"].tap()
        } else {
            throw XCTSkip("Search field not found")
        }
    }

    func test05_LibraryMiniPlayer() throws {
        app.navigateToTab(.library)

        let miniPlayer = app.otherElements[ScreenIdentifiers.Library.miniPlayer]
        guard miniPlayer.waitForExistence(timeout: 3) else {
            throw XCTSkip("Mini player not visible - no book playing")
        }

        takeScreenshot("05-library-miniplayer")
    }

    // MARK: - Player Screenshots

    func test09_PlayerMain() throws {
        // Open full player from mini player
        app.navigateToTab(.library)

        let miniPlayer = app.otherElements[ScreenIdentifiers.Library.miniPlayer]
        guard miniPlayer.waitForExistence(timeout: 3) else {
            throw XCTSkip("Mini player not visible - cannot open player")
        }

        miniPlayer.tap()

        let playerView = app.otherElements[ScreenIdentifiers.Player.viewMain]
        _ = playerView.waitForExistence(timeout: 3)

        takeScreenshot("09-player-main")
    }

    func test10_PlayerChapters() throws {
        // Assumes player is open from previous test
        let chaptersButton = app.buttons[ScreenIdentifiers.Player.buttonChapters]
        guard chaptersButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("Chapters button not found")
        }

        chaptersButton.tap()

        let chaptersView = app.otherElements[ScreenIdentifiers.PlayerChapters.viewMain]
        _ = chaptersView.waitForExistence(timeout: 3)

        takeScreenshot("10-player-chapters")
        app.dismissSheet()
    }

    func test11_PlayerBookmarks() throws {
        let bookmarksButton = app.buttons[ScreenIdentifiers.Player.buttonBookmarks]
        guard bookmarksButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("Bookmarks button not found")
        }

        bookmarksButton.tap()

        let bookmarksView = app.otherElements[ScreenIdentifiers.PlayerBookmarks.viewMain]
        _ = bookmarksView.waitForExistence(timeout: 3)

        takeScreenshot("11-player-bookmarks")
        app.dismissSheet()
    }

    // MARK: - Profile Tab Screenshots (Squabble)

    func test14_ProfileNotLoggedIn() throws {
        app.navigateToTab(.profile)

        let notLoggedInView = app.otherElements[ScreenIdentifiers.Profile.stateNotLoggedIn]
        guard notLoggedInView.waitForExistence(timeout: 5) else {
            // User might already be logged in
            throw XCTSkip("User appears to be logged in already")
        }

        takeScreenshot("14-profile-not-logged-in")
    }

    func test15_ProfileLoginSheet() throws {
        app.navigateToTab(.profile)

        let signInButton = app.buttons[ScreenIdentifiers.Profile.buttonSignIn]
        guard signInButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("Sign in button not found")
        }

        signInButton.tap()
        Thread.sleep(forTimeInterval: 0.5)

        takeScreenshot("15-profile-login-sheet")
        app.dismissSheet()
    }

    func test16_ProfileNoGuild() throws {
        app.navigateToTab(.profile)

        let noGuildView = app.otherElements[ScreenIdentifiers.Profile.stateNoGuild]
        guard noGuildView.waitForExistence(timeout: 5) else {
            throw XCTSkip("User is not in no-guild state")
        }

        takeScreenshot("16-profile-no-guild")
    }

    func test17_GuildCreateSheet() throws {
        app.navigateToTab(.profile)

        let createButton = app.buttons[ScreenIdentifiers.Profile.buttonCreateGuild]
        guard createButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("Create guild button not found")
        }

        createButton.tap()

        let createSheet = app.otherElements[ScreenIdentifiers.Guild.sheetCreate]
        _ = createSheet.waitForExistence(timeout: 3)

        takeScreenshot("17-guild-create-sheet")
        app.dismissSheet()
    }

    func test18_GuildJoinSheet() throws {
        app.navigateToTab(.profile)

        let joinButton = app.buttons[ScreenIdentifiers.Profile.buttonJoinGuild]
        guard joinButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("Join guild button not found")
        }

        joinButton.tap()

        let joinSheet = app.otherElements[ScreenIdentifiers.Guild.sheetJoin]
        _ = joinSheet.waitForExistence(timeout: 3)

        takeScreenshot("18-guild-join-sheet")
        app.dismissSheet()
    }

    func test19_GuildView() throws {
        app.navigateToTab(.profile)

        let guildView = app.otherElements[ScreenIdentifiers.Profile.stateGuild]
        guard guildView.waitForExistence(timeout: 5) else {
            throw XCTSkip("User is not in a guild")
        }

        takeScreenshot("19-guild-view")
    }

    func test20_GuildInviteCode() throws {
        app.navigateToTab(.profile)

        let inviteButton = app.buttons[ScreenIdentifiers.Guild.buttonInvite]
        guard inviteButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("Invite button not found")
        }

        inviteButton.tap()

        let inviteSheet = app.otherElements[ScreenIdentifiers.Guild.sheetInviteCode]
        _ = inviteSheet.waitForExistence(timeout: 3)

        takeScreenshot("20-guild-invite-code")
        app.dismissSheet()
    }

    // MARK: - Settings Tab Screenshots

    func test21_SettingsMain() throws {
        app.navigateToTab(.settings)

        let settingsView = app.otherElements[ScreenIdentifiers.Settings.viewMain]
        _ = settingsView.waitForExistence(timeout: 3)

        takeScreenshot("21-settings-main")
    }

    func test22_SettingsThemes() throws {
        app.navigateToSettingsScreen(ScreenIdentifiers.Settings.rowThemes)

        let themesView = app.otherElements[ScreenIdentifiers.SettingsThemes.viewMain]
        _ = themesView.waitForExistence(timeout: 3)

        takeScreenshot("22-settings-themes")
        app.navigateBack()
    }

    func test23_SettingsIcons() throws {
        app.navigateToSettingsScreen(ScreenIdentifiers.Settings.rowIcons)

        let iconsView = app.otherElements[ScreenIdentifiers.SettingsIcons.viewMain]
        _ = iconsView.waitForExistence(timeout: 3)

        takeScreenshot("23-settings-icons")
        app.navigateBack()
    }

    func test24_SettingsControls() throws {
        app.navigateToSettingsScreen(ScreenIdentifiers.Settings.rowControls)

        let controlsView = app.otherElements[ScreenIdentifiers.PlayerControls.viewMain]
        _ = controlsView.waitForExistence(timeout: 3)

        takeScreenshot("24-settings-controls")
        app.navigateBack()
    }

    func test25_SettingsStorage() throws {
        app.navigateToSettingsScreen(ScreenIdentifiers.Settings.rowStorage)

        let storageView = app.otherElements[ScreenIdentifiers.SettingsStorage.viewMain]
        _ = storageView.waitForExistence(timeout: 3)

        takeScreenshot("25-settings-storage")
        app.navigateBack()
    }

    func test27_SettingsHardcover() throws {
        app.navigateToSettingsScreen(ScreenIdentifiers.Settings.rowHardcover)

        Thread.sleep(forTimeInterval: 0.5)
        takeScreenshot("27-settings-hardcover")
        app.navigateBack()
    }

    func test28_SettingsDebug() throws {
        app.navigateToSettingsScreen(ScreenIdentifiers.Settings.rowDebug)

        Thread.sleep(forTimeInterval: 0.5)
        takeScreenshot("28-settings-debug")
        app.navigateBack()
    }
}
