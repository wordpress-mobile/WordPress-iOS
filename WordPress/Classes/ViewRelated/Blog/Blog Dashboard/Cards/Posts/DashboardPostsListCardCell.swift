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

    private var frameView: BlogDashboardCardFrameView?
    private var ghostableTableView: UITableView?
    private var errorView: DashboardCardInnerErrorView?

    lazy var tableView: UITableView = {
        let tableView = PostCardTableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.isScrollEnabled = false
        tableView.backgroundColor = nil
        let postCompactCellNib = PostCompactCell.defaultNib
        tableView.register(postCompactCellNib, forCellReuseIdentifier: PostCompactCell.defaultReuseID)
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

    // MARK: Helpers

    private func commonInit() {
        addSubviews()
        tableView.delegate = self
    }

    private func addSubviews() {
        let frameView = BlogDashboardCardFrameView()
        frameView.icon = UIImage.gridicon(.posts, size: Constants.iconSize)
        frameView.translatesAutoresizingMaskIntoConstraints = false

        frameView.add(subview: tableView)

        self.frameView = frameView

        contentView.addSubview(frameView)
        contentView.pinSubviewToAllEdges(frameView, priority: Constants.constraintPriority)
    }

    func configureGhostableTableView() {
        guard ghostableTableView?.superview == nil else {
            return
        }

        let ghostableTableView = PostCardTableView()

        frameView?.addSubview(ghostableTableView)

        ghostableTableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: ghostableTableView.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: ghostableTableView.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: ghostableTableView.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: ghostableTableView.trailingAnchor).isActive = true

        ghostableTableView.isScrollEnabled = false
        ghostableTableView.separatorStyle = .none

        let postCompactCellNib = BlogDashboardPostCardGhostCell.defaultNib
        ghostableTableView.register(postCompactCellNib, forCellReuseIdentifier: BlogDashboardPostCardGhostCell.defaultReuseID)

        let ghostOptions = GhostOptions(displaysSectionHeader: false, reuseIdentifier: BlogDashboardPostCardGhostCell.defaultReuseID, rowsPerSection: [Constants.numberOfPosts])
        let style = GhostStyle(beatDuration: GhostStyle.Defaults.beatDuration,
                               beatStartColor: .placeholderElement,
                               beatEndColor: .placeholderElementFaded)
        ghostableTableView.removeGhostContent()
        ghostableTableView.displayGhostContent(options: ghostOptions, style: style)

        self.ghostableTableView = ghostableTableView
    }

    func removeGhostableTableView() {
        ghostableTableView?.removeFromSuperview()
    }

    func trackPostsDisplayed() {
        WPAnalytics.track(.dashboardCardShown, properties: ["type": "post", "sub_type": status.rawValue])
    }

}

// MARK: BlogDashboardCardConfigurable

extension DashboardPostsListCardCell {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?, cardType: DashboardCard) {
        self.blog = blog
        self.viewController = viewController

        switch cardType {
        case .draftPosts:
            configureDraftsList(blog: blog)
            status = .draft
        case .scheduledPosts:
            configureScheduledList(blog: blog)
            status = .scheduled
        default:
            return
        }
        viewModel = PostsCardViewModel(blog: blog, status: status, viewController: self, shouldSync: true)
        viewModel?.viewDidLoad()
        tableView.dataSource = viewModel?.diffableDataSource
        viewModel?.refresh()
    }

    private func configureDraftsList(blog: Blog) {
        frameView?.title = Strings.draftsTitle
        frameView?.onHeaderTap = { [weak self] in
            self?.presentPostList(with: .draft)
        }
    }

    private func configureScheduledList(blog: Blog) {
        frameView?.title = Strings.scheduledTitle
        frameView?.onHeaderTap = { [weak self] in
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
    func showLoading() {
        configureGhostableTableView()
    }

    func hideLoading() {
        guard ghostableTableView?.superview != nil else {
            return
        }

        hideError()
        removeGhostableTableView()

        if errorView == nil {
            trackPostsDisplayed()
        }
    }

    func showError(message: String, retry: Bool) {
        let errorView = DashboardCardInnerErrorView(message: message, canRetry: retry)
        errorView.delegate = self
        errorView.translatesAutoresizingMaskIntoConstraints = false
        tableView.addSubview(withFadeAnimation: errorView)
        tableView.pinSubviewToSafeArea(errorView)
        self.errorView = errorView

        // Force the table view to recalculate its height
        _ = tableView.intrinsicContentSize

        WPAnalytics.track(.dashboardCardShown, properties: ["type": "post", "sub_type": "error"])
    }

    func hideError() {
        errorView?.removeFromSuperview()
    }

    func showNextPostPrompt() {
        // TODO: Should be removed from protocol
    }

    func hideNextPrompt() {
        // TODO: Should be removed from protocol
    }

    func firstPostPublished() {
        // TODO: Should be removed from protocol
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

// MARK: - DashboardCardInnerErrorViewDelegate

extension DashboardPostsListCardCell: DashboardCardInnerErrorViewDelegate {
    func retry() {
        viewModel?.retry()
    }
}

// MARK: Constants

private extension DashboardPostsListCardCell {

    private enum Strings {
        static let draftsTitle = NSLocalizedString("Work on a draft post", comment: "Title for the card displaying draft posts.")
        static let scheduledTitle = NSLocalizedString("Upcoming scheduled posts", comment: "Title for the card displaying upcoming scheduled posts.")
    }

    enum Constants {
        static let iconSize = CGSize(width: 18, height: 18)
        static let constraintPriority = UILayoutPriority(999)
        static let numberOfPosts = 3
    }
}

// MARK: - PostCardTableView

extension NSNotification.Name {
    /// Fired when a PostCardTableView changes its size
    static let postCardTableViewSizeChanged = NSNotification.Name("IntrinsicContentSizeUpdated")
}

private class PostCardTableView: UITableView {
    private var previousHeight: CGFloat = 0

    override var contentSize: CGSize {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }

    /// Emits a notification when the intrinsicContentSize changes
    /// This allows subscribers to update their layouts (ie.: UICollectionViews)
    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        if contentSize.height != previousHeight, contentSize.height != 0 {
            previousHeight = contentSize.height
            NotificationCenter.default.post(name: .postCardTableViewSizeChanged, object: nil)
        }
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}
