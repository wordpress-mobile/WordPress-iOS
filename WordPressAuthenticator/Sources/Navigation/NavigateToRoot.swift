import Foundation

/// Navigates to the root of the unified login flow.
///
public struct NavigateToRoot: NavigationCommand {
    public init() {}
    public func execute(from: UIViewController?) {
        presentUnifiedSiteAddressView(navigationController: from?.navigationController)
    }
}

private extension NavigateToRoot {
    func presentUnifiedSiteAddressView(navigationController: UINavigationController?) {
        navigationController?.popToRootViewController(animated: true)
    }
}
