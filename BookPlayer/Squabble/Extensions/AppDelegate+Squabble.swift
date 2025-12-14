//
//  AppDelegate+Squabble.swift
//  BookPlayer
//
//  Created for Squabble - Social Audiobook Features
//
//  This extension provides Squabble initialization for AppDelegate.
//  Call setupSquabble() after Firebase is configured.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore

extension AppDelegate {

    /// Initialize all Squabble features.
    /// Call this after FirebaseApp.configure() in didFinishLaunchingWithOptions.
    func setupSquabble() {
        // Check for UI test mode first
        NSLog("[Squabble] setupSquabble called, isUITesting=%@, useEmulator=%@",
              isUITesting ? "true" : "false",
              useEmulator ? "true" : "false")
        NSLog("[Squabble] CommandLine.arguments: %@", CommandLine.arguments.joined(separator: ", "))

        // Configure Firebase emulators for integration testing
        if useEmulator {
            setupFirebaseEmulators()
        }

        if isUITesting {
            setupUITestMode()
        }

        // Copy test audiobook for integration tests (emulator mode)
        // This is separate from UI test mode which uses mocks
        if useEmulator && isWithBooksTest {
            copyTestAudiobookToDocuments()
        }

        SquabbleManager.shared.setup()
    }

    /// Configure Firebase to use local emulators for integration testing.
    /// Requires emulators running: `firebase emulators:start --only auth,firestore`
    private func setupFirebaseEmulators() {
        NSLog("[Squabble] Configuring Firebase emulators...")

        // Configure Auth emulator
        Auth.auth().useEmulator(withHost: "127.0.0.1", port: 9099)
        NSLog("[Squabble] Auth emulator configured at 127.0.0.1:9099")

        // Configure Firestore emulator
        let settings = Firestore.firestore().settings
        settings.host = "127.0.0.1:8080"
        settings.cacheSettings = MemoryCacheSettings()
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings
        NSLog("[Squabble] Firestore emulator configured at 127.0.0.1:8080")
    }

    // MARK: - UI Test Mode Helpers

    private var isUITesting: Bool {
        CommandLine.arguments.contains("--uitesting")
    }

    private var useEmulator: Bool {
        CommandLine.arguments.contains("--use-emulator")
    }

    private var isLoggedInTest: Bool {
        CommandLine.arguments.contains("--logged-in")
    }

    private var isWithGuildTest: Bool {
        CommandLine.arguments.contains("--with-guild")
    }

    private var isWithFriendsTest: Bool {
        CommandLine.arguments.contains("--with-friends")
    }

    private var isWithBooksTest: Bool {
        CommandLine.arguments.contains("--with-books")
    }

    private var isWithPlayerTest: Bool {
        CommandLine.arguments.contains("--with-player")
    }

    private var disableAnimationsTest: Bool {
        CommandLine.arguments.contains("--disable-animations")
    }

    /// Configure the app for UI testing with mock data
    private func setupUITestMode() {
        NSLog("[UITestMode] Running in UI test mode")

        // Disable animations for faster tests
        if disableAnimationsTest {
            UIView.setAnimationsEnabled(false)
            NSLog("[UITestMode] Animations disabled")
        }

        // Mock user data
        let mockUserId = "uitest-user-001"
        let mockUserEmail = "testuser@squabble.dev"
        let mockUserDisplayName = "Test User"

        // Configure mock Squabble state based on launch arguments
        NSLog("[UITestMode] isLoggedInTest=%@, isWithGuildTest=%@, isWithFriendsTest=%@, isWithBooksTest=%@",
              isLoggedInTest ? "true" : "false",
              isWithGuildTest ? "true" : "false",
              isWithFriendsTest ? "true" : "false",
              isWithBooksTest ? "true" : "false")

        if isLoggedInTest || isWithGuildTest || isWithFriendsTest {
            SquabbleAuthService.shared.setUITestState(
                userId: mockUserId,
                email: mockUserEmail,
                displayName: mockUserDisplayName
            )
            NSLog("[UITestMode] Mock auth state configured")
        }

        if isWithGuildTest || isWithFriendsTest {
            let mockMembers = [
                GuildMember(id: mockUserId, displayName: mockUserDisplayName, email: mockUserEmail, role: .owner, joinedAt: Date()),
                GuildMember(id: "uitest-alice-002", displayName: "Alice", email: "alice@test.com", role: .member, joinedAt: Date()),
                GuildMember(id: "uitest-bob-003", displayName: "Bob", email: "bob@test.com", role: .member, joinedAt: Date()),
                GuildMember(id: "uitest-charlie-004", displayName: "Charlie", email: "charlie@test.com", role: .member, joinedAt: Date()),
                GuildMember(id: "uitest-diana-005", displayName: "Diana", email: "diana@test.com", role: .member, joinedAt: Date()),
            ]

            GuildService.shared.setUITestState(
                guildId: "uitest-guild-001",
                guildName: "Test Guild",
                inviteCode: "TEST123",
                members: mockMembers
            )
            NSLog("[UITestMode] Mock guild state configured with %d members", mockMembers.count)
        }

        // Copy test audiobook to Documents folder
        if isWithBooksTest || isWithPlayerTest {
            copyTestAudiobookToDocuments()
        }
    }

    /// Copy the bundled test audiobook to the Inbox folder for UI testing.
    /// BookPlayer will automatically detect and import files from the Inbox folder.
    private func copyTestAudiobookToDocuments() {
        NSLog("[UITestMode] copyTestAudiobookToDocuments called")

        guard let sourceURL = Bundle.main.url(forResource: "test_audiobook", withExtension: "mp3") else {
            NSLog("[UITestMode] Warning: test_audiobook.mp3 not found in bundle")
            return
        }

        NSLog("[UITestMode] Found test_audiobook.mp3 at: %@", sourceURL.path)

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        // Copy to Inbox folder - BookPlayer watches this for imports
        let inboxURL = documentsURL.appendingPathComponent("Inbox")

        // Create Inbox folder if it doesn't exist
        try? FileManager.default.createDirectory(at: inboxURL, withIntermediateDirectories: true)

        let destinationURL = inboxURL.appendingPathComponent("Test Audiobook.mp3")

        // Remove existing file if present
        try? FileManager.default.removeItem(at: destinationURL)

        do {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            NSLog("[UITestMode] Copied test audiobook to Inbox: %@", destinationURL.path)
        } catch {
            NSLog("[UITestMode] Failed to copy test audiobook: %@", error.localizedDescription)
        }
    }
}
