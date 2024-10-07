import Foundation
import UIKit
import WordPressShared

// Notification sent when a comment is moderated/edited to allow views that display Comments to update if necessary.
// Specifically, the Comments snippet on ReaderDetailViewController.
extension NSNotification.Name {
    static let ReaderCommentModifiedNotification = NSNotification.Name(rawValue: "ReaderCommentModifiedNotification")
}

@objc public extension ReaderCommentsViewController {
    func shouldShowSuggestions(for siteID: NSNumber?) -> Bool {
        guard let siteID = siteID, let blog = Blog.lookup(withID: siteID, in: ContextManager.shared.mainContext) else { return false }
        return SuggestionService.shared.shouldShowSuggestions(for: blog)
    }

    func handleHeaderTapped() {
        guard let post = post,
              allowsPushingPostDetails else {
                  return
              }

        // Note: Let's manually hide the comments button, in order to prevent recursion in the flow
        let controller = ReaderDetailViewController.controllerWithPost(post)
        controller.shouldHideComments = true
        navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: New Comment Threads

    func configuredHeaderView(for tableView: UITableView) -> UIView {
        guard let post = post else {
            return .init()
        }
        let headerView = CommentTableHeaderView(
            title: post.titleForDisplay(),
            subtitle: .commentThread,
            showsDisclosureIndicator: allowsPushingPostDetails
        ) { [weak self] in
            self?.handleHeaderTapped()
        }
        return headerView
    }

    func configureContentCell(
        _ cell: UITableViewCell,
        comment: Comment,
        attributedText: NSAttributedString,
        indexPath: IndexPath,
        handler: WPTableViewHandler
    ) {
        guard let cell = cell as? CommentContentTableViewCell else {
            return
        }

        cell.badgeTitle = comment.isFromPostAuthor() ? .authorBadgeText : nil
        cell.indentationWidth = Constants.indentationWidth
        cell.indentationLevel = min(Constants.maxIndentationLevel, Int(comment.depth))
        cell.accessoryButtonType = isModerationMenuEnabled(for: comment) ? .ellipsis : .share
        cell.shouldHideSeparator = true

        // if the comment can be moderated, show the context menu when tapping the accessory button.
        // Note that accessoryButtonAction will be ignored when the menu is assigned.
        cell.accessoryButton.showsMenuAsPrimaryAction = isModerationMenuEnabled(for: comment)
        cell.accessoryButton.menu = isModerationMenuEnabled(for: comment) ? menu(for: comment,
                                                                                 indexPath: indexPath,
                                                                                 handler: handler,
                                                                                 sourceView: cell.accessoryButton) : nil

        cell.configure(with: comment, renderMethod: .richContent(attributedText)) { _ in
            // don't adjust cell height when it's already scrolled out of viewport.
            guard let visibleIndexPaths = handler.tableView.indexPathsForVisibleRows,
                  visibleIndexPaths.contains(indexPath) else {
                      return
                  }

            handler.tableView.performBatchUpdates({})
        }
    }

    /// Opens a share sheet, prompting the user to share the URL of the provided comment.
    ///
    func shareComment(_ comment: Comment, sourceView: UIView?) {
        guard let commentURL = comment.commentURL() else {
            return
        }

        // track share intent.
        WPAnalytics.track(.readerArticleCommentShared)

        let activityViewController = UIActivityViewController(activityItems: [commentURL as Any], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = sourceView
        present(activityViewController, animated: true, completion: nil)
    }

    func isModerationMenuEnabled(for comment: Comment) -> Bool {
        return comment.allowsModeration()
    }

    // MARK: - Tracking

    func trackCommentsOpened() {
        var properties: [AnyHashable: Any] = [
            WPAppAnalyticsKeySource: descriptionForSource(source)
        ]

        if let post = post {
            properties[WPAppAnalyticsKeyPostID] = post.postID
            properties[WPAppAnalyticsKeyBlogID] = post.siteID
        }

        WPAnalytics.trackReader(.readerArticleCommentsOpened, properties: properties)
    }

    @objc func trackCommentsOpened(postID: NSNumber, siteID: NSNumber, source: ReaderCommentsSource) {
        let properties: [AnyHashable: Any] = [
            WPAppAnalyticsKeyPostID: postID,
            WPAppAnalyticsKeyBlogID: siteID,
            WPAppAnalyticsKeySource: descriptionForSource(source)
        ]

        WPAnalytics.trackReader(.readerArticleCommentsOpened, properties: properties)
    }

    // MARK: - Notification

    @objc func postCommentModifiedNotification() {
        NotificationCenter.default.post(name: .ReaderCommentModifiedNotification, object: nil)
    }

}

// MARK: - Popover Presentation Delegate

extension ReaderCommentsViewController: UIPopoverPresentationControllerDelegate {
    // Force popover views to be presented as a popover (instead of being presented as a form sheet on iPhones).
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

// MARK: - Private Helpers

private extension ReaderCommentsViewController {
    struct Constants {
        static let indentationWidth: CGFloat = 15.0
        static let maxIndentationLevel: Int = 4
    }

    var commentService: CommentService {
        return CommentService(coreDataStack: ContextManager.shared)
    }

    /// Returns a `UIMenu` structure to be displayed when the accessory button is tapped.
    /// Note that this should only be called on iOS version 14 and above.
    ///
    /// For example, given an comment menu list `[[Foo, Bar], [Baz]]`, it will generate a menu as below:
    ///     ________
    ///    | Foo   •|
    ///    | Bar   •|
    ///    |--------|
    ///    | Baz   •|
    ///     --------
    ///
    func menu(for comment: Comment, indexPath: IndexPath, handler: WPTableViewHandler, sourceView: UIView?) -> UIMenu {
        let commentMenus = commentMenu(for: comment, indexPath: indexPath, handler: handler, sourceView: sourceView)
        return UIMenu(title: "", options: .displayInline, children: commentMenus.map {
            UIMenu(title: "", options: .displayInline, children: $0.map({ menu in menu.toAction }))
        })
    }

    /// Returns a list of array that each contains a menu item. Separators will be shown between each array. Note that
    /// the order of comment menu will determine the order of appearance for the corresponding menu element.
    ///
    func commentMenu(for comment: Comment, indexPath: IndexPath, handler: WPTableViewHandler, sourceView: UIView?) -> [[ReaderCommentMenu]] {
        return [
            [
                .unapprove { [weak self] in
                    self?.moderateComment(comment, status: .pending)
                },
                .spam { [weak self] in
                    self?.moderateComment(comment, status: .spam)
                },
                .trash { [weak self] in
                    self?.moderateComment(comment, status: .unapproved)
                }
            ],
            [
                .edit { [weak self] in
                    self?.editMenuTapped(for: comment, indexPath: indexPath, tableView: handler.tableView)
                },
                .share { [weak self] in
                    self?.shareComment(comment, sourceView: sourceView)
                }
            ]
        ]
    }

    func editMenuTapped(for comment: Comment, indexPath: IndexPath, tableView: UITableView) {
        let editCommentTableViewController = EditCommentTableViewController(comment: comment) { [weak self] comment, commentChanged in
            guard commentChanged else {
                return
            }

            // optimistically update the comment in the thread with local changes.
            tableView.reloadRows(at: [indexPath], with: .automatic)

            // track user's intent to edit the comment.
            CommentAnalytics.trackCommentEdited(comment: comment)

            self?.commentService.uploadComment(comment, success: {
                self?.commentModified = true

                // update the thread again in case the approval status changed.
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }, failure: { _ in
                self?.displayNotice(title: .editCommentFailureNoticeText)
            })
        }

        let navigationControllerToPresent = UINavigationController(rootViewController: editCommentTableViewController)
        navigationControllerToPresent.modalPresentationStyle = .fullScreen
        present(navigationControllerToPresent, animated: true)
    }

    func moderateComment(_ comment: Comment, status: CommentStatusType) {
        let successBlock: (String) -> Void = { [weak self] noticeText in
            guard let self = self else {
                return
            }

            // when a comment is unapproved/spammed/trashed, ensure that all of the replies are hidden.
            self.commentService.updateRepliesVisibility(for: comment) {
                self.commentModified = true
                self.refreshAfterCommentModeration()

                // Dismiss any old notices to avoid stacked Undo notices.
                self.dismissNotice()

                // If the status is Approved, the user has undone a comment moderation.
                // So don't show the Undo option in this case.
                (status == .approved) ? self.displayNotice(title: noticeText) :
                                        self.showActionableNotice(title: noticeText, comment: comment)
            }
        }

        switch status {
        case .pending:
            commentService.unapproveComment(comment) {
                successBlock(.pendingSuccess)
            } failure: { [weak self] _ in
                self?.displayNotice(title: .pendingFailed)
            }

        case .spam:
            commentService.spamComment(comment) {
                successBlock(.spamSuccess)
            } failure: { [weak self] _ in
                self?.displayNotice(title: .spamFailed)
            }

        case .unapproved: // trash
            commentService.trashComment(comment) {
                successBlock(.trashSuccess)
            } failure: { [weak self] _ in
                self?.displayNotice(title: .trashFailed)
            }
        case .approved:
            commentService.approve(comment) {
                successBlock(.approveSuccess)
            } failure: { [weak self] _ in
                self?.displayNotice(title: .approveFailed)
            }
        default:
            break
        }
    }

    func showActionableNotice(title: String, comment: Comment) {
        displayActionableNotice(title: title,
                                actionTitle: .undoActionTitle,
                                actionHandler: { [weak self] _ in
            // Set the Comment's status back to Approved when the user selects Undo on the notice.
            self?.moderateComment(comment, status: .approved)
        })
    }

    func descriptionForSource(_ source: ReaderCommentsSource) -> String {
        switch source {
        case .postCard:
            return "reader_post_card"
        case .postDetails:
            return "reader_post_details"
        case .postDetailsComments:
            return "reader_post_details_comments"
        case .commentNotification:
            return "comment_notification"
        case .commentLikeNotification:
            return "comment_like_notification"
        case .mySiteComment:
            return "my_site_comment"
        case .activityLogDetail:
            return "activity_log_detail"
        case .postsList:
            return "posts_list"
        default:
            return "unknown"
        }
    }

}

// MARK: - Localization

private extension String {
    static let authorBadgeText = NSLocalizedString("Author", comment: "Title for a badge displayed beside the comment writer's name. "
                                                   + "Shown when the comment is written by the post author.")
    static let editCommentFailureNoticeText = NSLocalizedString("There has been an unexpected error while editing the comment",
                                                                comment: "Error displayed if a comment fails to get updated")
    static let undoActionTitle = NSLocalizedString("Undo", comment: "Button title. Reverts a comment moderation action.")

    // moderation messages
    static let pendingSuccess = NSLocalizedString("Comment set to pending.", comment: "Message displayed when pending a comment succeeds.")
    static let pendingFailed = NSLocalizedString("Error setting comment to pending.", comment: "Message displayed when pending a comment fails.")
    static let spamSuccess = NSLocalizedString("Comment marked as spam.", comment: "Message displayed when spamming a comment succeeds.")
    static let spamFailed = NSLocalizedString("Error marking comment as spam.", comment: "Message displayed when spamming a comment fails.")
    static let trashSuccess = NSLocalizedString("Comment moved to trash.", comment: "Message displayed when trashing a comment succeeds.")
    static let trashFailed = NSLocalizedString("Error moving comment to trash.", comment: "Message displayed when trashing a comment fails.")
    static let approveSuccess = NSLocalizedString("Comment set to approved.", comment: "Message displayed when approving a comment succeeds.")
    static let approveFailed = NSLocalizedString("Error setting comment to approved.", comment: "Message displayed when approving a comment fails.")
}

// MARK: - Reader Comment Menu

/// Represents the available menu when the ellipsis accessory button on the comment cell is tapped.
enum ReaderCommentMenu {
    case unapprove(_ handler: () -> Void)
    case spam(_ handler: () -> Void)
    case trash(_ handler: () -> Void)
    case edit(_ handler: () -> Void)
    case share(_ handler: () -> Void)

    var title: String {
        switch self {
        case .unapprove:
            return NSLocalizedString("Unapprove", comment: "Unapproves a comment")
        case .spam:
            return NSLocalizedString("Mark as Spam", comment: "Marks comment as spam")
        case .trash:
            return NSLocalizedString("Move to Trash", comment: "Trashes the comment")
        case .edit:
            return NSLocalizedString("Edit", comment: "Edits the comment")
        case .share:
            return NSLocalizedString("Share", comment: "Shares the comment URL")
        }
    }

    var image: UIImage? {
        switch self {
        case .unapprove:
            return .init(systemName: "x.circle")
        case .spam:
            return .init(systemName: "exclamationmark.octagon")
        case .trash:
            return .init(systemName: "trash")
        case .edit:
            return .init(systemName: "pencil")
        case .share:
            return .init(systemName: "square.and.arrow.up")
        }
    }

    var toAction: UIAction {
        switch self {
        case .unapprove(let handler),
                .spam(let handler),
                .trash(let handler),
                .edit(let handler),
                .share(let handler):
            return UIAction(title: title, image: image) { _ in
                handler()
            }
        }
    }
}
