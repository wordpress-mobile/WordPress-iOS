import UIKit

protocol PrepublishingDismissible {
    func handleDismiss()
}

class PrepublishingNavigationController: LightNavigationController {

    private let shouldDisplayPortrait: Bool

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        shouldDisplayPortrait ? .portrait : .all
    }

    // We are using intrinsicHeight as the view's collapsedHeight which is calculated from the preferredContentSize.
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

        transition(for: viewController)
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        let viewController = super.popViewController(animated: animated)

        transition(for: viewController)

        return viewController
    }

    init(rootViewController: UIViewController, shouldDisplayPortrait: Bool) {
        self.shouldDisplayPortrait = shouldDisplayPortrait
        super.init(rootViewController: rootViewController)

        configureNavigationBar()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func transition(for viewController: UIViewController?) {
        guard let bottomSheet = self.parent as? BottomSheetViewController,
              let presentedVC = bottomSheet.presentedVC else {
            return
        }

        let preferredDrawerPosition: DrawerPosition = {
            guard RemoteFeatureFlag.jetpackSocialImprovements.enabled() else {
                return .collapsed
            }

            if let positionable = viewController as? ChildDrawerPositionable {
                return positionable.preferredDrawerPosition
            }

            return traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? .expanded : .collapsed
        }()

        presentedVC.transition(to: preferredDrawerPosition)
    }

    /// Updates the navigation bar color so it matches the view's background.
    ///
    /// Originally, in dark mode the navigation bar color is grayish, but there's a few points gap on top of the
    /// navigation bar to accommodate the `GripButton` from `BottomSheetViewController`. The bottom sheet itself
    /// assigns the background color according to its child controller's view background color.
    private func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .basicBackground

        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
    }
}

// MARK: - DrawerPresentable

extension PrepublishingNavigationController: DrawerPresentable {
    var allowsUserTransition: Bool {
        guard let visibleDrawer = visibleViewController as? DrawerPresentable else {
            return true
        }

        return visibleDrawer.allowsUserTransition
    }

    var expandedHeight: DrawerHeight {
        return .topMargin(20)
    }

    var collapsedHeight: DrawerHeight {
        guard let visibleDrawer = visibleViewController as? DrawerPresentable else {
            return .contentHeight(300)
        }

        return visibleDrawer.collapsedHeight
    }

    var scrollableView: UIScrollView? {
        return topViewController?.view as? UIScrollView
    }

    func handleDismiss() {
        if let rootViewController = viewControllers.first as? PrepublishingDismissible {
            rootViewController.handleDismiss()
        }
    }
}
