//
//  PlayerCoordinator+Squabble.swift
//  BookPlayer
//
//  Created for Squabble - Social Audiobook Features
//
//  This extension adds Squabble comment functionality to the player.
//

import UIKit

extension PlayerCoordinator {

    /// Present the comment input sheet for adding a timestamped comment.
    /// - Parameters:
    ///   - bookId: Identifier for the current audiobook
    ///   - bookTitle: Display title of the audiobook
    ///   - timestamp: Current playback position in seconds
    func showCommentInput(bookId: String, bookTitle: String, timestamp: TimeInterval) {
        // Check if user is authenticated and in a guild
        guard SquabbleAuthService.shared.isAuthenticated else {
            showSquabbleAuthRequired()
            return
        }

        guard GuildService.shared.currentGuildId != nil else {
            showGuildRequired()
            return
        }

        let vc = CommentInputViewController(
            bookTitle: bookTitle,
            timestamp: timestamp,
            onSubmit: { [weak self] text in
                try await CommentsService.shared.postComment(
                    bookId: bookId,
                    bookTitle: bookTitle,
                    timestamp: timestamp,
                    text: text
                )
                // Dismiss on success
                await MainActor.run {
                    self?.playerViewController.dismiss(animated: true)
                }
            },
            onCancel: { [weak self] in
                self?.playerViewController.dismiss(animated: true)
            }
        )

        playerViewController.present(vc, animated: true)
    }

    /// Show an alert prompting the user to sign in
    private func showSquabbleAuthRequired() {
        let alert = UIAlertController(
            title: "Sign In Required",
            message: "Sign in to your Squabble account to leave comments for your guild.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        playerViewController.present(alert, animated: true)
    }

    /// Show an alert prompting the user to join a guild
    private func showGuildRequired() {
        let alert = UIAlertController(
            title: "Join a Guild",
            message: "Join or create a guild to leave comments that your guildmates can see.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        playerViewController.present(alert, animated: true)
    }
}
