//
//  CommentOverlayView.swift
//  BookPlayer
//
//  Created for Squabble - Social Audiobook Features
//
//  Toast-style overlay for displaying guildmate comments when the user
//  passes the timestamp where the comment was left.
//

import SwiftUI
import UIKit

// MARK: - SwiftUI View

struct CommentOverlayView: View {
    let comment: Comment
    let onDismiss: () -> Void

    @State private var isVisible = false
    @State private var dismissTask: Task<Void, Never>?

    /// Auto-dismiss duration in seconds
    private let autoDismissDuration: TimeInterval = 4.0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Name and timestamp
            HStack {
                // User avatar/initials
                ZStack {
                    Circle()
                        .fill(userColor)
                        .frame(width: 28, height: 28)
                    Text(initials)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(comment.userDisplayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text("at \(comment.formattedTimestamp)")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                // Dismiss button
                Button(action: dismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            // Comment text
            Text(comment.text)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.15))
                .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(userColor.opacity(0.4), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -20)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            withAnimation {
                isVisible = true
            }
            scheduleAutoDismiss()
        }
        .onDisappear {
            dismissTask?.cancel()
        }
        .accessibilityIdentifier("comment_overlay_toast")
    }

    // MARK: - Helpers

    private var initials: String {
        let components = comment.userDisplayName.components(separatedBy: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1).uppercased()
            let last = components[components.count - 1].prefix(1).uppercased()
            return "\(first)\(last)"
        } else {
            return String(comment.userDisplayName.prefix(2)).uppercased()
        }
    }

    private var userColor: Color {
        // Generate consistent color from user ID
        let hash = comment.userId.hash
        let hue = Double(abs(hash) % 360) / 360.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.7)
    }

    private func dismiss() {
        dismissTask?.cancel()
        withAnimation {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            onDismiss()
        }
    }

    private func scheduleAutoDismiss() {
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(autoDismissDuration * 1_000_000_000))
            if !Task.isCancelled {
                await MainActor.run {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - UIKit Integration

/// UIKit host for displaying comment toast overlays
final class CommentOverlayHostView: UIView {

    private var hostingController: UIHostingController<AnyView>?
    private var currentComment: Comment?

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
    }

    /// Show a comment toast. If another comment is showing, it will be replaced.
    func showComment(_ comment: Comment) {
        // Remove existing toast
        hideCurrentComment(animated: false)

        currentComment = comment

        let overlay = CommentOverlayView(comment: comment) { [weak self] in
            self?.hideCurrentComment(animated: false)
        }

        let hostingController = UIHostingController(rootView: AnyView(overlay))
        hostingController.view.backgroundColor = .clear
        self.hostingController = hostingController

        addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: topAnchor),
            hostingController.view.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ])
    }

    /// Hide the current comment toast
    func hideCurrentComment(animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                self.hostingController?.view.alpha = 0
            }, completion: { _ in
                self.hostingController?.view.removeFromSuperview()
                self.hostingController = nil
                self.currentComment = nil
            })
        } else {
            hostingController?.view.removeFromSuperview()
            hostingController = nil
            currentComment = nil
        }
    }

    /// Check if a comment is currently being displayed
    var isShowingComment: Bool {
        return currentComment != nil
    }
}

// MARK: - Preview

#if DEBUG
struct CommentOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                Spacer()

                CommentOverlayView(
                    comment: Comment(
                        id: "preview-1",
                        bookId: "book-1",
                        bookTitle: "The Great Adventure",
                        userId: "user-123",
                        userDisplayName: "Sarah Miller",
                        timestamp: 3725.5,
                        text: "WHAT. NO. WHAT. I can't believe that just happened! This book is amazing!",
                        createdAt: Date()
                    ),
                    onDismiss: {}
                )

                Spacer()
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}
#endif
