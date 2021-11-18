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

    // MARK: New Comment Threads

    func configuredHeaderView(for tableView: UITableView) -> UIView {
        guard let post = post else {
            return .init()
        }

        let cell = CommentHeaderTableViewCell()
        cell.backgroundColor = .systemBackground
        cell.configure(for: .thread, subtitle: post.titleForDisplay(), showsDisclosureIndicator: false)

        // the table view does not render separators for the section header views, so we need to create one.
        cell.contentView.addBottomBorder(withColor: .separator, leadingMargin: tableView.separatorInset.left)

        return cell
    }
}
