import Foundation

open class Store: EventEmitter {
    public let globalDispatcher: Dispatcher
    private var dispatchToken: DispatchToken!
    public let dispatcher = GenericDispatcher<Void>()

    deinit {
        globalDispatcher.unregister(token: dispatchToken)
    }

    public init(dispatcher: Dispatcher = .global) {
        globalDispatcher = dispatcher
        dispatchToken = dispatcher.register(callback: { [weak self] (action) in
            self?.onDispatch(action)
        })
    }

    open func onDispatch(_ action: Action) {
        // Subclasses should override this
    }

}
