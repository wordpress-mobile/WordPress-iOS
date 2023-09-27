import UIKit

extension RootViewPresenter {

    /// Navigates to "Me > App Settings > Privacy Settings"
    func navigateToPrivacySettings() {
        navigateToMeScene()
            .then(navigateToAppSettings())
            .then(navigateToPrivacySettings())
            .start(on: rootViewController, animated: true)
    }

    // MARK: - Navigators

    /// Creates a navigation action to navigate to the "Me" scene.
    ///
    /// The "Me" scene's navigation controller is popped to the root in case the "Me" scene was already presented.
    private func navigateToMeScene() -> ViewControllerNavigationAction {
        return .init { [weak self] context, completion in
            guard let self else {
                return
            }
            CATransaction.perform {
                self.showMeScreen()
                self.popMeTabToRoot()
            } completion: {
                completion(self.meViewController)
            }
        }
    }

    /// Creates a navigation action to navigate to the "App Settings" from the "Me" scene.
    private func navigateToAppSettings() -> ViewControllerNavigationAction {
        return .init { context, completion in
            let me: MeViewController = try context.fromViewController()
            CATransaction.perform {
                me.navigateToAppSettings()
            } completion: {
                completion(me.navigationController?.topViewController)
            }
        }
    }

    /// Creates a navigation action to navigate to the "Privacy Settings" from the "App Settings" scene.
    private func navigateToPrivacySettings() -> ViewControllerNavigationAction {
        return .init { context, completion in
            let appSettings: AppSettingsViewController = try context.fromViewController()
            appSettings.navigateToPrivacySettings(animated: context.animated) { privacySettings in
                completion(privacySettings)
            }
        }
    }
}

// MARK: - Private Tools

/// `ViewControllerNavigationAction` encapsulates a navigation action performed on a view controller.
/// It includes the capability to chain these actions together to perform a sequence of navigations.
/// This sequence is internally represented as a linked list where each node represents a navigation action.
/// The `then` method is used to chain navigation actions, and the `start` method initiates the sequence.
private class ViewControllerNavigationAction {

    /// Reference to the first navigation action. It also represents the first node in a Linked List.
    private var first: ViewControllerNavigationAction?

    /// Reference to the next navigation action. It is called when the current one is complete.
    private var next: ViewControllerNavigationAction?

    /// The navigation action to perform.
    private let action: Action

    /// Initializes the navigation with an action to perform.
    init(action: @escaping Action) {
        self.action = action
    }

    /// Assigns the next action to perform.
    @discardableResult func then(_ navigator: ViewControllerNavigationAction) -> ViewControllerNavigationAction {
        self.next = navigator
        self.next?.first = first ?? self
        return navigator
    }

    /// Convenience method to start the navigation flow from the first navigator in the chain.
    func start(on rootViewController: UIViewController, animated: Bool = true) {
        let context = Context(animated: animated, sourceViewController: rootViewController)
        let navigator = first ?? self
        navigator.perform(with: context)
    }

    /// Performs the navigation action, then calls the next navigation action.
    private func perform(with context: Context) {
        do {
            try self.action(context) { presented in
                if let next = self.next, let presented {
                    let context = Context(animated: context.animated, sourceViewController: presented)
                    next.perform(with: context)
                } else {
                    self.free()
                }
            }
        } catch {
            DDLogError("Failed to perform navigation action with error: \(error.localizedDescription)")
            self.free()
        }
    }

    /// Recursively nullifies the `next`, `first`references of all nodes in the Linked List.
    ///
    /// This method must be called at the end of the navigation to prevent memory leaks.
    private func free() {
        if let first {
            first.free()
            return
        }
        let next = self.next
        self.next = nil
        self.first = nil
        next?.first = nil
        next?.free()
    }

    // MARK: Types

    typealias Action = (Context, @escaping Completion) throws -> Void
    typealias Completion = (UIViewController?) -> Void
}

extension ViewControllerNavigationAction {

    /// `Context` provides the necessary data for a navigation action, including whether
    /// the navigation is animated and the view controller initiating the navigation.
    struct Context {

        let animated: Bool

        fileprivate let sourceViewController: UIViewController

        func fromViewController<T: UIViewController>() throws -> T {
            guard let sourceVC = self.sourceViewController as? T else {
                throw NSError(domain: "ViewControllerNavigationActionCastError", code: 1)
            }
            return sourceVC
        }
    }
}
