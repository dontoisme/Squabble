//
//  CommentsService.swift
//  BookPlayer
//
//  Created for Squabble - Social Audiobook Features
//
//  This service handles timestamped comments on audiobooks.
//  Comments are stored per-guild and only revealed to guildmates
//  after they pass the comment's timestamp (spoiler-free).
//

import FirebaseFirestore
import Combine
import Foundation

/// Errors that can occur during comment operations
enum CommentError: LocalizedError {
    case notAuthenticated
    case noGuild
    case commentTooLong
    case emptyComment
    case notFound
    case notOwner
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to comment"
        case .noGuild:
            return "You must be in a guild to comment"
        case .commentTooLong:
            return "Comment exceeds \(Comment.maxCharacterCount) characters"
        case .emptyComment:
            return "Comment cannot be empty"
        case .notFound:
            return "Comment not found"
        case .notOwner:
            return "You can only delete your own comments"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

/// Service for managing timestamped comments in Firestore
final class CommentsService: ObservableObject {

    static let shared = CommentsService()

    private let db = Firestore.firestore()

    /// Comments for the current book (filtered by user's progress)
    @Published private(set) var comments: [Comment] = []

    /// Loading state
    @Published private(set) var isLoading = false

    /// Current book being tracked
    private var currentBookId: String?

    /// Firestore listener for real-time updates
    private var commentsListener: ListenerRegistration?

    /// Track which comments have been shown to avoid duplicates
    private var seenCommentIds: Set<String> = []

    private init() {}

    deinit {
        commentsListener?.remove()
    }

    // MARK: - Post Comment

    /// Post a new comment at the specified timestamp
    /// - Parameters:
    ///   - bookId: Identifier for the audiobook
    ///   - bookTitle: Display title of the audiobook
    ///   - timestamp: Position in seconds from the start
    ///   - text: Comment content (max 280 characters)
    /// - Returns: The created Comment
    @discardableResult
    func postComment(
        bookId: String,
        bookTitle: String,
        timestamp: TimeInterval,
        text: String
    ) async throws -> Comment {
        // Validate authentication
        guard let userId = SquabbleAuthService.shared.userId else {
            throw CommentError.notAuthenticated
        }

        // Validate guild membership
        guard let guildId = GuildService.shared.currentGuildId else {
            throw CommentError.noGuild
        }

        // Validate comment text
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            throw CommentError.emptyComment
        }
        guard trimmedText.count <= Comment.maxCharacterCount else {
            throw CommentError.commentTooLong
        }

        // Get display name
        let displayName = SquabbleAuthService.shared.displayName
            ?? SquabbleAuthService.shared.userEmail?.components(separatedBy: "@").first
            ?? "Anonymous"

        // Create comment document
        let commentId = UUID().uuidString.lowercased()
        let now = Date()

        let comment = Comment(
            id: commentId,
            bookId: bookId,
            bookTitle: bookTitle,
            userId: userId,
            userDisplayName: displayName,
            timestamp: timestamp,
            text: trimmedText,
            createdAt: now
        )

        // Save to Firestore
        let commentRef = db.collection("guilds").document(guildId)
            .collection("comments").document(commentId)

        try await commentRef.setData(comment.toFirestoreData())

        SquabbleConfig.log("Posted comment at \(comment.formattedTimestamp): \(trimmedText.prefix(50))...")

        return comment
    }

    // MARK: - Delete Comment

    /// Delete a comment (only the author can delete their own comments)
    /// - Parameter commentId: The comment ID to delete
    func deleteComment(_ commentId: String) async throws {
        guard let userId = SquabbleAuthService.shared.userId else {
            throw CommentError.notAuthenticated
        }

        guard let guildId = GuildService.shared.currentGuildId else {
            throw CommentError.noGuild
        }

        let commentRef = db.collection("guilds").document(guildId)
            .collection("comments").document(commentId)

        // Verify ownership before deleting
        let doc = try await commentRef.getDocument()
        guard let data = doc.data(),
              let commentUserId = data["userId"] as? String else {
            throw CommentError.notFound
        }

        guard commentUserId == userId else {
            throw CommentError.notOwner
        }

        try await commentRef.delete()

        SquabbleConfig.log("Deleted comment: \(commentId)")

        // Remove from local state
        await MainActor.run {
            self.comments.removeAll { $0.id == commentId }
            self.seenCommentIds.remove(commentId)
        }
    }

    // MARK: - Fetch Comments (for Epic 2.2)

    /// Fetch comments for a book up to a certain timestamp (spoiler-free)
    /// - Parameters:
    ///   - bookId: The audiobook identifier
    ///   - beforeTimestamp: Only return comments at or before this timestamp
    /// - Returns: Array of comments sorted by timestamp
    func fetchComments(bookId: String, beforeTimestamp: TimeInterval) async throws -> [Comment] {
        guard let guildId = GuildService.shared.currentGuildId else {
            throw CommentError.noGuild
        }

        let snapshot = try await db.collection("guilds").document(guildId)
            .collection("comments")
            .whereField("bookId", isEqualTo: bookId)
            .whereField("timestamp", isLessThanOrEqualTo: beforeTimestamp)
            .order(by: "timestamp", descending: false)
            .getDocuments()

        let fetchedComments = snapshot.documents.compactMap { doc in
            Comment.from(documentId: doc.documentID, data: doc.data())
        }

        return fetchedComments
    }

    // MARK: - Real-time Listening (for Epic 2.2)

    /// Start listening for comments on a book (filtered by progress)
    /// - Parameters:
    ///   - bookId: The audiobook identifier
    ///   - maxTimestamp: Only listen for comments up to this timestamp
    func startListening(bookId: String, maxTimestamp: TimeInterval) {
        stopListening()

        guard let guildId = GuildService.shared.currentGuildId else {
            SquabbleConfig.log("Cannot start comment listener: no guild")
            return
        }

        currentBookId = bookId

        commentsListener = db.collection("guilds").document(guildId)
            .collection("comments")
            .whereField("bookId", isEqualTo: bookId)
            .whereField("timestamp", isLessThanOrEqualTo: maxTimestamp)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else {
                    if let error = error {
                        SquabbleConfig.log("Comment listener error: \(error.localizedDescription)")
                    }
                    return
                }

                let fetchedComments = documents.compactMap { doc in
                    Comment.from(documentId: doc.documentID, data: doc.data())
                }

                DispatchQueue.main.async {
                    self.comments = fetchedComments
                }
            }

        SquabbleConfig.log("Started comment listener for book: \(bookId) up to \(maxTimestamp)s")
    }

    /// Stop listening for comments
    func stopListening() {
        commentsListener?.remove()
        commentsListener = nil
        currentBookId = nil
    }

    // MARK: - Spoiler-Free Reveal Logic (for Epic 2.2)

    /// Get comments that are newly visible based on progress update
    /// - Parameter progress: Current playback position in seconds
    /// - Returns: Comments that haven't been shown yet and are now past the user's progress
    func getNewlyVisibleComments(progress: TimeInterval) -> [Comment] {
        let newlyVisible = comments.filter { comment in
            comment.timestamp <= progress && !seenCommentIds.contains(comment.id)
        }
        return newlyVisible
    }

    /// Mark a comment as seen (won't be returned by getNewlyVisibleComments again)
    func markAsSeen(_ commentId: String) {
        seenCommentIds.insert(commentId)
    }

    /// Reset seen comments (e.g., when switching books)
    func resetSeenComments() {
        seenCommentIds.removeAll()
    }

    // MARK: - UI Test Support

    #if DEBUG
    /// Configure mock comment state for UI tests
    static func setUITestState(comments: [Comment]) {
        guard CommandLine.arguments.contains("--uitesting") else {
            NSLog("[CommentsService] setUITestState called outside of UI test mode - ignoring")
            return
        }

        CommentsService.shared.comments = comments
        CommentsService.shared.isLoading = false

        NSLog("[CommentsService] UI test state configured with %d comments", comments.count)
    }

    /// Clear UI test state
    static func clearUITestState() {
        guard CommandLine.arguments.contains("--uitesting") else { return }

        CommentsService.shared.comments = []
        CommentsService.shared.seenCommentIds = []
        CommentsService.shared.currentBookId = nil
        CommentsService.shared.isLoading = false
    }
    #endif
}
