import UIKit
import WordPressAuthenticator

protocol WordPressAuthenticatorProtocol {
    static func loginUI() -> UIViewController?
    static func track(_ event: WPAnalyticsStat)
}

extension WordPressAuthenticator: WordPressAuthenticatorProtocol {
    static func loginUI() -> UIViewController? {
        Self.loginUI(showCancel: false, restrictToWPCom: false, onLoginButtonTapped: nil, continueWithDotCom: { viewController in
            // TODO: Replce with a remote feature flag.
            // Enable web-based login for debug builds until the remote feature flag is available.
            #if DEBUG
            let webLoginEnabled = true
            #else
            let webLoginEnabled = false
            #endif

            guard webLoginEnabled, let navigationController = viewController.navigationController else {
                return false
            }

            Task { @MainActor in
                await WordPressDotComAuthenticator().signIn(from: navigationController)
            }

            return true
        })
    }
}
