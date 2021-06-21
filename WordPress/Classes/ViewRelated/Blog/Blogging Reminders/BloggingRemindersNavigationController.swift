import UIKit

protocol ChildDrawerPositionable {
    var preferredDrawerPosition: DrawerPosition { get }
}

class BloggingRemindersNavigationController: LightNavigationController {

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override public var preferredContentSize: CGSize {
        set {
            viewControllers.last?.preferredContentSize = newValue
            super.preferredContentSize = newValue
        }
        get {
            guard let visibleViewController = viewControllers.last else {
                return .zero
            }

            return visibleViewController.preferredContentSize
        }
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)

        updateDrawerPosition()
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        let viewController = super.popViewController(animated: animated)

        updateDrawerPosition()

        return viewController
    }

    private func updateDrawerPosition() {
        if let bottomSheet = self.parent as? BottomSheetViewController,
           let presentedVC = bottomSheet.presentedVC,
           let currentVC = topViewController as? ChildDrawerPositionable {
            presentedVC.transition(to: currentVC.preferredDrawerPosition)
        }
    }
}

// MARK: - DrawerPresentable

extension BloggingRemindersNavigationController: DrawerPresentable {
    var allowsUserTransition: Bool {
        return false
    }

    var allowsDragToDismiss: Bool {
        return true
    }

    var allowsTapToDismiss: Bool {
        return true
    }

    var expandedHeight: DrawerHeight {
        return .maxHeight
    }

    var collapsedHeight: DrawerHeight {
        if let viewController = viewControllers.last as? DrawerPresentable {
            return viewController.collapsedHeight
        }

        return .intrinsicHeight
    }

    func handleDismiss() {
        (children.last as? DrawerPresentable)?.handleDismiss()
    }
}

// MARK: - NavigationControllerDelegate

extension BloggingRemindersNavigationController: UINavigationControllerDelegate {

    /// This implementation uses the custom `BloggingRemindersAnimator` to improve screen transitions
    /// in the blogging reminders setup flow.
    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        return BloggingRemindersAnimator()
    }
}
