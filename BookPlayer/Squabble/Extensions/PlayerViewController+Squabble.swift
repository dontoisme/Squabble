//
//  PlayerViewController+Squabble.swift
//  BookPlayer
//
//  Created for Squabble - Social Audiobook Features
//
//  This extension provides Squabble ghost marker functionality for PlayerViewController.
//  It manages the ghost overlay view and fetches ghost progress data.
//

import UIKit

// MARK: - Associated Keys

private var ghostOverlayKey: UInt8 = 0

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
}
