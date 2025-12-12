//
//  SquabbleProfileView.swift
//  BookPlayer
//
//  Created for Squabble - Social Audiobook Features
//
//  This view replaces the BookPlayer Profile tab when Squabble is enabled.
//  It provides guild management and guild library features.
//

import SwiftUI

struct SquabbleProfileView: View {
    @StateObject private var guildService = GuildService.shared
    @StateObject private var authService = SquabbleAuthService.shared
    @EnvironmentObject private var theme: ThemeViewModel

    @State private var showingCreateGuild = false
    @State private var showingJoinGuild = false
    @State private var showingInviteCode = false

    var body: some View {
        NavigationStack {
            Group {
                if !authService.isAuthenticated {
                    // Not logged in to Squabble
                    SquabbleNotLoggedInView()
                        .accessibilityIdentifier("profile_state_notloggedin")
                } else if guildService.isLoading {
                    ProgressView("Loading...")
                } else if let guild = guildService.currentGuild {
                    // Has a guild - show guild profile
                    SquabbleGuildProfileView(
                        guild: guild,
                        members: guildService.currentGuildMembers,
                        onShowInviteCode: { showingInviteCode = true }
                    )
                    .accessibilityIdentifier("profile_state_guild")
                } else {
                    // Logged in but no guild
                    SquabbleNoGuildProfileView(
                        onCreateGuild: { showingCreateGuild = true },
                        onJoinGuild: { showingJoinGuild = true }
                    )
                    .accessibilityIdentifier("profile_state_noguild")
                }
            }
            .navigationTitle("Guild")
            .navigationBarTitleDisplayMode(.inline)
            .applyListStyle(with: theme, background: theme.systemGroupedBackgroundColor)
            .miniPlayerSafeAreaInset()
            .sheet(isPresented: $showingCreateGuild) {
                CreateGuildView()
            }
            .sheet(isPresented: $showingJoinGuild) {
                JoinGuildView()
            }
            .sheet(isPresented: $showingInviteCode) {
                if let guild = guildService.currentGuild {
                    InviteCodeView(
                        guild: guild,
                        isOwner: guild.createdBy == authService.userId
                    )
                }
            }
        }
        .foregroundStyle(theme.primaryColor)
        .tint(theme.linkColor)
    }
}

// MARK: - Not Logged In View

struct SquabbleNotLoggedInView: View {
    @State private var showingLogin = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Sign in to Squabble")
                .font(.title2)
                .fontWeight(.bold)

            Text("Create an account to join guilds and share your audiobook progress with friends.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)

            Button {
                showingLogin = true
            } label: {
                Text("Sign In / Sign Up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .accessibilityIdentifier("profile_button_signin")
            .padding(.horizontal, 40)

            Spacer()
        }
        .sheet(isPresented: $showingLogin) {
            NavigationView {
                SquabbleLoginView(onAuthenticated: {
                    showingLogin = false
                    // Load guild after authentication
                    Task {
                        await GuildService.shared.loadCurrentGuild()
                    }
                })
            }
        }
    }
}

// MARK: - No Guild View

struct SquabbleNoGuildProfileView: View {
    let onCreateGuild: () -> Void
    let onJoinGuild: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Join a Guild")
                .font(.title2)
                .fontWeight(.bold)

            Text("Guilds let you see where your friends are in their audiobooks and share your progress.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)

            VStack(spacing: 12) {
                Button(action: onCreateGuild) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Guild")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .accessibilityIdentifier("profile_button_createguild")

                Button(action: onJoinGuild) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Join with Code")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                }
                .accessibilityIdentifier("profile_button_joinguild")
            }
            .padding(.horizontal, 40)

            Spacer()

            // Account info at bottom
            SquabbleAccountFooter()
        }
    }
}

// MARK: - Guild Profile View

struct SquabbleGuildProfileView: View {
    let guild: Guild
    let members: [GuildMember]
    let onShowInviteCode: () -> Void

    @State private var showingLeaveConfirmation = false
    @State private var isLeaving = false

    private var isOwner: Bool {
        guild.createdBy == SquabbleAuthService.shared.userId
    }

    var body: some View {
        Form {
            // Guild Header Section
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "person.3.fill")
                        .font(.title)
                        .foregroundColor(.accentColor)
                        .frame(width: 50, height: 50)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(10)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(guild.name)
                            .font(.headline)
                        Text("\(guild.memberCount) member\(guild.memberCount == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
            }

            // Invite Code Section
            Section {
                Button(action: onShowInviteCode) {
                    HStack {
                        Label("Invite Code", systemImage: "ticket")
                        Spacer()
                        Text(guild.inviteCode)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .accessibilityIdentifier("guild_button_invite")
                .foregroundColor(.primary)
            } footer: {
                Text("Share this code to invite friends.")
            }

            // Members Section
            Section("Members") {
                ForEach(members) { member in
                    HStack {
                        Image(systemName: member.role == .owner ? "crown.fill" : "person.fill")
                            .foregroundColor(member.role == .owner ? .yellow : .secondary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(member.displayName)
                            if member.role == .owner {
                                Text("Owner")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        if member.id == SquabbleAuthService.shared.userId {
                            Text("You")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
            }

            // Guild Library Section (placeholder for now)
            Section("Guild Library") {
                HStack {
                    Image(systemName: "books.vertical")
                        .foregroundColor(.secondary)
                    Text("Coming soon...")
                        .foregroundColor(.secondary)
                }
            }

            // Leave Guild Section (non-owners only)
            if !isOwner {
                Section {
                    Button(role: .destructive) {
                        showingLeaveConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            if isLeaving {
                                ProgressView()
                            } else {
                                Text("Leave Guild")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isLeaving)
                }
            }

            // Account Section
            Section {
                SquabbleAccountRow()
            }
        }
        .confirmationDialog("Leave Guild?", isPresented: $showingLeaveConfirmation, titleVisibility: .visible) {
            Button("Leave", role: .destructive) {
                leaveGuild()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will no longer see guild members' progress.")
        }
    }

    private func leaveGuild() {
        isLeaving = true
        Task {
            do {
                try await GuildService.shared.leaveGuild()
            } catch {
                isLeaving = false
            }
        }
    }
}

// MARK: - Account Components

struct SquabbleAccountRow: View {
    @StateObject private var authService = SquabbleAuthService.shared
    @State private var showingSignOutConfirmation = false

    var body: some View {
        HStack {
            Image(systemName: "person.circle")
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(authService.userEmail ?? "Signed In")
                    .font(.subheadline)
                Text("Squabble Account")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("Sign Out") {
                showingSignOutConfirmation = true
            }
            .font(.subheadline)
            .foregroundColor(.red)
        }
        .confirmationDialog("Sign Out?", isPresented: $showingSignOutConfirmation, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                try? authService.signOut()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct SquabbleAccountFooter: View {
    @StateObject private var authService = SquabbleAuthService.shared
    @State private var showingSignOutConfirmation = false

    var body: some View {
        VStack(spacing: 8) {
            if let email = authService.userEmail {
                Text("Signed in as \(email)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Sign Out") {
                    showingSignOutConfirmation = true
                }
                .font(.caption)
                .foregroundColor(.red)
            }
        }
        .padding(.bottom, 16)
        .confirmationDialog("Sign Out?", isPresented: $showingSignOutConfirmation, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                try? authService.signOut()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

#Preview {
    SquabbleProfileView()
        .environmentObject(ThemeViewModel())
}
