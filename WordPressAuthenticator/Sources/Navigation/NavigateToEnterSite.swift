import Foundation

/// Navigates to the unified site address login flow.
///
public struct NavigateToEnterSite: NavigationCommand {
    public init() {}
    public func execute(from: UIViewController?) {
        presentUnifiedSiteAddressView(navigationController: from?.navigationController)
    }
}

private extension NavigateToEnterSite {
    func presentUnifiedSiteAddressView(navigationController: UINavigationController?) {
        guard let vc = SiteAddressViewController.instantiate(from: .siteAddress) else {
            WPAuthenticatorLogError("Failed to navigate from LoginViewController to SiteAddressViewController")
            return
        }

        navigationController?.pushViewController(vc, animated: true)
    }
}
