import UIKit

/// Render a small list of posts for a given blog and post status (drafts or scheduled)
///
/// This class handles showing posts from the database, syncing and interacting with them
///
@objc class PostsCardViewController: UIViewController {
    @objc var blog: Blog?

    private let postsTableView = IntrinsicTableView()

    private var viewModel: PostsCardViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        viewModel = PostsCardViewModel(tableView: postsTableView, blog: blog!)
        viewModel.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        postsTableView.dataSource = viewModel
        viewModel.refresh()
    }
}

private extension PostsCardViewController {
    func configureView() {
        view.addSubview(postsTableView)
        postsTableView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(postsTableView)
        let postCompactCellNib = PostCompactCell.defaultNib
        postsTableView.register(postCompactCellNib, forCellReuseIdentifier: PostCompactCell.defaultReuseID)
    }
}
