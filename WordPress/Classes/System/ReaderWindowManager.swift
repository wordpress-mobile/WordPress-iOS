import UIKit
import SwiftUI
import Combine
import WordPressData
import WordPressShared
import WordPressUI

class ReaderWindowManager: WindowManager {
    override func showUI(for blog: Blog?, animated: Bool = true) {
        // TODO: (reader) do we need automatic migration or SSO?

        // Show App UI if user is logged in
        if AccountHelper.isLoggedIn {
            showAppUI(for: blog)
        } else {
            showSignInUI()
        }
    }

    override func showSignInUI(completion: Completion? = nil) {
        let welcomeVC = UIHostingController(rootView: ReaderWelcomeView { [weak self] in
            self?.continueWithDotComTapped()
        })
        show(welcomeVC)
    }

    private func continueWithDotComTapped() {
        guard let presentingViewController = UIViewController.topViewController else {
            return wpAssertionFailure("missing top view controller")
        }
        Task { @MainActor [weak self] in
            let accountID = await WordPressDotComAuthenticator().signIn(from: presentingViewController, context: .default)
            if accountID != nil {
                self?.showAppUI()
            }
        }
    }
}
