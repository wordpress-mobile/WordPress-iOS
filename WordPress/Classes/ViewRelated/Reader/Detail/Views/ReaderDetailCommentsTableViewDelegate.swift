import UIKit
/// Table View delegate to handle the Comments table displayed in Reader Post details.
///
class ReaderDetailCommentsTableViewDelegate: NSObject, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Private Properties

    private(set) var totalComments = 0
    private var post: ReaderPost?
    private var presentingViewController: UIViewController?
    private weak var buttonDelegate: BorderedButtonTableViewCellDelegate?
    private(set) var headerView: ReaderDetailCommentsHeader?
    var followButtonTappedClosure: (() ->Void)?

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

    private var commentsEnabled: Bool {
        return post?.commentsOpen ?? false
    }

    // MARK: - Public Methods

    func updateWith(post: ReaderPost,
                    comments: [Comment] = [],
                    totalComments: Int = 0,
                    presentingViewController: UIViewController,
                    buttonDelegate: BorderedButtonTableViewCellDelegate? = nil) {
        self.post = post
        hideButton = (comments.count == 0 && !commentsEnabled)
        self.comments = comments
        self.totalComments = totalComments
        self.presentingViewController = presentingViewController
        self.buttonDelegate = buttonDelegate
    }

    func updateFollowButtonState(post: ReaderPost) {
        self.post = post
        headerView?.updateFollowButtonState(post: post)
    }

    func followButtonMidPoint() -> CGPoint? {
        headerView?.followButtonMidPoint()
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
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: ReaderDetailCommentsHeader.defaultReuseID) as? ReaderDetailCommentsHeader,
              let post = post,
              let presentingViewController = presentingViewController else {
            return nil
        }

        header.configure(
            post: post,
            totalComments: totalComments,
            presentingViewController: presentingViewController,
            followButtonTappedClosure: followButtonTappedClosure
        )
        headerView = header
        return header
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        /// We used this method to show the Jetpack badge rather than setting `tableFooterView` because it scaled better with Dynamic type.
        guard section == 0, JetpackBrandingVisibility.all.enabled else {
            return nil
        }
        return JetpackButton.makeBadgeView(bottomPadding: Constants.jetpackBadgeBottomPadding)
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return ReaderDetailCommentsHeader.estimatedHeight
    }

    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return ReaderDetailCommentsHeader.estimatedHeight
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard section == 0, JetpackBrandingVisibility.all.enabled else {
            return 0
        }
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
        static let buttonInsets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        static let jetpackBadgeBottomPadding: CGFloat = 10
    }
}
