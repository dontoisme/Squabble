//
//  SquabbleAuthService.swift
//  BookPlayer
//
//  Created for Squabble - Phase 0 Spike
//

import FirebaseAuth
import Combine

/// Simple auth service for Squabble using Firebase Email/Password authentication
final class SquabbleAuthService: ObservableObject {

    static let shared = SquabbleAuthService()

    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated = false

    private var authStateListener: AuthStateDidChangeListenerHandle?

    private init() {
        // Skip Firebase auth listener in UI test mode - we'll set state manually
        if !CommandLine.arguments.contains("--uitesting") {
            setupAuthStateListener()
        }
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    // MARK: - Auth State

    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isAuthenticated = user != nil
        }
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        await MainActor.run {
            self.currentUser = result.user
            self.isAuthenticated = true
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        await MainActor.run {
            self.currentUser = result.user
            self.isAuthenticated = true
        }
    }

    // MARK: - Sign Out

    func signOut() throws {
        try Auth.auth().signOut()
        currentUser = nil
        isAuthenticated = false
    }

    // MARK: - Current User Info

    var userId: String? {
        uiTestUserId ?? currentUser?.uid
    }

    var userEmail: String? {
        uiTestUserEmail ?? currentUser?.email
    }

    var displayName: String? {
        uiTestDisplayName ?? currentUser?.displayName
    }

    // MARK: - UI Test Support

    /// Mock user ID for UI testing (bypasses Firebase)
    private var uiTestUserId: String?
    /// Mock email for UI testing
    private var uiTestUserEmail: String?
    /// Mock display name for UI testing
    private var uiTestDisplayName: String?

    /// Configure mock authentication state for UI tests.
    /// This bypasses Firebase and sets the auth state directly.
    func setUITestState(userId: String, email: String, displayName: String) {
        guard CommandLine.arguments.contains("--uitesting") else {
            print("[SquabbleAuth] setUITestState called outside of UI test mode - ignoring")
            return
        }

        self.uiTestUserId = userId
        self.uiTestUserEmail = email
        self.uiTestDisplayName = displayName
        self.isAuthenticated = true

        print("[SquabbleAuth] UI test state configured: \(email)")
    }

    /// Clear UI test state
    func clearUITestState() {
        uiTestUserId = nil
        uiTestUserEmail = nil
        uiTestDisplayName = nil
        if CommandLine.arguments.contains("--uitesting") {
            isAuthenticated = false
        }
    }
}
