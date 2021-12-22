/// Table View delegate to handle the Comments table displayed in Reader Post details.
///
class ReaderDetailCommentsTableViewDelegate: NSObject, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Private Properties

    private(set) var totalComments = 0
    private var commentsEnabled = true
    private weak var buttonDelegate: BorderedButtonTableViewCellDelegate?

    private var totalRows = 0
    private var hideButton = true

    private var comments: [Comment] = [] {
        didSet {
            totalRows = {
                // If there are no comments and commenting is closed, 1 empty cell.
                if hideButton {
                    return 1
                }

                // If there are no comments, 1 empty cell + 1 button.
                if comments.count == 0 {
                    return 2
                }

                // Otherwise add 1 for the button.
                return comments.count + 1
            }()
        }
    }

    // MARK: - Public Methods

    func updateWith(comments: [Comment] = [],
                    totalComments: Int = 0,
                    commentsEnabled: Bool = true,
                    buttonDelegate: BorderedButtonTableViewCellDelegate? = nil) {
        self.commentsEnabled = commentsEnabled
        hideButton = (comments.count == 0 && !commentsEnabled)
        self.comments = comments
        self.totalComments = totalComments
        self.buttonDelegate = buttonDelegate
    }

    // MARK: - Table Methods

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return totalRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == (totalRows - 1) && !hideButton {
            return showCommentsButtonCell()
        }

        if let comment = comments[safe: indexPath.row] {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentContentTableViewCell.defaultReuseID) as? CommentContentTableViewCell else {
                return UITableViewCell()
            }

            cell.configureForPostDetails(with: comment) { _ in
                tableView.performBatchUpdates({})
            }

            return cell
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReaderDetailNoCommentCell.defaultReuseID) as? ReaderDetailNoCommentCell else {
            return UITableViewCell()
        }

        cell.titleLabel.text = commentsEnabled ? Constants.noComments : Constants.closedComments
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: ReaderDetailCommentsHeader.defaultReuseID) as? ReaderDetailCommentsHeader else {
            return nil
        }

        header.titleLabel.text = {
            switch totalComments {
            case 0:
                return Constants.comments
            case 1:
                return String(format: Constants.singularCommentFormat, totalComments)
            default:
                return String(format: Constants.pluralCommentsFormat, totalComments)
            }
        }()

        header.addBottomBorder(withColor: .divider)
        return header
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return ReaderDetailCommentsHeader.estimatedHeight
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

}

private extension ReaderDetailCommentsTableViewDelegate {

    func showCommentsButtonCell() -> BorderedButtonTableViewCell {
        let cell = BorderedButtonTableViewCell()
        let title = totalComments == 0 ? Constants.leaveCommentButtonTitle : Constants.viewAllButtonTitle
        cell.configure(buttonTitle: title, borderColor: .textTertiary, buttonInsets: Constants.buttonInsets)
        cell.delegate = buttonDelegate
        return cell
    }

    struct Constants {
        static let noComments = NSLocalizedString("No comments yet", comment: "Displayed on the post details page when there are no post comments.")
        static let closedComments = NSLocalizedString("Comments are closed", comment: "Displayed on the post details page when there are no post comments and commenting is closed.")
        static let viewAllButtonTitle = NSLocalizedString("View all comments", comment: "Title for button on the post details page to show all comments when tapped.")
        static let leaveCommentButtonTitle = NSLocalizedString("Be the first to comment", comment: "Title for button on the post details page when there are no comments.")
        static let singularCommentFormat = NSLocalizedString("%1$d Comment", comment: "Singular label displaying number of comments. %1$d is a placeholder for the number of Comments.")
        static let pluralCommentsFormat = NSLocalizedString("%1$d Comments", comment: "Plural label displaying number of comments. %1$d is a placeholder for the number of Comments.")
        static let comments = NSLocalizedString("Comments", comment: "Comments table header label.")
        static let buttonInsets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
    }
}
