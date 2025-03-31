import Foundation

/// Navigates to the WPCOM password flow.
///
public struct NavigateToEnterWPCOMPassword: NavigationCommand {
    private let loginFields: LoginFields

    public init(loginFields: LoginFields) {
        self.loginFields = loginFields
    }
    public func execute(from: UIViewController?) {
        let navigationController = (from as? UINavigationController) ?? from?.navigationController
        presentPasswordView(navigationController: navigationController,
                            loginFields: loginFields)
    }
}

private extension NavigateToEnterWPCOMPassword {
    func presentPasswordView(navigationController: UINavigationController?, loginFields: LoginFields) {
        guard let controller = PasswordViewController.instantiate(from: .password) else {
            WPAuthenticatorLogError("Failed to navigate to PasswordViewController from GetStartedViewController")
            return
        }

        controller.loginFields = loginFields
        navigationController?.pushViewController(controller, animated: true)
    }
}
