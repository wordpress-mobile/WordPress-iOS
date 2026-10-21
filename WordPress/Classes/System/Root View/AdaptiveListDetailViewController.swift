import UIKit

/// Keeps one list and detail hierarchy as UIKit collapses and expands the content.
final class AdaptiveListDetailViewController: UIViewController, UISplitViewControllerDelegate {
    let splitViewControllerForContent = UISplitViewController(style: .doubleColumn)
    let listNavigationController: UINavigationController
    let detailNavigationController = UINavigationController()
    private let placeholder = UIViewController()
    private let usesDetailForCompactWidth: Bool
    private let automaticallyHidesTabBar: Bool

    var onDetailDidShow: ((UIViewController) -> Void)?
    var onListVisibilityChanged: ((Bool) -> Void)?
    private(set) var isListVisible = false

    var isShowingAlongsideDetail: Bool { !splitViewControllerForContent.isCollapsed }

    var requestsHiddenBottomBar: Bool {
        guard automaticallyHidesTabBar else { return false }
        let navigation =
            usesDetailForCompactWidth || !splitViewControllerForContent.isCollapsed
            ? detailNavigationController : listNavigationController
        return navigation.requestsHiddenBottomBar
    }

    init(
        list: UIViewController,
        usesDetailForCompactWidth: Bool = false,
        automaticallyHidesTabBar: Bool = false
    ) {
        self.usesDetailForCompactWidth = usesDetailForCompactWidth
        self.automaticallyHidesTabBar = automaticallyHidesTabBar
        listNavigationController = (list as? UINavigationController) ?? UINavigationController(rootViewController: list)
        super.init(nibName: nil, bundle: nil)
        listNavigationController.delegate = self
        detailNavigationController.delegate = self
        title = list.title
        placeholder.view.backgroundColor = .systemBackground
        detailNavigationController.setViewControllers([placeholder], animated: false)
        let split = splitViewControllerForContent
        split.delegate = self
        split.preferredDisplayMode = .oneBesideSecondary
        split.displayModeButtonVisibility = .never
        split.preferredSplitBehavior = .tile
        split.preferredPrimaryColumnWidth = 360
        split.minimumPrimaryColumnWidth = 300
        split.maximumPrimaryColumnWidth = 420
        split.setViewController(listNavigationController, for: .primary)
        split.setViewController(detailNavigationController, for: .secondary)
        if usesDetailForCompactWidth {
            // Reuse the content stack so compact Back navigation never exposes the site menu.
            split.setViewController(detailNavigationController, for: .compact)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        let split = splitViewControllerForContent
        addChild(split)
        view.addSubview(split.view)
        split.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            split.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            split.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            split.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            split.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        split.didMove(toParent: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        updateTabBarVisibility(animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let split = splitViewControllerForContent
        updateListVisibility(!split.isCollapsed && split.displayMode != .secondaryOnly)
        updateTabBarVisibility(animated: false)
    }

    private func updateTabBarVisibility(animated: Bool) {
        (tabBarController as? AppTabBarController)?.updateTabBarVisibility(animated: animated)
    }

    private func updateListVisibility(_ isVisible: Bool) {
        if isVisible != isListVisible {
            isListVisible = isVisible
            onListVisibilityChanged?(isVisible)
        }
    }

    func showDetail(_ controller: UIViewController, keeping root: UIViewController? = nil) {
        let controllers = root.map { [$0, controller] } ?? [controller]
        detailNavigationController.setViewControllers(controllers, animated: false)
        showDetailColumn()
    }

    private func showDetailColumn() {
        if !usesDetailForCompactWidth || !splitViewControllerForContent.isCollapsed {
            splitViewControllerForContent.show(.secondary)
        }
    }

    func pushDetail(_ controller: UIViewController, animated: Bool) {
        if detailNavigationController.viewControllers.first === placeholder {
            showDetail(controller)
        } else {
            detailNavigationController.pushViewController(controller, animated: animated)
            showDetailColumn()
        }
    }

    func splitViewControllerDidCollapse(_ svc: UISplitViewController) {
        updateListVisibility(false)
    }

    func splitViewControllerDidExpand(_ svc: UISplitViewController) {
        updateListVisibility(svc.displayMode != .secondaryOnly)
    }

    func splitViewController(
        _ svc: UISplitViewController,
        willChangeTo displayMode: UISplitViewController.DisplayMode
    ) {
        updateListVisibility(!svc.isCollapsed && displayMode != .secondaryOnly)
    }

    func splitViewController(
        _ svc: UISplitViewController,
        topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column
    ) -> UISplitViewController.Column {
        detailNavigationController.viewControllers.first === placeholder ? .primary : .secondary
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
        // A cancelled interactive pop restores the original stack.
        updateTabBarVisibility(animated: animated)
        if navigationController === detailNavigationController {
            onDetailDidShow?(viewController)
        }
    }
}

extension UINavigationController {
    var requestsHiddenBottomBar: Bool {
        // UIKit can embed the detail navigation controller in the primary stack when collapsing.
        viewControllers.contains {
            $0.hidesBottomBarWhenPushed || ($0 as? UINavigationController)?.requestsHiddenBottomBar == true
        }
    }
}
