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

    func configureContentCell(_ cell: UITableViewCell, comment: Comment, indexPath: IndexPath, tableView: UITableView) {
        guard let cell = cell as? CommentContentTableViewCell else {
            return
        }

        cell.badgeTitle = comment.isFromPostAuthor() ? .authorBadgeText : nil
        cell.indentationWidth = Constants.indentationWidth
        cell.indentationLevel = min(Constants.maxIndentationLevel, Int(comment.depth))
        cell.accessoryButtonType = comment.allowsModeration() ? .ellipsis : .share
        cell.hidesModerationBar = true

        // if the comment can be moderated, show the context menu when tapping the accessory button.
        // Note that accessoryButtonAction will be ignored when the menu is assigned.
        if #available (iOS 14.0, *) {
            cell.accessoryButton.showsMenuAsPrimaryAction = comment.allowsModeration()
            cell.accessoryButton.menu = comment.allowsModeration() ? menu(for: comment,
                                                                             indexPath: indexPath,
                                                                             tableView: tableView,
                                                                             sourceView: cell.accessoryButton) : nil
        }

        cell.configure(with: comment) { _ in
            tableView.performBatchUpdates({})
        }
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

    /// Opens a share sheet, prompting the user to share the URL of the provided comment.
    ///
    func shareComment(_ comment: Comment, sourceView: UIView?) {
        guard let commentURL = comment.commentURL() else {
            return
        }

        let activityViewController = UIActivityViewController(activityItems: [commentURL as Any], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = sourceView
        present(activityViewController, animated: true, completion: nil)
    }

    /// Shows a contextual menu through `UIPopoverPresentationController`. This is a fallback implementation for iOS 13, since the menu can't be
    /// shown programmatically or through a single tap.
    ///
    /// NOTE: Remove this once we bump the minimum version to iOS 14.
    ///
    func showMenuSheet(for comment: Comment, indexPath: IndexPath, tableView: UITableView, sourceView: UIView?) {
        let commentMenus = commentMenu(for: comment, indexPath: indexPath, tableView: tableView, sourceView: sourceView)
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
    func menu(for comment: Comment, indexPath: IndexPath, tableView: UITableView, sourceView: UIView?) -> UIMenu {
        let commentMenus = commentMenu(for: comment, indexPath: indexPath, tableView: tableView, sourceView: sourceView)
        return UIMenu(title: "", options: .displayInline, children: commentMenus.map {
            UIMenu(title: "", options: .displayInline, children: $0.map({ menu in menu.toAction }))
        })
    }

    /// Returns a list of array that each contains a menu item. Separators will be shown between each array. Note that
    /// the order of comment menu will determine the order of appearance for the corresponding menu element.
    ///
    func commentMenu(for comment: Comment, indexPath: IndexPath, tableView: UITableView, sourceView: UIView?) -> [[ReaderCommentMenu]] {
        return [
            [
                .unapprove {
                    // TODO: Unapprove comment
                },
                .spam {
                    // TODO: Unapprove comment
                },
                .trash {
                    // TODO: Unapprove comment
                }
            ],
            [
                .edit { [weak self] in
                    self?.editMenuTapped(for: comment, indexPath: indexPath, tableView: tableView)
                },
                .share { [weak self] in
                    self?.shareComment(comment, sourceView: sourceView)
                }
            ]
        ]
    }
}

// MARK: - Localization

private extension String {
    static let authorBadgeText = NSLocalizedString("Author", comment: "Title for a badge displayed beside the comment writer's name. "
                                                   + "Shown when the comment is written by the post author.")
    static let editCommentFailureNoticeText = NSLocalizedString("There has been an unexpected error while editing the comment",
                                                                comment: "Error displayed if a comment fails to get updated")
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
