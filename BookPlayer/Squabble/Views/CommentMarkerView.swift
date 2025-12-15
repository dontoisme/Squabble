//
//  CommentMarkerView.swift
//  BookPlayer
//
//  Created for Squabble - Social Audiobook Features
//
//  Displays small comment markers on the player timeline for comments
//  the user has already passed. Tapping shows the comment popup.
//

import UIKit

// MARK: - Comment Marker Data

/// Represents a comment marker to display on the timeline
struct CommentMarkerData {
    let comment: Comment
    /// Position as percentage (0-100) of the timeline
    let percent: Double

    init(comment: Comment, bookDuration: TimeInterval) {
        self.comment = comment
        self.percent = bookDuration > 0 ? (comment.timestamp / bookDuration) * 100 : 0
    }
}

// MARK: - Comment Markers Overlay View

/// Overlay view that displays comment markers on top of the progress slider.
/// Similar to SquabbleGhostOverlayView but for comments.
final class CommentMarkersOverlayView: UIView {

    // MARK: - Properties

    /// Comment markers to display
    var commentMarkers: [CommentMarkerData] = [] {
        didSet {
            updateMarkerViews()
        }
    }

    /// Callback when a marker is tapped
    var onMarkerTapped: ((Comment) -> Void)?

    /// Horizontal inset to match ProgressSlider track
    private let horizontalInset: CGFloat = 24.0

    /// Comment marker diameter
    private let markerDiameter: CGFloat = 16.0

    /// Container for marker views
    private var markerViews: [CommentMarkerView] = []

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        isUserInteractionEnabled = true
        clipsToBounds = false
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        positionMarkers()
    }

    private func updateMarkerViews() {
        // Remove old markers
        markerViews.forEach { $0.removeFromSuperview() }
        markerViews.removeAll()

        // Create new markers
        for markerData in commentMarkers {
            let markerView = CommentMarkerView(markerData: markerData, diameter: markerDiameter)
            markerView.onTap = { [weak self] in
                self?.onMarkerTapped?(markerData.comment)
            }
            addSubview(markerView)
            markerViews.append(markerView)
        }

        positionMarkers()
    }

    private func positionMarkers() {
        let sliderRect = bounds.insetBy(dx: horizontalInset, dy: 0.0)
        let yCenter = bounds.height / 2

        for (index, markerView) in markerViews.enumerated() {
            guard index < commentMarkers.count else { continue }
            let markerData = commentMarkers[index]

            // Calculate x position based on percentage (0-100)
            let normalizedPercent = CGFloat(markerData.percent / 100.0)
            let xPosition = sliderRect.origin.x + (sliderRect.width * normalizedPercent)

            markerView.frame = CGRect(
                x: xPosition - markerDiameter / 2,
                y: yCenter - markerDiameter / 2,
                width: markerDiameter,
                height: markerDiameter
            )
        }
    }
}

// MARK: - Individual Comment Marker View

private final class CommentMarkerView: UIView {

    private let markerData: CommentMarkerData
    private let diameter: CGFloat
    var onTap: (() -> Void)?

    private lazy var iconLabel: UILabel = {
        let label = UILabel()
        label.text = "💬"
        label.font = .systemFont(ofSize: 8)
        label.textAlignment = .center
        return label
    }()

    init(markerData: CommentMarkerData, diameter: CGFloat) {
        self.markerData = markerData
        self.diameter = diameter
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .clear
        isUserInteractionEnabled = true

        // Add shadow for depth
        layer.shadowColor = UIColor.systemBlue.cgColor
        layer.shadowOffset = .zero
        layer.shadowRadius = 3
        layer.shadowOpacity = 0.5

        addSubview(iconLabel)

        // Add tap gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)

        accessibilityIdentifier = "comment_marker"
        accessibilityLabel = "Comment by \(markerData.comment.userDisplayName)"
        accessibilityHint = "Double tap to view comment"
        isAccessibilityElement = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        iconLabel.frame = bounds
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let circleRect = rect.insetBy(dx: 1, dy: 1)

        // Draw filled circle background
        let circlePath = UIBezierPath(ovalIn: circleRect)
        UIColor.systemBlue.withAlphaComponent(0.8).setFill()
        circlePath.fill()

        // Draw border
        UIColor.white.withAlphaComponent(0.9).setStroke()
        circlePath.lineWidth = 1.0
        circlePath.stroke()
    }

    @objc private func handleTap() {
        // Animate tap feedback
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }, completion: { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = .identity
            }
        })

        onTap?()
    }
}

// MARK: - Factory

extension CommentMarkersOverlayView {

    /// Create a comment markers overlay configured to match a ProgressSlider.
    /// - Parameter slider: The ProgressSlider to overlay
    /// - Returns: Configured comment markers overlay view
    static func overlay(for slider: UISlider) -> CommentMarkersOverlayView {
        let overlay = CommentMarkersOverlayView(frame: slider.bounds)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        return overlay
    }

    /// Add this overlay as a subview of the slider's superview, positioned over the slider.
    /// - Parameter slider: The ProgressSlider to overlay
    func addAsOverlay(for slider: UISlider) {
        guard let superview = slider.superview else {
            SquabbleConfig.log("Cannot add comment markers overlay - slider has no superview")
            return
        }

        superview.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: slider.leadingAnchor),
            trailingAnchor.constraint(equalTo: slider.trailingAnchor),
            topAnchor.constraint(equalTo: slider.topAnchor),
            bottomAnchor.constraint(equalTo: slider.bottomAnchor)
        ])
    }
}
