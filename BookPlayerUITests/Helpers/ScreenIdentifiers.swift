//
//  ScreenIdentifiers.swift
//  BookPlayerUITests
//
//  Centralized accessibility identifiers for UI testing.
//  These identifiers must match those added to the main app views.
//

import Foundation

/// Accessibility identifiers for UI test navigation
enum ScreenIdentifiers {

    // MARK: - Main Navigation

    enum MainView {
        static let tabLibrary = "mainview_tab_library"
        static let tabProfile = "mainview_tab_profile"
        static let tabSettings = "mainview_tab_settings"
    }

    // MARK: - Library Tab

    enum Library {
        static let viewEmpty = "library_view_empty"
        static let listItems = "library_list_items"
        static let buttonAdd = "library_button_add"
        static let miniPlayer = "library_miniplayer"
        static let searchField = "library_search_field"
    }

    // MARK: - Profile Tab (Squabble)

    enum Profile {
        static let stateNotLoggedIn = "profile_state_notloggedin"
        static let stateNoGuild = "profile_state_noguild"
        static let stateGuild = "profile_state_guild"
        static let buttonSignIn = "profile_button_signin"
        static let buttonCreateGuild = "profile_button_createguild"
        static let buttonJoinGuild = "profile_button_joinguild"
    }

    enum Guild {
        static let viewMain = "guild_view_main"
        static let listMembers = "guild_list_members"
        static let buttonInvite = "guild_button_invite"
        static let buttonLeave = "guild_button_leave"
        static let sheetCreate = "guild_sheet_create"
        static let sheetJoin = "guild_sheet_join"
        static let sheetInviteCode = "guild_sheet_invitecode"
        static let fieldGuildName = "guild_field_name"
        static let fieldInviteCode = "guild_field_code"
    }

    // MARK: - Settings Tab

    enum Settings {
        static let viewMain = "settings_view_main"
        static let rowThemes = "settings_row_themes"
        static let rowIcons = "settings_row_icons"
        static let rowControls = "settings_row_controls"
        static let rowAutoplay = "settings_row_autoplay"
        static let rowAutolock = "settings_row_autolock"
        static let rowStorage = "settings_row_storage"
        static let rowIntegrations = "settings_row_integrations"
        static let rowHardcover = "settings_row_hardcover"
        static let rowPrivacy = "settings_row_privacy"
        static let rowSupport = "settings_row_support"
        static let rowCredits = "settings_row_credits"
        static let rowDebug = "settings_row_debug"
    }

    enum SettingsThemes {
        static let viewMain = "settings_themes_view"
        static let listThemes = "settings_themes_list"
    }

    enum SettingsIcons {
        static let viewMain = "settings_icons_view"
        static let gridIcons = "settings_icons_grid"
    }

    enum SettingsStorage {
        static let viewMain = "settings_storage_view"
        static let listItems = "settings_storage_list"
    }

    // MARK: - Player

    enum Player {
        static let viewMain = "player_view_main"
        static let buttonPlayPause = "player_button_playpause"
        static let buttonChapters = "player_button_chapters"
        static let buttonBookmarks = "player_button_bookmarks"
        static let sliderProgress = "player_slider_progress"
        static let viewArtwork = "player_view_artwork"
        static let viewGhostOverlay = "player_view_ghost"
    }

    enum PlayerChapters {
        static let viewMain = "player_chapters_view"
        static let listChapters = "player_chapters_list"
    }

    enum PlayerBookmarks {
        static let viewMain = "player_bookmarks_view"
        static let listBookmarks = "player_bookmarks_list"
    }

    enum PlayerControls {
        static let viewMain = "player_controls_view"
        static let sliderSpeed = "player_controls_speed"
        static let sliderBoost = "player_controls_boost"
    }
}
