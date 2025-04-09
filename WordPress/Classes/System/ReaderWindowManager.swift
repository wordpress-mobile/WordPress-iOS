import UIKit
import SwiftUI
import Combine
import WordPressShared

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

    private func showSingInUI() {
        let welcomeVC = UIHostingController(rootView: ReaderWelcomeView {
            
        })
        show(welcomeVC)
    }
}
