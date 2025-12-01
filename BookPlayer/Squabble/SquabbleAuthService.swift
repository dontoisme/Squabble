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
        setupAuthStateListener()
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
        currentUser?.uid
    }

    var userEmail: String? {
        currentUser?.email
    }
}
