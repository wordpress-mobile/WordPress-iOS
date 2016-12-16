import UIKit
import WordPressShared

@objc enum WPSplitViewControllerPrimaryColumnWidth: Int {
    case `default`
    case narrow
    case full
}

@objc enum WPSplitViewControllerCollapseMode: Int {
    case Automatic
    case AlwaysKeepDetail
}

class WPSplitViewController: UISplitViewController {

    static let navigationControllerRestorationIdentifier = "WPSplitViewDetailNavigationControllerRestorationID"
    static let detailNavigationStackModifiedRestorationKey = "WPSplitViewDetailNavigationStackModifiedRestorationKey"

    /// Determines how the split view handles the detail pane when collapsing itself.
    /// If 'Automatic', then the detail pane will be pushed onto the primary navigation stack
    /// if the user has manually changed the selection in the primary pane. Otherwise,
    /// if the detail pane is still showing its default content, it will be discarded.
    /// If 'AlwaysKeepDetail', the detail pane will always be pushed onto the
    /// primary navigation stack.
    var collapseMode: WPSplitViewControllerCollapseMode = .Automatic

    var wpPrimaryColumnWidth: WPSplitViewControllerPrimaryColumnWidth = .default {
        didSet {
            updateSplitViewForPrimaryColumnWidth()
        }
    }

    fileprivate enum WPSplitViewControllerNarrowPrimaryColumnWidth: CGFloat {
        case portrait = 230
        case landscape = 320

        static func widthForInterfaceOrientation(_ orientation: UIInterfaceOrientation) -> CGFloat {
            // If the app is in multitasking (so isn't fullscreen), just use the narrow width
            if let windowFrame = UIApplication.shared.keyWindow?.frame {
                if windowFrame.width < UIScreen.main.bounds.width {
                    return self.portrait.rawValue
                }
            }

            if UIInterfaceOrientationIsPortrait(orientation) || WPDeviceIdentification.isiPhoneSixPlus() {
                return self.portrait.rawValue
            } else {
                return self.landscape.rawValue
            }
        }
    }

    fileprivate func updateSplitViewForPrimaryColumnWidth() {
        switch wpPrimaryColumnWidth {
        case .default:
            minimumPrimaryColumnWidth = UISplitViewControllerAutomaticDimension
            maximumPrimaryColumnWidth = UISplitViewControllerAutomaticDimension
            preferredPrimaryColumnWidthFraction = UISplitViewControllerAutomaticDimension
        case .narrow:
            let orientation = UIApplication.shared.statusBarOrientation
            let columnWidth = WPSplitViewControllerNarrowPrimaryColumnWidth.widthForInterfaceOrientation(orientation)

            minimumPrimaryColumnWidth = columnWidth
            maximumPrimaryColumnWidth = columnWidth
            preferredPrimaryColumnWidthFraction = UIScreen.main.bounds.width / columnWidth
        case .full:
            maximumPrimaryColumnWidth = UIScreen.main.bounds.width
            preferredPrimaryColumnWidthFraction = 1.0
        }
    }

    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        preferredDisplayMode = .allVisible

        extendedLayoutIncludesOpaqueBars = true
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func overrideTraitCollection(forChildViewController childViewController: UIViewController) -> UITraitCollection? {
        guard let collection = super.overrideTraitCollection(forChildViewController: childViewController) else { return nil }

        // By default, the detail view controller of a split view is passed the same size class as the split view itself.
        // However, if the splitview is smaller than full screen (i.e. multitasking is active), a number of our
        // view controllers will display better if we tell them they're compact even though the split view is regular.
        if childViewController == viewControllers.last && shouldOverrideDetailViewControllerHorizontalSizeClass {
            return UITraitCollection(traitsFrom: [collection, UITraitCollection(horizontalSizeClass: .compact)])
        }

        let overrideCollection = UITraitCollection(horizontalSizeClass: self.traitCollection.horizontalSizeClass)
        return UITraitCollection(traitsFrom: [collection, overrideCollection])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateDimmingViewFrame()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { context in
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

    fileprivate var shouldOverrideDetailViewControllerHorizontalSizeClass: Bool {
        return view.frame.width < UIScreen.main.bounds.width
    }

    fileprivate var overriddenTraitCollectionForDetailViewController: UITraitCollection? {
        guard let detailViewController = viewControllers.last, shouldOverrideDetailViewControllerHorizontalSizeClass else {
            return nil
        }

        return  UITraitCollection(traitsFrom: [detailViewController.traitCollection, UITraitCollection(horizontalSizeClass: .compact)])
    }

    // MARK: - Dimming support

    fileprivate lazy var dimmingView: UIView = {
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

    fileprivate let dimmingViewAlpha: CGFloat = 0.5
    fileprivate let dimmingViewAnimationDuration: TimeInterval = 0.3

    fileprivate func dimDetailViewController(_ dimmed: Bool) {
        if dimmed {
            if dimmingView.superview == nil {
                view.addSubview(dimmingView)
                updateDimmingViewFrame()
                dimmingView.alpha = WPAlphaZero

                // Dismiss the keyboard from the detail view controller if active
                topDetailViewController?.navigationController?.view.endEditing(true)
                UIView.animate(withDuration: dimmingViewAnimationDuration, animations: {
                    self.dimmingView.alpha = self.dimmingViewAlpha
                })
            }
        } else if dimmingView.superview != nil {
            UIView.animate(withDuration: dimmingViewAnimationDuration, animations: {
                self.dimmingView.alpha = WPAlphaZero
                }, completion: { _ in
                    self.dimmingView.removeFromSuperview()
            })
        }
    }

    fileprivate func updateDimmingViewFrame() {
        if dimmingView.superview != nil {
            dimmingView.frame = view.frame

            let attribute = view.semanticContentAttribute
            let layoutDirection = UIView.userInterfaceLayoutDirection(for: attribute)
            if layoutDirection == .leftToRight {
                dimmingView.frame.origin.x = primaryColumnWidth
            } else {
                dimmingView.frame.size.width = dimmingView.frame.size.width - primaryColumnWidth
            }
        }
    }

    // MARK: - Detail view controller management

    override func showDetailViewController(_ vc: UIViewController, sender: Any?) {
        var detailVC = vc

        // Ensure that detail view controllers are wrapped in a navigation controller
        // when the split is not collapsed
        if !isCollapsed {
            detailVC = wrapViewControllerInNavigationControllerIfRequired(vc)
        }

        detailNavigationStackHasBeenModified = true

        super.showDetailViewController(detailVC, sender: sender)
    }

    var topDetailViewController: UIViewController? {
        if isCollapsed {
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
    func setInitialPrimaryViewController(_ viewController: UIViewController) {
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

    fileprivate func initialDetailViewControllerForPrimaryViewController(_ viewController: UIViewController) -> UIViewController? {
        guard let detailProvider = viewController as? WPSplitViewControllerDetailProvider,
        let detailViewController = detailProvider.initialDetailViewControllerForSplitView(self)  else {
            return nil
        }

        return wrapViewControllerInNavigationControllerIfRequired(detailViewController)
    }

    fileprivate func wrapViewControllerInNavigationControllerIfRequired(_ viewController: UIViewController) -> UIViewController {
        var navigationController: UINavigationController!

        if let viewController = viewController as? UINavigationController {
            navigationController = viewController
        } else {
            navigationController = UINavigationController(rootViewController: viewController)
        }

        navigationController.restorationIdentifier = type(of: self).navigationControllerRestorationIdentifier
        navigationController.delegate = self
        navigationController.extendedLayoutIncludesOpaqueBars = true

        return navigationController
    }

    fileprivate var detailNavigationStackHasBeenModified = false
}

// MARK: - UISplitViewControllerDelegate

extension WPSplitViewController: UISplitViewControllerDelegate {
    /** By default, the top view controller from the primary navigation
     *  controller will be popped and used as the secondary view controller.
     *  However, we want to ensure the the secondary view controller is a
     *  navigation controller, so we'll pop off everything but the root view
     *  controller and wrap it in a navigation controller if necessary.
     */
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        guard let primaryNavigationController = primaryViewController as? UINavigationController else {
            assertionFailure("Split view's primary view controller should be a navigation controller!")
            return nil
        }

        var viewControllers: [UIViewController] = []

        // Splits the view controller list into primary and detail view controllers at the specified index
        let separateViewControllersAtIndex: ((Int) -> Void) = { index in
            viewControllers = Array(primaryNavigationController.viewControllers.suffix(from: index))
            primaryNavigationController.viewControllers = Array(primaryNavigationController.viewControllers.prefix(upTo: index))
        }

        if let index = primaryNavigationController.viewControllers.index(where: { $0 is UINavigationController }) {
            // If there's another navigation controller somewhere in the primary navigation stack
            // (this is the default behaviour of a collapse), then we'll split the view controllers
            // apart at that point.
            separateViewControllersAtIndex(index)
        } else if let index = primaryNavigationController.viewControllers.lastIndex(where: { $0 is WPSplitViewControllerDetailProvider }) {
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
            navigationController.restorationIdentifier = type(of: self).navigationControllerRestorationIdentifier
            navigationController.viewControllers = viewControllers

            return navigationController
        }
    }

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
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
        if let primaryViewController = primaryViewController as? UINavigationController {
            if let secondaryViewController = secondaryViewController as? UINavigationController {

                // When state restoration is occurring, it's possible for the primary
                // navigation controller to have already had the had the detail
                // view controllers pushed onto it. We'll check for this first by
                // ensuring there's nothing other than a detail provider on the
                // end of the navigation stack.
                let forceKeepDetail = (collapseMode == .AlwaysKeepDetail &&
                                       primaryViewController.viewControllers.last is WPSplitViewControllerDetailProvider)

                if detailNavigationStackHasBeenModified || forceKeepDetail {
                    primaryViewController.viewControllers.append(contentsOf: secondaryViewController.viewControllers)
                }
            }

            return true
        }

        return false
    }

    fileprivate var isDetailViewDimmed: Bool {
        return dimmingView.superview != nil
    }
}

// MARK: - UINavigationControllerDelegate

extension WPSplitViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if navigationController == viewControllers.first {
            primaryNavigationController(navigationController, willShowViewController: viewController, animated: animated)
        } else if navigationController == viewControllers.last {
            detailNavigationController(navigationController, willShowViewController: viewController, animated: animated)
        }
    }

    fileprivate func primaryNavigationController(_ navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {

        if let coordinator = navigationController.topViewController?.transitionCoordinator {
            // If the user is popping back to the root view controller using the
            // interactive pop transition, we need to check whether the gesture
            // gets cancelled so that we can undim the detail view if necessary.
            // (i.e. the user begins a back swipe but doesn't go through with it)
            coordinator.notifyWhenInteractionEnds({ [weak self] context in
                if context.initiallyInteractive && context.isCancelled {
                    self?.dimDetailViewController(false)
                }
            })
        }

        dimDetailViewControllerIfNecessary()
    }

    fileprivate func detailNavigationController(_ navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        if navigationController.viewControllers.count > 1 {
            detailNavigationStackHasBeenModified = true
        }
    }

    fileprivate func dimDetailViewControllerIfNecessary() {
        if let primaryNavigationController = viewControllers.first as? UINavigationController,
            dimsDetailViewControllerAutomatically && !isCollapsed {
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
    func initialDetailViewControllerForSplitView(_ splitView: WPSplitViewController) -> UIViewController?
}
