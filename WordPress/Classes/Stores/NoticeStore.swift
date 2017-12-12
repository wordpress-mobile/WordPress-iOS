import Foundation
import WordPressFlux

struct Notice {
    let title: String
    let message: String?
    let actionTitle: String?
    let actionHandler: (() -> Void)?

    init(title: String, message: String? = nil, actionTitle: String? = nil, actionHandler: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.actionHandler = actionHandler
    }
}


enum NoticeAction: Action {
    case post(Notice)
    case dismiss
}


struct NoticeStoreState {
    fileprivate var notice: Notice?
}


class NoticeStore: StatefulStore<NoticeStoreState> {
    private var pending = Queue<Notice>()

    init(dispatcher: ActionDispatcher = .global) {
        super.init(initialState: NoticeStoreState(), dispatcher: dispatcher)
    }

    override func onDispatch(_ action: Action) {
        guard FeatureFlag.notices.enabled else {
            return
        }

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
