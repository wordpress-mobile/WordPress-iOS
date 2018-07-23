import Foundation
import WordPressFlux

/// Notice represents a small notification that that can be displayed within
/// the app, much like Android toasts or snackbars.
/// Once you've created a Notice, you can dispatch a `NoticeAction` to display it.
///
struct Notice {
    /// The title of the notice
    let title: String

    /// An optional subtitle for the notice
    let message: String?

    /// An optional taptic feedback type. If provided, taptic feedback will be
    /// triggered when the notice is displayed.
    let feedbackType: UINotificationFeedbackType?

    /// If provided, the notice will be presented as a system notification when
    /// the app isn't in the foreground.
    let notificationInfo: NoticeNotificationInfo?

    /// Style used to configure visual style when displayed
    ///
    let style: Style

    /// A title for an optional action button that can be displayed as part of
    /// a notice
    let actionTitle: String?

    /// An optional handler closure that will be called when the action button
    /// is tapped, if you've provided an action title
    let actionHandler: (() -> Void)?

    init(title: String, message: String? = nil, feedbackType: UINotificationFeedbackType? = nil, notificationInfo: NoticeNotificationInfo? = nil, style: Style = .normal) {
        self.title = title
        self.message = message
        self.feedbackType = feedbackType
        self.notificationInfo = notificationInfo
        self.actionTitle = nil
        self.actionHandler = nil
        self.style = style
    }

    init(title: String, message: String? = nil, feedbackType: UINotificationFeedbackType? = nil, notificationInfo: NoticeNotificationInfo? = nil, style: Style = .normal, actionTitle: String, actionHandler: @escaping (() -> Void)) {
        self.title = title
        self.message = message
        self.feedbackType = feedbackType
        self.notificationInfo = notificationInfo
        self.actionTitle = actionTitle
        self.actionHandler = actionHandler
        self.style = style
    }

    public enum Style {
        case normal
        case quickStart
    }
}

struct NoticeNotificationInfo {
    /// Unique identifier for this notice. When displayed as a system notification,
    /// this value will be used as the `UNNotificationRequest`'s identifier.
    let identifier: String

    /// Optional category identifier for this notice. If provided, this value
    /// will be used as the `UNNotificationContent`'s category identifier.
    let categoryIdentifier: String?

    /// Optional title. If provided, this will override the notice's
    /// standard title when displayed as a notification.
    let title: String?

    /// Optional body text. If provided, this will override the notice's
    /// standard message when displayed as a notification.
    let body: String?

    /// If provided, this will be added to the `UNNotificationRequest` for this notice.
    let userInfo: [String: Any]?

    init(identifier: String, categoryIdentifier: String? = nil, title: String? = nil, body: String? = nil, userInfo: [String: Any]? = nil) {
        self.identifier = identifier
        self.categoryIdentifier = categoryIdentifier
        self.title = title
        self.body = body
        self.userInfo = userInfo
    }
}

/// NoticeActions can be posted to control or report the display of notices.
///
enum NoticeAction: Action {
    /// The specified notice will be queued for display to the user
    case post(Notice)
    /// The currently displayed notice should be removed from the notice store
    case dismiss
}


struct NoticeStoreState {
    fileprivate var notice: Notice?
}

/// NoticeStore queues notices for display to the user.
///
class NoticeStore: StatefulStore<NoticeStoreState> {
    private var pending = Queue<Notice>()

    init(dispatcher: ActionDispatcher = .global) {
        super.init(initialState: NoticeStoreState(), dispatcher: dispatcher)
    }

    override func onDispatch(_ action: Action) {
        guard let action = action as? NoticeAction else {
            return
        }
        switch action {
        case .post(let notice):
            enqueueNotice(notice)
        case .dismiss:
            dequeueNotice()
        }
    }

    // MARK: - Accessors

    /// Returns the next notice that should be displayed to the user, if
    /// one is available
    ///
    var nextNotice: Notice? {
        return state.notice
    }

    // MARK: - Action handlers

    private func enqueueNotice(_ notice: Notice) {
        if state.notice == nil {
            state.notice = notice
        } else {
            pending.push(notice)
        }
    }

    private func dequeueNotice() {
        state.notice = pending.pop()
    }
}
