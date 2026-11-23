import UIKit

/// Owns the content stacks while UIKit moves them between columns and compact navigation.
final class AdaptiveListDetailViewController: UISplitViewController {
    var contentSplitViewController: UISplitViewController { self }
    let listNavigationController: UINavigationController
    let detailNavigationController: UINavigationController

    var onDetailDidShow: ((UIViewController) -> Void)?
    var onReturnToList: (() -> Void)?
    private weak var lastShownListController: UIViewController?
    var onListVisibilityChanged: ((Bool) -> Void)?
    var onCollapseStateChanged: ((Bool) -> Void)?
    private(set) var isListVisible = false
    private var wasCollapsed: Bool?

    private let usesDetailForCompactWidth: Bool
    private let placeholder = UIViewController()

    var isShowingAlongsideDetail: Bool { !contentSplitViewController.isCollapsed }

    var requestsHiddenBottomBar: Bool {
        let navigation =
            usesDetailForCompactWidth || !contentSplitViewController.isCollapsed
            ? detailNavigationController : listNavigationController
        return navigation.requestsHiddenBottomBar
    }

    init(
        list: UINavigationController,
        detail: UINavigationController = UINavigationController(),
        usesDetailForCompactWidth: Bool = false
    ) {
        listNavigationController = list
        detailNavigationController = detail
        self.usesDetailForCompactWidth = usesDetailForCompactWidth
        super.init(style: .doubleColumn)

        list.delegate = self
        detail.delegate = self
        if detail.viewControllers.isEmpty {
            placeholder.view.backgroundColor = .systemBackground
            detail.setViewControllers([placeholder], animated: false)
        }
        let split = contentSplitViewController
        split.delegate = self
        split.setViewController(list, for: .primary)
        split.setViewController(detail, for: .secondary)
        if usesDetailForCompactWidth {
            // Dashboard stays at the bottom of My Site's compact Back history.
            split.setViewController(detail, for: .compact)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateListVisibility()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateListVisibility()
    }

    func showDetail(_ controller: UIViewController, keeping root: UIViewController? = nil) {
        detailNavigationController.setViewControllers(root.map { [$0, controller] } ?? [controller], animated: false)
        showDetailColumn()
    }

    func pushDetail(_ controller: UIViewController, animated: Bool) {
        if detailNavigationController.viewControllers.first === placeholder {
            showDetail(controller)
        } else {
            detailNavigationController.pushViewController(controller, animated: animated)
            showDetailColumn()
        }
    }

    func showDetailColumn() {
        if !usesDetailForCompactWidth || !contentSplitViewController.isCollapsed {
            contentSplitViewController.show(.secondary)
            if isCollapsed {
                lastShownListController = listNavigationController.topViewController
            }
        }
    }

    func resetDetail() {
        detailNavigationController.setViewControllers([placeholder], animated: false)
        if contentSplitViewController.isCollapsed {
            contentSplitViewController.show(.primary)
        }
    }

    private func updateListVisibility(displayMode: UISplitViewController.DisplayMode? = nil) {
        let split = contentSplitViewController
        if wasCollapsed != split.isCollapsed {
            wasCollapsed = split.isCollapsed
            onCollapseStateChanged?(split.isCollapsed)
        }
        let isVisible = !split.isCollapsed && (displayMode ?? split.displayMode) != .secondaryOnly
        guard isListVisible != isVisible else { return }
        isListVisible = isVisible
        onListVisibilityChanged?(isVisible)
    }

    private func updateTabBarVisibility(animated: Bool) {
        (tabBarController as? WPTabBarController)?.updateAdaptiveTabBarVisibility(animated: animated)
    }
}

extension AdaptiveListDetailViewController: UISplitViewControllerDelegate {
    func splitViewControllerDidCollapse(_ svc: UISplitViewController) {
        lastShownListController = listNavigationController.topViewController
        updateListVisibility()
    }

    func splitViewControllerDidExpand(_ svc: UISplitViewController) {
        updateListVisibility()
    }

    func splitViewController(
        _ svc: UISplitViewController,
        willChangeTo displayMode: UISplitViewController.DisplayMode
    ) {
        updateListVisibility(displayMode: displayMode)
    }

    func splitViewController(
        _ svc: UISplitViewController,
        topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column
    ) -> UISplitViewController.Column {
        if usesDetailForCompactWidth { return .compact }
        return detailNavigationController.viewControllers.first === placeholder ? .primary : .secondary
    }
}

extension AdaptiveListDetailViewController: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        updateTabBarVisibility(animated: animated)
    }

    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        // This also restores visibility after a cancelled interactive pop.
        updateTabBarVisibility(animated: animated)
        if navigationController === detailNavigationController {
            onDetailDidShow?(viewController)
        } else if navigationController === listNavigationController {
            let previous = lastShownListController
            lastShownListController = viewController
            if isCollapsed, traitCollection.horizontalSizeClass == .compact,
                viewController === navigationController.viewControllers.first,
                let previous, previous !== viewController
            {
                onReturnToList?()
            }
        }
    }
}

extension UINavigationController {
    var requestsHiddenBottomBar: Bool {
        // UIKit can nest the secondary navigation controller inside the primary during collapse.
        viewControllers.contains {
            $0.hidesBottomBarWhenPushed || ($0 as? UINavigationController)?.requestsHiddenBottomBar == true
        }
    }
}
