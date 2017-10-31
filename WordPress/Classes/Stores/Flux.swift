import Foundation

protocol FluxAction {}

class Dispatcher<Payload> {
    typealias DispatchToken = UUID
    typealias Callback = (Payload) -> Void

    private let queue = DispatchQueue(label: "org.wordpress.dispatcher")
    private var observers = [DispatchToken: Callback]()
    var observerCount: Int {
        return observers.count
    }

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

    func dispatch(_ payload: Payload) {
        queue.async {
            self.observers.forEach { (_, callback) in
                DispatchQueue.main.sync {
                    callback(payload)
                }
            }
        }
    }
}

class FluxDispatcher: Dispatcher<FluxAction> {
    static let global = FluxDispatcher()

    static func dispatch(_ action: FluxAction, dispatcher: FluxDispatcher = .global) {
        dispatcher.dispatch(action)
    }
}

open class FluxStore {
    private let globalDispatcher: FluxDispatcher
    private var dispatchToken: FluxDispatcher.DispatchToken!
    private let storeDispatcher = Dispatcher<Void>()

    var listenerCount: Int {
        return storeDispatcher.observerCount
    }

    deinit {
        globalDispatcher.unregister(token: dispatchToken)
    }

    init(dispatcher: FluxDispatcher = .global) {
        self.globalDispatcher = dispatcher
        dispatchToken = dispatcher.register(callback: { [weak self] (action) in
            self?.onDispatch(action)
        })
    }

    func onDispatch(_ action: FluxAction) {
        // Subclasses should override this
    }

    func onChange(_ handler: @escaping Action) -> Listener {
        let token = storeDispatcher.register(callback: handler)
        return Listener(dispatchToken: token, store: self)
    }

    func removeListener(_ listener: Listener) {
        guard let token = listener.dispatchToken else {
            assertionFailure("Attempting to remove a listener that has already stopped listening.")
            return
        }
        storeDispatcher.unregister(token: token)
    }

    func emitChange() {
        storeDispatcher.dispatch()
    }
}

extension FluxStore {
    class Listener {
        var dispatchToken: Dispatcher<Void>.DispatchToken?
        weak var store: FluxStore?

        fileprivate init(dispatchToken: Dispatcher<Void>.DispatchToken, store: FluxStore) {
            self.dispatchToken = dispatchToken
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
