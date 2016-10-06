import UIKit
import WordPressShared

@objc enum WPSplitViewControllerPrimaryColumnWidth: Int {
    case Default
    case Narrow
    case Full
}

class WPSplitViewController: UISplitViewController {

    static let navigationControllerRestorationIdentifier = "WPSplitViewDetailNavigationControllerRestorationID"
    static let detailNavigationStackModifiedRestorationKey = "WPSplitViewDetailNavigationStackModifiedRestorationKey"

    var wpPrimaryColumnWidth: WPSplitViewControllerPrimaryColumnWidth = .Default {
        didSet {
            updateSplitViewForPrimaryColumnWidth()
        }
    }

    private enum WPSplitViewControllerNarrowPrimaryColumnWidth: CGFloat {
        case Portrait = 230
        case Landscape = 320

        static func widthForInterfaceOrientation(orientation: UIInterfaceOrientation) -> CGFloat {
            if UIInterfaceOrientationIsPortrait(orientation) || WPDeviceIdentification.isiPhoneSixPlus() {
                return self.Portrait.rawValue
            } else {
                return self.Landscape.rawValue
            }
        }
    }

    private func updateSplitViewForPrimaryColumnWidth() {
        switch wpPrimaryColumnWidth {
        case .Default:
            minimumPrimaryColumnWidth = UISplitViewControllerAutomaticDimension
            maximumPrimaryColumnWidth = UISplitViewControllerAutomaticDimension
            preferredPrimaryColumnWidthFraction = UISplitViewControllerAutomaticDimension
        case .Narrow:
            let orientation = UIApplication.sharedApplication().statusBarOrientation
            let columnWidth = WPSplitViewControllerNarrowPrimaryColumnWidth.widthForInterfaceOrientation(orientation)

            minimumPrimaryColumnWidth = columnWidth
            maximumPrimaryColumnWidth = columnWidth
            preferredPrimaryColumnWidthFraction = UIScreen.mainScreen().bounds.width / columnWidth
        case .Full:
            maximumPrimaryColumnWidth = UIScreen.mainScreen().bounds.width
            preferredPrimaryColumnWidthFraction = 1.0
        }
    }

    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        preferredDisplayMode = .AllVisible

        extendedLayoutIncludesOpaqueBars = true
    }

    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        super.encodeRestorableStateWithCoder(coder)

        coder.encodeBool(detailNavigationStackHasBeenModified, forKey: self.dynamicType.detailNavigationStackModifiedRestorationKey)
    }

    override func decodeRestorableStateWithCoder(coder: NSCoder) {
        super.decodeRestorableStateWithCoder(coder)

        detailNavigationStackHasBeenModified = coder.decodeBoolForKey(self.dynamicType.detailNavigationStackModifiedRestorationKey)
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    override func overrideTraitCollectionForChildViewController(childViewController: UIViewController) -> UITraitCollection? {
        guard let collection = super.overrideTraitCollectionForChildViewController(childViewController) else { return nil }

        // By default, the detail view controller of a split view is passed the same size class as the split view itself.
        // However, if the splitview is smaller than full screen (i.e. multitasking is active), a number of our
        // view controllers will display better if we tell them they're compact even though the split view is regular.
        if childViewController == viewControllers.last && shouldOverrideDetailViewControllerHorizontalSizeClass {
            return UITraitCollection(traitsFromCollections: [collection, UITraitCollection(horizontalSizeClass: .Compact)])
        }

        let overrideCollection = UITraitCollection(horizontalSizeClass: self.traitCollection.horizontalSizeClass)
        return UITraitCollection(traitsFromCollections: [collection, overrideCollection])
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)

        coordinator.animateAlongsideTransition({ context in
            self.updateSplitViewForPrimaryColumnWidth()
            self.updateDimmingViewFrame()
        }, completion: nil)

        // Calling `setOverrideTraitCollection` prompts `overrideTraitCollectionForChildViewController` to be called.
        if let _ = overriddenTraitCollectionForDetailViewController,
            let detailViewController = viewControllers.last {
                setOverrideTraitCollection(detailViewController.traitCollection, forChildViewController: detailViewController)
        }
    }

    override var viewControllers: [UIViewController] {
        didSet {
            // Ensure that each top level navigation controller has
            // `extendedLayoutIncludesOpaqueBars` set to true. Otherwise we
            // see a large tab bar sized gap underneath each view controller.
            for viewController in viewControllers {
                if let viewController = viewController as? UINavigationController {
                    viewController.extendedLayoutIncludesOpaqueBars = true

                    // Override traits to pass a compact size class if necessary
                    setOverrideTraitCollection(overriddenTraitCollectionForDetailViewController, forChildViewController: viewController)
                }
            }
        }
    }

    private var shouldOverrideDetailViewControllerHorizontalSizeClass: Bool {
        return view.frame.width < UIScreen.mainScreen().bounds.width
    }

    private var overriddenTraitCollectionForDetailViewController: UITraitCollection? {
        guard let detailViewController = viewControllers.last where shouldOverrideDetailViewControllerHorizontalSizeClass else {
            return nil
        }

        return  UITraitCollection(traitsFromCollections: [detailViewController.traitCollection, UITraitCollection(horizontalSizeClass: .Compact)])
    }

    // MARK: - Dimming support

    private lazy var dimmingView: UIView = {
        let dimmingView = UIView()
        dimmingView.backgroundColor = WPStyleGuide.greyDarken30()
        return dimmingView
    }()

    /// If set to `true`, the split view will automatically dim the detail
    /// view controller whenever the primary navigation controller is popped
    /// back to its root view controller.
    var dimsDetailViewControllerAutomatically = false {
        didSet {
            if !dimsDetailViewControllerAutomatically {
                dimDetailViewController(false)
            }
        }
    }

    private let dimmingViewAlpha: CGFloat = 0.5
    private let dimmingViewAnimationDuration: NSTimeInterval = 0.3

    private func dimDetailViewController(dimmed: Bool) {
        if dimmed {
            if dimmingView.superview == nil {
                view.addSubview(dimmingView)
                updateDimmingViewFrame()
                dimmingView.alpha = WPAlphaZero

                // Dismiss the keyboard from the detail view controller if active
                topDetailViewController?.navigationController?.view.endEditing(true)
                UIView.animateWithDuration(dimmingViewAnimationDuration, animations: {
                    self.dimmingView.alpha = self.dimmingViewAlpha
                })
            }
        } else if dimmingView.superview != nil {
            UIView.animateWithDuration(dimmingViewAnimationDuration, animations: {
                self.dimmingView.alpha = WPAlphaZero
                }, completion: { _ in
                    self.dimmingView.removeFromSuperview()
            })
        }
    }

    private func updateDimmingViewFrame() {
        if dimmingView.superview != nil {
            dimmingView.frame = view.frame
            dimmingView.frame.origin.x = primaryColumnWidth
        }
    }

    // MARK: - Detail view controller management

    override func showDetailViewController(vc: UIViewController, sender: AnyObject?) {
        var detailVC = vc

        // Ensure that detail view controllers are wrapped in a navigation controller
        // when the split is not collapsed
        if !collapsed {
            detailVC = wrapViewControllerInNavigationControllerIfRequired(vc)
        }

        detailNavigationStackHasBeenModified = true

        super.showDetailViewController(detailVC, sender: sender)
    }

    var topDetailViewController: UIViewController? {
        if collapsed {
            return (viewControllers.first as? UINavigationController)?.topViewController
        } else {
            return (viewControllers.last as? UINavigationController)?.topViewController
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
        } else {
            viewControllers = [viewController, UIViewController()]
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
        var navigationController: UINavigationController!

        if let viewController = viewController as? UINavigationController {
            navigationController = viewController
        } else {
            navigationController = UINavigationController(rootViewController: viewController)
        }

        navigationController.restorationIdentifier = self.dynamicType.navigationControllerRestorationIdentifier
        navigationController.delegate = self
        navigationController.extendedLayoutIncludesOpaqueBars = true

        return navigationController
    }

    private var detailNavigationStackHasBeenModified = false
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

        // Splits the view controller list into primary and detail view controllers at the specified index
        let separateViewControllersAtIndex: (Int -> Void) = { index in
            viewControllers = Array(primaryNavigationController.viewControllers.suffixFrom(index))
            primaryNavigationController.viewControllers = Array(primaryNavigationController.viewControllers.prefixUpTo(index))
        }

        if let index = primaryNavigationController.viewControllers.indexOf({ $0 is UINavigationController }) {
            // If there's another navigation controller somewhere in the primary navigation stack
            // (this is the default behaviour of a collapse), then we'll split the view controllers
            // apart at that point.
            separateViewControllersAtIndex(index)
        } else if let index = primaryNavigationController.viewControllers.lastIndexOf({ $0 is WPSplitViewControllerDetailProvider }) {
            // Otherwise, if there's a detail provider somewhere in the stack, find the last one
            separateViewControllersAtIndex(index + 1)
        }

        dimDetailViewControllerIfNecessary()

        // If we have no detail view controllers, try and fetch the primary view controller's
        // initial detail view controller.
        if viewControllers.count == 0 {
            if let primaryViewController = primaryNavigationController.viewControllers.last,
                let detailViewController = initialDetailViewControllerForPrimaryViewController(primaryViewController) {
                return detailViewController
            }
        }

        if let firstViewController = viewControllers.first as? UINavigationController {
            // If it's already a navigation controller, just return it
            return firstViewController
        } else {
            let navigationController = UINavigationController()
            navigationController.delegate = self
            navigationController.restorationIdentifier = self.dynamicType.navigationControllerRestorationIdentifier
            navigationController.viewControllers = viewControllers

            return navigationController
        }
    }

    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
        let detailDimmed = isDetailViewDimmed

        // Un-dim the detail view
        if dimsDetailViewControllerAutomatically {
            dimDetailViewController(false)
        }

        // If we had dimmed the detail view controller, then return true so that
        // we discard the detail VCs and just show the primary view controller
        if detailDimmed {
            return true
        }

        // Otherwise, concatenate the primary and detail navigation controllers' content
        // (the iOS default behavior here is to just push the detail navigation controller
        // itself onto the primary navigation controller, which is just weird)
        if let primaryViewController = primaryViewController as? UINavigationController,
            let secondaryViewController = secondaryViewController as? UINavigationController {

            if detailNavigationStackHasBeenModified {
                primaryViewController.viewControllers.appendContentsOf(secondaryViewController.viewControllers)
            }

            return true
        }

        return false
    }

    private var isDetailViewDimmed: Bool {
        return dimmingView.superview != nil
    }
}

// MARK: - UINavigationControllerDelegate

extension WPSplitViewController: UINavigationControllerDelegate {
    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        if navigationController == viewControllers.first {
            primaryNavigationController(navigationController, willShowViewController: viewController, animated: animated)
        } else if navigationController == viewControllers.last {
            detailNavigationController(navigationController, willShowViewController: viewController, animated: animated)
        }
    }

    private func primaryNavigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {

        if let coordinator = navigationController.topViewController?.transitionCoordinator() {
            // If the user is popping back to the root view controller using the
            // interactive pop transition, we need to check whether the gesture
            // gets cancelled so that we can undim the detail view if necessary.
            // (i.e. the user begins a back swipe but doesn't go through with it)
            coordinator.notifyWhenInteractionEndsUsingBlock({ [weak self] context in
                if context.initiallyInteractive() && context.isCancelled() {
                    self?.dimDetailViewController(false)
                }
            })
        }

        dimDetailViewControllerIfNecessary()
    }

    private func detailNavigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        if navigationController.viewControllers.count > 1 {
            detailNavigationStackHasBeenModified = true
        }
    }

    private func dimDetailViewControllerIfNecessary() {
        if let primaryNavigationController = viewControllers.first as? UINavigationController where
            dimsDetailViewControllerAutomatically && !collapsed {
            let shouldDim = primaryNavigationController.viewControllers.count == 1
            dimDetailViewController(shouldDim)
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
