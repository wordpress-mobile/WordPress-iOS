import UIKit
import Combine
import WordPressShared

final class DashboardQuickActionsCardCell: UICollectionViewCell, Reusable, UITableViewDataSource, UITableViewDelegate {

    private lazy var tableView: UITableView = {
        let tableView = IntrinsicTableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isScrollEnabled = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.clipsToBounds = true
        tableView.layer.cornerRadius = 10
        tableView.backgroundColor = .listForeground
        tableView.register(DashboardQuickActionCell.self, forCellReuseIdentifier: Constants.cellReuseID)
        return tableView
    }()

    private var items: [DashboardQuickActionItemViewModel] = []
    private var viewModel: DashboardQuickActionsViewModel?
    private weak var parentViewController: BlogDashboardViewController?
    private weak var blogDetailsViewController: BlogDetailsViewController?
    private var cancellables: [AnyCancellable] = []

    override init(frame: CGRect) {
        super.init(frame: frame)

        createView()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    private func createView() {
        contentView.addSubview(tableView)
        contentView.pinSubviewToAllEdges(tableView, priority: UILayoutPriority(999))
    }

    func configure(viewModel: DashboardQuickActionsViewModel, viewController: BlogDashboardViewController) {
        self.parentViewController = viewController
        self.viewModel = viewModel

        cancellables = []

        viewModel.onViewWillAppear = { [weak self] in
            self?.deselectCurrentCell()
        }

        viewModel.$items.sink { [weak self] in
            guard let self else { return }
            self.items = $0
            self.tableView.reloadData()
            self.setNeedsLayout()
            self.layoutIfNeeded()
            self.parentViewController?.collectionView.collectionViewLayout.invalidateLayout()
        }.store(in: &cancellables)
    }

    private func deselectCurrentCell() {
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellReuseID, for: indexPath) as! DashboardQuickActionCell
        cell.configure(items[indexPath.row])
        cell.backgroundColor = .clear
        cell.accessoryType = .disclosureIndicator
        cell.isSeparatorHidden = indexPath.row == (items.count - 1)
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let blog = viewModel?.blog, let parentViewController else { return }

        switch items[indexPath.row].action {
        case .posts:
            trackQuickActionsEvent(.openedPosts, blog: blog)
            PostListViewController.showForBlog(blog, from: parentViewController)
        case .pages:
            trackQuickActionsEvent(.openedPages, blog: blog)
            PageListViewController.showForBlog(blog, from: parentViewController)
        case .comments:
            if let viewController = CommentsViewController(blog: blog) {
                trackQuickActionsEvent(.openedComments, blog: blog)
                parentViewController.show(viewController, sender: nil)
            }
        case .media:
            trackQuickActionsEvent(.openedMediaLibrary, blog: blog)
            MediaLibraryViewController.showForBlog(blog, from: parentViewController)
        case .stats:
            trackQuickActionsEvent(.statsAccessed, blog: blog)
            StatsViewController.show(for: blog, from: parentViewController)
        case .more:
            let viewController = BlogDetailsViewController()
            viewController.isScrollEnabled = true
            viewController.tableView.isScrollEnabled = true
            viewController.blog = blog
            viewController.presentationDelegate = self
            viewController.navigationItem.scrollEdgeAppearance = {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                return appearance
            }()
            self.blogDetailsViewController = viewController
            self.parentViewController?.show(viewController, sender: nil)
        }
    }

    private func trackQuickActionsEvent(_ event: WPAnalyticsStat, blog: Blog) {
        WPAppAnalytics.track(event, withProperties: [WPAppAnalyticsKeyTabSource: "dashboard", WPAppAnalyticsKeyTapSource: "quick_actions"], with: blog)
    }
}

// MARK: - DashboardQuickActionsCardCell (BlogDetailsPresentationDelegate)

extension DashboardQuickActionsCardCell: BlogDetailsPresentationDelegate {
    func showBlogDetailsSubsection(_ subsection: BlogDetailsSubsection) {
        self.blogDetailsViewController?.showDetailView(for: subsection)
    }

    func presentBlogDetailsViewController(_ viewController: UIViewController) {
        self.blogDetailsViewController?.show(viewController, sender: nil)
    }
}

private enum Constants {
    static let cellReuseID = "cellReuseID"
}
