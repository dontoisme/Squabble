//
//  SquabbleSyncService.swift
//  BookPlayer
//
//  Created for Squabble - Phase 0 Spike
//

import FirebaseFirestore
import Foundation
import Combine

/// Service for syncing playback progress to Firestore for Squabble guilds
final class SquabbleSyncService {

    static let shared = SquabbleSyncService()

    private let db = Firestore.firestore()

    /// Minimum interval between syncs (5 minutes) to avoid excessive writes
    private let minSyncInterval: TimeInterval = 300

    /// Last sync timestamps per book
    private var lastSyncTimes: [String: Date] = [:]

    /// Current guild ID (dynamically fetched from GuildService)
    /// Note: This should be read from the main thread for thread safety
    private var guildId: String? {
        if Thread.isMainThread {
            return GuildService.shared.currentGuildId
        } else {
            // If called from background thread, dispatch sync to main to get accurate value
            var result: String?
            DispatchQueue.main.sync {
                result = GuildService.shared.currentGuildId
            }
            return result
        }
    }

    /// Current book ID being tracked
    private var currentBookId: String?

    /// Queue of pending syncs that failed or couldn't be sent
    private var pendingSyncs: [[String: Any]] = []

    /// Maximum number of pending syncs to queue
    private let maxPendingSyncs = 10

    /// Maximum retry attempts for sync operations
    private let maxRetries = 3

    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Listen for guild becoming ready to process pending syncs
        GuildService.shared.$isGuildReady
            .filter { $0 }
            .sink { [weak self] _ in
                self?.processPendingSyncs()
            }
            .store(in: &cancellables)
    }

    // MARK: - Progress Sync

    /// Sync progress to Firestore
    /// - Parameters:
    ///   - bookTitle: Title of the book being played
    ///   - currentTime: Current playback position in seconds
    ///   - duration: Total duration in seconds
    ///   - percentCompleted: Calculated percent (0-100)
    func syncProgress(
        bookTitle: String,
        currentTime: Double,
        duration: Double,
        percentCompleted: Double
    ) {
        guard SquabbleConfig.isEnabled && SquabbleConfig.progressSyncEnabled else {
            return
        }

        guard let userId = SquabbleAuthService.shared.userId else {
            // User not signed in to Squabble - this is fine with lazy auth
            return
        }

        // Generate a stable book ID from title (simplified for spike)
        let bookId = bookTitle.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)

        currentBookId = bookId

        // Throttle syncs to avoid excessive Firestore writes
        let now = Date()
        if let lastSync = lastSyncTimes[bookId],
           now.timeIntervalSince(lastSync) < minSyncInterval {
            // Skip sync, too soon
            return
        }

        // Update last sync time
        lastSyncTimes[bookId] = now

        // Prepare sync data
        let data: [String: Any] = [
            "bookId": bookId,
            "bookTitle": bookTitle,
            "userId": userId,
            "userEmail": SquabbleAuthService.shared.userEmail ?? "unknown",
            "progressPercent": percentCompleted,
            "progressTimestamp": currentTime,
            "totalDuration": duration,
            "lastUpdatedAt": FieldValue.serverTimestamp(),
            "isActive": true
        ]

        // Check if guild is ready
        guard GuildService.shared.isGuildReady else {
            // Guild not ready yet - queue for later
            SquabbleConfig.log("Guild not ready, queuing sync for later")
            queuePendingSync(data)
            return
        }

        guard let guildId = guildId else {
            // Guild ready but no guild ID - user not in a guild
            let guildServiceGuild = GuildService.shared.currentGuild?.name ?? "nil"
            SquabbleConfig.log("Not syncing - no guild. userId=\(userId), guildName=\(guildServiceGuild)")
            return
        }

        // Perform the sync with retry
        performSync(data: data, guildId: guildId, userId: userId, retryCount: 0)
    }

    /// Perform the actual Firestore sync with retry logic
    private func performSync(data: [String: Any], guildId: String, userId: String, retryCount: Int) {
        guard let bookId = data["bookId"] as? String else { return }

        let progressRef = db
            .collection("guilds").document(guildId)
            .collection("progress").document("\(bookId)_\(userId)")

        progressRef.setData(data, merge: true) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                print("[Squabble] Error syncing progress (attempt \(retryCount + 1)): \(error.localizedDescription)")

                // Retry if under max attempts
                if retryCount < self.maxRetries - 1 {
                    let delay = Double(retryCount + 1) * 2.0 // Exponential backoff: 2s, 4s, 6s
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.performSync(data: data, guildId: guildId, userId: userId, retryCount: retryCount + 1)
                    }
                } else {
                    // Max retries reached, queue for later
                    print("[Squabble] Max retries reached, queuing sync for later")
                    self.queuePendingSync(data)
                }
            } else {
                if let bookTitle = data["bookTitle"] as? String,
                   let percentCompleted = data["progressPercent"] as? Double {
                    print("[Squabble] Progress synced: \(bookTitle) - \(String(format: "%.1f", percentCompleted))%")
                }
            }
        }
    }

    /// Queue a sync operation for later processing
    private func queuePendingSync(_ data: [String: Any]) {
        // Remove oldest if at capacity
        if pendingSyncs.count >= maxPendingSyncs {
            pendingSyncs.removeFirst()
        }
        pendingSyncs.append(data)
        SquabbleConfig.log("Queued pending sync, total: \(pendingSyncs.count)")
    }

    /// Process any pending syncs (called when guild becomes ready)
    private func processPendingSyncs() {
        guard !pendingSyncs.isEmpty else { return }
        guard let guildId = guildId,
              let userId = SquabbleAuthService.shared.userId else {
            SquabbleConfig.log("Cannot process pending syncs - no guild or user")
            return
        }

        SquabbleConfig.log("Processing \(pendingSyncs.count) pending syncs")

        let syncsToProcess = pendingSyncs
        pendingSyncs.removeAll()

        for data in syncsToProcess {
            performSync(data: data, guildId: guildId, userId: userId, retryCount: 0)
        }
    }

    /// Force sync immediately (called on pause/app background)
    func forceSyncProgress(
        bookTitle: String,
        currentTime: Double,
        duration: Double,
        percentCompleted: Double
    ) {
        guard SquabbleAuthService.shared.userId != nil else { return }

        let bookId = bookTitle.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)

        // Clear throttle for this book
        lastSyncTimes[bookId] = nil

        // Sync immediately (will queue if guild not ready)
        syncProgress(
            bookTitle: bookTitle,
            currentTime: currentTime,
            duration: duration,
            percentCompleted: percentCompleted
        )
    }

    // MARK: - Ghost Fetching (for next spike task)

    /// Fetch all guild members' progress for a book
    func fetchGuildProgress(bookId: String) async throws -> [GhostProgress] {
        guard let guildId = guildId else { return [] }

        let snapshot = try await db
            .collection("guilds").document(guildId)
            .collection("progress")
            .whereField("bookId", isEqualTo: bookId)
            .getDocuments()

        return snapshot.documents.compactMap { doc -> GhostProgress? in
            let data = doc.data()
            guard let odId = data["userId"] as? String,
                  let progressPercent = data["progressPercent"] as? Double,
                  let userEmail = data["userEmail"] as? String else {
                return nil
            }

            return GhostProgress(
                odId: odId,
                userEmail: userEmail,
                progressPercent: progressPercent,
                lastUpdatedAt: (data["lastUpdatedAt"] as? Timestamp)?.dateValue()
            )
        }
    }
}

// MARK: - Models

struct GhostProgress {
    let odId: String
    let userEmail: String
    let progressPercent: Double
    let lastUpdatedAt: Date?

    /// Display name (first part of email for now)
    var displayName: String {
        userEmail.components(separatedBy: "@").first ?? "Ghost"
    }
}
