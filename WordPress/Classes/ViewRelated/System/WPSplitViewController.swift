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

    /// Determines how the split view handles the detail pane when collapsing itself.
    /// If 'Automatic', then the detail pane will be pushed onto the primary navigation stack
    /// if the user has manually changed the selection in the primary pane. Otherwise,
    /// if the detail pane is still showing its default content, it will be discarded.
    /// If 'AlwaysKeepDetail', the detail pane will always be pushed onto the
    /// primary navigation stack.
    @objc var collapseMode: WPSplitViewControllerCollapseMode = .Automatic

    /// Set to false to disable fullscreen display mode
    @objc var fullscreenDisplayEnabled = true

    @objc var wpPrimaryColumnWidth: WPSplitViewControllerPrimaryColumnWidth = .default {
        didSet {
            updateSplitViewForPrimaryColumnWidth()
        }
    }

    fileprivate enum WPSplitViewControllerNarrowPrimaryColumnWidth: CGFloat {
        case portrait = 230
        case landscape = 320

        static func width(for size: CGSize) -> CGFloat {
            // If the app is in multitasking (so isn't fullscreen), just use the narrow width
            if size.width < UIScreen.main.bounds.width {
                return self.portrait.rawValue
            }

            if size.width < size.height || WPDeviceIdentification.isUnzoomediPhonePlus() {
                return self.portrait.rawValue
            } else {
                return self.landscape.rawValue
            }
        }
    }

    fileprivate func updateSplitViewForPrimaryColumnWidth(size: CGSize = UIScreen.main.bounds.size) {
        switch wpPrimaryColumnWidth {
        case .default:
            minimumPrimaryColumnWidth = UISplitViewController.automaticDimension
            maximumPrimaryColumnWidth = UISplitViewController.automaticDimension
            preferredPrimaryColumnWidthFraction = UISplitViewController.automaticDimension
        case .narrow:
            let columnWidth = WPSplitViewControllerNarrowPrimaryColumnWidth.width(for: size)
            minimumPrimaryColumnWidth = columnWidth
            maximumPrimaryColumnWidth = columnWidth
            preferredPrimaryColumnWidthFraction = columnWidth / size.width
        case .full:
            break

            // Ref: https://github.com/wordpress-mobile/WordPress-iOS/issues/14547
            // Due to a bug where the column widths are not updating correctly when the primary column
            // is set to full width, the empty views are not sized correctly on rotation. As a workaround,
            // don't attempt to resize the columns for full width. These lines should be restored when
            // the full width issue is resolved.
            // maximumPrimaryColumnWidth = size.width
            // preferredPrimaryColumnWidthFraction = 1.0
        }
    }

    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        preferredDisplayMode = .oneBesideSecondary
    }

    @objc var overrideTraitCollection: UITraitCollection? = nil

    override var traitCollection: UITraitCollection {
        get {
            if let overrideTraitCollection = overrideTraitCollection {
                return UITraitCollection.init(traitsFrom: [super.traitCollection, overrideTraitCollection])
            }

            return super.traitCollection
        }
    }

    override func overrideTraitCollection(forChild childViewController: UIViewController) -> UITraitCollection? {
        guard let collection = super.overrideTraitCollection(forChild: childViewController) else { return nil }

        var traits = [collection]

        // By default, the detail view controller of a split view is passed the same size class as the split view itself.
        // However, if the splitview is smaller than full screen (i.e. multitasking is active), a number of our
        // view controllers will display better if we tell them they're compact even though the split view is regular.
        if childViewController == viewControllers.last && shouldOverrideDetailViewControllerHorizontalSizeClass {
            traits.append(UITraitCollection(horizontalSizeClass: .compact))
        } else {
            traits.append(UITraitCollection(horizontalSizeClass: traitCollection.horizontalSizeClass))
        }

        // This is to work around an apparent bug in iOS 13 where the detail view is assuming the system is in dark
        // mode when switching out of the app and then back in. Here we ensure the overridden user interface style
        // traits are replaced with the correct current traits before we use them.
        traits.append(UITraitCollection(userInterfaceStyle: traitCollection.userInterfaceStyle))

        return UITraitCollection(traitsFrom: traits)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateDimmingViewFrame()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        updateSplitViewForPrimaryColumnWidth(size: size)
        coordinator.animate(alongsideTransition: { context in
            self.updateDimmingViewFrame()
        })

        // Calling `setOverrideTraitCollection` prompts `overrideTraitCollectionForChildViewController` to be called.
        if let _ = overriddenTraitCollectionForDetailViewController,
            let detailViewController = viewControllers.last {
            setOverrideTraitCollection(detailViewController.traitCollection, forChild: detailViewController)
        }
    }

    override var viewControllers: [UIViewController] {
        didSet {
            for viewController in viewControllers {
                if let viewController = viewController as? UINavigationController {
                    // Override traits to pass a compact size class if necessary
                    setOverrideTraitCollection(overriddenTraitCollectionForDetailViewController,
                                               forChild: viewController)
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if hasHorizontallyCompactView() && preferredDisplayMode == .secondaryOnly {
            setPrimaryViewControllerHidden(false, animated: false)
        }
    }

    // MARK: - Dimming support

    fileprivate lazy var dimmingView: UIView = {
        let dimmingView = UIView()
        dimmingView.backgroundColor = UIAppColor.neutral(.shade60)
        return dimmingView
    }()

    /// If set to `true`, the split view will automatically dim the detail
    /// view controller whenever the primary navigation controller is popped
    /// back to its root view controller.
    @objc var dimsDetailViewControllerAutomatically = false {
        didSet {
            if !dimsDetailViewControllerAutomatically {
                dimDetailViewController(false)
            }
        }
    }

    /// A flag that indicates whether the split view controller is showing the
    /// initial (i.e. default) view controller or not.
    ///
    @objc var isShowingInitialDetail = false

    fileprivate let dimmingViewAlpha: CGFloat = 0.5
    fileprivate let dimmingViewAnimationDuration: TimeInterval = 0.3

    func dimDetailViewController(_ dimmed: Bool, withAlpha alpha: CGFloat? = nil) {
        if dimmed {
            if dimmingView.superview == nil {
                view.addSubview(dimmingView)
                updateDimmingViewFrame()
                dimmingView.alpha = 0

                // Dismiss the keyboard from the detail view controller if active
                topDetailViewController?.navigationController?.view.endEditing(true)
                UIView.animate(withDuration: dimmingViewAnimationDuration, animations: {
                    self.dimmingView.alpha = alpha ?? self.dimmingViewAlpha
                })
            }
        } else if dimmingView.superview != nil {
            UIView.animate(withDuration: dimmingViewAnimationDuration, animations: {
                self.dimmingView.alpha = 0
                }, completion: { _ in
                    self.dimmingView.removeFromSuperview()
            })
        }
    }

    fileprivate func updateDimmingViewFrame() {
        if dimmingView.superview != nil {
            dimmingView.frame = view.frame

            if view.userInterfaceLayoutDirection() == .leftToRight {
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

        if let navigationController = viewControllers.first as? UINavigationController,
            traitCollection.containsTraits(in: UITraitCollection(horizontalSizeClass: .compact)) {
            navigationController.show(vc, sender: sender)
            return
        }

        super.showDetailViewController(detailVC, sender: sender)
    }

    /// The topmost view controller in the detail navigation stack (or the
    /// primary stack if the split view is collapsed).
    @objc var topDetailViewController: UIViewController? {
        if isCollapsed {
            return (viewControllers.first as? UINavigationController)?.topViewController
        } else {
            return (viewControllers.last as? UINavigationController)?.topViewController
        }
    }

    /// The bottommost view controller in the detail navigation stack (or the
    /// first view controller after the last `WPSplitViewControllerDetailProvider`
    /// in the primary stack if the split view is collapsed).
    @objc var rootDetailViewController: UIViewController? {
        guard isCollapsed else {
            return (viewControllers.last as? UINavigationController)?.viewControllers.first
        }

        guard let navigationController = viewControllers.first as? UINavigationController else {
            return nil
        }

        guard let index = navigationController.viewControllers.lastIndex(where: { $0 is WPSplitViewControllerDetailProvider }),
            navigationController.viewControllers.count > index + 1 else {
            return nil
        }

        return navigationController.viewControllers[index + 1]
    }

    /** Sets the primary view controller of the split view as specified, and
     *  automatically sets the detail view controller if the primary
     *  conforms to `WPSplitViewControllerDetailProvider` and can vend a
     *  detail view controller.
     */
    @objc func setInitialPrimaryViewController(_ viewController: UIViewController) {
        guard let navigationController = viewController as? UINavigationController,
            let rootViewController = navigationController.viewControllers.last,
            let detailViewController = initialDetailViewControllerForPrimaryViewController(rootViewController) else {
                viewControllers = [viewController, UIViewController()]
                return
        }

        navigationController.delegate = self
        viewControllers = [viewController, detailViewController]
    }

    fileprivate func initialDetailViewControllerForPrimaryViewController(_ viewController: UIViewController) -> UIViewController? {

        guard let detailProvider = viewController as? WPSplitViewControllerDetailProvider,
        let detailViewController = detailProvider.initialDetailViewControllerForSplitView(self) else {
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
        navigationController.delegate = self
        WPStyleGuide.configureColors(view: navigationController.view, tableView: nil)

        return navigationController
    }

    fileprivate var detailNavigationStackHasBeenModified = false

    /// Shows or hides the primary view controller pane.
    ///
    /// - Parameter hidden: If `true`, hide the primary view controller.
    @objc func setPrimaryViewControllerHidden(_ hidden: Bool, animated: Bool = true) {
        guard fullscreenDisplayEnabled else {
            return
        }

        let updateDisplayMode = {
            self.preferredDisplayMode = (hidden) ? .secondaryOnly : .oneBesideSecondary
        }

        if animated {
            UIView.animate(withDuration: 0.33) {
                updateDisplayMode()
            }
        } else {
            updateDisplayMode()
        }
    }

    /// Pops both the primary and detail navigation controllers (if present)
    /// to their roots.
    ///
    @objc func popToRootViewControllersAnimated(_ animated: Bool) {
        let popOrScrollToTop = { (navigationController: UINavigationController) in
            if navigationController.viewControllers.count > 1 {
                navigationController.popToRootViewController(animated: animated)

                // Ensure navigation bars are visible – otherwise if we popped
                // back from e.g. a Reader Detail screen which had hidden its
                // bars, they'd stay hidden.
                navigationController.setNavigationBarHidden(false, animated: animated)
            } else {
                navigationController.scrollContentToTopAnimated(animated)
            }

        }

        if let primaryNavigationController = viewControllers.first as? UINavigationController {
            popOrScrollToTop(primaryNavigationController)

            if let detailNavigationController = viewControllers.last as? UINavigationController,
                primaryNavigationController != detailNavigationController {
                popOrScrollToTop(detailNavigationController)
            }
        }
    }
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

        // If the primary view is full width (i.e. when the No Results View is displayed),
        // don't show a detail view as it will be rendered on top of (thus covering) the primary view.
        if wpPrimaryColumnWidth == .full {
            return primaryNavigationController
        }

        var viewControllers: [UIViewController] = []

        // Splits the view controller list into primary and detail view controllers at the specified index
        let separateViewControllersAtIndex: ((Int) -> Void) = { index in
            viewControllers = Array(primaryNavigationController.viewControllers.suffix(from: index))
            primaryNavigationController.viewControllers = Array(primaryNavigationController.viewControllers.prefix(upTo: index))
        }

        if let index = primaryNavigationController.viewControllers.firstIndex(where: { $0 is UINavigationController }) {
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
            navigationController.viewControllers = viewControllers
            WPStyleGuide.configureColors(view: navigationController.view, tableView: nil)

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

                if (!isShowingInitialDetail && detailNavigationStackHasBeenModified) || forceKeepDetail {
                    primaryViewController.viewControllers.append(contentsOf: secondaryViewController.viewControllers)
                    secondaryViewController.viewControllers = [] // This prevents a crash that manifests on Xcode 15.0 / iOS 17.0
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
    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController,
                              animated: Bool) {
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
            // gets canceled so that we can undim the detail view if necessary.
            // (i.e. the user begins a back swipe but doesn't go through with it)
            coordinator.notifyWhenInteractionChanges({ [weak self] context in
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

        let hasFullscreenViewControllersInStack = navigationController.viewControllers.filter({$0 is PrefersFullscreenDisplay}).count > 0
        let isCurrentlyFullscreen = preferredDisplayMode != .oneBesideSecondary

        // Handle popping from fullscreen view controllers
        //
        // If we're currently in fullscreen mode, and there are no view controllers
        // left in the navigation stack that prefer to be fullscreen, then
        // animate back to a standard split view.
        if fullscreenDisplayEnabled && isCurrentlyFullscreen && !hasFullscreenViewControllersInStack {
            let performTransition = { (animated: Bool) in
                self.setPrimaryViewControllerHidden(false, animated: animated)

                if animated && !self.hasHorizontallyCompactView() {
                    navigationController.navigationBar.fadeOutNavigationItems(animated: true)
                }
            }

            if UIAccessibility.isReduceMotionEnabled {
                view.hideWithBlankingSnapshot(afterScreenUpdates: false)
                performTransition(false)
            } else {
                performTransition(animated)
            }
        }
    }

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        // Unfortunately by default when implementing custom navigation controller
        // transitions, the interactive gesture is disabled. To work around this,
        // we can implement the delegate ourselves (see: http://stackoverflow.com/a/38859457/570547)
        navigationController.interactivePopGestureRecognizer?.delegate = self

        if !hasHorizontallyCompactView() {
            // Restore navigation items after a push or pop if they were previously hidden
            navigationController.navigationBar.fadeInNavigationItemsIfNecessary()

            if UIAccessibility.isReduceMotionEnabled {
                view.fadeOutAndRemoveBlankingSnapshot()
            }
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

// MARK: - UIGestureRecognizerDelegate

// Used to selectively enable / disable our navigation controllers'
// interactive pop gesture recognizers
extension WPSplitViewController: UIGestureRecognizerDelegate {

    // We want to disable the interactive back gesture in a couple of situations:
    //
    // 1. There's only one view controller in the navigation stack
    //
    // 2. The top view controller is a fullscreen view controller, and navigating
    //    back means we would switch back to a split view. The interactive
    //    gesture doesn't work with the split view showing / hiding its primary
    //    view controller pane.
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        func gestureIsValidInNavigationController(_ navigationController: UINavigationController) -> Bool {
            return gestureRecognizer.view == navigationController.view &&
                navigationController.viewControllers.count > 1
        }

        // If the gesture is in the primary view controller and there's more
        // than 2 view controllers in the primary navigation stack then allow
        // the back gesture.
        if let primaryNavigationController = viewControllers.first as? UINavigationController,
            gestureIsValidInNavigationController(primaryNavigationController) {
            return true
        }

        // Same check but for the detail view controller
        if let detailNavigationController = viewControllers.last as? UINavigationController,
            gestureIsValidInNavigationController(detailNavigationController) && !isCollapsed {
            guard fullscreenDisplayEnabled else { return true }

            // Don't allow the back gesture if we're switching back from
            // fullscreen to split view
            var stack = detailNavigationController.viewControllers
            let topViewController = stack.popLast() // Remove the top view controller

            let currentlyFullscreen = topViewController is PrefersFullscreenDisplay
            let hasFullscreenViewControllersInStack = stack.filter({$0 is PrefersFullscreenDisplay}).count > 0

            let movingFromFullscreen = currentlyFullscreen && !hasFullscreenViewControllersInStack

            return !movingFromFullscreen
        }

        return false
    }
}

// MARK: - UIViewController Helpers

extension UIViewController {
    @objc var splitViewControllerIsHorizontallyCompact: Bool {
        return splitViewController?.hasHorizontallyCompactView() ?? hasHorizontallyCompactView()
    }
}

/// Used to indicate whether a view controller would prefer its splitview
/// to hide the primary view controller pane.
///
/// This isn't actually used on presentation of a view controller, but is used
/// to keep track of whether any view controllers in the navigation stack
/// would like to be fullscreen.
///
/// Once we've pushed a fullscreen view controller, the split view will remain
/// in fullscreen until the `navigationController(_:willShowViewController:animated:)`
/// delegate method detects that there are no fullscreen view controllers left
/// in the stack.
protocol PrefersFullscreenDisplay: AnyObject {}
