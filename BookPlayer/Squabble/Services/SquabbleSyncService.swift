//
//  SquabbleSyncService.swift
//  BookPlayer
//
//  Created for Squabble - Phase 0 Spike
//

import FirebaseFirestore
import Foundation

/// Service for syncing playback progress to Firestore for Squabble guilds
final class SquabbleSyncService {

    static let shared = SquabbleSyncService()

    private let db = Firestore.firestore()

    /// Minimum interval between syncs (5 minutes) to avoid excessive writes
    private let minSyncInterval: TimeInterval = 300

    /// Last sync timestamps per book
    private var lastSyncTimes: [String: Date] = [:]

    /// Current guild ID (dynamically fetched from GuildService)
    private var guildId: String? {
        GuildService.shared.currentGuildId
    }

    /// Current book ID being tracked
    private var currentBookId: String?

    private init() {}

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

        guard let guildId = guildId else {
            SquabbleConfig.log("Not syncing - no guild (user may not have joined one yet)")
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

        // Create progress document
        let progressRef = db
            .collection("guilds").document(guildId)
            .collection("progress").document("\(bookId)_\(userId)")

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

        progressRef.setData(data, merge: true) { error in
            if let error = error {
                print("[Squabble] Error syncing progress: \(error.localizedDescription)")
            } else {
                print("[Squabble] Progress synced: \(bookTitle) - \(String(format: "%.1f", percentCompleted))%")
            }
        }
    }

    /// Force sync immediately (called on pause/app background)
    func forceSyncProgress(
        bookTitle: String,
        currentTime: Double,
        duration: Double,
        percentCompleted: Double
    ) {
        guard let userId = SquabbleAuthService.shared.userId,
              let guildId = guildId else { return }

        let bookId = bookTitle.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)

        // Clear throttle for this book
        lastSyncTimes[bookId] = nil

        // Sync immediately
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
