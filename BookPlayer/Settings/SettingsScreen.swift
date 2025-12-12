//
//  SettingsScreen.swift
//  BookPlayer
//
//  Created by Gianni Carlo on 19/7/25.
//  Copyright © 2025 BookPlayer LLC. All rights reserved.
//

import Foundation

enum SettingsScreen: String, Hashable {
  case themes, icons
  case controls, autoplay, autolock
  case storage, syncbackup
  case shortcuts
  case jellyfin, audiobookshelf, hardcover
  case squabbleGuild  // SQUABBLE: Guild management screen
  case squabbleDebug  // SQUABBLE: Debug tools (DEBUG builds only)
  case tipjar
  case credits
}
