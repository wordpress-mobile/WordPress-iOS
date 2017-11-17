import Foundation

open class Store: EventEmitter {
    public let actionDispatcher: ActionDispatcher
    private var dispatchToken: DispatchToken!
    public let changeDispatcher = Dispatcher<Void>()

    deinit {
        actionDispatcher.unregister(token: dispatchToken)
    }

    public init(dispatcher: ActionDispatcher = .global) {
        actionDispatcher = dispatcher
        dispatchToken = dispatcher.register(callback: { [weak self] (action) in
            self?.onDispatch(action)
        })
    }

    open func onDispatch(_ action: Action) {
        // Subclasses should override this
    }

}
