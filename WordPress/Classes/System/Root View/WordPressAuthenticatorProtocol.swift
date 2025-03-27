import SwiftUI
import UIKit
import SVProgressHUD
import WordPressAuthenticator

protocol WordPressAuthenticatorProtocol {
    static func loginUI() -> UIViewController?
    static func track(_ event: WPAnalyticsStat)
}

extension WordPressAuthenticator: WordPressAuthenticatorProtocol {
    static func loginUI() -> UIViewController? {
        Self.loginUI(
            showCancel: false,
            restrictToWPCom: false,
            onLoginButtonTapped: nil,
            continueWithDotCom: Self.continueWithDotCom(_:),
            selfHostedSiteLogin: Self.selfHostedSiteLogin(_:)
        )
    }

    static var dotComWebLoginEnabled: Bool {
        // Some UI tests go through the native login flow. They should be updated once the web sign in flow is fully
        // rolled out. We'll disable web login for UI tests for now.
        if UITestConfigurator.isUITesting() {
            return false
        }

        return RemoteFeatureFlag.dotComWebLogin.enabled()
    }

    private static func continueWithDotCom(_ viewController: UIViewController) -> Bool {
        guard Self.dotComWebLoginEnabled, let navigationController = viewController.navigationController else {
            return false
        }

        Task { @MainActor in
            let accountID = await WordPressDotComAuthenticator().signIn(from: navigationController, context: .default)
            if accountID != nil {
                WordPressAppDelegate.shared?.presentDefaultAccountPrimarySite(from: navigationController)
            }
        }

        return true
    }

    private static func selfHostedSiteLogin(_ viewController: UIViewController) -> Bool {
        guard FeatureFlag.authenticateUsingApplicationPassword.enabled else { return false }
        guard let window = viewController.view.window, let navigationController = viewController.navigationController else { return false }

        let client = SelfHostedSiteAuthenticator(session: URLSession(configuration: .ephemeral))
        let view = LoginWithUrlView(client: client, anchor: window) { [weak viewController] credentials in
            viewController?.dismiss(animated: true)

            SVProgressHUD.show()
            WordPressAuthenticator.shared.delegate!.sync(credentials: .init(wporg: credentials)) {
                SVProgressHUD.dismiss()

                NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: WordPressAuthenticator.WPSigninDidFinishNotification), object: nil)

                WordPressAuthenticator.shared.delegate!.presentLoginEpilogue(
                    in: navigationController,
                    for: .init(wporg: credentials),
                    source: .custom(source: "applicaton-password-login")) { /* Do nothing */ }
            }
        }.toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(SharedStrings.Button.cancel) { [weak viewController] in
                    viewController?.dismiss(animated: true)
                }
            }
        }
        let hostVC = UIHostingController(rootView: view)
        let navigationVC = UINavigationController(rootViewController: hostVC)
        navigationVC.modalPresentationStyle = .formSheet
        viewController.present(navigationVC, animated: true)
        return true
    }
}
