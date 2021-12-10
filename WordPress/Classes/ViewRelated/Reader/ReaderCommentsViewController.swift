import Foundation
import UIKit
import WordPressShared

@objc public extension ReaderCommentsViewController {
    func shouldShowSuggestions(for siteID: NSNumber?) -> Bool {
        guard let siteID = siteID, let blog = Blog.lookup(withID: siteID, in: ContextManager.shared.mainContext) else { return false }
        return SuggestionService.shared.shouldShowSuggestions(for: blog)
    }

    func showNotificationSheet(notificationsEnabled: Bool, delegate: ReaderCommentsNotificationSheetDelegate?, sourceBarButtonItem: UIBarButtonItem?) {
        let sheetViewController = ReaderCommentsNotificationSheetViewController(isNotificationEnabled: notificationsEnabled, delegate: delegate)
        let bottomSheet = BottomSheetViewController(childViewController: sheetViewController)
        bottomSheet.show(from: self, sourceBarButtonItem: sourceBarButtonItem)
    }

    // MARK: Post Subscriptions

    /// Enumerates the kind of actions available in relation to post subscriptions.
    /// TODO: Add `followConversation` and `unfollowConversation` once the "Follow Conversation" feature flag is removed.
    @objc enum PostSubscriptionAction: Int {
        case enableNotification
        case disableNotification
    }

    func noticeTitle(forAction action: PostSubscriptionAction, success: Bool) -> String {
        switch (action, success) {
        case (.enableNotification, true):
            return NSLocalizedString("In-app notifications enabled", comment: "The app successfully enabled notifications for the subscription")
        case (.enableNotification, false):
            return NSLocalizedString("Could not enable notifications", comment: "The app failed to enable notifications for the subscription")
        case (.disableNotification, true):
            return NSLocalizedString("In-app notifications disabled", comment: "The app successfully disabled notifications for the subscription")
        case (.disableNotification, false):
            return NSLocalizedString("Could not disable notifications", comment: "The app failed to disable notifications for the subscription")
        }
    }

    func handleHeaderTapped() {
        guard let post = post,
              allowsPushingPostDetails else {
                  return
              }

        // Note: Let's manually hide the comments button, in order to prevent recursion in the flow
        let controller = ReaderDetailViewController.controllerWithPost(post)
        controller.shouldHideComments = true
        navigationController?.pushFullscreenViewController(controller, animated: true)
    }

    // MARK: New Comment Threads

    func configuredHeaderView(for tableView: UITableView) -> UIView {
        guard let post = post else {
            return .init()
        }

        let cell = CommentHeaderTableViewCell()
        cell.backgroundColor = .systemBackground
        cell.configure(for: .thread, subtitle: post.titleForDisplay(), showsDisclosureIndicator: allowsPushingPostDetails)
        cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleHeaderTapped)))

        // the table view does not render separators for the section header views, so we need to create one.
        cell.contentView.addBottomBorder(withColor: .separator, leadingMargin: tableView.separatorInset.left)

        return cell
    }

    func configureContentCell(_ cell: UITableViewCell, comment: Comment, indexPath: IndexPath, handler: WPTableViewHandler) {
        guard let cell = cell as? CommentContentTableViewCell else {
            return
        }

        cell.badgeTitle = comment.isFromPostAuthor() ? .authorBadgeText : nil
        cell.indentationWidth = Constants.indentationWidth
        cell.indentationLevel = min(Constants.maxIndentationLevel, Int(comment.depth))
        cell.accessoryButtonType = isModerationMenuEnabled(for: comment) ? .ellipsis : .share
        cell.hidesModerationBar = true

        // if the comment can be moderated, show the context menu when tapping the accessory button.
        // Note that accessoryButtonAction will be ignored when the menu is assigned.
        if #available (iOS 14.0, *) {
            cell.accessoryButton.showsMenuAsPrimaryAction = isModerationMenuEnabled(for: comment)
            cell.accessoryButton.menu = isModerationMenuEnabled(for: comment) ? menu(for: comment,
                                                                                     indexPath: indexPath,
                                                                                     handler: handler,
                                                                                     sourceView: cell.accessoryButton) : nil
        }

        cell.configure(with: comment, renderMethod: .richContent) { _ in
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

    /// Shows a contextual menu through `UIPopoverPresentationController`. This is a fallback implementation for iOS 13, since the menu can't be
    /// shown programmatically or through a single tap.
    ///
    /// NOTE: Remove this once we bump the minimum version to iOS 14.
    ///
    func showMenuSheet(for comment: Comment, indexPath: IndexPath, handler: WPTableViewHandler, sourceView: UIView?) {
        let commentMenus = commentMenu(for: comment, indexPath: indexPath, handler: handler, sourceView: sourceView)
        let menuViewController = MenuSheetViewController(items: commentMenus.map { menuSection in
            // Convert ReaderCommentMenu to MenuSheetViewController.MenuItem
            menuSection.map { $0.toMenuItem }
        })

        menuViewController.modalPresentationStyle = .popover
        if let popoverPresentationController = menuViewController.popoverPresentationController {
            popoverPresentationController.delegate = self
            popoverPresentationController.sourceView = sourceView
            popoverPresentationController.sourceRect = sourceView?.bounds ?? .null
        }

        present(menuViewController, animated: true)
    }

    func isModerationMenuEnabled(for comment: Comment) -> Bool {
        return comment.allowsModeration() && Feature.enabled(.commentThreadModerationMenu)
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
        return CommentService(managedObjectContext: ContextManager.shared.mainContext)
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
                    self?.moderateComment(comment, status: .pending, handler: handler)
                },
                .spam { [weak self] in
                    self?.moderateComment(comment, status: .spam, handler: handler)
                },
                .trash { [weak self] in
                    self?.moderateComment(comment, status: .unapproved, handler: handler)
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

    func moderateComment(_ comment: Comment, status: CommentStatusType, handler: WPTableViewHandler) {
        let successBlock: (String) -> Void = { [weak self] noticeText in
            let context = comment.managedObjectContext ?? ContextManager.shared.mainContext

            // decrement the ReaderPost's comment count.
            if let post = self?.post, let commentCount = post.commentCount?.intValue {
                post.commentCount = NSNumber(value: commentCount - 1)
            }

            // delete the comment from ReaderPost.
            context.delete(comment)
            ContextManager.shared.saveContextAndWait(context)

            // Refresh the UI. The table view handler is needed because the fetched results delegate is set to nil.
            handler.refreshTableViewPreservingOffset()
            self?.displayNotice(title: noticeText)
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

        default:
            break
        }
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

    // moderation messages
    static let pendingSuccess = NSLocalizedString("Comment set to pending.", comment: "Message displayed when pending a comment succeeds.")
    static let pendingFailed = NSLocalizedString("Error setting comment to pending.", comment: "Message displayed when pending a comment fails.")
    static let spamSuccess = NSLocalizedString("Comment marked as spam.", comment: "Message displayed when spamming a comment succeeds.")
    static let spamFailed = NSLocalizedString("Error marking comment as spam.", comment: "Message displayed when spamming a comment fails.")
    static let trashSuccess = NSLocalizedString("Comment moved to trash.", comment: "Message displayed when trashing a comment succeeds.")
    static let trashFailed = NSLocalizedString("Error moving comment to trash.", comment: "Message displayed when trashing a comment fails.")
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

    /// NOTE: Remove when minimum version is bumped to iOS 14.
    var toMenuItem: MenuSheetViewController.MenuItem {
        switch self {
        case .unapprove(let handler),
                .spam(let handler),
                .trash(let handler),
                .edit(let handler),
                .share(let handler):
            return MenuSheetViewController.MenuItem(title: title, image: image) {
                handler()
            }
        }
    }
}
