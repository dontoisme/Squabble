//
//  LoadingCoordinator+Squabble.swift
//  BookPlayer
//
//  Created for Squabble - Social Audiobook Features
//
//  This extension provides the Squabble auth gate functionality.
//  It integrates with LoadingCoordinator to show the login screen
//  before allowing access to the main app.
//

import UIKit

extension LoadingCoordinator {

    /// Called after the loading sequence completes.
    /// Shows Squabble login if not authenticated, otherwise proceeds to main app.
    ///
    /// This is the ONLY Squabble integration point in LoadingCoordinator.
    /// The base LoadingCoordinator calls this method from didFinishLoadingSequence().
    func squabbleAuthGate(completion: @escaping () -> Void) {
        guard SquabbleConfig.isEnabled else {
            // Squabble disabled, proceed directly
            completion()
            return
        }

        if SquabbleAuthService.shared.isAuthenticated {
            SquabbleConfig.log("User authenticated, proceeding to main app")
            completion()
        } else {
            SquabbleConfig.log("User not authenticated, showing login")
            showSquabbleLogin(onAuthenticated: completion)
        }
    }

    /// Present the Squabble login screen.
    /// - Parameter onAuthenticated: Callback when authentication succeeds
    private func showSquabbleLogin(onAuthenticated: @escaping () -> Void) {
        let loginVC = SquabbleLoginViewController(onAuthenticated: onAuthenticated)
        flow.navigationController.setViewControllers([loginVC], animated: true)
    }
}
