import Foundation

/// `ViewControllerNavigationAction` encapsulates a navigation action performed on a view controller.
/// It includes the capability to chain these actions together to perform a sequence of navigations.
/// This sequence is internally represented as a linked list where each node represents a navigation action.
/// The `then` method is used to chain navigation actions, and the `start` method initiates the sequence.
final class ViewControllerNavigationAction {

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
