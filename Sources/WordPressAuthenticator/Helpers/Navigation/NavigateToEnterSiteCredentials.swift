import Foundation

/// Navigates to the wp-admin site credentials flow.
///
public struct NavigateToEnterSiteCredentials: NavigationCommand {
    private let loginFields: LoginFields

    public init(loginFields: LoginFields) {
        self.loginFields = loginFields
    }
    public func execute(from: UIViewController?) {
        let navigationController = (from as? UINavigationController) ?? from?.navigationController
        presentSiteCredentialsView(navigationController: navigationController,
                                   loginFields: loginFields)
    }
}

private extension NavigateToEnterSiteCredentials {
    func presentSiteCredentialsView(navigationController: UINavigationController?, loginFields: LoginFields) {
        guard let controller = SiteCredentialsViewController.instantiate(from: .siteAddress) else {
            WPAuthenticatorLogError("Failed to navigate to SiteCredentialsViewController")
            return
        }

        controller.loginFields = loginFields
        navigationController?.pushViewController(controller, animated: true)
    }
}
