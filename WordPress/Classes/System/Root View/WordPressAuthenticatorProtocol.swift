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

    private static func continueWithDotCom(_ viewController: UIViewController) -> Bool {
        guard let navigationController = viewController.navigationController else {
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

        let loginCompleted: (TaggedManagedObjectID<Blog>) -> Void = { [weak viewController] blogID in
            viewController?.dismiss(animated: true)

            guard let blog = try? ContextManager.shared.mainContext.existingObject(with: blogID) else {
                return wpAssertionFailure("Impossible to reach here since the app has just signed into the blog")
            }

            WordPressAppDelegate.shared?.present(selfHostedSite: blog, from: navigationController)
        }

        let presentDotComLogin = { [weak viewController] in
            guard let viewController else { return }
            _ = Self.continueWithDotCom(viewController)
        }

        let view = NavigationStack {
            LoginWithUrlView(
                presenter: viewController,
                loginCompleted: loginCompleted,
                presentDotComLogin: presentDotComLogin
            )
        }
        let hostVC = UIHostingController(rootView: view)
        hostVC.modalPresentationStyle = .formSheet
        viewController.present(hostVC, animated: true)
        return true
    }
}
