import Foundation

open class Store: EventEmitter {
    let globalDispatcher: Dispatcher
    private var dispatchToken: DispatchToken!
    public let dispatcher = GenericDispatcher<Void>()

    var listenerCount: Int {
        return dispatcher.observerCount
    }

    deinit {
        globalDispatcher.unregister(token: dispatchToken)
    }

    init(dispatcher: Dispatcher = .global) {
        globalDispatcher = dispatcher
        dispatchToken = dispatcher.register(callback: { [weak self] (action) in
            self?.onDispatch(action)
        })
    }

    func onDispatch(_ action: Action) {
        // Subclasses should override this
    }

}
