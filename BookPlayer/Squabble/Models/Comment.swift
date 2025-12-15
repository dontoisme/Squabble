//
//  Comment.swift
//  BookPlayer
//
//  Created for Squabble - Social Audiobook Features
//
//  This file defines the Comment data model for timestamped reactions.
//  Comments appear to guildmates only after they pass the timestamp (spoiler-free).
//

import Foundation
import FirebaseFirestore

/// Represents a timestamped comment left by a guild member on an audiobook.
///
/// Firestore Structure:
/// ```
/// guilds/{guildId}/comments/{commentId}
///   - bookId: String (identifier for the audiobook)
///   - bookTitle: String (display title)
///   - userId: String (author's user ID)
///   - userDisplayName: String (author's display name)
///   - timestamp: Double (seconds into the audiobook)
///   - text: String (comment content, max 280 chars)
///   - createdAt: Timestamp
/// ```
struct Comment: Identifiable, Codable, Equatable {
    /// Firestore document ID
    let id: String

    /// Identifier for the audiobook (matches library item identifier)
    let bookId: String

    /// Display title of the audiobook
    let bookTitle: String

    /// User ID of the comment author
    let userId: String

    /// Display name of the comment author
    let userDisplayName: String

    /// Position in the audiobook (seconds from start)
    let timestamp: TimeInterval

    /// Comment text content (max 280 characters)
    let text: String

    /// When the comment was created
    let createdAt: Date

    /// Maximum character limit for comment text
    static let maxCharacterCount = 280

    enum CodingKeys: String, CodingKey {
        case id
        case bookId
        case bookTitle
        case userId
        case userDisplayName
        case timestamp
        case text
        case createdAt
    }
}

// MARK: - Firestore Conversion

extension Comment {
    /// Create a Comment from Firestore document data
    /// - Parameters:
    ///   - documentId: The Firestore document ID
    ///   - data: The document data dictionary
    /// - Returns: A Comment instance if data is valid, nil otherwise
    static func from(documentId: String, data: [String: Any]) -> Comment? {
        guard let bookId = data["bookId"] as? String,
              let bookTitle = data["bookTitle"] as? String,
              let userId = data["userId"] as? String,
              let userDisplayName = data["userDisplayName"] as? String,
              let timestamp = data["timestamp"] as? Double,
              let text = data["text"] as? String else {
            return nil
        }

        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

        return Comment(
            id: documentId,
            bookId: bookId,
            bookTitle: bookTitle,
            userId: userId,
            userDisplayName: userDisplayName,
            timestamp: timestamp,
            text: text,
            createdAt: createdAt
        )
    }

    /// Convert to Firestore document data
    func toFirestoreData() -> [String: Any] {
        return [
            "bookId": bookId,
            "bookTitle": bookTitle,
            "userId": userId,
            "userDisplayName": userDisplayName,
            "timestamp": timestamp,
            "text": text,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}

// MARK: - Formatting Helpers

extension Comment {
    /// Format the timestamp as a human-readable string (e.g., "1:23:45")
    var formattedTimestamp: String {
        let hours = Int(timestamp) / 3600
        let minutes = (Int(timestamp) % 3600) / 60
        let seconds = Int(timestamp) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    /// Format the creation date relative to now (e.g., "2h ago", "Yesterday")
    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}
