import UIKit
import WordPressShared

class WPSplitViewController: UISplitViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        preferredDisplayMode = .AllVisible

        extendedLayoutIncludesOpaqueBars = true

        // Values based on the behaviour of Settings.app
        preferredPrimaryColumnWidthFraction = 0.38
        minimumPrimaryColumnWidth = 320
        maximumPrimaryColumnWidth = 390
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    override func overrideTraitCollectionForChildViewController(childViewController: UIViewController) -> UITraitCollection? {
        guard let collection = super.overrideTraitCollectionForChildViewController(childViewController) else { return nil }

        let overrideCollection = UITraitCollection(horizontalSizeClass: self.traitCollection.horizontalSizeClass)
        return UITraitCollection(traitsFromCollections: [collection, overrideCollection])
    }

    override var viewControllers: [UIViewController] {
        didSet {
            // Ensure that each top level navigation controller has
            // `extendedLayoutIncludesOpaqueBars` set to true. Otherwise we
            // see a large tab bar sized gap underneath each view controller.
            for viewController in viewControllers {
                if let viewController = viewController as? UINavigationController {
                    viewController.extendedLayoutIncludesOpaqueBars = true
                }
            }
        }
    }

    override func showDetailViewController(vc: UIViewController, sender: AnyObject?) {
        var detailVC = vc

        // Ensure that detail view controllers are wrapped in a navigation controller
        if !(vc is UINavigationController || collapsed) {
            detailVC = UINavigationController(rootViewController: vc)
        }

        super.showDetailViewController(detailVC, sender: self)
    }

    /** Sets the primary view controller of the split view as specified, and
     *  automatically sets the detail view controller if the primary
     *  conforms to `WPSplitViewControllerDetailProvider` and can vend a
     *  detail view controller.
     */
    func setInitialPrimaryViewController(viewController: UIViewController) {
        var initialViewControllers = [viewController]

        if let navigationController = viewController as? UINavigationController,
            let rootViewController = navigationController.viewControllers.first,
            let detailViewController = initialDetailViewControllerForPrimaryViewController(rootViewController) {

            navigationController.delegate = self

            initialViewControllers.append(detailViewController)

            viewControllers = initialViewControllers
        }
    }

    private func initialDetailViewControllerForPrimaryViewController(viewController: UIViewController) -> UIViewController? {
        guard let detailProvider = viewController as? WPSplitViewControllerDetailProvider,
        let detailViewController = detailProvider.initialDetailViewControllerForSplitView(self)  else {
            return nil
        }

        // Ensure it's wrapped in a navigation controller
        if detailViewController is UINavigationController {
            return detailViewController
        } else {
            return UINavigationController(rootViewController: detailViewController)
        }
    }

    private var primaryNavigationControllerStackHasBeenModified = false
}

extension WPSplitViewController: UISplitViewControllerDelegate {
    /** By default, the top view controller from the primary navigation
     *  controller will be popped and used as the secondary view controller.
     *  However, we want to ensure the the secondary view controller is a
     *  navigation controller, so we'll pop off everything but the root view
     *  controller and wrap it in a navigation controller if necessary.
     */
    func splitViewController(splitViewController: UISplitViewController, separateSecondaryViewControllerFromPrimaryViewController primaryViewController: UIViewController) -> UIViewController? {
        guard let primaryNavigationController = primaryViewController as? UINavigationController else {
            assertionFailure("Split view's primary view controller should be a navigation controller!")
            return nil
        }

        // Grab all but the root view controller from the primary navigation stack,
        // and pop it back.
        let viewControllers = Array(primaryNavigationController.viewControllers.dropFirst())
        primaryNavigationController.popToRootViewControllerAnimated(false)

        // If we have no detail view controllers, try and fetch the primary view controller's
        // initial detail view controller.
        if viewControllers.count == 0 {
            if let primaryViewController = primaryNavigationController.viewControllers.first,
                let initialDetailViewController = initialDetailViewControllerForPrimaryViewController(primaryViewController) {
                return initialDetailViewController
            }
        }

        if let firstViewController = viewControllers.first as? UINavigationController {
            // If it's already a navigation controller, just return it
            return firstViewController
        } else {
            let navigationController = UINavigationController()
            navigationController.viewControllers = viewControllers

            return navigationController
        }
    }

    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
        // If the user hasn't modified the navigation stack, then show the root view controller initially.
        // In a horizontally compact size class this means we can collapse to show the root
        // view controller, instead of having the detail view controller pushed onto the stack.
        if let navigationController = primaryViewController as? UINavigationController where !primaryNavigationControllerStackHasBeenModified {
            navigationController.popToRootViewControllerAnimated(false)
            return true
        }

        return false
    }
}

extension WPSplitViewController: UINavigationControllerDelegate {
    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        primaryNavigationControllerStackHasBeenModified = true
    }
}

extension UIViewController {
    /// Convenience method
    var splitViewControllerIsCollapsed: Bool {
        return splitViewController?.collapsed ?? true
    }
}

@objc
protocol WPSplitViewControllerDetailProvider {
    /**
     * View controllers that implement this method can return a view controller
     * to automatically populate the detail pane of the split view with.
     */
    func initialDetailViewControllerForSplitView(splitView: WPSplitViewController) -> UIViewController?
}
