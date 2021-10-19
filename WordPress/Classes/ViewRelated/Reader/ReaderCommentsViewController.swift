import Foundation
import WordPressFlux

@objc public extension ReaderCommentsViewController {
    func shouldShowSuggestions(for siteID: NSNumber?) -> Bool {
        guard let siteID = siteID, let blog = Blog.lookup(withID: siteID, in: ContextManager.shared.mainContext) else { return false }
        return SuggestionService.shared.shouldShowSuggestions(for: blog)
    }

    func displayFollowSuccessNotice(actionHandler: (() -> Void)?) {
        let notice = Notice(title: .followNoticeTitle, message: .followNoticeMessage, actionTitle: .followNoticeActionTitle) { _ in
            actionHandler?()
        }
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }

    func displayNotificationsEnabledNotice(actionHandler: (() -> Void)?) {
        let notice = Notice(title: .notificationsEnabledTitle, actionTitle: .notificationsEnabledActionTitle) { _ in
            actionHandler?()
        }
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }
}

private extension String {
    static let followNoticeTitle = NSLocalizedString("Following this conversation", comment: "The app successfully subscribed to the comments for the post")
    static let followNoticeMessage = NSLocalizedString("Enable in-app notifications?",
                                                       comment: "Hint for the notice's action button that enables notification for new comments on the post")
    static let followNoticeActionTitle = NSLocalizedString("Enable", comment: "Button title to enable notifications for post subscription")
    static let notificationsEnabledTitle = NSLocalizedString("In-app notifications enabled",
                                                             comment: "The app successfully enabled notifications for the subscription.")
    static let notificationsEnabledActionTitle = NSLocalizedString("Undo", comment: "Button title. Reverts the previous operation.")
}
