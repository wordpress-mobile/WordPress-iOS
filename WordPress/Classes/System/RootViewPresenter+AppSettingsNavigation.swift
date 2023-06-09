import UIKit

extension RootViewPresenter {

    /// Navigates to "Me > App Settings > Privacy Settings"
    func navigateToPrivacySettings() {
        navigateToMeScene()
            .then(navigateToAppSettings())
            .then(navigateToPrivacySettings())
            .start(with: rootViewController, animated: true)
    }

    // MARK: - Navigators

    private func navigateToMeScene() -> ViewControllerNavigator {
        return .init { [weak self] context, completion in
            guard let self else {
                return
            }
            self.showMeScene(animated: context.animated) { meViewController in
                self.popMeTabToRoot()
                completion(meViewController)
            }
        }
    }

    private func navigateToAppSettings() -> ViewControllerNavigator {
        return .init { context, completion in
            guard let me = context.presenting as? MeViewController else {
                completion(nil)
                return
            }
            CATransaction.perform {
                me.navigateToAppSettings()
            } completion: {
                completion(me.navigationController?.topViewController)
            }
        }
    }

    private func navigateToPrivacySettings() -> ViewControllerNavigator {
        return .init { context, completion in
            guard let appSettings = context.presenting as? AppSettingsViewController else {
                completion(nil)
                return
            }
            CATransaction.perform {
                appSettings.navigateToPrivacySettings(animated: context.animated)
            } completion: {
                completion(appSettings.navigationController?.topViewController)
            }
        }
    }
}


// MARK: - Private Types and Extensions

private final class ViewControllerNavigator {

    /// Reference to the first navigation action. It also represents the first node in a Linked List.
    private var first: ViewControllerNavigator?

    /// Reference to the next navigation action. It is called when the current one is complete.
    private var next: ViewControllerNavigator?

    /// The navigation action to perform.
    private let action: Action

    /// Initializes the navigation with an action to perform.
    init(action: @escaping Action) {
        self.action = action
    }

    /// Assigns the next action to perform.
    @discardableResult func then(_ navigator: ViewControllerNavigator) -> ViewControllerNavigator {
        self.next = navigator
        self.next?.first = first ?? self
        return navigator
    }

    /// Convenience method to start the navigation flow from the first navigator in the chain.
    func start(with presenting: UIViewController, animated: Bool = true) {
        let navigator = first ?? self
        navigator.perform(with: presenting, animated: animated)
    }

    /// Performs the navigation action, then calls the next navigation action where the `presenting` param
    /// is the last presented view controller.
    ///
    /// The idea is that the presented view controller of the current navigator is the presenting view controller of the next navigator.
    private func perform(with presenting: UIViewController, animated: Bool) {
        let context = Context(presenting: presenting, animated: animated)
        self.action(context) { presented in
            if let next = self.next, let presented {
                next.perform(with: presented, animated: animated)
            } else {
                self.free()
            }
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
        var current: ViewControllerNavigator? = self
        repeat {
            let next = current?.next
            current?.first = nil
            current?.next = nil
            current = next
        } while current != nil
    }

    typealias Action = (Context, @escaping Completion) -> Void
    typealias Completion = (UIViewController?) -> Void

    struct Context {
        let presenting: UIViewController
        let animated: Bool
    }
}

private extension CATransaction {

    static func perform(block: () -> Void, completion: @escaping () -> Void) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        block()
        CATransaction.commit()
    }
}
