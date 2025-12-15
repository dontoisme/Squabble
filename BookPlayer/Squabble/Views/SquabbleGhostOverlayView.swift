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
            updateMarkerViews()
        }
    }

    /// Horizontal inset to match ProgressSlider track
    private let horizontalInset: CGFloat = 24.0

    /// Ghost marker diameter
    private let ghostDiameter: CGFloat = 22.0

    /// Container for marker views
    private var markerViews: [GhostMarkerView] = []

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
        clipsToBounds = false  // Allow shadows to render outside bounds
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
        for ghost in ghostMarkers {
            let markerView = GhostMarkerView(ghost: ghost, diameter: ghostDiameter)
            addSubview(markerView)
            markerViews.append(markerView)
        }

        positionMarkers()
    }

    private func positionMarkers() {
        let sliderRect = bounds.insetBy(dx: horizontalInset, dy: 0.0)
        let yCenter = bounds.height / 2

        for (index, markerView) in markerViews.enumerated() {
            guard index < ghostMarkers.count else { continue }
            let ghost = ghostMarkers[index]

            // Calculate x position based on percentage (0-100)
            let normalizedPercent = CGFloat(ghost.percent / 100.0)
            let xPosition = sliderRect.origin.x + (sliderRect.width * normalizedPercent)

            markerView.frame = CGRect(
                x: xPosition - ghostDiameter / 2,
                y: yCenter - ghostDiameter / 2,
                width: ghostDiameter,
                height: ghostDiameter
            )
        }
    }
}

// MARK: - Ghost Marker View

/// Individual marker view with initials and styling
private class GhostMarkerView: UIView {

    private let ghost: GhostMarker
    private let diameter: CGFloat

    private lazy var initialsLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 10, weight: .bold)
        label.textColor = .white
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }()

    init(ghost: GhostMarker, diameter: CGFloat) {
        self.ghost = ghost
        self.diameter = diameter
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .clear

        // Add shadow for glow effect
        layer.shadowColor = ghost.color.cgColor
        layer.shadowOffset = .zero
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.6

        // Add initials label
        addSubview(initialsLabel)
        initialsLabel.text = getInitials(from: ghost.name)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        initialsLabel.frame = bounds
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        // Draw gradient-filled circle
        let circleRect = rect.insetBy(dx: 2, dy: 2)

        // Create gradient
        let colors = [
            ghost.color.withAlphaComponent(0.9).cgColor,
            ghost.color.withAlphaComponent(0.7).cgColor
        ]
        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors as CFArray,
            locations: [0.0, 1.0]
        )!

        // Clip to circle
        let circlePath = UIBezierPath(ovalIn: circleRect)
        context.saveGState()
        circlePath.addClip()

        // Draw gradient
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: circleRect.midX, y: circleRect.minY),
            end: CGPoint(x: circleRect.midX, y: circleRect.maxY),
            options: []
        )
        context.restoreGState()

        // Draw border
        UIColor.white.withAlphaComponent(0.9).setStroke()
        circlePath.lineWidth = 1.5
        circlePath.stroke()
    }

    private func getInitials(from name: String) -> String {
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            // First letter of first and last name
            let first = components[0].prefix(1).uppercased()
            let last = components[components.count - 1].prefix(1).uppercased()
            return "\(first)\(last)"
        } else {
            // Just first letter or first two letters
            return String(name.prefix(2)).uppercased()
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
