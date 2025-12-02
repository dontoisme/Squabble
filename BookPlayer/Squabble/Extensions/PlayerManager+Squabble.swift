//
//  PlayerManager+Squabble.swift
//  BookPlayer
//
//  Created for Squabble - Social Audiobook Features
//
//  This extension provides Squabble progress sync functionality.
//  It observes playback notifications and syncs progress to Firestore.
//

import Foundation
import Combine

/// Squabble observer that listens for playback events and syncs progress.
/// This is a standalone observer that doesn't modify PlayerManager.
final class SquabblePlaybackObserver {

    static let shared = SquabblePlaybackObserver()

    private var disposeBag = Set<AnyCancellable>()
    private var isSetup = false

    private init() {}

    /// Call this once during app launch to start observing playback events.
    func setup() {
        guard !isSetup else { return }
        guard SquabbleConfig.isEnabled && SquabbleConfig.progressSyncEnabled else {
            SquabbleConfig.log("Progress sync disabled")
            return
        }

        isSetup = true
        SquabbleConfig.log("Setting up playback observer for progress sync")

        // Observe playback progress updates
        NotificationCenter.default.publisher(for: .squabbleProgressUpdate)
            .sink { [weak self] notification in
                self?.handleProgressUpdate(notification)
            }
            .store(in: &disposeBag)

        // Observe pause events for force sync
        NotificationCenter.default.publisher(for: .bookPaused)
            .sink { [weak self] notification in
                self?.handlePause(notification)
            }
            .store(in: &disposeBag)
    }

    private func handleProgressUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let bookTitle = userInfo["bookTitle"] as? String,
              let currentTime = userInfo["currentTime"] as? Double,
              let duration = userInfo["duration"] as? Double,
              let percentCompleted = userInfo["percentCompleted"] as? Double else {
            return
        }

        SquabbleSyncService.shared.syncProgress(
            bookTitle: bookTitle,
            currentTime: currentTime,
            duration: duration,
            percentCompleted: percentCompleted
        )
    }

    private func handlePause(_ notification: Notification) {
        // Force sync on pause could be implemented here
        // For now, the regular sync handles this
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted by PlayerManager when playback progress updates.
    /// UserInfo: bookTitle, currentTime, duration, percentCompleted
    static let squabbleProgressUpdate = Notification.Name("squabbleProgressUpdate")
}

// MARK: - PlayerManager Extension

extension PlayerManager {
    /// Post a progress update notification for Squabble sync.
    /// Call this from updatePlaybackTime() instead of calling SquabbleSyncService directly.
    func postSquabbleProgressUpdate(bookTitle: String, currentTime: Double, duration: Double, percentCompleted: Double) {
        NotificationCenter.default.post(
            name: .squabbleProgressUpdate,
            object: self,
            userInfo: [
                "bookTitle": bookTitle,
                "currentTime": currentTime,
                "duration": duration,
                "percentCompleted": percentCompleted
            ]
        )
    }
}
