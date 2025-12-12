//
//  GuildView.swift
//  BookPlayer
//
//  Created for Squabble - Social Audiobook Features
//
//  Main view for guild management including:
//  - Displaying current guild info and members
//  - Creating a new guild
//  - Joining a guild via invite code
//  - Leaving the current guild
//  - Generating new invite codes
//

import SwiftUI

struct GuildView: View {
    @StateObject private var guildService = GuildService.shared
    @State private var showingCreateGuild = false
    @State private var showingJoinGuild = false
    @State private var errorMessage: String?
    @State private var showingError = false

    var body: some View {
        NavigationView {
            Group {
                if guildService.isLoading {
                    ProgressView("Loading...")
                } else if let guild = guildService.currentGuild {
                    GuildDetailView(guild: guild, members: guildService.currentGuildMembers)
                } else {
                    NoGuildView(
                        onCreateGuild: { showingCreateGuild = true },
                        onJoinGuild: { showingJoinGuild = true }
                    )
                }
            }
            .navigationTitle("Guild")
            .sheet(isPresented: $showingCreateGuild) {
                CreateGuildView()
            }
            .sheet(isPresented: $showingJoinGuild) {
                JoinGuildView()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }
}

// MARK: - No Guild View

struct NoGuildView: View {
    let onCreateGuild: () -> Void
    let onJoinGuild: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Guild")
                .font(.title)
                .fontWeight(.bold)

            Text("Join a guild to see where your friends are in their audiobooks and share your progress.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

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

                Button(action: onJoinGuild) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Join Guild")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
}

// MARK: - Create Guild View

struct CreateGuildView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var guildName = ""
    @State private var isCreating = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Guild Name", text: $guildName)
                        .autocapitalization(.words)
                } header: {
                    Text("Guild Name")
                } footer: {
                    Text("Choose a name for your reading group.")
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Create Guild")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createGuild()
                    }
                    .disabled(guildName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .disabled(isCreating)
            .overlay {
                if isCreating {
                    ProgressView()
                }
            }
        }
    }

    private func createGuild() {
        let name = guildName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        isCreating = true
        errorMessage = nil

        Task {
            do {
                _ = try await GuildService.shared.createGuild(name: name)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isCreating = false
                }
            }
        }
    }
}

// MARK: - Join Guild View

struct JoinGuildView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var inviteCode = ""
    @State private var isJoining = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Invite Code", text: $inviteCode)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                        .font(.system(.body, design: .monospaced))
                } header: {
                    Text("Invite Code")
                } footer: {
                    Text("Enter the 6-character invite code from your guild.")
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Join Guild")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Join") {
                        joinGuild()
                    }
                    .disabled(inviteCode.trimmingCharacters(in: .whitespaces).count < 6 || isJoining)
                }
            }
            .disabled(isJoining)
            .overlay {
                if isJoining {
                    ProgressView()
                }
            }
        }
    }

    private func joinGuild() {
        let code = inviteCode.trimmingCharacters(in: .whitespaces)
        guard code.count >= 6 else { return }

        isJoining = true
        errorMessage = nil

        Task {
            do {
                _ = try await GuildService.shared.joinGuild(inviteCode: code)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isJoining = false
                }
            }
        }
    }
}

// MARK: - Guild Detail View

struct GuildDetailView: View {
    let guild: Guild
    let members: [GuildMember]

    @State private var showingInviteCode = false
    @State private var showingLeaveConfirmation = false
    @State private var isLeaving = false
    @State private var errorMessage: String?
    @State private var showingError = false

    private var isOwner: Bool {
        guild.createdBy == SquabbleAuthService.shared.userId
    }

    var body: some View {
        List {
            // Guild Info Section
            Section {
                HStack {
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
                }
                .padding(.vertical, 4)
            }

            // Invite Code Section
            Section {
                Button {
                    showingInviteCode = true
                } label: {
                    HStack {
                        Label("Invite Code", systemImage: "ticket")
                        Spacer()
                        Text(guild.inviteCode)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.primary)
            } footer: {
                Text("Share this code with friends to invite them to the guild.")
            }

            // Members Section
            Section("Members") {
                ForEach(members) { member in
                    HStack {
                        Image(systemName: member.role == .owner ? "crown.fill" : "person.fill")
                            .foregroundColor(member.role == .owner ? .yellow : .secondary)

                        VStack(alignment: .leading) {
                            Text(member.displayName)
                                .font(.body)
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

            // Leave Guild Section
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
        }
        .sheet(isPresented: $showingInviteCode) {
            InviteCodeView(guild: guild, isOwner: isOwner)
        }
        .confirmationDialog("Leave Guild?", isPresented: $showingLeaveConfirmation, titleVisibility: .visible) {
            Button("Leave", role: .destructive) {
                leaveGuild()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will no longer see guild members' progress and they won't see yours.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private func leaveGuild() {
        isLeaving = true
        Task {
            do {
                try await GuildService.shared.leaveGuild()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isLeaving = false
                }
            }
        }
    }
}

// MARK: - Invite Code View

struct InviteCodeView: View {
    let guild: Guild
    let isOwner: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var currentCode: String
    @State private var isRegenerating = false
    @State private var copied = false

    init(guild: Guild, isOwner: Bool) {
        self.guild = guild
        self.isOwner = isOwner
        self._currentCode = State(initialValue: guild.inviteCode)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "ticket.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.accentColor)

                Text("Invite Code")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(currentCode)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .tracking(8)

                Text("Share this code with friends to invite them to \(guild.name)")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    Button {
                        UIPasteboard.general.string = currentCode
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            copied = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            Text(copied ? "Copied!" : "Copy Code")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }

                    Button {
                        shareCode()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }

                    if isOwner {
                        Button {
                            regenerateCode()
                        } label: {
                            HStack {
                                if isRegenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                                Text("Generate New Code")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(10)
                        }
                        .disabled(isRegenerating)
                    }
                }
                .padding(.horizontal, 40)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func shareCode() {
        let text = "Join my Squabble guild \"\(guild.name)\"! Use invite code: \(currentCode)"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    private func regenerateCode() {
        isRegenerating = true
        Task {
            do {
                let newCode = try await GuildService.shared.regenerateInviteCode()
                await MainActor.run {
                    currentCode = newCode
                    isRegenerating = false
                }
            } catch {
                await MainActor.run {
                    isRegenerating = false
                }
            }
        }
    }
}

// MARK: - UIKit Wrapper

final class GuildViewController: UIHostingController<GuildView> {
    init() {
        super.init(rootView: GuildView())
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
