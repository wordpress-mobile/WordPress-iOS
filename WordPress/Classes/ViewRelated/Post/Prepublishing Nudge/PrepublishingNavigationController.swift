import UIKit

protocol PrepublishingDismissible {
    func handleDismiss()
}

class PrepublishingNavigationController: LightNavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the height for iPad
        if UIDevice.isPad() {
            preferredContentSize = Constants.iPadPreferredContentSize
        }
    }

    // We are using intrinsicHeight as the view's collapsedHeight which is calculated from the preferredContentSize.
    override public var preferredContentSize: CGSize {
        set {
            viewControllers.last?.preferredContentSize = newValue
        }
        get {
            if UIDevice.isPad() {
                return Constants.iPadPreferredContentSize
            }

            guard let visibleViewController = viewControllers.last else {
                return .zero
            }

            return visibleViewController.preferredContentSize
        }
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)

        if let bottomSheet = self.parent as? BottomSheetViewController, let presentedVC = bottomSheet.presentedVC {
            presentedVC.transition(to: .collapsed)
        }
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        let viewController = super.popViewController(animated: animated)

        if let bottomSheet = self.parent as? BottomSheetViewController, let presentedVC = bottomSheet.presentedVC {
            presentedVC.transition(to: .collapsed)
        }

        return viewController
    }

    private enum Constants {
        static let iPadPreferredContentSize = CGSize(width: 300.0, height: 300.0)
    }
}


// MARK: - DrawerPresentable

extension PrepublishingNavigationController: DrawerPresentable {
    var allowsUserTransition: Bool {
        return false
    }

    var expandedHeight: DrawerHeight {
        return .topMargin(20)
    }

    var collapsedHeight: DrawerHeight {
        return .intrinsicHeight
    }

    var scrollableView: UIScrollView? {
        let scroll = topViewController?.view as? UIScrollView

        return scroll
    }

    func handleDismiss() {
        if let rootViewController = viewControllers.first as? PrepublishingDismissible {
            rootViewController.handleDismiss()
        }
    }
}
