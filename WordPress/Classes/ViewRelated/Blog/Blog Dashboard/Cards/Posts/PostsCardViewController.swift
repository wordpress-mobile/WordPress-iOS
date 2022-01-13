import UIKit

/// Render a small list of posts for a given blog and post status (drafts or scheduled)
///
/// This class handles showing posts from the database, syncing and interacting with them
///
@objc class PostsCardViewController: UIViewController {
    var blog: Blog

    let tableView: UITableView = IntrinsicTableView()

    private var viewModel: PostsCardViewModel!
    private var ghostableTableView: UITableView?

    @objc init(blog: Blog) {
        self.blog = blog
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        viewModel = PostsCardViewModel(blog: blog, viewController: self)
        viewModel.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.dataSource = viewModel
        viewModel.refresh()
    }
}

// MARK: - PostsCardView

extension PostsCardViewController: PostsCardView {
    func showLoading() {
        configureGhostableTableView()
    }

    func hideLoading() {
        removeGhostableTableView()
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
        view.pinSubviewToAllEdges(tableView)
        let postCompactCellNib = PostCompactCell.defaultNib
        tableView.register(postCompactCellNib, forCellReuseIdentifier: PostCompactCell.defaultReuseID)
    }

    func configureGhostableTableView() {
        let ghostableTableView = IntrinsicTableView()

        view.addSubview(ghostableTableView)

        ghostableTableView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(ghostableTableView)

        ghostableTableView.isScrollEnabled = false

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

    enum Constants {
        static let numberOfPosts = 3
    }
}

// MARK: - EditorAnalyticsProperties

extension PostsCardViewController: EditorAnalyticsProperties {
    func propertiesForAnalytics() -> [String: AnyObject] {
        [:]
    }
}
