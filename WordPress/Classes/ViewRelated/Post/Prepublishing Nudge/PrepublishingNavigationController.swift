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

        transition()
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        let viewController = super.popViewController(animated: animated)

        transition()

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

    private func transition() {
        if let bottomSheet = self.parent as? BottomSheetViewController, let presentedVC = bottomSheet.presentedVC {
            presentedVC.transition(to: .collapsed)
        }
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

    private enum Constants {
        static let iPadPreferredContentSize = CGSize(width: 300.0, height: 300.0)
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
