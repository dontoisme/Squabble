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
            Section("Test Data") {
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
