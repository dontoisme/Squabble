//
//  GhostMarker.swift
//  BookPlayer
//
//  Created for Squabble - Social Audiobook Features
//

import UIKit

/// Represents a guild member's progress position on the playback timeline.
/// Used to display "ghost" markers showing where other members are in the book.
struct GhostMarker {
    /// Progress percentage (0-100)
    let percent: Double

    /// Color for this marker
    let color: UIColor

    /// Display name of the guild member
    let name: String

    /// User ID of the guild member
    let userId: String?

    init(percent: Double, color: UIColor, name: String, userId: String? = nil) {
        self.percent = percent
        self.color = color
        self.name = name
        self.userId = userId
    }
}

// MARK: - Factory Methods

extension GhostMarker {
    /// Create ghost markers from guild progress data, excluding the current user.
    /// - Parameters:
    ///   - progressList: Array of GhostProgress from sync service
    ///   - currentUserId: Current user's ID to exclude from markers
    /// - Returns: Array of GhostMarker for display
    static func fromGuildProgress(_ progressList: [GhostProgress], excludingUserId currentUserId: String?) -> [GhostMarker] {
        let colors: [UIColor] = [
            .systemBlue,
            .systemGreen,
            .systemOrange,
            .systemPurple,
            .systemPink
        ]

        return progressList.enumerated().compactMap { index, progress in
            // Skip current user's marker
            guard progress.odId != currentUserId else { return nil }

            let color = colors[index % colors.count]
            return GhostMarker(
                percent: progress.progressPercent,
                color: color,
                name: progress.displayName,
                userId: progress.odId
            )
        }
    }
}
