//
//  SquabbleManager.swift
//  BookPlayer
//
//  Created for Squabble - Social Audiobook Features
//

import UIKit
import Combine

/// Central coordinator for Squabble social features.
/// Manages initialization, notifications, and coordination between services.
final class SquabbleManager {

    // MARK: - Singleton

    static let shared = SquabbleManager()

    // MARK: - Services

    let authService = SquabbleAuthService.shared
    let syncService = SquabbleSyncService.shared
    let guildService = GuildService.shared

    // MARK: - State

    private var disposeBag = Set<AnyCancellable>()
    private var isSetup = false

    // MARK: - Initialization

    private init() {}

    /// Call this early in app launch (e.g., from AppDelegate) to set up Squabble features.
    /// This method is idempotent - calling it multiple times has no effect.
    func setup() {
        guard !isSetup else { return }
        guard SquabbleConfig.isEnabled else {
            SquabbleConfig.log("Squabble features disabled")
            return
        }

        isSetup = true
        SquabbleConfig.log("Setting up Squabble features")

        setupPlaybackObserver()
        loadCurrentGuild()
    }

    /// Load user's current guild after authentication
    private func loadCurrentGuild() {
        // Check if already authenticated (Firebase may have restored session)
        if authService.isAuthenticated {
            SquabbleConfig.log("User already authenticated, loading guild...")
            Task {
                await guildService.loadCurrentGuild()
            }
        }

        // Also listen for future auth state changes (sign in/out)
        authService.$isAuthenticated
            .dropFirst()
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    SquabbleConfig.log("User signed in, loading guild...")
                    Task {
                        await self?.guildService.loadCurrentGuild()
                    }
                } else {
                    SquabbleConfig.log("User signed out")
                }
            }
            .store(in: &disposeBag)
    }

    // MARK: - Setup

    private func setupPlaybackObserver() {
        // Set up the playback observer for progress sync
        SquabblePlaybackObserver.shared.setup()
    }

    // MARK: - Auth Gate

    /// Check if user is authenticated and return appropriate view controller.
    /// Returns nil if authenticated, or login VC if not.
    func authGateViewController(onAuthenticated: @escaping () -> Void) -> UIViewController? {
        guard SquabbleConfig.isEnabled else { return nil }

        if authService.isAuthenticated {
            return nil
        } else {
            return SquabbleLoginViewController(onAuthenticated: onAuthenticated)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when ghost markers should be refreshed
    static let squabbleGhostsUpdated = Notification.Name("squabbleGhostsUpdated")

    /// Posted when user's guild changes
    static let squabbleGuildChanged = Notification.Name("squabbleGuildChanged")
}
