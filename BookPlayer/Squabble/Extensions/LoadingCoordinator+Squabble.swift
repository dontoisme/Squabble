//
//  LoadingCoordinator+Squabble.swift
//  BookPlayer
//
//  Created for Squabble - Social Audiobook Features
//
//  This extension provides the Squabble integration point in LoadingCoordinator.
//  Auth is now lazy - users sign in when they access guild features from the Profile tab.
//

import UIKit

extension LoadingCoordinator {

    /// Called after the loading sequence completes.
    /// No longer gates on auth - users can use the app freely and sign in
    /// when they want to access guild features from the Profile tab.
    ///
    /// This is the ONLY Squabble integration point in LoadingCoordinator.
    /// The base LoadingCoordinator calls this method from didFinishLoadingSequence().
    func squabbleAuthGate(completion: @escaping () -> Void) {
        // No auth gate - proceed directly to main app
        // Users will sign in lazily when they access guild features
        SquabbleConfig.log("Proceeding to main app (lazy auth)")
        completion()
    }
}
