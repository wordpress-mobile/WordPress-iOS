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
    case dismiss(Notice)
}


struct NoticeStoreState {
    fileprivate var notices = Queue<Notice>()
}


class NoticeStore: StatefulStore<NoticeStoreState> {

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
        case .dismiss(let notice):
            dequeueNotice(notice)
        }
    }

    // MARK: - Accessors

    var nextNotice: Notice? {
        return state.notices.first
    }

    var notices: [Notice] {
        return state.notices.elements
    }

    // MARK: - Action handlers

    private func enqueueNotice(_ notice: Notice) {
        state.notices.push(notice)
    }

    private func dequeueNotice(_ notice: Notice) {
        state.notices.pop()
    }
}

private struct Queue<T>: ExpressibleByArrayLiteral {
    typealias ArrayLiteralElement = T

    private(set) var elements: Array<T> = []

    init(arrayLiteral elements: T...) {
        self.elements = elements
    }

    mutating func push(_ value: T) {
        elements.append(value)
    }

    @discardableResult mutating func pop() -> T? {
        guard !isEmpty else {
            return nil
        }

        return elements.removeFirst()
    }

    var isEmpty: Bool {
        return elements.isEmpty
    }

    var first: T? {
        return elements.first
    }
}
