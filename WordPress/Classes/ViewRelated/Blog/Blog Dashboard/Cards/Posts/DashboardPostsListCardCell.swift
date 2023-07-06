import UIKit

final class DashboardDraftPostsCardCell: DashboardPostsListCardCell, BlogDashboardCardConfigurable {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        super.configure(blog: blog, viewController: viewController, apiResponse: apiResponse, cardType: .draftPosts)
    }
}

final class DashboardScheduledPostsCardCell: DashboardPostsListCardCell, BlogDashboardCardConfigurable {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        super.configure(blog: blog, viewController: viewController, apiResponse: apiResponse, cardType: .scheduledPosts)
    }
}

class DashboardPostsListCardCell: UICollectionViewCell, Reusable {

    // MARK: Views

    private let frameView = BlogDashboardCardFrameView()

    lazy var tableView: UITableView = {
        let tableView = DashboardCardTableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.isScrollEnabled = false
        tableView.backgroundColor = nil
        let postCompactCellNib = PostCompactCell.defaultNib
        tableView.register(postCompactCellNib, forCellReuseIdentifier: PostCompactCell.defaultReuseID)
        let ghostCellNib = BlogDashboardPostCardGhostCell.defaultNib
        tableView.register(ghostCellNib, forCellReuseIdentifier: BlogDashboardPostCardGhostCell.defaultReuseID)
        tableView.register(DashboardPostListErrorCell.self, forCellReuseIdentifier: DashboardPostListErrorCell.defaultReuseID)
        tableView.separatorStyle = .none
        return tableView
    }()


    // MARK: Private Variables

    private var viewModel: PostsCardViewModel?
    private var blog: Blog?
    private var status: BasePost.Status = .draft

    /// The VC presenting this cell
    private weak var viewController: BlogDashboardViewController?

    // MARK: Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        tableView.dataSource = nil
        viewModel?.stopObserving()
    }

    // MARK: Helpers

    private func commonInit() {
        addSubviews()
        tableView.delegate = self
    }

    private func addSubviews() {
        frameView.translatesAutoresizingMaskIntoConstraints = false
        frameView.add(subview: tableView)

        contentView.addSubview(frameView)
        contentView.pinSubviewToAllEdges(frameView, priority: Constants.constraintPriority)
    }

    func trackPostsDisplayed() {
        BlogDashboardAnalytics.shared.track(.dashboardCardShown, properties: ["type": "post", "sub_type": status.rawValue])
    }

}

// MARK: BlogDashboardCardConfigurable

extension DashboardPostsListCardCell {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?, cardType: DashboardCard) {
        self.blog = blog
        self.viewController = viewController

        switch cardType {
        case .draftPosts:
            addDraftsContextMenu(card: cardType, blog: blog)
            configureDraftsList(blog: blog)
            status = .draft
        case .scheduledPosts:
            addScheduledContextMenu(card: cardType, blog: blog)
            configureScheduledList(blog: blog)
            status = .scheduled
        default:
            assertionFailure("Cell used with wrong card type")
            return
        }

        viewModel = PostsCardViewModel(blog: blog, status: status, view: self)
        viewModel?.viewDidLoad()
        tableView.dataSource = viewModel?.diffableDataSource
        viewModel?.refresh()
    }

    private func addDraftsContextMenu(card: DashboardCard, blog: Blog) {
        guard FeatureFlag.personalizeHomeTab.enabled else { return }

        frameView.addMoreMenu(items: [
            UIMenu(options: .displayInline, children: [
                makeDraftsListMenuAction()
            ]),
            UIMenu(options: .displayInline, children: [
                BlogDashboardHelpers.makeHideCardAction(for: card, blog: blog)
            ])
        ], card: card)
    }

    private func addScheduledContextMenu(card: DashboardCard, blog: Blog) {
        guard FeatureFlag.personalizeHomeTab.enabled else { return }

        frameView.addMoreMenu(items: [
            UIMenu(options: .displayInline, children: [
                makeScheduledListMenuAction()
            ]),
            UIMenu(options: .displayInline, children: [
                BlogDashboardHelpers.makeHideCardAction(for: card, blog: blog)
            ])
        ], card: card)
    }

    private func makeDraftsListMenuAction() -> UIAction {
        UIAction(title: Strings.viewAllDrafts, image: UIImage(systemName: "square.and.pencil")) { [weak self] _ in
            self?.presentPostList(with: .draft)
        }
    }

    private func makeScheduledListMenuAction() -> UIAction {
        UIAction(title: Strings.viewAllScheduledPosts, image: UIImage(systemName: "calendar")) { [weak self] _ in
            self?.presentPostList(with: .scheduled)
        }
    }

    private func configureDraftsList(blog: Blog) {
        frameView.setTitle(Strings.draftsTitle)
        frameView.onHeaderTap = { [weak self] in
            self?.presentPostList(with: .draft)
        }
    }

    private func configureScheduledList(blog: Blog) {
        frameView.setTitle(Strings.scheduledTitle)
        frameView.onHeaderTap = { [weak self] in
            self?.presentPostList(with: .scheduled)
        }
    }

    private func presentPostList(with status: BasePost.Status) {
        guard let blog = blog, let viewController = viewController else {
            return
        }

        PostListViewController.showForBlog(blog, from: viewController, withPostStatus: status)
        WPAppAnalytics.track(.openedPosts, withProperties: [WPAppAnalyticsKeyTabSource: "dashboard", WPAppAnalyticsKeyTapSource: "posts_card"], with: blog)
    }

}

// MARK: - UITableViewDelegate
extension DashboardPostsListCardCell: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let post = viewModel?.postAt(indexPath),
              let viewController = viewController else {
            return
        }

        WPAnalytics.track(.dashboardCardItemTapped,
                          properties: ["type": "post", "sub_type": status.rawValue])
        viewController.presentedPostStatus = viewModel?.currentPostStatus()
        PostListEditorPresenter.handle(post: post, in: viewController, entryPoint: .dashboard)
    }
}

// MARK: PostsCardView

extension DashboardPostsListCardCell: PostsCardView {

    func removeIfNeeded() {
        viewController?.reloadCardsLocally()
    }
}

extension BlogDashboardViewController: EditorAnalyticsProperties {
    func propertiesForAnalytics() -> [String: AnyObject] {
        var properties = [String: AnyObject]()

        properties["type"] = PostServiceType.post.rawValue as AnyObject?
        properties["filter"] = presentedPostStatus as AnyObject?

        if let dotComID = blog.dotComID {
            properties[WPAppAnalyticsKeyBlogID] = dotComID
        }

        return properties
    }
}

// MARK: Constants

private extension DashboardPostsListCardCell {

    private enum Strings {
        static let draftsTitle = NSLocalizedString("my-sites.drafts.card.title", value: "Work on a draft post", comment: "Title for the card displaying draft posts.")
        static let scheduledTitle = NSLocalizedString("Upcoming scheduled posts", comment: "Title for the card displaying upcoming scheduled posts.")
        static let viewAllDrafts = NSLocalizedString("my-sites.drafts.card.viewAllDrafts", value: "View all drafts", comment: "Title for the View all drafts button in the More menu")
        static let viewAllScheduledPosts = NSLocalizedString("my-sites.scheduled.card.viewAllScheduledPosts", value: "View all scheduled posts", comment: "Title for the View all scheduled drafts button in the More menu")
    }

    enum Constants {
        static let iconSize = CGSize(width: 18, height: 18)
        static let constraintPriority = UILayoutPriority(999)
        static let numberOfPosts = 3
    }
}
