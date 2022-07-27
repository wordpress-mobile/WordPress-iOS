import Foundation
import WordPressFlux

/// Notice represents a small notification that that can be displayed within
/// the app, much like Android toasts or snackbars.
/// Once you've created a Notice, you can dispatch a `NoticeAction` to display it.
///
struct Notice {
    typealias ActionHandlerFunction = ((_ accepted: Bool) -> Void)
    typealias Tag = String

    private let identifier = UUID().uuidString

    /// The title of the notice
    let title: String

    /// An optional subtitle for the notice
    let message: String?

    /// An optional taptic feedback type. If provided, taptic feedback will be
    /// triggered when the notice is displayed.
    let feedbackType: UINotificationFeedbackGenerator.FeedbackType?

    /// If provided, the notice will be presented as a system notification when
    /// the app isn't in the foreground.
    let notificationInfo: NoticeNotificationInfo?

    /// Style used to configure visual style when displayed
    ///
    let style: NoticeStyle

    /// A title for an optional action button that can be displayed as part of
    /// a notice
    let actionTitle: String?

    /// A title for an optional cancel button that can be displayed as part of a notice
    ///
    let cancelTitle: String?

    /// An optional value that can be used as a reference by consumers.
    ///
    /// This is not used in the Notice system at all.
    let tag: Tag?

    /// An optional handler closure that will be called when the action button
    /// is tapped, if you've provided an action title
    let actionHandler: ActionHandlerFunction?

    init(title: String,
         message: String? = nil,
         feedbackType: UINotificationFeedbackGenerator.FeedbackType? = nil,
         notificationInfo: NoticeNotificationInfo? = nil,
         style: NoticeStyle = NormalNoticeStyle(),
         actionTitle: String? = nil,
         cancelTitle: String? = nil,
         tag: String? = nil,
         actionHandler: ActionHandlerFunction? = nil) {
        self.title = title
        self.message = message
        self.feedbackType = feedbackType
        self.notificationInfo = notificationInfo
        self.actionTitle = actionTitle
        self.cancelTitle = cancelTitle
        self.tag = tag
        self.actionHandler = actionHandler
        self.style = style
    }

}

extension Notice: Equatable {
    static func ==(lhs: Notice, rhs: Notice) -> Bool {
        return lhs.identifier == rhs.identifier
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

/// Objective-C bridge for ActionDispatcher specific for notices.
///
class NoticesDispatch: NSObject {
    @objc static func lock() -> Void {
        ActionDispatcher.dispatch(NoticeAction.lock)
    }

    @objc static func unlock() -> Void {
        ActionDispatcher.dispatch(NoticeAction.unlock)
    }
}

/// NoticeActions can be posted to control or report the display of notices.
///
enum NoticeAction: Action {
    /// The specified notice will be queued for display to the user
    case post(Notice)
    /// The currently displayed notice should be removed from the notice store
    ///
    /// Prefer to use `clear` or `clearWithTag` whenever possible to make sure the correct
    /// `Notice` is being dismissed. Here is an example fake scenario that may make `dismiss`
    /// not ideal:
    ///
    /// 1. MediaBrowser posts NoticeA. NoticeA is displayed.
    /// 2. Editor posts NoticeB.
    /// 3. Eventually, NoticeB is displayed.
    /// 4. MediaBrowser dispatches `dismiss` which dismisses **NoticeB**!
    ///
    /// If MediaBrowser used `clear` or `clearWithTag`, the NoticeB should not have been dismissed
    /// prematurely. 
    case dismiss
    /// Removes the given `Notice` from the Store.
    case clear(Notice)
    /// Removes all Notices that have the given tag.
    ///
    /// - SeeAlso: `Notice.tag`
    case clearWithTag(Notice.Tag)
    /// Removes all Notices except the current one.
    case empty
    // Prevents the notices from showing up untill an unlock action.
    case lock
    // Show the missed notices.
    case unlock
}


struct NoticeStoreState {
    fileprivate var notice: Notice?
}

/// NoticeStore queues notices for display to the user.
///
/// To interact with or modify the `NoticeStore`, use `ActionDispatcher` and dispatch Actions of
/// type `NoticeAction`. Example:
///
/// ```
/// let notice = Notice(title: "Hello, my old friend!")
/// ActionDispatcher.dispatch(NoticeAction.post(notice))
/// ```
///
/// - SeeAlso: `NoticeAction`
class NoticeStore: StatefulStore<NoticeStoreState> {
    private var pending = Queue<Notice>()
    private var storeLocked = false

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
        case .clear(let notice):
            clear(notice: notice)
        case .clearWithTag(let tag):
            clear(tag: tag)
        case .dismiss:
            dequeueNotice()
        case .empty:
            emptyQueue()
        case .lock:
            lock()
        case .unlock:
            unlock()
        }
    }

    // MARK: - Accessors

    /// Returns the notice that should be displayed to the user, if one is available.
    var currentNotice: Notice? {
        return state.notice
    }

    // MARK: - Action handlers

    private func enqueueNotice(_ notice: Notice) {
        if state.notice == nil && !storeLocked {
            state.notice = notice
        } else {
            pending.push(notice)
        }
    }

    private func dequeueNotice() {
        if !storeLocked {
            state.notice = pending.pop()
        }
    }

    private func lock() {
        if storeLocked {
            return
        }
        state.notice = nil
        storeLocked = true
    }

    private func unlock() {
        if !storeLocked {
            return
        }
        storeLocked = false
        dequeueNotice()
    }

    private func clear(notice: Notice) {
        pending.removeAll { $0 == notice }

        if state.notice == notice {
            state.notice = pending.pop()
        }
    }

    private func clear(tag: Notice.Tag) {
        pending.removeAll { $0.tag == tag }

        if state.notice?.tag == tag {
            state.notice = pending.pop()
        }
    }

    private func emptyQueue() {
        pending.removeAll()
    }
}
