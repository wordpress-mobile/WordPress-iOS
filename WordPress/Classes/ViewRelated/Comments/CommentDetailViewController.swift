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
        let row = rows[indexPath.row]
        switch row {
        case .header:
            configureHeaderCell()
            return headerCell

        case .text:
            let cell = tableView.dequeueReusableCell(withIdentifier: .textCellIdentifier) ?? .init(style: .subtitle, reuseIdentifier: .textCellIdentifier)
            configureTextCell(cell, with: row)
            return cell

        default:
            return .init()
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch rows[indexPath.row] {
        case .header:
            navigateToPost()

        case .text(_, _, _, let action):
            action?()

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
        case text(title: String, detail: String, image: UIImage? = nil, action: (() -> Void)? = nil)
    }

    struct Constants {
        static let tableLeadingInset: CGFloat = 20.0
    }

    func configureNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editButtonTapped))
    }

    func configureTable() {
        // get rid of the separator line for the last cell.
        tableView.tableFooterView = UIView(frame: .init(x: 0, y: 0, width: tableView.frame.size.width, height: 1))

        // assign 20pt leading inset to the table view, as per the design.
        // note that by default, the system assigns 16pt inset for .phone, and 20pt for .pad idioms.
        if UIDevice.current.userInterfaceIdiom == .phone {
            tableView.directionalLayoutMargins.leading = Constants.tableLeadingInset
        }
    }

    func configureRows() {
        rows = [
            .header,
            .text(title: .webAddressLabelText, detail: comment.authorUrlForDisplay(), image: .gridicon(.external), action: visitAuthorURL),
            .text(title: .emailAddressLabelText, detail: comment.author_email),
            .text(title: .ipAddressLabelText, detail: comment.author_ip)
        ]
    }

    // MARK: Cell configuration

    func configureHeaderCell() {
        // TODO: detect if the comment is a reply.

        headerCell.textLabel?.text = .postCommentTitleText
        headerCell.detailTextLabel?.text = comment.titleForDisplay()
    }

    func configureTextCell(_ cell: UITableViewCell, with row: RowType) {
        guard case let .text(title, detail, image, _) = row else {
            return
        }

        cell.tintColor = .primary

        cell.textLabel?.font = WPStyleGuide.fontForTextStyle(.subheadline)
        cell.textLabel?.textColor = .textSubtle
        cell.textLabel?.text = title

        cell.detailTextLabel?.font = WPStyleGuide.fontForTextStyle(.body)
        cell.detailTextLabel?.textColor = .text
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = detail.isEmpty ? " " : detail // prevent the cell from collapsing due to empty label text.

        cell.accessoryView = {
            guard let image = image else {
                return nil
            }
            return UIImageView(image: image)
        }()
    }

    // MARK: Actions and navigations

    func navigateToPost() {
        guard let blog = comment.blog,
              let siteID = blog.dotComID,
              blog.supports(.wpComRESTAPI) else {
            let postPermalinkURL = URL(string: comment.post?.permaLink ?? "")
            openWebView(for: postPermalinkURL)
            return
        }

        let readerViewController = ReaderDetailViewController.controllerWithPostID(NSNumber(value: comment.postID), siteID: siteID, isFeed: false)
        navigationController?.pushFullscreenViewController(readerViewController, animated: true)
    }

    func openWebView(for url: URL?) {
        guard let url = url else {
            DDLogError("\(Self.classNameWithoutNamespaces()): Attempted to open an invalid URL [\(url?.absoluteString ?? "")]")
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

    func visitAuthorURL() {
        guard let authorURL = comment.authorURL() else {
            return
        }

        openWebView(for: authorURL)
    }

}

// MARK: - Strings

private extension String {
    // MARK: Constants
    static let textCellIdentifier = "textCell"

    // MARK: Localization
    static let postCommentTitleText = NSLocalizedString("Comment on", comment: "Provides hint that the current screen displays a comment on a post. "
                                                            + "The title of the post will displayed below this string. "
                                                            + "Example: Comment on \n My First Post")
    static let webAddressLabelText = NSLocalizedString("Web address", comment: "Describes the web address section in the comment detail screen.")
    static let emailAddressLabelText = NSLocalizedString("Email address", comment: "Describes the email address section in the comment detail screen.")
    static let ipAddressLabelText = NSLocalizedString("IP address", comment: "Describes the IP address section in the comment detail screen.")
}
