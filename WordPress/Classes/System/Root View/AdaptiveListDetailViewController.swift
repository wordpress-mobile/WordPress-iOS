import UIKit

/// Keeps one list and detail hierarchy as UIKit collapses and expands the content.
final class AdaptiveListDetailViewController: UIViewController, UISplitViewControllerDelegate {
    let splitViewControllerForContent = UISplitViewController(style: .doubleColumn)
    let listNavigationController: UINavigationController
    private let detailNavigationController = UINavigationController()
    private let placeholder = UIViewController()

    var isShowingAlongsideDetail: Bool { !splitViewControllerForContent.isCollapsed }

    init(list: UIViewController) {
        listNavigationController = UINavigationController(rootViewController: list)
        super.init(nibName: nil, bundle: nil)
        title = list.title
        placeholder.view.backgroundColor = .systemBackground
        detailNavigationController.setViewControllers([placeholder], animated: false)
        let split = splitViewControllerForContent
        split.delegate = self
        split.preferredDisplayMode = .oneBesideSecondary
        split.preferredSplitBehavior = .tile
        split.preferredPrimaryColumnWidth = 360
        split.minimumPrimaryColumnWidth = 300
        split.maximumPrimaryColumnWidth = 420
        split.setViewController(listNavigationController, for: .primary)
        split.setViewController(detailNavigationController, for: .secondary)
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
            split.view.topAnchor.constraint(equalTo: view.topAnchor),
            split.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        split.didMove(toParent: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    func showDetail(_ controller: UIViewController) {
        detailNavigationController.setViewControllers([controller], animated: false)
        splitViewControllerForContent.show(.secondary)
    }

    func splitViewController(
        _ svc: UISplitViewController,
        topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column
    ) -> UISplitViewController.Column {
        detailNavigationController.viewControllers.first === placeholder ? .primary : .secondary
    }
}
