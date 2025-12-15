//
//  PlayerViewController+Squabble.swift
//  BookPlayer
//
//  Created for Squabble - Social Audiobook Features
//
//  This extension provides Squabble functionality for PlayerViewController:
//  - Ghost marker overlay for showing guildmates' progress
//  - Comment button for leaving timestamped reactions
//  - Comment display: toast overlay and timeline markers (spoiler-free)
//

import UIKit
import Combine

// MARK: - Associated Keys

private var ghostOverlayKey: UInt8 = 0
private var commentButtonKey: UInt8 = 0
private var commentOverlayHostKey: UInt8 = 0
private var commentMarkersOverlayKey: UInt8 = 0
private var commentCancellablesKey: UInt8 = 0
private var currentBookIdKey: UInt8 = 0
private var bookDurationKey: UInt8 = 0

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

    // MARK: - Comment Button

    /// The "Add Comment" button (stored via associated object)
    private var squabbleCommentButton: UIButton? {
        get {
            return objc_getAssociatedObject(self, &commentButtonKey) as? UIButton
        }
        set {
            objc_setAssociatedObject(self, &commentButtonKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// Set up the "Add Comment" button above the player controls.
    /// Call this from setupPlayerView.
    func setupSquabbleCommentButton() {
        guard SquabbleConfig.isEnabled else { return }
        guard squabbleCommentButton == nil else { return }  // Already set up

        let button = UIButton(type: .system)
        button.setTitle("Add Comment", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.setTitleColor(.systemBlue, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "player_button_add_comment"
        button.accessibilityLabel = "Add Comment"

        // Add tap action
        button.addTarget(self, action: #selector(handleAddCommentTapped), for: .touchUpInside)

        // Add to view hierarchy - position above the player controls
        view.addSubview(button)

        // Position above containerPlayerControlsStackView
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: containerPlayerControlsStackView.topAnchor, constant: -16)
        ])

        squabbleCommentButton = button

        SquabbleConfig.log("Comment button added to player")
    }

    /// Handle tap on "Add Comment" button
    @objc private func handleAddCommentTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        viewModel.leaveComment()
    }

    // MARK: - Comment Display (Epic 2.2)

    /// The comment toast overlay host view (stored via associated object)
    private var squabbleCommentOverlayHost: CommentOverlayHostView? {
        get {
            return objc_getAssociatedObject(self, &commentOverlayHostKey) as? CommentOverlayHostView
        }
        set {
            objc_setAssociatedObject(self, &commentOverlayHostKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// The comment markers overlay for timeline (stored via associated object)
    private var squabbleCommentMarkersOverlay: CommentMarkersOverlayView? {
        get {
            return objc_getAssociatedObject(self, &commentMarkersOverlayKey) as? CommentMarkersOverlayView
        }
        set {
            objc_setAssociatedObject(self, &commentMarkersOverlayKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// Combine cancellables for comment subscriptions
    private var squabbleCommentCancellables: Set<AnyCancellable> {
        get {
            return objc_getAssociatedObject(self, &commentCancellablesKey) as? Set<AnyCancellable> ?? []
        }
        set {
            objc_setAssociatedObject(self, &commentCancellablesKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// Current book ID being tracked
    private var squabbleCurrentBookId: String? {
        get {
            return objc_getAssociatedObject(self, &currentBookIdKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &currentBookIdKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// Current book duration
    private var squabbleBookDuration: TimeInterval {
        get {
            return objc_getAssociatedObject(self, &bookDurationKey) as? TimeInterval ?? 0
        }
        set {
            objc_setAssociatedObject(self, &bookDurationKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// Set up comment display views and listener.
    /// Call this from setupPlayerView after setting up ghost overlay.
    /// - Parameters:
    ///   - slider: The progress slider for marker overlay
    ///   - bookId: The audiobook identifier
    ///   - bookDuration: Total duration in seconds
    func setupSquabbleCommentDisplay(for slider: UISlider, bookId: String, bookDuration: TimeInterval) {
        guard SquabbleConfig.isEnabled else { return }

        squabbleCurrentBookId = bookId
        squabbleBookDuration = bookDuration

        // Set up comment toast overlay (positioned at top of player)
        setupCommentOverlayHost()

        // Set up comment markers overlay on timeline
        setupCommentMarkersOverlay(for: slider)

        // Subscribe to comment changes
        subscribeToCommentChanges()

        // Start listening for comments with initial progress = 0
        // This will be updated as playback progresses
        CommentsService.shared.resetSeenComments()
        CommentsService.shared.startListening(bookId: bookId, maxTimestamp: 0)

        SquabbleConfig.log("Comment display set up for book: \(bookId)")
    }

    private func setupCommentOverlayHost() {
        guard squabbleCommentOverlayHost == nil else { return }

        let overlayHost = CommentOverlayHostView()
        overlayHost.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayHost)

        // Position at top of player, below status bar
        NSLayoutConstraint.activate([
            overlayHost.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayHost.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayHost.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            overlayHost.heightAnchor.constraint(lessThanOrEqualToConstant: 150)
        ])

        squabbleCommentOverlayHost = overlayHost
    }

    private func setupCommentMarkersOverlay(for slider: UISlider) {
        guard squabbleCommentMarkersOverlay == nil else { return }

        let markersOverlay = CommentMarkersOverlayView()
        markersOverlay.addAsOverlay(for: slider)
        markersOverlay.onMarkerTapped = { [weak self] comment in
            self?.showCommentToast(comment)
        }

        squabbleCommentMarkersOverlay = markersOverlay
    }

    private func subscribeToCommentChanges() {
        var cancellables = squabbleCommentCancellables

        // Subscribe to comments publisher
        CommentsService.shared.$comments
            .receive(on: DispatchQueue.main)
            .sink { [weak self] comments in
                self?.updateCommentMarkers(with: comments)
            }
            .store(in: &cancellables)

        squabbleCommentCancellables = cancellables
    }

    private func updateCommentMarkers(with comments: [Comment]) {
        guard squabbleBookDuration > 0 else { return }

        let markerData = comments.map { comment in
            CommentMarkerData(comment: comment, bookDuration: squabbleBookDuration)
        }

        squabbleCommentMarkersOverlay?.commentMarkers = markerData
        SquabbleConfig.log("Updated comment markers: \(markerData.count) markers")
    }

    /// Check for and display newly visible comments based on progress.
    /// Call this from updateView(with:) or progress update handlers.
    /// - Parameter currentTime: Current playback position in seconds
    func checkForNewlyVisibleComments(at currentTime: TimeInterval) {
        guard SquabbleConfig.isEnabled else { return }
        guard let bookId = squabbleCurrentBookId else { return }

        // Update listener to include comments up to current time
        CommentsService.shared.startListening(bookId: bookId, maxTimestamp: currentTime)

        // Get and show newly visible comments
        let newlyVisible = CommentsService.shared.getNewlyVisibleComments(progress: currentTime)

        for comment in newlyVisible {
            showCommentToast(comment)
            CommentsService.shared.markAsSeen(comment.id)
        }
    }

    /// Display a comment as a toast overlay
    func showCommentToast(_ comment: Comment) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        squabbleCommentOverlayHost?.showComment(comment)
        SquabbleConfig.log("Showing comment toast from \(comment.userDisplayName)")
    }

    /// Clean up comment display when player is dismissed
    func tearDownSquabbleCommentDisplay() {
        CommentsService.shared.stopListening()

        // Cancel subscriptions
        squabbleCommentCancellables.forEach { $0.cancel() }
        squabbleCommentCancellables.removeAll()

        // Remove overlay views
        squabbleCommentOverlayHost?.removeFromSuperview()
        squabbleCommentOverlayHost = nil

        squabbleCommentMarkersOverlay?.removeFromSuperview()
        squabbleCommentMarkersOverlay = nil

        squabbleCurrentBookId = nil
        squabbleBookDuration = 0

        SquabbleConfig.log("Comment display torn down")
    }
}
