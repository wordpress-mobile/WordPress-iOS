import UIKit

class CommentDetailViewController: UITableViewController {

    // MARK: Properties

    private var comment: Comment

    private var rows = [RowType]()

    // MARK: Views

    private var headerCell = CommentHeaderTableViewCell()

    // MARK: Initialization

    @objc required init(comment: Comment) {
        self.comment = comment
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureTable()
        configureRows()
    }

    // MARK: Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch rows[indexPath.row] {
        case .header:
            configureHeaderCell()
            return headerCell

        default:
            return .init()
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch rows[indexPath.row] {
        case .header:
            navigateToPost()

        default:
            break
        }
    }

}

// MARK: - Private Helpers

private extension CommentDetailViewController {

    enum RowType {
        case header
        case content
        case replyIndicator
        case textWithDescriptor(descriptor: String, content: String, imageName: String?, action: (() -> Void)?)
    }

    func configureNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editButtonTapped))
    }

    func configureTable() {
        tableView.tableFooterView = UIView(frame: .zero)
    }

    func configureRows() {
        rows = [.header]
    }

    // MARK: Cell configuration

    func configureHeaderCell() {
        // TODO: detect if the comment is a reply.

        headerCell.textLabel?.text = .postCommentTitleText
        headerCell.detailTextLabel?.text = comment.titleForDisplay()
    }

    // MARK: Actions and navigations

    func navigateToPost() {
        guard let blog = comment.blog,
              let siteID = blog.dotComID,
              blog.supports(.wpComRESTAPI) else {
            viewPostInWebView()
            return
        }

        let readerViewController = ReaderDetailViewController.controllerWithPostID(NSNumber(value: comment.postID), siteID: siteID, isFeed: false)
        navigationController?.pushFullscreenViewController(readerViewController, animated: true)
    }

    func viewPostInWebView() {
        guard let post = comment.post,
              let permalink = post.permaLink,
              let url = URL(string: permalink) else {
            return
        }

        let viewController = WebViewControllerFactory.controllerAuthenticatedWithDefaultAccount(url: url)
        let navigationControllerToPresent = UINavigationController(rootViewController: viewController)

        present(navigationControllerToPresent, animated: true, completion: nil)
    }

    @objc func editButtonTapped() {
        let editCommentTableViewController = EditCommentTableViewController(comment: comment, completion: { [weak self] comment, commentChanged in
            guard commentChanged else {
                return
            }

            self?.comment = comment
            self?.tableView.reloadData()
            self?.updateComment()
        })

        let navigationControllerToPresent = UINavigationController(rootViewController: editCommentTableViewController)
        navigationControllerToPresent.modalPresentationStyle = .fullScreen
        present(navigationControllerToPresent, animated: true)
    }

    func updateComment() {
        // Regardless of success or failure track the user's intent to save a change.
        CommentAnalytics.trackCommentEdited(comment: comment)

        let context = ContextManager.sharedInstance().mainContext
        let commentService = CommentService(managedObjectContext: context)

        commentService.uploadComment(comment,
                                     success: { [weak self] in
                                        // The comment might have changed its approval status
                                        self?.tableView.reloadData()
                                     },
                                     failure: { [weak self] error in
                                        let message = NSLocalizedString("There has been an unexpected error while editing your comment",
                                                                        comment: "Error displayed if a comment fails to get updated")
                                        self?.displayNotice(title: message)
                                     })
    }

}

// MARK: - Localization

private extension String {
    static let postCommentTitleText = NSLocalizedString("Comment on", comment: "Provides hint that the current screen displays a comment on a post. "
                                                            + "The title of the post will displayed below this string. "
                                                            + "Example: Comment on \n My First Post")
}
