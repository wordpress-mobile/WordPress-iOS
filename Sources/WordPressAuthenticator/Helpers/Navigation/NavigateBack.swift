import Foundation

/// Navigates back one step.
///
public struct NavigateBack: NavigationCommand {
    public init() {}
    public func execute(from: UIViewController?) {
        pop(navigationController: from?.navigationController)
    }
}

private extension NavigateBack {
    func pop(navigationController: UINavigationController?) {
        navigationController?.popViewController(animated: true)
    }
}
