open class FluxStore {
    let globalDispatcher: FluxDispatcher
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
        listener.dispatchToken = nil
    }

    func emitChange() {
        storeDispatcher.dispatch()
    }
}

extension FluxStore {
    class Listener {
        fileprivate var dispatchToken: Dispatcher<Void>.DispatchToken?
        fileprivate weak var store: FluxStore?

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
