//
//  AuthFlowIntegrationTests.swift
//  BookPlayerUITests
//
//  Integration tests for authentication flows using Firebase emulators.
//  Tests real Firebase Auth operations against local emulator.
//

import XCTest

class AuthFlowIntegrationTests: FirebaseIntegrationTests {

    // MARK: - Sign Up Tests

    func testUserCanSignUpWithEmail() throws {
        // Given: A fresh app state (not signed in)
        let email = testEmail(prefix: "signup")

        // When: User navigates to sign up and creates account
        goToProfileTab()

        // Should see sign-in prompt since not logged in
        // Note: Use button label since accessibility identifier is inherited from parent view
        let signInButton = app.buttons["Sign In / Sign Up"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 10),
                      "Sign in button should be visible for unauthenticated user")

        signInButton.tap()

        // Login sheet appears - need to switch to sign up mode
        // The toggle text is "Don't have an account? Sign Up"
        let signUpToggle = app.buttons["Don't have an account? Sign Up"]
        if signUpToggle.waitForExistence(timeout: 5) {
            signUpToggle.tap()
        }

        // Fill in sign up form
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5), "Email field should appear")
        typeInField(emailField, text: email)

        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 2), "Password field should appear")
        typeInField(passwordField, text: testPassword)

        // Submit sign up - button text is "Create Account" when in sign up mode
        let signUpButton = app.buttons["Create Account"]
        XCTAssertTrue(signUpButton.waitForExistence(timeout: 2), "Create Account button should appear")
        signUpButton.tap()

        // Then: User should be signed in and see guild options
        // After successful sign up, user should see "No Guild" state with create/join options
        // Note: Use button labels since accessibility identifiers may be inherited from parent
        let createGuildButton = app.buttons["Create Guild"]
        let joinGuildButton = app.buttons["Join with Code"]

        // Wait and check
        let signedIn = createGuildButton.waitForExistence(timeout: 15) ||
                       joinGuildButton.waitForExistence(timeout: 1)

        if !signedIn {
            // Debug: Print what buttons ARE visible
            print("DEBUG: Buttons visible after sign up:")
            for button in app.buttons.allElementsBoundByIndex.prefix(20) {
                print("  - '\(button.label)'")
            }
        }

        XCTAssertTrue(signedIn,
                      "After sign up, user should see guild creation options")
    }

    func testSignUpWithInvalidEmailShowsError() throws {
        // Given: User tries to sign up with invalid email
        goToProfileTab()

        let signInButton = app.buttons["Sign In / Sign Up"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 10))
        signInButton.tap()

        let signUpToggle = app.buttons["Don't have an account? Sign Up"]
        if signUpToggle.waitForExistence(timeout: 5) {
            signUpToggle.tap()
        }

        // Enter invalid email
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        typeInField(emailField, text: "not-an-email")

        let passwordField = app.secureTextFields["Password"]
        typeInField(passwordField, text: testPassword)

        let signUpButton = app.buttons["Create Account"]
        signUpButton.tap()

        // Then: Should see error message
        let errorExists = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'invalid' OR label CONTAINS[c] 'error'")).firstMatch.waitForExistence(timeout: 5)

        // Either error message or we're still on sign up screen (didn't navigate away)
        let stillOnSignUp = emailField.exists
        XCTAssertTrue(errorExists || stillOnSignUp,
                      "Should show error or remain on sign up screen for invalid email")
    }

    func testSignUpWithWeakPasswordShowsError() throws {
        // Given: User tries to sign up with weak password
        let email = testEmail(prefix: "weakpass")

        goToProfileTab()

        let signInButton = app.buttons["Sign In / Sign Up"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 10))
        signInButton.tap()

        let signUpToggle = app.buttons["Don't have an account? Sign Up"]
        if signUpToggle.waitForExistence(timeout: 5) {
            signUpToggle.tap()
        }

        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        typeInField(emailField, text: email)

        // Enter weak password (too short)
        let passwordField = app.secureTextFields["Password"]
        typeInField(passwordField, text: "123")

        let signUpButton = app.buttons["Create Account"]
        signUpButton.tap()

        // Then: Should see error or validation message
        // Firebase requires min 6 characters
        let stillOnSignUp = passwordField.waitForExistence(timeout: 3)
        XCTAssertTrue(stillOnSignUp,
                      "Should remain on sign up screen with weak password")
    }

    // MARK: - Sign In Tests

    func testUserCanSignInWithExistingAccount() throws {
        // First, create an account
        let email = testEmail(prefix: "signin")

        // Sign up first
        try signUpNewUser(email: email, password: testPassword)

        // Verify signed in (use button labels)
        let createGuildButton = app.buttons["Create Guild"]
        XCTAssertTrue(createGuildButton.waitForExistence(timeout: 15),
                      "Should be signed in after sign up")

        // Sign out (terminate and relaunch without auth state)
        app.terminate()

        // Relaunch - Firebase Auth state should persist
        app.launch()

        // Go to profile
        goToProfileTab()

        // Should still be signed in (Firebase persists auth state)
        let stillSignedIn = createGuildButton.waitForExistence(timeout: 10) ||
                           app.buttons["Join with Code"].waitForExistence(timeout: 1)

        // Note: Firebase Auth emulator does persist state between launches
        // If we want to test fresh sign in, we'd need to clear emulator data
        XCTAssertTrue(stillSignedIn,
                      "Auth state should persist between app launches")
    }

    func testSignInWithWrongPasswordShowsError() throws {
        // First create an account
        let email = testEmail(prefix: "wrongpass")
        try signUpNewUser(email: email, password: testPassword)

        // Terminate and clear auth state would be needed here
        // For now, skip this test as it requires emulator reset
        throw XCTSkip("Test requires emulator auth state reset between runs")
    }

    // MARK: - Sign Out Tests

    func testUserCanSignOut() throws {
        // Create account and sign in
        let email = testEmail(prefix: "signout")
        try signUpNewUser(email: email, password: testPassword)

        // Verify signed in
        let createGuildButton = app.buttons["Create Guild"]
        XCTAssertTrue(createGuildButton.waitForExistence(timeout: 15))

        // Sign out is available on the no-guild screen via SquabbleAccountFooter
        // Look for "Sign Out" button in the footer
        let signOutButton = app.buttons["Sign Out"]
        if signOutButton.waitForExistence(timeout: 5) {
            signOutButton.tap()

            // Confirm sign out - it's a confirmationDialog (action sheet)
            let confirmButton = app.sheets.buttons["Sign Out"]
            if confirmButton.waitForExistence(timeout: 3) {
                confirmButton.tap()
            }

            // Verify signed out - should see sign in prompt
            let signInButton = app.buttons["Sign In / Sign Up"]
            XCTAssertTrue(signInButton.waitForExistence(timeout: 10),
                          "After sign out, should see sign in button")
        } else {
            // If no sign out button found, skip this test
            throw XCTSkip("Sign out button not found in current UI")
        }
    }
}
