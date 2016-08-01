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

    private func dimViewController(viewController: UIViewController, dimmed: Bool) {
        if dimmed {
            if let view = viewController.view {
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

    private func dimDetailViewController(dimmed: Bool) {
        if let detailViewController = viewControllers.last {
            dimViewController(detailViewController, dimmed: dimmed)
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
            initialDetailViewController = detailViewController
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

    // The initial detail view controller that's displayed
    // automatically whenever the split view's view controllers are reset.
    // Used primarily when separating the navigation stack when uncollapsing the split view,
    // to find the point at which the stack was previously collapsed.
    private var initialDetailViewController: UIViewController? = nil

    // Used to prevent reloading the detail view controller if the same view
    // controller is popped and then pushed back onto the navigation controller
    // (example: a user tapping Back out of a Blog Details VC to the Blog List VC,
    // and then tapping back into the same blog).
    private weak var previousTopPrimaryViewController: UIViewController? = nil
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

        let separateViewControllersAtIndex: (Int -> Void) = { index in
            viewControllers = Array(primaryNavigationController.viewControllers.suffixFrom(index))
            primaryNavigationController.viewControllers = Array(primaryNavigationController.viewControllers.prefixUpTo(index))
        }

        if let index = primaryNavigationController.viewControllers.indexOf({ $0 is UINavigationController }) {
            // If there's another navigation controller somewhere in the primary navigation stack
            // (this is the default behaviour of a collapse), then we'll split the view controllers
            // apart at that point.
            separateViewControllersAtIndex(index)
        } else if let index = primaryNavigationController.viewControllers.indexOf({ $0 is WPSplitViewControllerDetailProvider }) {
            // Otherwise, if there's a detail provider somewhere in the stack
            separateViewControllersAtIndex(index)
        }

        // If we have no detail view controllers, try and fetch the primary view controller's
        // initial detail view controller.
        if viewControllers.count == 0 {
            if let primaryViewController = primaryNavigationController.viewControllers.last,
                let detailViewController = initialDetailViewControllerForPrimaryViewController(primaryViewController) {
                initialDetailViewController = detailViewController
                return initialDetailViewController
            } else {
                if let initialDetailViewController = initialDetailViewController {
                    dimViewController(initialDetailViewController, dimmed: true)
                }

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

        // If the user hasn't modified the navigation stack, (the secondary view
        // controller is still the initial detail view controller) then
        // return true to prevent the system pushing the detail view controller
        // onto the primary stack.
        // In a horizontally compact size class this means we can collapse to show the root
        // view controller, instead of having the detail view controller pushed onto the stack.
        if secondaryViewController == initialDetailViewController {
            return true
        }

        return false
    }
}

// MARK: - UINavigationControllerDelegate

extension WPSplitViewController: UINavigationControllerDelegate {
    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        if dimsDetailViewControllerAutomatically && !collapsed {
            let shouldDim = navigationController.viewControllers.count == 1
            dimDetailViewController(shouldDim)
        }

        // If the split view isn't collapsed, and we're pushing onto the
        // primary navigation controller, update the detail pane if necessary
        if !collapsed && navigationController.viewControllers.count > 1 {
            // If the primary view controller has changed, reset the detail view controller
            // otherwise, keep the existing detail view controller there.
            // This allows a user to navigate back into the same item in the
            // primary view controller, and keep their place in the detail view controller.
            if previousTopPrimaryViewController != viewController {
                setInitialPrimaryViewController(navigationController)
            }

            previousTopPrimaryViewController = viewController
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
