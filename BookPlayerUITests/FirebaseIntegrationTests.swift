//
//  FirebaseIntegrationTests.swift
//  BookPlayerUITests
//
//  Base class for integration tests that use Firebase emulators.
//  These tests exercise real Firebase flows (not mocks) for:
//  - User signup/signin
//  - Guild creation and Firestore writes
//  - Joining guilds via invite code
//  - Progress sync
//
//  PREREQUISITES:
//  1. Start Firebase emulators: firebase emulators:start --only auth,firestore
//  2. Emulators must be running on:
//     - Auth: http://127.0.0.1:9099
//     - Firestore: http://127.0.0.1:8080
//

import XCTest

class FirebaseIntegrationTests: XCTestCase {

    var app: XCUIApplication!

    /// Unique test run ID for isolating test data
    var testRunId: String!

    override func setUpWithError() throws {
        continueAfterFailure = false

        // Generate unique ID for this test run to avoid data collisions
        testRunId = UUID().uuidString.prefix(8).lowercased()

        app = XCUIApplication()

        // Configure for emulator mode - NOT UI test mode
        // This means we use real Firebase (pointed at emulators) instead of mocks
        app.launchArguments = [
            "--use-emulator",        // Connect to local Firebase emulators
            "--squabble-enabled",    // Force Squabble features on
            "--disable-animations"   // Speed up tests
        ]

        app.launchEnvironment["INTEGRATION_TEST"] = "1"
        app.launchEnvironment["TEST_RUN_ID"] = testRunId

        // Verify emulators are running before starting tests
        try verifyEmulatorsRunning()

        app.launch()

        // Ensure we start each test signed out for isolation
        ensureSignedOut()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    /// Sign out if currently logged in to ensure test isolation
    private func ensureSignedOut() {
        // Go to profile tab
        app.navigateToTab(.profile)

        // If we see "Sign In / Sign Up" button, we're already signed out
        let signInButton = app.buttons["Sign In / Sign Up"]
        if signInButton.waitForExistence(timeout: 3) {
            return // Already signed out
        }

        // Otherwise, look for Sign Out button (on no-guild or guild screen)
        // On the guild screen, Sign Out may be at bottom of Form requiring scroll
        var signOutButton = app.buttons["Sign Out"]

        // Try scrolling down if Sign Out isn't immediately visible
        if !signOutButton.waitForExistence(timeout: 2) {
            app.swipeUp()
            sleep(1)
        }

        signOutButton = app.buttons["Sign Out"]
        if signOutButton.waitForExistence(timeout: 3) {
            signOutButton.tap()

            // Confirm sign out - it's a confirmationDialog (action sheet)
            let confirmButton = app.sheets.buttons["Sign Out"]
            if confirmButton.waitForExistence(timeout: 3) {
                confirmButton.tap()
            }

            // Wait for sign out to complete
            _ = signInButton.waitForExistence(timeout: 5)
        }
    }

    // MARK: - Emulator Verification

    /// Verify Firebase emulators are running before tests start
    private func verifyEmulatorsRunning() throws {
        // Check Auth emulator
        let authURL = URL(string: "http://127.0.0.1:9099/")!
        let authReachable = isURLReachable(authURL)

        // Check Firestore emulator
        let firestoreURL = URL(string: "http://127.0.0.1:8080/")!
        let firestoreReachable = isURLReachable(firestoreURL)

        if !authReachable || !firestoreReachable {
            throw XCTSkip("""
                Firebase emulators not running. Start them with:
                firebase emulators:start --only auth,firestore

                Expected:
                - Auth at http://127.0.0.1:9099 (reachable: \(authReachable))
                - Firestore at http://127.0.0.1:8080 (reachable: \(firestoreReachable))
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

    // MARK: - Test Helpers

    /// Generate a unique test email for this test run
    func testEmail(prefix: String = "test") -> String {
        "\(prefix)_\(testRunId)@test.squabble.dev"
    }

    /// Standard test password
    var testPassword: String {
        "TestPass123!"
    }

    /// Quick access to tab bar
    var tabBar: XCUIElement {
        app.tabBars.firstMatch
    }

    /// Navigate to Profile tab
    func goToProfileTab() {
        app.navigateToTab(.profile)
    }

    /// Find element by accessibility identifier
    func findElement(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    /// Wait for element and tap it
    func tapWhenReady(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        if element.waitForExistence(timeout: timeout) {
            element.tap()
            return true
        }
        return false
    }

    /// Type text into a text field, clearing it first
    func typeInField(_ element: XCUIElement, text: String) {
        element.tap()
        // Clear existing text
        if let currentValue = element.value as? String, !currentValue.isEmpty {
            element.tap()
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
            element.typeText(deleteString)
        }
        element.typeText(text)
    }

    /// Dismiss keyboard if visible
    func dismissKeyboard() {
        if app.keyboards.count > 0 {
            app.toolbars.buttons["Done"].tap()
        }
    }
}

// MARK: - Auth Flow Helpers

extension FirebaseIntegrationTests {

    /// Sign up a new user via the UI
    func signUpNewUser(email: String, password: String) throws {
        goToProfileTab()

        // Wait for sign-in prompt (use label since identifiers inherit from parent)
        let signInButton = app.buttons["Sign In / Sign Up"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 10), "Sign in button should appear")
        signInButton.tap()

        // Switch to sign up mode
        let signUpToggle = app.buttons["Don't have an account? Sign Up"]
        if signUpToggle.waitForExistence(timeout: 5) {
            signUpToggle.tap()
        }

        // Fill in credentials
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5), "Email field should appear")
        typeInField(emailField, text: email)

        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordField.exists, "Password field should exist")
        typeInField(passwordField, text: password)

        // Submit (button text is "Create Account" in sign up mode)
        let submitButton = app.buttons["Create Account"]
        XCTAssertTrue(submitButton.exists, "Create Account button should exist")
        submitButton.tap()
    }

    /// Sign in an existing user via the UI
    func signInUser(email: String, password: String) throws {
        goToProfileTab()

        let signInButton = app.buttons["Sign In / Sign Up"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 10), "Sign in button should appear")
        signInButton.tap()

        // Fill in credentials (default mode is sign in)
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5), "Email field should appear")
        typeInField(emailField, text: email)

        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordField.exists, "Password field should exist")
        typeInField(passwordField, text: password)

        // Submit (button text is "Sign In" in sign in mode)
        let submitButton = app.buttons["Sign In"]
        XCTAssertTrue(submitButton.exists, "Sign In button should exist")
        submitButton.tap()
    }

    /// Sign out the current user
    func signOut() {
        // Navigate to settings or wherever sign out is
        // Implementation depends on where sign out button is located
    }
}

// MARK: - Guild Flow Helpers

extension FirebaseIntegrationTests {

    /// Create a new guild via the UI
    func createGuild(name: String) throws {
        // Use button label (includes icon text)
        let createButton = app.buttons["Create Guild"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 10), "Create guild button should appear")
        createButton.tap()

        // CreateGuildView should appear as a sheet
        let nameField = app.textFields["Guild Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "Guild name field should appear")
        typeInField(nameField, text: name)

        let submitButton = app.buttons["Create"]
        submitButton.tap()
    }

    /// Join a guild via invite code
    func joinGuild(inviteCode: String) throws {
        let joinButton = app.buttons["Join with Code"]
        XCTAssertTrue(joinButton.waitForExistence(timeout: 10), "Join guild button should appear")
        joinButton.tap()

        // JoinGuildView should appear as a sheet
        let codeField = app.textFields["Invite Code"]
        XCTAssertTrue(codeField.waitForExistence(timeout: 5), "Invite code field should appear")
        typeInField(codeField, text: inviteCode)

        let submitButton = app.buttons["Join"]
        submitButton.tap()
    }
}
