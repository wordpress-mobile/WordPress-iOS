import UIKit
import WordPressShared

#warning("TODO: communicate willAppear here to remove selection")
final class DashboardQuickActionsCardCell: UICollectionViewCell, Reusable, UITableViewDataSource, UITableViewDelegate {

    private lazy var tableView: UITableView = {
        let tableView = SelfSizingTableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isScrollEnabled = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.clipsToBounds = true
        tableView.layer.cornerRadius = 10
        tableView.register(DashboardQuickActionCell.self, forCellReuseIdentifier: Constants.cellReuseID)
        return tableView
    }()

    private var items: [DashboardQuickActionItemViewModel] = []
    private weak var viewController: UIViewController?
    private weak var blogDetailsViewController: BlogDetailsViewController?
    private let scenePresenter = MeScenePresenter()

    override init(frame: CGRect) {
        super.init(frame: frame)

        createView()
        startObservingQuickStart()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    private func createView() {
        contentView.addSubview(tableView)
        contentView.pinSubviewToAllEdges(tableView, priority: UILayoutPriority(999))
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellReuseID, for: indexPath) as! DashboardQuickActionCell
        cell.configure(items[indexPath.row])
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        items[indexPath.row].action()
    }
}

// MARK: - DashboardQuickActionsCardCell (BlogDetailsPresentationDelegate)

extension DashboardQuickActionsCardCell: BlogDetailsPresentationDelegate {
    func showBlogDetailsSubsection(_ subsection: BlogDetailsSubsection) {
        self.blogDetailsViewController?.showDetailView(for: subsection)
    }

    func presentBlogDetailsViewController(_ viewController: UIViewController) {
        self.viewController?.showDetailViewController(viewController, sender: nil)
    }
}

// MARK: - Button Actions

extension DashboardQuickActionsCardCell {

#warning("TODO: add show more")
#warning("TODO: add details labels")
    func configure(for blog: Blog, with viewController: UIViewController) {
        items.removeAll()

        items.append(.init(image: .gridicon(.posts), title: Strings.posts, details: nil) { [weak self] in
            self?.showPostList(for: blog)
        })
        if blog.supports(.pages) {
            items.append(.init(image: .gridicon(.pages), title: Strings.pages, details: nil) { [weak self] in
                self?.showPageList(for: blog)
            })
        }
        items.append(.init(image: .gridicon(.image), title: Strings.media, details: nil) { [weak self] in
            self?.showMediaLibrary(for: blog)
        })
        if blog.supports(.stats) {
            items.append(.init(image: .gridicon(.statsAlt), title: Strings.stats, details: nil) { [weak self] in
                self?.showStats(for: blog)
            })
        }
        items.append(.init(image: .gridicon(.ellipsis), title: Strings.more, details: nil) { [weak self] in
            self?.showMoreDetails(for: blog)
        })

        self.tableView.reloadData()
        self.viewController = viewController
    }

    private func showStats(for blog: Blog) {
        guard let viewController else { return }
        trackQuickActionsEvent(.statsAccessed, blog: blog)
        StatsViewController.show(for: blog, from: viewController)
    }

    private func showPostList(for blog: Blog) {
        guard let viewController else { return }
        trackQuickActionsEvent(.openedPosts, blog: blog)
        PostListViewController.showForBlog(blog, from: viewController)
    }

    private func showMediaLibrary(for blog: Blog) {
        guard let viewController else { return }
        trackQuickActionsEvent(.openedMediaLibrary, blog: blog)
        MediaLibraryViewController.showForBlog(blog, from: viewController)
    }

    private func showPageList(for blog: Blog) {
        guard let viewController else { return }
        trackQuickActionsEvent(.openedPages, blog: blog)
        PageListViewController.showForBlog(blog, from: viewController)
    }

    private func showMoreDetails(for blog: Blog) {
        #warning("TODO: add track action")
//        trackQuickActionsEvent(.opened, blog: <#T##Blog#>)
        let viewController = BlogDetailsViewController(meScenePresenter: scenePresenter)
        viewController.blog = blog
        viewController.presentationDelegate = self
        self.blogDetailsViewController = viewController
        self.viewController?.show(viewController, sender: nil)

    }

    private func trackQuickActionsEvent(_ event: WPAnalyticsStat, blog: Blog) {
        WPAppAnalytics.track(event, withProperties: [WPAppAnalyticsKeyTabSource: "dashboard", WPAppAnalyticsKeyTapSource: "quick_actions"], with: blog)
    }
}

struct DashboardQuickActionItemViewModel {
    let image: UIImage
    let title: String
    let details: String?
    let action: () -> Void
}

extension DashboardQuickActionsCardCell {

    private func startObservingQuickStart() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleQuickStartTourElementChangedNotification(_:)), name: .QuickStartTourElementChangedNotification, object: nil)
    }

    #warning("TODO: reimplement")
    @objc private func handleQuickStartTourElementChangedNotification(_ notification: Foundation.Notification) {
//        guard let info = notification.userInfo,
//              let element = info[QuickStartTourGuide.notificationElementKey] as? QuickStartTourElement
//        else {
//            return
//        }
//
//        switch element {
//        case .stats:
//            guard QuickStartTourGuide.shared.entryPointForCurrentTour == .blogDashboard else {
//                return
//            }
//
//            autoScrollToStatsButton()
//        case .mediaScreen:
//            guard QuickStartTourGuide.shared.entryPointForCurrentTour == .blogDashboard else {
//                return
//            }
//
//            autoScrollToMediaButton()
//        default:
//            break
//        }
//        statsButton.shouldShowSpotlight = element == .stats
//        mediaButton.shouldShowSpotlight = element == .mediaScreen
    }

//    private func autoScrollToStatsButton() {
//        scrollView.scrollHorizontallyToView(statsButton, animated: true)
//    }
//
//    private func autoScrollToMediaButton() {
//        scrollView.scrollHorizontallyToView(mediaButton, animated: true)
//    }
}

private final class SelfSizingTableView: UITableView {
    override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        let height = min(.infinity, contentSize.height)
        return CGSize(width: contentSize.width, height: height - 1) // Hide the last separator
    }
}

extension DashboardQuickActionsCardCell {

    private enum Strings {
        static let stats = NSLocalizedString("Stats", comment: "Noun. Title for stats button.")
        static let posts = NSLocalizedString("Posts", comment: "Noun. Title for posts button.")
        static let media = NSLocalizedString("Media", comment: "Noun. Title for media button.")
        static let pages = NSLocalizedString("Pages", comment: "Noun. Title for pages button.")
        static let more = NSLocalizedString("More", comment: "Noun. Title for more button.")
    }

    private enum Constants {
        static let cellReuseID = "cellReuseID"
        static let contentViewCornerRadius = 8.0
        static let stackViewSpacing = 16.0
        static let stackViewHorizontalPadding = 20.0
    }
}
