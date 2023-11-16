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

    private let quickStartNavigationSettings = QuickStartNavigationSettings()

    fileprivate static let navigationControllerRestorationIdentifier = "WPSplitViewDetailNavigationControllerRestorationID"
    fileprivate static let preferredDisplayModeModifiedRestorationKey = "WPSplitViewPreferredDisplayModeRestorationKey"

    /// Determines how the split view handles the detail pane when collapsing itself.
    /// If 'Automatic', then the detail pane will be pushed onto the primary navigation stack
    /// if the user has manually changed the selection in the primary pane. Otherwise,
    /// if the detail pane is still showing its default content, it will be discarded.
    /// If 'AlwaysKeepDetail', the detail pane will always be pushed onto the
    /// primary navigation stack.
    @objc var collapseMode: WPSplitViewControllerCollapseMode = .Automatic

    /// Set to false to disable fullscreen display mode
    @objc var fullscreenDisplayEnabled = true

    // MARK: State restoration

    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
    }

    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
    }

    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()


        maximumPrimaryColumnWidth = 300
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return WPStyleGuide.preferredStatusBarStyle
    }

    override var childForStatusBarStyle: UIViewController? {
        if let _ = topDetailViewController as? DefinesVariableStatusBarStyle {
            return topDetailViewController
        }
        return nil
    }


    /// A flag that indicates whether the split view controller is showing the
    /// initial (i.e. default) view controller or not.
    ///
    @objc var isShowingInitialDetail = false

    fileprivate let dimmingViewAlpha: CGFloat = 0.5
    fileprivate let dimmingViewAnimationDuration: TimeInterval = 0.3


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

//        navigationController.delegate = self
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

        navigationController.restorationIdentifier = type(of: self).navigationControllerRestorationIdentifier
        navigationController.extendedLayoutIncludesOpaqueBars = true
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
            UIView.animate(withDuration: WPFullscreenNavigationTransition.transitionDuration) {
                updateDisplayMode()
            }
        } else {
            updateDisplayMode()
        }
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

/// Used to indicate whether a view controller varies its preferred status bar style.
///
protocol DefinesVariableStatusBarStyle: AnyObject {}

// MARK: - WPSplitViewControllerDetailProvider Protocol

@objc
protocol WPSplitViewControllerDetailProvider {
    /**
     * View controllers that implement this method can return a view controller
     * to automatically populate the detail pane of the split view with.
     */
    func initialDetailViewControllerForSplitView(_ splitView: WPSplitViewController) -> UIViewController?
}
