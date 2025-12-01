//
//  SquabbleLoginView.swift
//  BookPlayer
//
//  Created for Squabble - Phase 0 Spike
//

import SwiftUI

struct SquabbleLoginView: View {
    @StateObject private var authService = SquabbleAuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    let onAuthenticated: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Logo/Title
                VStack(spacing: 8) {
                    Image(systemName: "book.closed.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.accentColor)

                    Text("Squabble")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("A fantasy tavern for audiobook guilds")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)

                Spacer()

                // Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(isSignUp ? .newPassword : .password)

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button(action: performAuth) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(isSignUp ? "Create Account" : "Sign In")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(isLoading || email.isEmpty || password.isEmpty)

                    Button(action: { isSignUp.toggle() }) {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.footnote)
                    }
                }
                .padding(.horizontal, 32)

                Spacer()

                // Dev note
                Text("Phase 0 Spike - Email/Password Auth")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 16)
            }
            .navigationBarHidden(true)
        }
        .onChange(of: authService.isAuthenticated) { isAuth in
            if isAuth {
                onAuthenticated()
            }
        }
        .onAppear {
            // Check if already authenticated
            if authService.isAuthenticated {
                onAuthenticated()
            }
        }
    }

    private func performAuth() {
        guard !email.isEmpty, !password.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                if isSignUp {
                    try await authService.signUp(email: email, password: password)
                } else {
                    try await authService.signIn(email: email, password: password)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - UIKit Hosting

import UIKit

final class SquabbleLoginViewController: UIHostingController<SquabbleLoginView> {

    init(onAuthenticated: @escaping () -> Void) {
        let view = SquabbleLoginView(onAuthenticated: onAuthenticated)
        super.init(rootView: view)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
