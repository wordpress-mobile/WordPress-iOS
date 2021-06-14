import UIKit

class BloggingRemindersNavigationController: LightNavigationController {

    private let viewControllerDrawerPositions: [DrawerPosition]

    init(rootViewController: UIViewController, viewControllerDrawerPositions: [DrawerPosition]) {
        self.viewControllerDrawerPositions = viewControllerDrawerPositions

        super.init(rootViewController: rootViewController)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        let index = max(min(viewControllers.count-1, viewControllerDrawerPositions.count-1), 0)
        let newPosition = viewControllerDrawerPositions[index]

        if let viewController = viewControllers.last {
            preferredContentSize = viewController.preferredContentSize
        }

        if let bottomSheet = self.parent as? BottomSheetViewController, let presentedVC = bottomSheet.presentedVC {
            presentedVC.transition(to: newPosition)
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
}
