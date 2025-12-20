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

    private var isFreshInstall: Bool {
        CommandLine.arguments.contains("--fresh-install")
    }

    /// Configure the app for UI testing with mock data
    private func setupUITestMode() {
        NSLog("[UITestMode] Running in UI test mode")

        // Clear all data for fresh install simulation
        if isFreshInstall {
            clearLibraryData()
        }

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

    /// Clear all library data for fresh install simulation.
    /// Removes files from Documents, Inbox, and Core Data database.
    private func clearLibraryData() {
        NSLog("[UITestMode] Clearing library data for fresh install...")

        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

        // Clear Inbox folder (pending imports)
        let inboxURL = documentsURL.appendingPathComponent("Inbox")
        if let contents = try? fileManager.contentsOfDirectory(at: inboxURL, includingPropertiesForKeys: nil) {
            for file in contents {
                try? fileManager.removeItem(at: file)
            }
            NSLog("[UITestMode] Cleared Inbox folder")
        }

        // Clear Processed folder (imported files)
        let processedURL = documentsURL.appendingPathComponent("Processed")
        if let contents = try? fileManager.contentsOfDirectory(at: processedURL, includingPropertiesForKeys: nil) {
            for file in contents {
                try? fileManager.removeItem(at: file)
            }
            NSLog("[UITestMode] Cleared Processed folder")
        }

        // Clear root Documents folder (audiobook files)
        if let contents = try? fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil) {
            for file in contents {
                // Skip folders we've already handled
                let filename = file.lastPathComponent
                if filename == "Inbox" || filename == "Processed" {
                    continue
                }
                // Remove audio files and folders (but not system files)
                let audioExtensions = ["mp3", "m4b", "m4a", "mp4", "aac", "wav", "flac"]
                if audioExtensions.contains(file.pathExtension.lowercased()) {
                    try? fileManager.removeItem(at: file)
                }
                // Also remove any folder that's not a system folder
                var isDirectory: ObjCBool = false
                if fileManager.fileExists(atPath: file.path, isDirectory: &isDirectory),
                   isDirectory.boolValue,
                   !filename.hasPrefix(".") {
                    try? fileManager.removeItem(at: file)
                }
            }
            NSLog("[UITestMode] Cleared Documents audio files and folders")
        }

        // Clear Core Data database from App Group container
        let appGroupId = "group.\(Bundle.main.bundleIdentifier ?? "com.tortugapower.audiobookplayer").files"
        if let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) {
            let sqliteURL = containerURL.appendingPathComponent("BookPlayer.sqlite")
            let walURL = containerURL.appendingPathComponent("BookPlayer.sqlite-wal")
            let shmURL = containerURL.appendingPathComponent("BookPlayer.sqlite-shm")

            try? fileManager.removeItem(at: sqliteURL)
            try? fileManager.removeItem(at: walURL)
            try? fileManager.removeItem(at: shmURL)
            NSLog("[UITestMode] Cleared Core Data database")

            // Also clear any audiobook files in the app group container
            if let contents = try? fileManager.contentsOfDirectory(at: containerURL, includingPropertiesForKeys: nil) {
                for file in contents {
                    let audioExtensions = ["mp3", "m4b", "m4a", "mp4", "aac", "wav", "flac"]
                    if audioExtensions.contains(file.pathExtension.lowercased()) {
                        try? fileManager.removeItem(at: file)
                    }
                }
            }
        }

        // Clear shared UserDefaults
        if let sharedDefaults = UserDefaults(suiteName: appGroupId) {
            sharedDefaults.removePersistentDomain(forName: appGroupId)
            sharedDefaults.synchronize()
            NSLog("[UITestMode] Cleared shared UserDefaults")
        }

        // Clear standard UserDefaults for library state
        UserDefaults.standard.removeObject(forKey: "library_items")
        UserDefaults.standard.synchronize()
        NSLog("[UITestMode] Cleared library UserDefaults")

        NSLog("[UITestMode] Fresh install state ready")
    }
}
