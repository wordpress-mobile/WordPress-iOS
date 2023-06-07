import UIKit

final class DashboardPagesListCardCell: DashboardCollectionViewCell, PagesCardView {

    var parentViewController: UIViewController? {
        presentingViewController
    }

    private var blog: Blog?
    private weak var presentingViewController: BlogDashboardViewController?
    private var viewModel: PagesCardViewModel?

    // MARK: - Views

    private lazy var cardFrameView: BlogDashboardCardFrameView = {
        let frameView = BlogDashboardCardFrameView()
        frameView.translatesAutoresizingMaskIntoConstraints = false
        frameView.setTitle(Strings.title)
        frameView.accessibilityIdentifier = "dashboard-pages-card-frameview"
        return frameView
    }()

    lazy var tableView: UITableView = {
        let tableView = DashboardCardTableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.isScrollEnabled = false
        tableView.backgroundColor = nil
        tableView.register(DashboardPageCell.self,
                           forCellReuseIdentifier: DashboardPageCell.defaultReuseID)
        tableView.register(DashboardPageCreationCompactCell.self,
                           forCellReuseIdentifier: DashboardPageCreationCompactCell.defaultReuseID)
        tableView.register(DashboardPageCreationExpandedCell.self,
                           forCellReuseIdentifier: DashboardPageCreationExpandedCell.defaultReuseID)
        tableView.register(BlogDashboardPostCardGhostCell.defaultNib,
                           forCellReuseIdentifier: BlogDashboardPostCardGhostCell.defaultReuseID)
        tableView.separatorStyle = .none
        return tableView
    }()

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    // MARK: View Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        tableView.dataSource = nil
        viewModel?.tearDown()
    }

    // MARK: - Helpers

    private func commonInit() {
        setupView()
        configureHeaderAction()
        tableView.delegate = self
    }

    private func setupView() {
        cardFrameView.add(subview: tableView)

        contentView.addSubview(cardFrameView)
        contentView.pinSubviewToAllEdges(cardFrameView, priority: .defaultHigh)
    }

    private func configureHeaderAction() {
        cardFrameView.onHeaderTap = { [weak self] in
            self?.showPagesList(source: .header)
        }
    }
}

// MARK: - BlogDashboardCardConfigurable

extension DashboardPagesListCardCell {
    func configure(blog: Blog,
                   viewController: BlogDashboardViewController?,
                   apiResponse: BlogDashboardRemoteEntity?) {
        self.blog = blog
        self.presentingViewController = viewController

        configureContextMenu(blog: blog)

        viewModel = PagesCardViewModel(blog: blog, view: self)
        viewModel?.viewDidLoad()
        tableView.dataSource = viewModel?.diffableDataSource
        viewModel?.refresh()
    }

    // MARK: Context Menu

    private func configureContextMenu(blog: Blog) {
        cardFrameView.onEllipsisButtonTap = {
            BlogDashboardAnalytics.trackContextualMenuAccessed(for: .pages)
        }
        cardFrameView.ellipsisButton.showsMenuAsPrimaryAction = true

        let children = [
            makeAllPagesAction(),
            BlogDashboardHelpers.makeHideCardAction(for: .pages, blog: blog)
        ].compactMap { $0 }

        cardFrameView.ellipsisButton.menu = UIMenu(title: String(), options: .displayInline, children: children)
    }

    private func makeAllPagesAction() -> UIMenuElement {
        let allPagesAction = UIAction(title: Strings.allPages,
                                      image: Style.allPagesImage,
                                      handler: { _ in self.showPagesList(source: .contextMenu) })

        // Wrap the pages action in a menu to display a divider between the pages action and hide this action.
        // https://developer.apple.com/documentation/uikit/uimenu/options/3261455-displayinline
        let allPagesSubmenu = UIMenu(title: String(), options: .displayInline, children: [allPagesAction])
        return allPagesSubmenu
    }

    // MARK: Actions

    private func showPagesList(source: PagesListSource) {
        guard let blog, let presentingViewController else {
            return
        }
        PageListViewController.showForBlog(blog, from: presentingViewController)
        WPAppAnalytics.track(.openedPages,
                             withProperties: [WPAppAnalyticsKeyTapSource: source.rawValue],
                             with: blog)
    }
}

// MARK: - UITableViewDelegate
extension DashboardPagesListCardCell: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let isPagesSection = indexPath.section == 0
        if isPagesSection {
            handlePageSelected(at: indexPath)
        } else {
            handleCreatePageSectionSelected()
        }

    }

    private func handlePageSelected(at indexPath: IndexPath) {
        guard let page = viewModel?.pageAt(indexPath),
              let presentingViewController else {
            return
        }
        PageEditorPresenter.handle(page: page,
                                   in: presentingViewController,
                                   entryPoint: .dashboard)

        viewModel?.trackPageTapped()
    }

    private func handleCreatePageSectionSelected() {
        viewModel?.createPage()
    }
}

extension DashboardPagesListCardCell {

    static func shouldShowCard(for blog: Blog) -> Bool {
        guard RemoteFeatureFlag.pagesDashboardCard.enabled(),
              blog.supports(.pages) else {
            return false
        }

        return true
    }
}

private extension DashboardPagesListCardCell {

    enum PagesListSource: String {
        case header = "pages_card_header"
        case contextMenu = "pages_card_context_menu"
    }

    enum Strings {
        static let title = NSLocalizedString("dashboardCard.Pages.title",
                                             value: "Pages",
                                             comment: "Title for the Pages dashboard card.")
        static let allPages = NSLocalizedString("dashboardCard.Pages.contextMenu.allPages",
                                                   value: "All pages",
                                                   comment: "Title for an action that opens the full pages list.")
    }

    enum Style {
        static let allPagesImage = UIImage(systemName: "doc.text")
    }
}
