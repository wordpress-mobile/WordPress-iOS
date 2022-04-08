import UIKit

protocol PostsCardViewControllerDelegate: AnyObject {
    func didShowNextPostPrompt(cardFrameView: BlogDashboardCardFrameView?)
    func didHideNextPostPrompt(cardFrameView: BlogDashboardCardFrameView?)
}

/// Render a small list of posts for a given blog and post status (drafts or scheduled)
///
/// This class handles showing posts from the database, syncing and interacting with them
///
/// If posts are not available, a "write your next post" prompt is shown.
///
@objc class PostsCardViewController: UIViewController {
    var blog: Blog

    let tableView: UITableView = PostCardTableView()

    private var viewModel: PostsCardViewModel!
    private var ghostableTableView: UITableView?
    private var errorView: DashboardCardInnerErrorView?
    private var nextPostView: BlogDashboardNextPostView?
    private var status: BasePost.Status = .draft
    private var hasPublishedPosts: Bool
    private var shouldSync: Bool

    weak var delegate: PostsCardViewControllerDelegate?

    private var cardFrameView: BlogDashboardCardFrameView? {
        return view.superview?.superview as? BlogDashboardCardFrameView
    }

    init(blog: Blog, status: BasePost.Status, hasPublishedPosts: Bool = true, shouldSync: Bool = true) {
        self.blog = blog
        self.status = status
        self.hasPublishedPosts = hasPublishedPosts
        self.shouldSync = shouldSync
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        viewModel = PostsCardViewModel(blog: blog, status: status, viewController: self, shouldSync: shouldSync)
        viewModel.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.dataSource = viewModel.diffableDataSource
        tableView.delegate = self
        viewModel.refresh()
    }

    func update(blog: Blog, status: BasePost.Status, hasPublishedPosts: Bool, shouldSync: Bool) {
        self.blog = blog
        self.status = status
        self.hasPublishedPosts = hasPublishedPosts
        self.shouldSync = shouldSync
        viewModel?.update(blog: blog, status: status, shouldSync: shouldSync)
    }
}

// MARK: - Private methods

private extension PostsCardViewController {
    func configureView() {
        configureTableView()
    }

    func configureTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.isScrollEnabled = false
        tableView.backgroundColor = nil
        view.pinSubviewToAllEdges(tableView)
        let postCompactCellNib = PostCompactCell.defaultNib
        tableView.register(postCompactCellNib, forCellReuseIdentifier: PostCompactCell.defaultReuseID)
        tableView.separatorStyle = .none
    }

    func configureGhostableTableView() {
        guard ghostableTableView?.superview == nil else {
            return
        }

        let ghostableTableView = PostCardTableView()

        view.addSubview(ghostableTableView)

        ghostableTableView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(ghostableTableView)

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

    func presentEditor() {
        let editor = EditPostViewController(blog: blog)
        present(editor, animated: true)
    }

    func notifyOfHeightChange() {
        NotificationCenter.default.post(name: .postCardTableViewSizeChanged, object: nil)
    }

    func trackPostsDisplayed() {
        BlogDashboardAnalytics.shared.track(.dashboardCardShown, properties: ["type": "post", "sub_type": status.rawValue])
    }

    enum Constants {
        static let numberOfPosts = 3
        static let writeFirstPostViewHeight: CGFloat = 92
    }
}

// MARK: - UITableViewDelegate
extension PostsCardViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = viewModel.postAt(indexPath)

        WPAnalytics.track(.dashboardCardItemTapped,
                          properties: ["type": "post", "sub_type": status.rawValue])

        PostListEditorPresenter.handle(post: post, in: self, entryPoint: .dashboard)
    }
}

// MARK: - PostsCardView

extension PostsCardViewController: PostsCardView {
    func showLoading() {
        configureGhostableTableView()
    }

    func hideLoading() {
        guard ghostableTableView?.superview != nil else {
            return
        }

        hideError()
        removeGhostableTableView()

        if nextPostView == nil && errorView == nil {
            trackPostsDisplayed()
        }
    }

    func showError(message: String, retry: Bool) {
        guard nextPostView == nil else {
            notifyOfHeightChange()
            return
        }

        let errorView = DashboardCardInnerErrorView(message: message, canRetry: retry)
        errorView.delegate = self
        errorView.translatesAutoresizingMaskIntoConstraints = false
        tableView.addSubview(withFadeAnimation: errorView)
        tableView.pinSubviewToSafeArea(errorView)
        self.errorView = errorView

        // Force the table view to recalculate its height
        _ = tableView.intrinsicContentSize

        BlogDashboardAnalytics.shared.track(.dashboardCardShown, properties: ["type": "post", "sub_type": "error"])
    }

    func hideError() {
        errorView?.removeFromSuperview()
    }

    func showNextPostPrompt() {
        guard nextPostView == nil ||
              nextPostView?.hasPublishedPosts != hasPublishedPosts else {
            notifyOfHeightChange()
            return
        }

        hideError()

        self.nextPostView?.removeFromSuperview()
        self.nextPostView = nil

        let nextPostView = BlogDashboardNextPostView()
        nextPostView.hasPublishedPosts = hasPublishedPosts
        nextPostView.onTap = { [weak self] in
            self?.presentEditor()
        }
        nextPostView.translatesAutoresizingMaskIntoConstraints = false
        tableView.addSubview(withFadeAnimation: nextPostView)
        tableView.pinSubviewToSafeArea(nextPostView)

        self.nextPostView = nextPostView

        notifyOfHeightChange()

        delegate?.didShowNextPostPrompt(cardFrameView: cardFrameView)

        BlogDashboardAnalytics.shared.track(.dashboardCardShown, properties: ["type": "post", "sub_type": hasPublishedPosts ? "create_next" : "create_first"])
    }

    func hideNextPrompt() {

        guard nextPostView != nil else {
            delegate?.didHideNextPostPrompt(cardFrameView: cardFrameView)
            return
        }

        nextPostView?.removeFromSuperview()
        nextPostView = nil
        delegate?.didHideNextPostPrompt(cardFrameView: cardFrameView)

        trackPostsDisplayed()
    }

    func firstPostPublished() {
        hasPublishedPosts = true
        nextPostView?.hasPublishedPosts = true
    }
}

// MARK: - EditorAnalyticsProperties

extension PostsCardViewController: EditorAnalyticsProperties {
    func propertiesForAnalytics() -> [String: AnyObject] {
        var properties = [String: AnyObject]()

        properties["type"] = PostServiceType.post.rawValue as AnyObject?
        properties["filter"] = viewModel.currentPostStatus() as AnyObject?

        if let dotComID = blog.dotComID {
            properties[WPAppAnalyticsKeyBlogID] = dotComID
        }

        return properties
    }
}

// MARK: - DashboardCardInnerErrorViewDelegate

extension PostsCardViewController: DashboardCardInnerErrorViewDelegate {
    func retry() {
        viewModel.retry()
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
