import SwiftUI
import UIKit
import SVProgressHUD
import WordPressAuthenticator
import WordPressData
import WordPressShared

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

        return true
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
        guard FeatureFlag.allowApplicationPasswords.enabled else { return false }
        guard let navigationController = viewController.navigationController else { return false }

        let view = LoginWithUrlView(presenter: viewController) { [weak viewController] blogID in
            viewController?.dismiss(animated: true)

            guard let blog = try? ContextManager.shared.mainContext.existingObject(with: blogID) else {
                return wpAssertionFailure("Impossible to reach here since the app has just signed into the blog")
            }

            WordPressAppDelegate.shared?.present(selfHostedSite: blog, from: navigationController)
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
