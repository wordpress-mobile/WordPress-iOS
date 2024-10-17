import UIKit
import WordPressAuthenticator

protocol WordPressAuthenticatorProtocol {
    static func loginUI() -> UIViewController?
    static func track(_ event: WPAnalyticsStat)
}

extension WordPressAuthenticator: WordPressAuthenticatorProtocol {
    static func loginUI() -> UIViewController? {
        Self.loginUI(showCancel: false, restrictToWPCom: false, onLoginButtonTapped: nil, continueWithDotCom: { viewController in
            guard Self.dotComWebLoginEnabled, let navigationController = viewController.navigationController else {
                return false
            }

            Task { @MainActor in
                await WordPressDotComAuthenticator().signIn(from: navigationController)
            }

            return true
        })
    }

    static var dotComWebLoginEnabled: Bool {
        // Some UI tests go through the native login flow. They should be updated once the web sign in flow is fully
        // rolled out. We'll disable web login for UI tests for now.
        if UITestConfigurator.isUITesting() {
            return false
        }

        // TODO: Replce with a remote feature flag.
        // Enable web-based login for debug builds until the remote feature flag is available.
        #if DEBUG
        let webLoginEnabled = true
        #else
        let webLoginEnabled = false
        #endif

        return webLoginEnabled
    }
}
