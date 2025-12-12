//
//  GuildService.swift
//  BookPlayer
//
//  Created for Squabble - Social Audiobook Features
//
//  This service handles all guild-related operations including:
//  - Creating guilds
//  - Joining guilds via invite code
//  - Leaving guilds
//  - Fetching guild data and members
//  - Generating new invite codes
//

import FirebaseFirestore
import Combine
import Foundation

/// Errors that can occur during guild operations
enum GuildError: LocalizedError {
    case notAuthenticated
    case guildNotFound
    case invalidInviteCode
    case alreadyMember
    case cannotLeaveAsOwner
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to perform this action"
        case .guildNotFound:
            return "Guild not found"
        case .invalidInviteCode:
            return "Invalid invite code"
        case .alreadyMember:
            return "You are already a member of this guild"
        case .cannotLeaveAsOwner:
            return "Guild owners cannot leave. Transfer ownership or delete the guild."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

/// Service for managing guilds in Firestore
final class GuildService: ObservableObject {

    static let shared = GuildService()

    private let db = Firestore.firestore()

    /// Currently active guild for the user
    @Published private(set) var currentGuild: Guild?

    /// Members of the current guild
    @Published private(set) var currentGuildMembers: [GuildMember] = []

    /// Loading state
    @Published private(set) var isLoading = false

    /// Firestore listeners
    private var guildListener: ListenerRegistration?
    private var membersListener: ListenerRegistration?

    private init() {}

    deinit {
        guildListener?.remove()
        membersListener?.remove()
    }

    // MARK: - Create Guild

    /// Create a new guild with the given name
    /// - Parameter name: The display name for the guild
    /// - Returns: The created Guild
    @discardableResult
    func createGuild(name: String) async throws -> Guild {
        guard let userId = SquabbleAuthService.shared.userId,
              let userEmail = SquabbleAuthService.shared.userEmail else {
            throw GuildError.notAuthenticated
        }

        let guildId = UUID().uuidString.lowercased()
        let inviteCode = Guild.generateInviteCode()
        let now = Date()

        let guild = Guild(
            id: guildId,
            name: name,
            createdBy: userId,
            createdAt: now,
            inviteCode: inviteCode,
            memberCount: 1
        )

        // Create guild document
        let guildRef = db.collection("guilds").document(guildId)
        try await guildRef.setData(guild.toFirestoreData())

        // Add creator as owner member
        let member = GuildMember(
            id: userId,
            displayName: userEmail.components(separatedBy: "@").first ?? "User",
            email: userEmail,
            role: .owner,
            joinedAt: now
        )

        try await guildRef.collection("members").document(userId).setData(member.toFirestoreData())

        // Store guild ID in user's document for quick lookup
        try await db.collection("users").document(userId).setData([
            "currentGuildId": guildId,
            "email": userEmail
        ], merge: true)

        SquabbleConfig.log("Created guild: \(name) with code: \(inviteCode)")

        // Start listening to this guild
        await MainActor.run {
            self.currentGuild = guild
        }
        startListening(to: guildId)

        return guild
    }

    // MARK: - Join Guild

    /// Join a guild using an invite code
    /// - Parameter inviteCode: The 6-character invite code
    /// - Returns: The joined Guild
    @discardableResult
    func joinGuild(inviteCode: String) async throws -> Guild {
        guard let userId = SquabbleAuthService.shared.userId,
              let userEmail = SquabbleAuthService.shared.userEmail else {
            throw GuildError.notAuthenticated
        }

        // Find guild by invite code
        let normalizedCode = inviteCode.uppercased().trimmingCharacters(in: .whitespaces)
        let snapshot = try await db.collection("guilds")
            .whereField("inviteCode", isEqualTo: normalizedCode)
            .limit(to: 1)
            .getDocuments()

        guard let document = snapshot.documents.first,
              let guild = Guild.from(documentId: document.documentID, data: document.data()) else {
            throw GuildError.invalidInviteCode
        }

        // Check if already a member
        let memberDoc = try await db.collection("guilds").document(guild.id)
            .collection("members").document(userId).getDocument()

        if memberDoc.exists {
            throw GuildError.alreadyMember
        }

        // Add as member
        let member = GuildMember(
            id: userId,
            displayName: userEmail.components(separatedBy: "@").first ?? "User",
            email: userEmail,
            role: .member,
            joinedAt: Date()
        )

        let guildRef = db.collection("guilds").document(guild.id)
        try await guildRef.collection("members").document(userId).setData(member.toFirestoreData())

        // Increment member count
        try await guildRef.updateData([
            "memberCount": FieldValue.increment(Int64(1))
        ])

        // Update user's current guild
        try await db.collection("users").document(userId).setData([
            "currentGuildId": guild.id,
            "email": userEmail
        ], merge: true)

        SquabbleConfig.log("Joined guild: \(guild.name)")

        // Start listening to this guild
        startListening(to: guild.id)

        return guild
    }

    // MARK: - Leave Guild

    /// Leave the current guild
    func leaveGuild() async throws {
        guard let userId = SquabbleAuthService.shared.userId else {
            throw GuildError.notAuthenticated
        }

        guard let guild = currentGuild else {
            throw GuildError.guildNotFound
        }

        // Check if user is owner
        let memberDoc = try await db.collection("guilds").document(guild.id)
            .collection("members").document(userId).getDocument()

        if let data = memberDoc.data(),
           let roleString = data["role"] as? String,
           roleString == GuildRole.owner.rawValue {
            throw GuildError.cannotLeaveAsOwner
        }

        let guildRef = db.collection("guilds").document(guild.id)

        // Remove member document
        try await guildRef.collection("members").document(userId).delete()

        // Decrement member count
        try await guildRef.updateData([
            "memberCount": FieldValue.increment(Int64(-1))
        ])

        // Clear user's current guild
        try await db.collection("users").document(userId).updateData([
            "currentGuildId": FieldValue.delete()
        ])

        SquabbleConfig.log("Left guild: \(guild.name)")

        // Stop listening and clear state
        stopListening()
        await MainActor.run {
            self.currentGuild = nil
            self.currentGuildMembers = []
        }
    }

    // MARK: - Generate New Invite Code

    /// Generate a new invite code for the current guild (owner only)
    /// - Returns: The new invite code
    func regenerateInviteCode() async throws -> String {
        guard let userId = SquabbleAuthService.shared.userId else {
            throw GuildError.notAuthenticated
        }

        guard let guild = currentGuild else {
            throw GuildError.guildNotFound
        }

        // Verify user is owner
        guard guild.createdBy == userId else {
            throw GuildError.notAuthenticated
        }

        let newCode = Guild.generateInviteCode()

        try await db.collection("guilds").document(guild.id).updateData([
            "inviteCode": newCode
        ])

        SquabbleConfig.log("Generated new invite code: \(newCode)")

        return newCode
    }

    // MARK: - Fetch Current Guild

    /// Load the user's current guild on app launch
    func loadCurrentGuild() async {
        guard let userId = SquabbleAuthService.shared.userId else { return }

        await MainActor.run { self.isLoading = true }

        do {
            // Get user's current guild ID
            let userDoc = try await db.collection("users").document(userId).getDocument()

            guard let data = userDoc.data(),
                  let guildId = data["currentGuildId"] as? String else {
                await MainActor.run {
                    self.isLoading = false
                    self.currentGuild = nil
                }
                return
            }

            // Fetch guild document
            let guildDoc = try await db.collection("guilds").document(guildId).getDocument()

            guard let guildData = guildDoc.data(),
                  let guild = Guild.from(documentId: guildDoc.documentID, data: guildData) else {
                await MainActor.run {
                    self.isLoading = false
                    self.currentGuild = nil
                }
                return
            }

            await MainActor.run {
                self.currentGuild = guild
                self.isLoading = false
            }

            // Start listening for updates
            startListening(to: guildId)

            SquabbleConfig.log("Loaded current guild: \(guild.name)")
        } catch {
            SquabbleConfig.log("Error loading guild: \(error.localizedDescription)")
            await MainActor.run { self.isLoading = false }
        }
    }

    // MARK: - Real-time Listening

    /// Start listening to guild and members updates
    private func startListening(to guildId: String) {
        stopListening()

        // Listen to guild document
        guildListener = db.collection("guilds").document(guildId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self,
                      let data = snapshot?.data(),
                      let guild = Guild.from(documentId: guildId, data: data) else {
                    return
                }
                DispatchQueue.main.async {
                    self.currentGuild = guild
                }
            }

        // Listen to members collection
        membersListener = db.collection("guilds").document(guildId)
            .collection("members")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }

                let members = documents.compactMap { doc in
                    GuildMember.from(documentId: doc.documentID, data: doc.data())
                }.sorted { $0.joinedAt < $1.joinedAt }

                DispatchQueue.main.async {
                    self.currentGuildMembers = members
                }
            }
    }

    /// Stop listening to updates
    private func stopListening() {
        guildListener?.remove()
        guildListener = nil
        membersListener?.remove()
        membersListener = nil
    }

    // MARK: - Utility

    /// Get the current guild ID (for sync service)
    var currentGuildId: String? {
        currentGuild?.id
    }
}
