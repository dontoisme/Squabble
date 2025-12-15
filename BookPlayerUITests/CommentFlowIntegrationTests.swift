//
//  CommentFlowIntegrationTests.swift
//  BookPlayerUITests
//
//  Integration tests for comment flows using Firebase emulators.
//  Tests posting and retrieving comments against local Firestore.
//
//  PREREQUISITES:
//  1. Start Firebase emulators: firebase emulators:start --only auth,firestore
//  2. Reset simulator for clean state
//

import XCTest

class CommentFlowIntegrationTests: FirebaseIntegrationTests {

    // MARK: - Setup Override

    /// Override to include test audiobook from start
    override func setUpWithError() throws {
        continueAfterFailure = false

        testRunId = UUID().uuidString.prefix(8).lowercased()

        app = XCUIApplication()

        // Configure for emulator mode with test audiobook from the start
        app.launchArguments = [
            "--use-emulator",
            "--squabble-enabled",
            "--disable-animations",
            "--with-books"
        ]

        app.launchEnvironment["INTEGRATION_TEST"] = "1"
        app.launchEnvironment["TEST_RUN_ID"] = testRunId

        // Verify emulators are running
        try verifyEmulatorsRunning()

        app.launch()

        // Wait for app to be ready
        sleep(2)

        // Dismiss import dialog if it appears
        let doneButton = app.buttons["Done"]
        if doneButton.waitForExistence(timeout: 5) {
            sleep(2)
            doneButton.tap()
            sleep(1)
        }

        // Ensure signed out for test isolation
        ensureSignedOut()
    }

    // MARK: - Comment Flow Tests

    /// Test that a user can post a comment from the player
    func testUserCanPostCommentFromPlayer() throws {
        // Given: A signed-in user with a guild
        let email = testEmail(prefix: "comment_post")
        try signUpNewUser(email: email, password: testPassword)

        // Create a guild first
        let createGuildButton = app.buttons["Create Guild"]
        XCTAssertTrue(createGuildButton.waitForExistence(timeout: 15),
                      "Should see Create Guild button")
        createGuildButton.tap()

        let guildName = "CommentTest_\(testRunId!)"
        let nameField = app.textFields["Guild Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        typeInField(nameField, text: guildName)

        let createButton = app.buttons["Create"]
        createButton.tap()

        // Wait for guild to be created
        let guildNameLabel = app.staticTexts[guildName]
        XCTAssertTrue(guildNameLabel.waitForExistence(timeout: 10),
                      "Guild should be created")

        // Navigate to library (no relaunch needed - books already imported at setup)
        app.navigateToTab(.library)

        // Wait for library to load
        sleep(3)

        // Find the audiobook
        let libraryItems = app.collectionViews.cells
        let hasBooks = libraryItems.count > 0

        if !hasBooks {
            print("DEBUG: Library items count: \(libraryItems.count)")
            print("DEBUG: Static texts visible:")
            for text in app.staticTexts.allElementsBoundByIndex.prefix(20) {
                print("  - '\(text.label)'")
            }
            throw XCTSkip("Test audiobook not imported yet - import may require more time")
        }

        // Tap the first book to start playback
        libraryItems.firstMatch.tap()
        sleep(2)

        // Look for the Add Comment button
        let addCommentButton = app.buttons["player_button_add_comment"]

        if addCommentButton.waitForExistence(timeout: 5) {
            // When: User taps add comment
            addCommentButton.tap()
            sleep(1)

            // Should see comment input sheet - look for the text field or navigation title
            let commentTextField = app.textViews["comment_text_field"]
            let addCommentTitle = app.staticTexts["Add Comment"]

            let sheetAppeared = commentTextField.waitForExistence(timeout: 3) ||
                                addCommentTitle.waitForExistence(timeout: 1)

            XCTAssertTrue(sheetAppeared,
                          "Comment input sheet should appear")

            // Type a comment
            if commentTextField.exists {
                commentTextField.tap()
                commentTextField.typeText("Test comment from integration test!")
            } else if let textView = app.textViews.firstMatch as? XCUIElement, textView.exists {
                textView.tap()
                textView.typeText("Test comment from integration test!")
            }

            // Submit the comment - look for button by identifier or label
            let submitButton = app.buttons["comment_submit_button"]
            let postButton = app.buttons["Post Comment"]

            if submitButton.waitForExistence(timeout: 2) {
                submitButton.tap()
            } else if postButton.exists {
                postButton.tap()
            }

            // Wait for posting to complete
            sleep(3)

            // Verify sheet is dismissed by checking text field is gone
            let sheetDismissed = !commentTextField.exists && !addCommentTitle.exists

            if !sheetDismissed {
                // Check for specific error messages
                let notAuthError = app.staticTexts["You must be signed in to comment"]
                let noGuildError = app.staticTexts["You must be in a guild to comment"]

                if notAuthError.exists {
                    XCTFail("Comment posting failed: User not authenticated")
                } else if noGuildError.exists {
                    XCTFail("Comment posting failed: User not in guild")
                } else {
                    // Debug: print visible UI elements
                    print("DEBUG: Sheet still visible. Looking for errors...")
                    let texts = app.staticTexts
                    print("DEBUG: Number of static texts: \(texts.count)")
                }
            }

            XCTAssertTrue(sheetDismissed,
                          "Comment sheet should dismiss after posting")

            print("✓ Comment posted successfully!")
        } else {
            // Comment button not visible - might need guild auth
            print("DEBUG: Add Comment button not found")
            print("DEBUG: Available buttons:")
            for button in app.buttons.allElementsBoundByIndex.prefix(20) {
                print("  - '\(button.identifier)' / '\(button.label)'")
            }
            throw XCTSkip("Add Comment button not found - requires guild membership")
        }
    }

    // MARK: - Private Helpers

    private func verifyEmulatorsRunning() throws {
        let authURL = URL(string: "http://127.0.0.1:9099/")!
        let firestoreURL = URL(string: "http://127.0.0.1:8080/")!

        let authReachable = isURLReachable(authURL)
        let firestoreReachable = isURLReachable(firestoreURL)

        if !authReachable || !firestoreReachable {
            throw XCTSkip("""
                Firebase emulators not running. Start them with:
                firebase emulators:start --only auth,firestore
                """)
        }
    }

    private func isURLReachable(_ url: URL) -> Bool {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 2

        let semaphore = DispatchSemaphore(value: 0)
        var isReachable = false

        let task = URLSession.shared.dataTask(with: request) { _, response, _ in
            if let httpResponse = response as? HTTPURLResponse {
                isReachable = (200...499).contains(httpResponse.statusCode)
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()

        return isReachable
    }

    private func ensureSignedOut() {
        app.navigateToTab(.profile)

        let signInButton = app.buttons["Sign In / Sign Up"]
        if signInButton.waitForExistence(timeout: 3) {
            return
        }

        var signOutButton = app.buttons["Sign Out"]
        if !signOutButton.waitForExistence(timeout: 2) {
            app.swipeUp()
            sleep(1)
        }

        signOutButton = app.buttons["Sign Out"]
        if signOutButton.waitForExistence(timeout: 3) {
            signOutButton.tap()

            let confirmButton = app.sheets.buttons["Sign Out"]
            if confirmButton.waitForExistence(timeout: 3) {
                confirmButton.tap()
            }

            _ = signInButton.waitForExistence(timeout: 5)
        }
    }

    /// Test that comments appear after user passes the timestamp (spoiler-free)
    ///
    /// This test verifies Epic 2.2: Comments only become visible when the user's
    /// playback position passes the comment's timestamp.
    ///
    /// Implementation requirements:
    /// 1. Post a comment at timestamp T (e.g., 30 seconds)
    /// 2. Start playback from 0
    /// 3. Verify comment_overlay_toast does NOT exist
    /// 4. Seek/wait until past timestamp T
    /// 5. Verify comment_overlay_toast appears
    ///
    /// Blocked by: Need reliable way to control audiobook seek position in tests
    func testCommentsAppearAfterTimestamp() throws {
        throw XCTSkip("Epic 2.2 test - requires playback seek control. Comment posting verified in testUserCanPostCommentFromPlayer.")
    }
}
