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
        // when the split is not collapsed
        if !collapsed {
            detailVC = wrapViewControllerInNavigationControllerIfRequired(vc)
        }

        super.showDetailViewController(detailVC, sender: self)
    }


    private lazy var dimmingView: UIView = {
        let dimmingView = UIView()
        dimmingView.backgroundColor = WPStyleGuide.greyDarken30()
        return dimmingView
    }()

    /// If set to `true`, the split view will automatically dim the detail
    /// view controller whenever the primary navigation controller is popped
    /// back to its root view controller.
    var dimsDetailViewControllerAutomatically = false

    private let dimmingViewAlpha: CGFloat = 0.5
    private let dimmingViewAnimationDuration: NSTimeInterval = 0.3

    private func dimDetailViewController(dimmed: Bool) {
        if dimmed {
            if let detailViewController = viewControllers.last,
                let view = detailViewController.view {
                dimmingView.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(dimmingView)
                view.pinSubviewToAllEdges(dimmingView)
                dimmingView.alpha = 0
                UIView.animateWithDuration(dimmingViewAnimationDuration, animations: {
                    self.dimmingView.alpha = self.dimmingViewAlpha
                })
            }
        } else if dimmingView.superview != nil {
            UIView.animateWithDuration(dimmingViewAnimationDuration, animations: {
                self.dimmingView.alpha = 0
                }, completion: { _ in
                    self.dimmingView.removeFromSuperview()
            })
        }
    }

    /** Sets the primary view controller of the split view as specified, and
     *  automatically sets the detail view controller if the primary
     *  conforms to `WPSplitViewControllerDetailProvider` and can vend a
     *  detail view controller.
     */
    func setInitialPrimaryViewController(viewController: UIViewController) {
        var initialViewControllers = [viewController]

        if let navigationController = viewController as? UINavigationController,
            let rootViewController = navigationController.viewControllers.last,
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

        return wrapViewControllerInNavigationControllerIfRequired(detailViewController)
    }

    private func wrapViewControllerInNavigationControllerIfRequired(viewController: UIViewController) -> UIViewController {
        return (viewController is UINavigationController) ? viewController : UINavigationController(rootViewController: viewController)
    }

    private var primaryNavigationControllerStackHasBeenModified = false
}

// MARK: - UISplitViewControllerDelegate

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

        var viewControllers: [UIViewController] = []
        if let index = primaryNavigationController.viewControllers.indexOf({ $0 is UINavigationController }) {
            // If there's another navigation controller somewhere in the primary navigation stack
            // (this is the default behaviour of a collapse), then we'll split the view controllers
            // apart at that point.
            viewControllers = Array(primaryNavigationController.viewControllers.suffixFrom(index))
            primaryNavigationController.viewControllers = Array(primaryNavigationController.viewControllers.prefixUpTo(index))
        }

        // If we have no detail view controllers, try and fetch the primary view controller's
        // initial detail view controller.
        if viewControllers.count == 0 {
            if let primaryViewController = primaryNavigationController.viewControllers.last,
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
        if dimsDetailViewControllerAutomatically {
            dimDetailViewController(false)
        }

        // If the user hasn't modified the navigation stack, then show the root view controller initially.
        // In a horizontally compact size class this means we can collapse to show the root
        // view controller, instead of having the detail view controller pushed onto the stack.
        if let navigationController = primaryViewController as? UINavigationController where !primaryNavigationControllerStackHasBeenModified && navigationController.viewControllers.count == 1 {
            navigationController.popToRootViewControllerAnimated(false)
            return true
        }

        return false
    }
}

// MARK: - UINavigationControllerDelegate

extension WPSplitViewController: UINavigationControllerDelegate {
    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        primaryNavigationControllerStackHasBeenModified = true

        if dimsDetailViewControllerAutomatically && !collapsed {
            let shouldDim = navigationController.viewControllers.count == 1
            dimDetailViewController(shouldDim)
        }

        // If the split view isn't collapsed, and we're pushing a new view controller
        // onto the primary navigation controller, update the detail pane
        // to show the appropriate initial view controller
        if !collapsed && navigationController.viewControllers.count > 1 {
            setInitialPrimaryViewController(navigationController)
        }
    }
}

// MARK: - UIViewController Helpers

extension UIViewController {
    var splitViewControllerIsHorizontallyCompact: Bool {
        return splitViewController?.isViewHorizontallyCompact() ?? isViewHorizontallyCompact()
    }
}

// MARK: - WPSplitViewControllerDetailProvider Protocol

@objc
protocol WPSplitViewControllerDetailProvider {
    /**
     * View controllers that implement this method can return a view controller
     * to automatically populate the detail pane of the split view with.
     */
    func initialDetailViewControllerForSplitView(splitView: WPSplitViewController) -> UIViewController?
}
