import Foundation
import UIKit

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

    func configureContentCell(_ cell: UITableViewCell, comment: Comment, tableView: UITableView) {
        guard let cell = cell as? CommentContentTableViewCell else {
            return
        }

        cell.badgeTitle = comment.isFromPostAuthor() ? Constants.authorBadgeText : nil
        cell.indentationWidth = Constants.indentationWidth
        cell.indentationLevel = min(Constants.maxIndentationLevel, Int(comment.depth))
        cell.accessoryButtonType = comment.allowsModeration() ? .ellipsis : .share
        cell.hidesModerationBar = true

        // if the comment can be moderated, show the context menu when tapping the accessory button.
        // Note that accessoryButtonAction will be ignored when the menu is assigned.
        if #available (iOS 14.0, *) {
            cell.accessoryButton.showsMenuAsPrimaryAction = comment.allowsModeration()
            cell.accessoryButton.menu = comment.allowsModeration() ? menu(for: comment, tableView: tableView, sourceView: cell.accessoryButton) : nil
        }

        cell.configure(with: comment) { _ in
            tableView.performBatchUpdates({})
        }
    }

    func shareComment(_ comment: Comment, sourceView: UIView) {
        guard let commentURL = comment.commentURL() else {
            return
        }

        let activityViewController = UIActivityViewController(activityItems: [commentURL as Any], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = sourceView
        present(activityViewController, animated: true, completion: nil)
    }

    func menu(for comment: Comment, tableView: UITableView, sourceView: UIView) -> UIMenu {
        return UIMenu(title: "", options: .displayInline, children: [
            ReaderCommentMenu.unapprove.action {
                // TODO: Unapprove comment
            },
            ReaderCommentMenu.spam.action {
                // TODO: Spam comment
            },
            ReaderCommentMenu.trash.action {
                // TODO: Trash comment
            },
            UIMenu(title: "", options: .displayInline, children: [
                ReaderCommentMenu.edit.action {
                    // TODO: Edit comment
                },
                ReaderCommentMenu.share.action { [weak self] in
                    self?.shareComment(comment, sourceView: sourceView)
                }
            ])
        ])
    }
}

private extension ReaderCommentsViewController {
    struct Constants {
        static let indentationWidth: CGFloat = 15.0
        static let maxIndentationLevel: Int = 4

        static let authorBadgeText = NSLocalizedString("Author", comment: "Title for a badge displayed beside the comment writer's name. "
                                                       + "Shown when the comment is written by the post author.")
    }

    enum ReaderCommentMenu {
        case unapprove
        case spam
        case trash
        case edit
        case share

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

        func action(handler: @escaping () -> Void) -> UIAction {
            return UIAction(title: title, image: image) { _ in
                handler()
            }
        }
    }
}
