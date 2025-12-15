//
//  PlayerViewController+Squabble.swift
//  BookPlayer
//
//  Created for Squabble - Social Audiobook Features
//
//  This extension provides Squabble functionality for PlayerViewController:
//  - Ghost marker overlay for showing guildmates' progress
//  - Comment button for leaving timestamped reactions
//

import UIKit

// MARK: - Associated Keys

private var ghostOverlayKey: UInt8 = 0
private var commentButtonKey: UInt8 = 0

// MARK: - PlayerViewController Extension

extension PlayerViewController {

    /// The ghost overlay view (stored via associated object)
    var squabbleGhostOverlay: SquabbleGhostOverlayView? {
        get {
            return objc_getAssociatedObject(self, &ghostOverlayKey) as? SquabbleGhostOverlayView
        }
        set {
            objc_setAssociatedObject(self, &ghostOverlayKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// Set up the ghost overlay view on top of the progress slider.
    /// Call this from setupPlayerView, passing the progressSlider.
    /// - Parameter slider: The progress slider to overlay
    func setupSquabbleGhostOverlay(for slider: UISlider) {
        guard SquabbleConfig.isEnabled && SquabbleConfig.ghostMarkersEnabled else { return }
        guard squabbleGhostOverlay == nil else { return }  // Already set up

        let overlay = SquabbleGhostOverlayView()
        overlay.addAsOverlay(for: slider)
        squabbleGhostOverlay = overlay

        SquabbleConfig.log("Ghost overlay view added to player")
    }

    /// Fetch and display ghost markers for a book.
    /// - Parameter bookTitle: Title of the book to fetch ghosts for
    func fetchAndDisplayGhosts(for bookTitle: String) {
        guard SquabbleConfig.isEnabled && SquabbleConfig.ghostMarkersEnabled else { return }

        // Generate book ID (same logic as sync service)
        let bookId = bookTitle.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)

        Task {
            do {
                let ghosts = try await SquabbleSyncService.shared.fetchGuildProgress(bookId: bookId)

                // Convert to markers, excluding current user
                let currentUserId = SquabbleAuthService.shared.userId
                let markers = GhostMarker.fromGuildProgress(ghosts, excludingUserId: currentUserId)

                await MainActor.run {
                    self.squabbleGhostOverlay?.ghostMarkers = markers
                    SquabbleConfig.log("Displaying \(markers.count) ghost markers")
                }
            } catch {
                SquabbleConfig.log("Error fetching ghosts: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Comment Button

    /// The "Add Comment" button (stored via associated object)
    private var squabbleCommentButton: UIButton? {
        get {
            return objc_getAssociatedObject(self, &commentButtonKey) as? UIButton
        }
        set {
            objc_setAssociatedObject(self, &commentButtonKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// Set up the "Add Comment" button above the player controls.
    /// Call this from setupPlayerView.
    func setupSquabbleCommentButton() {
        guard SquabbleConfig.isEnabled else { return }
        guard squabbleCommentButton == nil else { return }  // Already set up

        let button = UIButton(type: .system)
        button.setTitle("Add Comment", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.setTitleColor(.systemBlue, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "player_button_add_comment"
        button.accessibilityLabel = "Add Comment"

        // Add tap action
        button.addTarget(self, action: #selector(handleAddCommentTapped), for: .touchUpInside)

        // Add to view hierarchy - position above the player controls
        view.addSubview(button)

        // Position above containerPlayerControlsStackView
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: containerPlayerControlsStackView.topAnchor, constant: -16)
        ])

        squabbleCommentButton = button

        SquabbleConfig.log("Comment button added to player")
    }

    /// Handle tap on "Add Comment" button
    @objc private func handleAddCommentTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        viewModel.leaveComment()
    }
}
