import UIKit
import WordPressShared

/// The Me tab: the Me list beside the selected screen when the tab is wide enough (for example the
/// inner screen of iPhone Duo, or a Plus, Pro Max or Air iPhone in landscape on iOS 27), and a
/// single navigation stack otherwise.
///
/// The split view collapses at compact width, so a regular iPhone keeps the plain navigation stack.
///
/// Every screen opened from the Me list goes into `detailNavigationController` and is shown with
/// `show(.secondary)`, in both layouts. UIKit then moves that whole navigation controller onto the
/// Me list's stack when the split view collapses, and back into the detail column when it expands,
/// so a screen never changes navigation controller. Moving screens between navigation controllers
/// by hand left them with the bar insets of the previous one (a 90 pt gap above All Domains on an
/// iPhone Air after rotating), and moving the nested navigation controller crashed.
@objc final class MeSplitViewController: UISplitViewController {
    @objc let meViewController: MeViewController
    @objc let primaryNavigationController: UINavigationController
    private let detailNavigationController = UINavigationController()

    /// Whether the detail column shows a screen the user picked, rather than the default one.
    private var isShowingSelectedDetail = false

    @objc init(meViewController: MeViewController) {
        self.meViewController = meViewController
        self.primaryNavigationController = UINavigationController(rootViewController: meViewController)
        super.init(style: .doubleColumn)

        setViewController(primaryNavigationController, for: .primary)
        setViewController(detailNavigationController, for: .secondary)
        preferredDisplayMode = .oneBesideSecondary
        preferredSplitBehavior = .tile
        // The default width wraps row titles such as "Account Settings" on a 669 pt wide screen.
        minimumPrimaryColumnWidth = 300
        preferredPrimaryColumnWidth = 320
        presentsWithGesture = false
        displayModeButtonVisibility = .never
        primaryBackgroundStyle = .none
        delegate = self
        primaryNavigationController.delegate = self
        detailNavigationController.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        showDefaultDetailIfNeeded()
        updateTabBarVisibility(animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // A split view can still report itself collapsed in `viewIsAppearing`, and expanding from
        // there doesn't call `splitViewControllerDidExpand`.
        showDefaultDetailIfNeeded()
        meViewController.restoreDetailSelection()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.refreshTabBarInsets()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // The other tabs rely on their own navigation controllers to hide the tab bar.
        if tabBarController?.isTabBarHidden == true {
            tabBarController?.setTabBarHidden(false, animated: false)
        }
    }

    // MARK: - Detail

    /// Shows `viewController` from the Me list: beside it when expanded, pushed when collapsed.
    func showDetail(_ viewController: UIViewController, isSelectedByUser: Bool = true) {
        isShowingSelectedDetail = isSelectedByUser
        viewController.navigationItem.largeTitleDisplayMode = .never
        detailNavigationController.setViewControllers([viewController], animated: false)
        show(.secondary)
    }

    /// Shows the default screen in the detail column, replacing the screen there.
    func showDefaultDetail() {
        guard !isCollapsed else {
            return
        }
        showDetail(meViewController.makeDefaultDetail(), isSelectedByUser: false)
        meViewController.restoreDetailSelection()
    }

    /// Fills an empty detail column, the way Settings on iPad does.
    private func showDefaultDetailIfNeeded() {
        // `isCollapsed` alone isn't enough: a split view that is about to collapse on a compact
        // iPhone reports `false` when it first appears.
        guard traitCollection.horizontalSizeClass == .regular, !isCollapsed,
            detailNavigationController.viewControllers.isEmpty
        else {
            return
        }
        showDefaultDetail()
    }

    // MARK: - Tab Bar

    /// `hidesBottomBarWhenPushed` only works when a navigation controller is a tab directly, so
    /// apply it here for the collapsed stack. Expanded, the tab bar stays: the Me list is still on
    /// screen.
    private func updateTabBarVisibility(animated: Bool) {
        guard let tabBarController, tabBarController.selectedViewController === self else {
            return
        }
        let isHidden = isCollapsed && collapsedStack.contains { $0.hidesBottomBarWhenPushed }
        if tabBarController.isTabBarHidden != isHidden {
            tabBarController.setTabBarHidden(isHidden, animated: animated)
        }
    }

    /// After a rotation, `UITabBarController` keeps the old tab bar height (83 pt in portrait, not
    /// 64 pt in landscape) in the bottom safe area of a tab that isn't a navigation controller.
    /// Hiding and showing the tab bar in the same run loop makes it measure again, and nothing
    /// changes on screen.
    private func refreshTabBarInsets() {
        guard let tabBarController, tabBarController.selectedViewController === self,
            !tabBarController.isTabBarHidden
        else {
            return
        }
        tabBarController.setTabBarHidden(true, animated: false)
        tabBarController.setTabBarHidden(false, animated: false)
    }

    /// The screens on the collapsed stack, including those of the detail navigation controller
    /// that UIKit nests in it.
    private var collapsedStack: [UIViewController] {
        primaryNavigationController.viewControllers.flatMap { viewController in
            (viewController as? UINavigationController)?.viewControllers ?? [viewController]
        }
    }
}

extension MeSplitViewController: UISplitViewControllerDelegate {
    func splitViewController(
        _ svc: UISplitViewController,
        topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column
    ) -> UISplitViewController.Column {
        // Keep a screen the user opened on screen; otherwise go back to the Me list.
        guard isShowingSelectedDetail, !detailNavigationController.viewControllers.isEmpty else {
            meViewController.clearDetailSelection()
            return .primary
        }
        return .secondary
    }

    func splitViewControllerDidCollapse(_ svc: UISplitViewController) {
        updateTabBarVisibility(animated: false)
    }

    func splitViewControllerDidExpand(_ svc: UISplitViewController) {
        updateTabBarVisibility(animated: false)
        showDefaultDetailIfNeeded()
        meViewController.restoreDetailSelection()
    }
}

extension MeSplitViewController: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        updateTabBarVisibility(animated: animated)
        // An interactive pop can be cancelled, which leaves the stack as it was.
        navigationController.transitionCoordinator?
            .animate(alongsideTransition: nil) { [weak self] context in
                if context.isCancelled {
                    self?.updateTabBarVisibility(animated: false)
                }
            }
    }
}
