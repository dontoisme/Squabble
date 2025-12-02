//
//  SquabbleGhostOverlayView.swift
//  BookPlayer
//
//  Created for Squabble - Social Audiobook Features
//
//  This view displays ghost markers as an overlay on top of the progress slider.
//  It's designed to be positioned exactly over the ProgressSlider track.
//

import UIKit

/// Overlay view that displays guild members' progress as ghost markers.
/// Add this as a subview positioned over the ProgressSlider.
final class SquabbleGhostOverlayView: UIView {

    // MARK: - Properties

    /// Ghost markers to display
    var ghostMarkers: [GhostMarker] = [] {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Horizontal inset to match ProgressSlider track
    private let horizontalInset: CGFloat = 24.0

    /// Track height to match ProgressSlider
    private let trackHeight: CGFloat = 3.0

    /// Ghost marker radius
    private let ghostRadius: CGFloat = 5.0

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
        isUserInteractionEnabled = false  // Allow touches to pass through to slider
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        guard !ghostMarkers.isEmpty else { return }

        let sliderRect = bounds.insetBy(dx: horizontalInset, dy: 0.0)
        let yCenter = bounds.height / 2

        for ghost in ghostMarkers {
            // Calculate x position based on percentage (0-100)
            let normalizedPercent = CGFloat(ghost.percent / 100.0)
            let xPosition = sliderRect.origin.x + (sliderRect.width * normalizedPercent)

            // Draw ghost circle
            ghost.color.set()
            let ghostRect = CGRect(
                x: xPosition - ghostRadius,
                y: yCenter - ghostRadius,
                width: ghostRadius * 2,
                height: ghostRadius * 2
            )
            let ghostPath = UIBezierPath(ovalIn: ghostRect)
            ghostPath.fill()

            // Draw border
            UIColor.white.withAlphaComponent(0.8).set()
            ghostPath.lineWidth = 1.0
            ghostPath.stroke()
        }
    }
}

// MARK: - Factory

extension SquabbleGhostOverlayView {

    /// Create a ghost overlay configured to match a ProgressSlider.
    /// - Parameter slider: The ProgressSlider to overlay
    /// - Returns: Configured ghost overlay view
    static func overlay(for slider: UISlider) -> SquabbleGhostOverlayView {
        let overlay = SquabbleGhostOverlayView(frame: slider.bounds)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        return overlay
    }

    /// Add this overlay as a subview of the slider's superview, positioned over the slider.
    /// - Parameter slider: The ProgressSlider to overlay
    func addAsOverlay(for slider: UISlider) {
        guard let superview = slider.superview else {
            SquabbleConfig.log("Cannot add ghost overlay - slider has no superview")
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
