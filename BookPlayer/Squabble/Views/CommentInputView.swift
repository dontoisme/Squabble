//
//  CommentInputView.swift
//  BookPlayer
//
//  Created for Squabble - Social Audiobook Features
//
//  A sheet for entering timestamped comments on audiobooks.
//  Shows the current timestamp and a character-limited text field.
//

import SwiftUI
import UIKit

struct CommentInputView: View {
    let bookTitle: String
    let timestamp: TimeInterval
    let onSubmit: (String) async throws -> Void
    let onCancel: () -> Void

    @State private var commentText = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    @FocusState private var isTextFieldFocused: Bool

    private var formattedTimestamp: String {
        let hours = Int(timestamp) / 3600
        let minutes = (Int(timestamp) % 3600) / 60
        let seconds = Int(timestamp) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    private var charactersRemaining: Int {
        Comment.maxCharacterCount - commentText.count
    }

    private var isValidComment: Bool {
        let trimmed = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= Comment.maxCharacterCount
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Timestamp badge
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text(formattedTimestamp)
                        .font(.headline)
                        .monospacedDigit()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)

                // Book title
                Text(bookTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Comment input
                VStack(alignment: .trailing, spacing: 8) {
                    TextEditor(text: $commentText)
                        .frame(minHeight: 100, maxHeight: 150)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .focused($isTextFieldFocused)
                        .accessibilityIdentifier("comment_text_field")

                    // Character count
                    Text("\(charactersRemaining)")
                        .font(.caption)
                        .foregroundColor(charactersRemaining < 0 ? .red : .secondary)
                        .monospacedDigit()
                }
                .padding(.horizontal)

                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                // Submit button
                Button(action: submitComment) {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Post Comment")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isValidComment && !isSubmitting ? Color.accentColor : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(!isValidComment || isSubmitting)
                .padding(.horizontal)
                .accessibilityIdentifier("comment_submit_button")
            }
            .padding(.vertical)
            .navigationTitle("Add Comment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
            .accessibilityIdentifier("comment_input_sheet")
        }
        .onAppear {
            // Focus the text field after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }

    private func submitComment() {
        guard isValidComment else { return }

        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                try await onSubmit(commentText)
                // Success - the presenting view will dismiss
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSubmitting = false
                }
            }
        }
    }
}

// MARK: - UIKit Hosting

final class CommentInputViewController: UIHostingController<CommentInputView> {

    init(
        bookTitle: String,
        timestamp: TimeInterval,
        onSubmit: @escaping (String) async throws -> Void,
        onCancel: @escaping () -> Void
    ) {
        let view = CommentInputView(
            bookTitle: bookTitle,
            timestamp: timestamp,
            onSubmit: onSubmit,
            onCancel: onCancel
        )
        super.init(rootView: view)

        // Configure as medium sheet
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Preview

#if DEBUG
struct CommentInputView_Previews: PreviewProvider {
    static var previews: some View {
        CommentInputView(
            bookTitle: "Dungeon Crawler Carl - Book 5",
            timestamp: 5234.5, // 1:27:14
            onSubmit: { _ in },
            onCancel: { }
        )
    }
}
#endif
