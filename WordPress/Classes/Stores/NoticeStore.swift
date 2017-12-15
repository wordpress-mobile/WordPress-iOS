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

    /// A title for an optional action button that can be displayed as part of
    /// a notice
    let actionTitle: String?

    /// An optional handler closure that will be called when the action button
    /// is tapped, if you've provided an action title
    let actionHandler: (() -> Void)?

    init(title: String, message: String? = nil) {
        self.title = title
        self.message = message
        self.actionTitle = nil
        self.actionHandler = nil
    }

    init(title: String, message: String? = nil, actionTitle: String, actionHandler: @escaping (() -> Void)) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.actionHandler = actionHandler
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
