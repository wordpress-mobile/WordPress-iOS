import Foundation
import WordPressFlux

struct InAppNotification {
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


enum InAppNotificationAction: Action {
    case notify(InAppNotification)
    case dismiss(InAppNotification)
}


struct InAppNotificationStoreState {
    fileprivate var notifications = Queue<InAppNotification>()
}


class InAppNotificationStore: StatefulStore<InAppNotificationStoreState> {

    init(dispatcher: ActionDispatcher = .global) {
        super.init(initialState: InAppNotificationStoreState(), dispatcher: dispatcher)
    }

    override func onDispatch(_ action: Action) {
        guard let action = action as? InAppNotificationAction else {
            return
        }
        switch action {
        case .notify(let notification):
            enqueueNotification(notification)
        case .dismiss(let notification):
            dequeueNotification(notification)
        }
    }

    // MARK: - Accessors

    var nextNotification: InAppNotification? {
        return state.notifications.first
    }

    var notifications: [InAppNotification] {
        return state.notifications.elements
    }

    // MARK: - Action handlers

    private func enqueueNotification(_ notification: InAppNotification) {
        state.notifications.push(notification)
    }

    private func dequeueNotification(_ notification: InAppNotification) {
        state.notifications.pop()
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
