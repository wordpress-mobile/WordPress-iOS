import Foundation

protocol FluxAction {}

class FluxDispatcher {
    typealias DispatchToken = UUID
    typealias Payload = FluxAction
    typealias Callback = (Payload) -> Void

    private let queue = DispatchQueue(label: "org.wordpress.flux-dispatcher")
    var observers = [DispatchToken: Callback]()

    static let global = FluxDispatcher()

    func register(callback: @escaping Callback) -> DispatchToken {
        let token = DispatchToken()
        queue.sync {
            observers[token] = callback
        }
        return token
    }

    func unregister(token: DispatchToken) {
        queue.sync {
            observers[token] = nil
        }
    }

    static func dispatch(_ payload: Payload, dispatcher: FluxDispatcher = .global) {
        dispatcher.dispatch(payload)
    }

    func dispatch(_ payload: Payload) {
        queue.async {
            self.observers.forEach { (_, callback) in
                callback(payload)
            }
        }
    }
}

open class FluxStore {
    private let changeNotification = NSNotification.Name("FluxStoreChanged")
    var listenerCount = 0
    private let dispatcher: FluxDispatcher
    private var dispatchToken: FluxDispatcher.DispatchToken!

    deinit {
        dispatcher.unregister(token: dispatchToken)
    }

    init(dispatcher: FluxDispatcher = .global) {
        self.dispatcher = dispatcher
        dispatchToken = dispatcher.register(callback: { [weak self] (action) in
            self?.onDispatch(action)
        })
    }

    func onDispatch(_ action: FluxAction) {
        // Subclasses should override this
    }

    func onChange(_ handler: @escaping Action) -> Listener {
        listenerCount += 1
        let notificationObserver = NotificationCenter.default.addObserver(
            forName: changeNotification,
            object: self,
            queue: nil,
            using: { _ in
                handler()
        })
        return Listener(notificationObserver: notificationObserver, store: self)
    }

    func removeListener(_ listener: Listener) {
        guard let notificationObserver = listener.notificationObserver else {
            assertionFailure("Attempting to remove a listener that has already stopped listening.")
            return
        }
        NotificationCenter.default.removeObserver(notificationObserver, name: changeNotification, object: self)
        listenerCount -= 1
    }

    func emitChange() {
        NotificationCenter.default.post(name: changeNotification, object: self)
    }
}

extension FluxStore {
    class Listener {
        var notificationObserver: NSObjectProtocol?
        weak var store: FluxStore?

        fileprivate init(notificationObserver: NSObjectProtocol, store: FluxStore) {
            self.notificationObserver = notificationObserver
            self.store = store
        }

        deinit {
            stopListening()
        }

        func stopListening() {
            store?.removeListener(self)
        }
    }
}

class StoreContainer {
    static let shared = StoreContainer()

    private init() {}

    let plugin = PluginStore()
}
