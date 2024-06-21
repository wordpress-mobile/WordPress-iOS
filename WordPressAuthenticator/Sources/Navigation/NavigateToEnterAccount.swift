import Foundation

/// Navigates to the unified "Continue with WordPress.com" flow.
///
public struct NavigateToEnterAccount: NavigationCommand {
    private let signInSource: SignInSource
    private let email: String?

    public init(signInSource: SignInSource, email: String? = nil) {
        self.signInSource = signInSource
        self.email = email
    }

    public func execute(from: UIViewController?) {
        continueWithDotCom(email: email, navigationController: from?.navigationController)
    }
}

private extension NavigateToEnterAccount {
    private func continueWithDotCom(email: String? = nil, navigationController: UINavigationController?) {
        guard let vc = GetStartedViewController.instantiate(from: .getStarted) else {
            WPAuthenticatorLogError("Failed to navigate from LoginPrologueViewController to GetStartedViewController")
            return
        }
        vc.source = signInSource
        vc.loginFields.username = email ?? ""

        navigationController?.pushViewController(vc, animated: true)
    }
}
