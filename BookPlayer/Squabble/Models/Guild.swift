//
//  Guild.swift
//  BookPlayer
//
//  Created for Squabble - Social Audiobook Features
//
//  This file defines the Guild data model and its Firestore structure.
//

import Foundation
import FirebaseFirestore

/// Represents a Squabble guild (reading group) with members who share progress.
///
/// Firestore Structure:
/// ```
/// guilds/{guildId}
///   - name: String
///   - createdBy: String (userId)
///   - createdAt: Timestamp
///   - inviteCode: String (6-character alphanumeric)
///   - memberCount: Int
///
/// guilds/{guildId}/members/{userId}
///   - joinedAt: Timestamp
///   - displayName: String
///   - email: String
///   - role: String ("owner" | "member")
///
/// guilds/{guildId}/progress/{bookId_userId}
///   - (existing structure from SquabbleSyncService)
/// ```
struct Guild: Identifiable, Codable {
    /// Firestore document ID
    let id: String

    /// Display name of the guild
    let name: String

    /// User ID of the guild creator
    let createdBy: String

    /// When the guild was created
    let createdAt: Date

    /// 6-character invite code for joining
    let inviteCode: String

    /// Number of members (denormalized for display)
    var memberCount: Int

    /// Coding keys for Firestore
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdBy
        case createdAt
        case inviteCode
        case memberCount
    }
}

// MARK: - Firestore Conversion

extension Guild {
    /// Create a Guild from Firestore document data
    /// - Parameters:
    ///   - documentId: The Firestore document ID
    ///   - data: The document data dictionary
    /// - Returns: A Guild instance if data is valid, nil otherwise
    static func from(documentId: String, data: [String: Any]) -> Guild? {
        guard let name = data["name"] as? String,
              let createdBy = data["createdBy"] as? String,
              let inviteCode = data["inviteCode"] as? String else {
            return nil
        }

        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let memberCount = data["memberCount"] as? Int ?? 0

        return Guild(
            id: documentId,
            name: name,
            createdBy: createdBy,
            createdAt: createdAt,
            inviteCode: inviteCode,
            memberCount: memberCount
        )
    }

    /// Convert to Firestore document data
    func toFirestoreData() -> [String: Any] {
        return [
            "name": name,
            "createdBy": createdBy,
            "createdAt": Timestamp(date: createdAt),
            "inviteCode": inviteCode,
            "memberCount": memberCount
        ]
    }
}

// MARK: - Guild Member

/// Represents a member of a guild
struct GuildMember: Identifiable, Codable {
    /// User ID (also the document ID)
    let id: String

    /// Display name
    let displayName: String

    /// Email address
    let email: String

    /// Role in the guild
    let role: GuildRole

    /// When they joined
    let joinedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case email
        case role
        case joinedAt
    }
}

/// Role within a guild
enum GuildRole: String, Codable {
    case owner = "owner"
    case member = "member"
}

// MARK: - GuildMember Firestore Conversion

extension GuildMember {
    /// Create a GuildMember from Firestore document data
    static func from(documentId: String, data: [String: Any]) -> GuildMember? {
        guard let displayName = data["displayName"] as? String,
              let email = data["email"] as? String,
              let roleString = data["role"] as? String,
              let role = GuildRole(rawValue: roleString) else {
            return nil
        }

        let joinedAt = (data["joinedAt"] as? Timestamp)?.dateValue() ?? Date()

        return GuildMember(
            id: documentId,
            displayName: displayName,
            email: email,
            role: role,
            joinedAt: joinedAt
        )
    }

    /// Convert to Firestore document data
    func toFirestoreData() -> [String: Any] {
        return [
            "displayName": displayName,
            "email": email,
            "role": role.rawValue,
            "joinedAt": Timestamp(date: joinedAt)
        ]
    }
}

// MARK: - Invite Code Generation

extension Guild {
    /// Generate a random 6-character alphanumeric invite code
    static func generateInviteCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Excludes confusing characters (0, O, I, 1)
        return String((0..<6).map { _ in characters.randomElement()! })
    }
}
