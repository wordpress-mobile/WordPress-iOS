import UIKit

/// Render a small list of posts for a given blog and post status (drafts or scheduled)
///
/// This class handles showing posts from the database, syncing and interacting with them
///
@objc class PostsCardViewController: UIViewController {
    var blog: Blog

    private let postsTableView = IntrinsicTableView()

    private var viewModel: PostsCardViewModel!

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
        viewModel = PostsCardViewModel(tableView: postsTableView, blog: blog)
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
