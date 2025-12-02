//
//  SquabbleConfig.swift
//  BookPlayer
//
//  Created for Squabble - Social Audiobook Features
//

import Foundation

/// Configuration and feature flags for Squabble social features
struct SquabbleConfig {

    // MARK: - Feature Flags

    /// Enable/disable all Squabble features (master switch)
    static let isEnabled = true

    /// Enable ghost markers on progress bar
    static let ghostMarkersEnabled = true

    /// Enable progress sync to Firestore
    static let progressSyncEnabled = true

    // MARK: - Sync Settings

    /// Minimum interval between progress syncs (in seconds)
    static let syncIntervalSeconds: TimeInterval = 300  // 5 minutes

    // MARK: - Guild Settings

    /// Default guild ID for Phase 0 spike (will be dynamic in Phase 1)
    static let defaultGuildId = "spike-guild"

    /// Maximum guild members
    static let maxGuildMembers = 5

    // MARK: - UI Settings

    /// Ghost marker colors for guild members
    static let ghostColors: [String] = [
        "systemBlue",
        "systemGreen",
        "systemOrange",
        "systemPurple",
        "systemPink"
    ]

    /// Ghost marker radius in points
    static let ghostMarkerRadius: CGFloat = 5.0

    // MARK: - Debug

    /// Enable verbose logging with [Squabble] prefix
    static let debugLoggingEnabled = true

    /// Log a debug message if logging is enabled
    static func log(_ message: String) {
        if debugLoggingEnabled {
            print("[Squabble] \(message)")
        }
    }
}
