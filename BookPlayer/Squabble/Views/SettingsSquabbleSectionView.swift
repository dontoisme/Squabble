//
//  SettingsSquabbleSectionView.swift
//  BookPlayer
//
//  Created for Squabble - Social Audiobook Features
//
//  Settings section for Squabble guild management.
//

import SwiftUI

struct SettingsSquabbleSectionView: View {
    @StateObject private var guildService = GuildService.shared
    @EnvironmentObject var theme: ThemeViewModel

    var body: some View {
        Section {
            NavigationLink(value: SettingsScreen.squabbleGuild) {
                HStack {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Guild")
                        if let guild = guildService.currentGuild {
                            Text(guild.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Not in a guild")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        } header: {
            Text("Squabble")
                .foregroundStyle(theme.secondaryColor)
        } footer: {
            Text("Share your audiobook progress with friends.")
        }
    }
}

#Preview {
    NavigationStack {
        Form {
            SettingsSquabbleSectionView()
        }
    }
    .environmentObject(ThemeViewModel())
}
