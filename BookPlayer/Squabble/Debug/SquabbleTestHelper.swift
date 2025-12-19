//
//  SquabbleTestHelper.swift
//  BookPlayer
//
//  Debug helper for seeding test data into Firestore guilds.
//  Only available in DEBUG builds.
//

#if DEBUG

import FirebaseFirestore
import Foundation

/// Helper for populating guilds with fake members and progress data for testing
final class SquabbleTestHelper {

    static let shared = SquabbleTestHelper()

    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Fake Users

    /// Predefined fake users for testing
    static let fakeUsers: [(id: String, email: String, displayName: String)] = [
        ("fake-alice-001", "alice@test.com", "Alice"),
        ("fake-bob-002", "bob@test.com", "Bob"),
        ("fake-charlie-003", "charlie@test.com", "Charlie"),
        ("fake-diana-004", "diana@test.com", "Diana"),
        ("fake-eve-005", "eve@test.com", "Eve"),
        ("fake-frank-006", "frank@test.com", "Frank"),
        ("fake-grace-007", "grace@test.com", "Grace"),
        ("fake-hank-008", "hank@test.com", "Hank"),
    ]

    // MARK: - Seed Members

    /// Add fake members to the current guild
    /// - Parameter count: Number of fake members to add (max 8)
    /// - Returns: Array of added member IDs
    @discardableResult
    func seedFakeMembers(count: Int = 4) async throws -> [String] {
        guard let guildId = GuildService.shared.currentGuildId else {
            throw TestHelperError.noGuild
        }

        let membersToAdd = Array(Self.fakeUsers.prefix(min(count, Self.fakeUsers.count)))
        var addedIds: [String] = []

        let guildRef = db.collection("guilds").document(guildId)

        for user in membersToAdd {
            let memberData: [String: Any] = [
                "displayName": user.displayName,
                "email": user.email,
                "role": "member",
                "joinedAt": Timestamp(date: Date().addingTimeInterval(-Double.random(in: 86400...604800))) // 1-7 days ago
            ]

            try await guildRef.collection("members").document(user.id).setData(memberData)
            addedIds.append(user.id)
            print("[SquabbleTest] Added fake member: \(user.displayName)")
        }

        // Update member count
        try await guildRef.updateData([
            "memberCount": FieldValue.increment(Int64(addedIds.count))
        ])

        print("[SquabbleTest] Seeded \(addedIds.count) fake members")
        return addedIds
    }

    // MARK: - Seed Progress

    /// Add fake progress for members on a specific book
    /// - Parameters:
    ///   - bookTitle: The book title to add progress for
    ///   - totalDuration: Total duration of the book in seconds (default 10 hours)
    ///   - progresses: Optional dictionary of userId -> progressPercent. If nil, generates random progress.
    func seedFakeProgress(
        bookTitle: String,
        totalDuration: Double = 36000, // 10 hours default
        progresses: [String: Double]? = nil
    ) async throws {
        guard let guildId = GuildService.shared.currentGuildId else {
            throw TestHelperError.noGuild
        }

        let bookId = bookTitle.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)

        let guildRef = db.collection("guilds").document(guildId)

        // Get current members
        let membersSnapshot = try await guildRef.collection("members").getDocuments()

        for doc in membersSnapshot.documents {
            let userId = doc.documentID
            let data = doc.data()
            let email = data["email"] as? String ?? "unknown@test.com"

            // Skip if specific progresses provided and this user isn't included
            if let progresses = progresses, progresses[userId] == nil {
                continue
            }

            // Determine progress percentage
            let progressPercent: Double
            if let progresses = progresses, let specified = progresses[userId] {
                progressPercent = specified
            } else {
                // Random progress between 5% and 95%
                progressPercent = Double.random(in: 5...95)
            }

            let progressTimestamp = (progressPercent / 100.0) * totalDuration

            let progressData: [String: Any] = [
                "bookId": bookId,
                "bookTitle": bookTitle,
                "userId": userId,
                "userEmail": email,
                "progressPercent": progressPercent,
                "progressTimestamp": progressTimestamp,
                "totalDuration": totalDuration,
                "lastUpdatedAt": Timestamp(date: Date().addingTimeInterval(-Double.random(in: 60...3600))), // 1min-1hr ago
                "isActive": true
            ]

            let docId = "\(bookId)_\(userId)"
            try await guildRef.collection("progress").document(docId).setData(progressData)
            print("[SquabbleTest] Set progress for \(email): \(String(format: "%.1f", progressPercent))%")
        }

        print("[SquabbleTest] Seeded progress for '\(bookTitle)'")
    }

    // MARK: - Convenience: Seed Everything

    /// Seed both fake members and their progress on a book
    /// - Parameters:
    ///   - memberCount: Number of fake members to add
    ///   - bookTitle: Book to add progress for
    ///   - totalDuration: Book duration in seconds
    func seedGuildWithProgress(
        memberCount: Int = 4,
        bookTitle: String,
        totalDuration: Double = 36000
    ) async throws {
        // Add fake members
        try await seedFakeMembers(count: memberCount)

        // Small delay to let Firestore sync
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Add progress for all members (including the real user if they exist)
        try await seedFakeProgress(bookTitle: bookTitle, totalDuration: totalDuration)
    }

    // MARK: - Clear Test Data

    /// Remove all fake members and their progress from the current guild
    func clearFakeData() async throws {
        guard let guildId = GuildService.shared.currentGuildId else {
            throw TestHelperError.noGuild
        }

        let guildRef = db.collection("guilds").document(guildId)
        let fakeUserIds = Set(Self.fakeUsers.map { $0.id })

        var removedCount = 0

        // Remove fake members
        for userId in fakeUserIds {
            do {
                try await guildRef.collection("members").document(userId).delete()
                removedCount += 1
            } catch {
                // Ignore if doesn't exist
            }
        }

        // Remove progress documents for fake users
        let progressSnapshot = try await guildRef.collection("progress").getDocuments()
        for doc in progressSnapshot.documents {
            let data = doc.data()
            if let odId = data["userId"] as? String, fakeUserIds.contains(odId) {
                try await doc.reference.delete()
                print("[SquabbleTest] Removed progress doc: \(doc.documentID)")
            }
        }

        // Update member count
        if removedCount > 0 {
            try await guildRef.updateData([
                "memberCount": FieldValue.increment(Int64(-removedCount))
            ])
        }

        print("[SquabbleTest] Cleared \(removedCount) fake members and their progress")
    }

    // MARK: - Seed Comments

    /// Seed fake comments for testing the comment reveal system
    /// - Parameters:
    ///   - bookTitle: The book title
    ///   - comments: Array of (userId, timestamp in seconds, text)
    func seedFakeComments(
        bookTitle: String,
        comments: [(userId: String, timestamp: Double, text: String)]
    ) async throws {
        guard let guildId = GuildService.shared.currentGuildId else {
            throw TestHelperError.noGuild
        }

        let bookId = bookTitle.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)

        let guildRef = db.collection("guilds").document(guildId)

        // Get member info for display names
        let membersSnapshot = try await guildRef.collection("members").getDocuments()
        var memberNames: [String: String] = [:]
        for doc in membersSnapshot.documents {
            if let displayName = doc.data()["displayName"] as? String {
                memberNames[doc.documentID] = displayName
            }
        }

        for (userId, timestamp, text) in comments {
            let commentId = UUID().uuidString.lowercased()
            let displayName = memberNames[userId] ?? "Unknown"

            let commentData: [String: Any] = [
                "bookId": bookId,
                "bookTitle": bookTitle,
                "userId": userId,
                "userDisplayName": displayName,
                "timestamp": timestamp,
                "text": text,
                "createdAt": Timestamp(date: Date().addingTimeInterval(-Double.random(in: 3600...86400))) // 1hr-1day ago
            ]

            try await guildRef.collection("comments").document(commentId).setData(commentData)
            print("[SquabbleTest] Added comment at \(formatTime(timestamp)): \"\(text.prefix(30))...\"")
        }

        print("[SquabbleTest] Seeded \(comments.count) comments for '\(bookTitle)'")
    }

    /// Clear all comments for a book in the current guild
    func clearComments(bookTitle: String) async throws {
        guard let guildId = GuildService.shared.currentGuildId else {
            throw TestHelperError.noGuild
        }

        let bookId = bookTitle.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)

        let guildRef = db.collection("guilds").document(guildId)
        let commentsSnapshot = try await guildRef.collection("comments")
            .whereField("bookId", isEqualTo: bookId)
            .getDocuments()

        for doc in commentsSnapshot.documents {
            try await doc.reference.delete()
        }

        print("[SquabbleTest] Cleared \(commentsSnapshot.documents.count) comments for '\(bookTitle)'")
    }

    private func formatTime(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }

    // MARK: - Specific Progress Scenarios

    /// Seed a "race" scenario where members are at various points in the same book
    func seedRaceScenario(bookTitle: String, totalDuration: Double = 36000) async throws {
        guard let guildId = GuildService.shared.currentGuildId else {
            throw TestHelperError.noGuild
        }

        // Add 4 fake members
        try await seedFakeMembers(count: 4)
        try await Task.sleep(nanoseconds: 500_000_000)

        // Set specific progress to simulate a race
        // Alice is winning, Bob close behind, Charlie and Diana further back
        let raceProgress: [String: Double] = [
            "fake-alice-001": 78.5,
            "fake-bob-002": 72.3,
            "fake-charlie-003": 45.0,
            "fake-diana-004": 31.2,
        ]

        // Also include current user if authenticated
        var allProgress = raceProgress
        if let currentUserId = SquabbleAuthService.shared.userId {
            allProgress[currentUserId] = 65.0 // Put current user in the middle of the pack
        }

        try await seedFakeProgress(
            bookTitle: bookTitle,
            totalDuration: totalDuration,
            progresses: allProgress
        )

        print("[SquabbleTest] Seeded race scenario for '\(bookTitle)'")
    }

    // MARK: - Test Book Scenario

    /// Seed a complete test scenario for "Tavern of Infinite Levels"
    /// A fictional LitRPG for testing purposes
    /// Duration: 20:38:01 (74281 seconds)
    /// User is at ~19:10 (1150 seconds) in Chapter 2
    func seedTestBookScenario() async throws {
        let bookTitle = "Tavern of Infinite Levels"
        let totalDuration: Double = 74281 // 20:38:01

        // Add 4 fake guildmates
        try await seedFakeMembers(count: 4)
        try await Task.sleep(nanoseconds: 500_000_000)

        // Set progress positions:
        // Alice - ahead at ~35% (~7:13:00)
        // Bob - way ahead at ~60% (~12:22:00)
        // Charlie - behind at ~0.5% (~6:10)
        // Diana - slightly ahead at ~5% (~1:01:54)
        let progress: [String: Double] = [
            "fake-alice-001": 35.0,   // ~26000s / 7:13:00
            "fake-bob-002": 60.0,     // ~44570s / 12:22:00
            "fake-charlie-003": 0.5,  // ~370s / 6:10
            "fake-diana-004": 5.0,    // ~3714s / 1:01:54
        ]

        try await seedFakeProgress(
            bookTitle: bookTitle,
            totalDuration: totalDuration,
            progresses: progress
        )

        // Seed comments - mix of before and after user's position (1150s / 19:10)
        let comments: [(userId: String, timestamp: Double, text: String)] = [
            // BEFORE user position (will be visible immediately)
            ("fake-charlie-003", 330, "Starting this one finally! Heard great things"),
            ("fake-alice-001", 720, "The intro is setting up something good..."),
            ("fake-diana-004", 945, "Wait did he just...?"),

            // AFTER user position (will reveal as user progresses)
            ("fake-alice-001", 1500, "OK this is getting interesting"),
            ("fake-bob-002", 2700, "LMAO the narrator is hilarious"),
            ("fake-diana-004", 5400, "I did NOT see that coming"),
            ("fake-alice-001", 10800, "This book is so good, I can't stop listening"),
            ("fake-bob-002", 18000, "The world building is chef's kiss"),
            ("fake-alice-001", 26000, "WHAT. NO. WHAT."),
            ("fake-bob-002", 44000, "OK that twist though..."),
        ]

        try await seedFakeComments(bookTitle: bookTitle, comments: comments)

        print("[SquabbleTest] ✓ Test book scenario seeded!")
        print("[SquabbleTest]   - 4 guildmates at various positions")
        print("[SquabbleTest]   - 3 comments before your position (visible now)")
        print("[SquabbleTest]   - 7 comments ahead (will reveal as you progress)")
    }

    /// Clear all test book data
    func clearTestBookScenario() async throws {
        try await clearFakeData()
        try await clearComments(bookTitle: "Tavern of Infinite Levels")
        print("[SquabbleTest] ✓ Test book scenario cleared!")
    }
}

// MARK: - Errors

enum TestHelperError: LocalizedError {
    case noGuild
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .noGuild:
            return "No current guild. Join or create a guild first."
        case .notAuthenticated:
            return "Not authenticated. Sign in first."
        }
    }
}

// MARK: - SwiftUI Debug View

import SwiftUI

/// Debug view for triggering test data seeding
struct SquabbleDebugView: View {
    @State private var bookTitle = "The Great Gatsby"
    @State private var memberCount = 4
    @State private var isLoading = false
    @State private var statusMessage = ""

    var body: some View {
        Form {
            Section("Test Book Scenario") {
                Text("\"Tavern of Infinite Levels\" - 4 guildmates, 10 comments")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Seed Test Book Scenario") {
                    seedTestBook()
                }
                .disabled(isLoading)

                Button("Clear Test Book Data", role: .destructive) {
                    clearTestBook()
                }
                .disabled(isLoading)
            }

            Section("Custom Test Data") {
                TextField("Book Title", text: $bookTitle)

                Stepper("Members: \(memberCount)", value: $memberCount, in: 1...8)

                Button("Seed Guild with Progress") {
                    seedData()
                }
                .disabled(isLoading)

                Button("Seed Race Scenario") {
                    seedRace()
                }
                .disabled(isLoading)

                Button("Clear Fake Data", role: .destructive) {
                    clearData()
                }
                .disabled(isLoading)
            }

            if !statusMessage.isEmpty {
                Section("Status") {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Squabble Debug")
    }

    private func seedData() {
        isLoading = true
        statusMessage = "Seeding..."

        Task {
            do {
                try await SquabbleTestHelper.shared.seedGuildWithProgress(
                    memberCount: memberCount,
                    bookTitle: bookTitle
                )
                await MainActor.run {
                    statusMessage = "✓ Seeded \(memberCount) members with progress on '\(bookTitle)'"
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    statusMessage = "✗ Error: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }

    private func seedRace() {
        isLoading = true
        statusMessage = "Seeding race..."

        Task {
            do {
                try await SquabbleTestHelper.shared.seedRaceScenario(bookTitle: bookTitle)
                await MainActor.run {
                    statusMessage = "✓ Seeded race scenario for '\(bookTitle)'"
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    statusMessage = "✗ Error: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }

    private func clearData() {
        isLoading = true
        statusMessage = "Clearing..."

        Task {
            do {
                try await SquabbleTestHelper.shared.clearFakeData()
                await MainActor.run {
                    statusMessage = "✓ Cleared all fake data"
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    statusMessage = "✗ Error: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }

    private func seedTestBook() {
        isLoading = true
        statusMessage = "Seeding test book scenario..."

        Task {
            do {
                try await SquabbleTestHelper.shared.seedTestBookScenario()
                await MainActor.run {
                    statusMessage = "✓ Test book scenario ready!\n  • 4 guildmates seeded\n  • 3 comments visible now\n  • 7 comments ahead to discover"
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    statusMessage = "✗ Error: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }

    private func clearTestBook() {
        isLoading = true
        statusMessage = "Clearing test book data..."

        Task {
            do {
                try await SquabbleTestHelper.shared.clearTestBookScenario()
                await MainActor.run {
                    statusMessage = "✓ Test book scenario cleared"
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    statusMessage = "✗ Error: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Settings Section

/// Section view for Settings that links to the debug screen
struct SettingsSquabbleDebugSectionView: View {
    var body: some View {
        Section {
            NavigationLink(value: SettingsScreen.squabbleDebug) {
                HStack {
                    Image(systemName: "ant.fill")
                        .foregroundColor(.orange)
                    Text("Squabble Debug")
                }
            }
        } header: {
            Text("Developer")
        } footer: {
            Text("Seed test data for Squabble guilds. Only visible in DEBUG builds.")
        }
    }
}

#endif
