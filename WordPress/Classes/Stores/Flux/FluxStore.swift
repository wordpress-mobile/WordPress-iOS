open class FluxStore: FluxEmitter {
    let globalDispatcher: FluxDispatcher
    private var dispatchToken: FluxDispatcher.DispatchToken!
    let dispatcher = Dispatcher<Void>()

    var listenerCount: Int {
        return dispatcher.observerCount
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
}
