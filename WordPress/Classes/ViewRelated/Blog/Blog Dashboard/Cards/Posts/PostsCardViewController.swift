import UIKit

protocol PostsCardViewControllerDelegate: AnyObject {
    func didShowNextPostPrompt()
    func didHideNextPostPrompt()
}

/// Render a small list of posts for a given blog and post status (drafts or scheduled)
///
/// This class handles showing posts from the database, syncing and interacting with them
///
@objc class PostsCardViewController: UIViewController {
    var blog: Blog

    let tableView: UITableView = PostCardTableView()

    private var viewModel: PostsCardViewModel!
    private var ghostableTableView: UITableView?
    private var errorView: DashboardCardInnerErrorView?
    private var nextPostView: BlogDashboardNextPostView?
    private var status: BasePost.Status = .draft

    weak var delegate: PostsCardViewControllerDelegate?

    init(blog: Blog, status: BasePost.Status) {
        self.blog = blog
        self.status = status
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        viewModel = PostsCardViewModel(blog: blog, status: status, viewController: self)
        viewModel.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideSeparatorForGhostCells()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.dataSource = viewModel
        tableView.delegate = self
        viewModel.refresh()
    }

    func update(blog: Blog, status: BasePost.Status) {
        self.blog = blog
        self.status = status
        viewModel?.update(blog: blog, status: status)
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

        let postCompactCellNib = PostCompactCell.defaultNib
        ghostableTableView.register(postCompactCellNib, forCellReuseIdentifier: PostCompactCell.defaultReuseID)

        let ghostOptions = GhostOptions(displaysSectionHeader: false, reuseIdentifier: PostCompactCell.defaultReuseID, rowsPerSection: [Constants.numberOfPosts])
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

    func hideSeparatorForGhostCells() {
        ghostableTableView?.visibleCells
            .forEach { ($0 as? PostCompactCell)?.hideSeparator() }
    }

    func presentEditor() {
        let editor = EditPostViewController(blog: blog)
        present(editor, animated: true)
    }

    enum Constants {
        static let numberOfPosts = 3
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
        errorView?.removeFromSuperview()
        removeGhostableTableView()
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
    }

    func showNextPostPrompt() {
        guard nextPostView == nil else {
            // Force the table view to recalculate its height
            _ = tableView.intrinsicContentSize
            return
        }

        let nextPostView = BlogDashboardNextPostView()
        nextPostView.onTap = { [weak self] in
            self?.presentEditor()
        }
        nextPostView.translatesAutoresizingMaskIntoConstraints = false
        tableView.addSubview(withFadeAnimation: nextPostView)
        tableView.pinSubviewToSafeArea(nextPostView)

        self.nextPostView = nextPostView

        // Force the table view to recalculate its height
        _ = tableView.intrinsicContentSize

        delegate?.didShowNextPostPrompt()
    }

    func hideNextPrompt() {
        nextPostView?.removeFromSuperview()
        nextPostView = nil
        delegate?.didHideNextPostPrompt()
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
    override var contentSize: CGSize {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }

    /// Emits a notification when the intrinsicContentSize changes
    /// This allows subscribers to update their layouts (ie.: UICollectionViews)
    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        NotificationCenter.default.post(name: .postCardTableViewSizeChanged, object: nil)
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}
