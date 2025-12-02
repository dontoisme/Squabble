//
//  AppDelegate+Squabble.swift
//  BookPlayer
//
//  Created for Squabble - Social Audiobook Features
//
//  This extension provides Squabble initialization for AppDelegate.
//  Call setupSquabble() after Firebase is configured.
//

import Foundation

extension AppDelegate {

    /// Initialize all Squabble features.
    /// Call this after FirebaseApp.configure() in didFinishLaunchingWithOptions.
    func setupSquabble() {
        SquabbleManager.shared.setup()
    }
}
