import Foundation

open class Store: Observable {
    public let actionDispatcher: ActionDispatcher
    private var dispatchReceipt: Receipt?
    public let changeDispatcher = Dispatcher<Void>()

    public init(dispatcher: ActionDispatcher = .global) {
        actionDispatcher = dispatcher
        dispatchReceipt = dispatcher.subscribe { [weak self] (action) in
            self?.onDispatch(action)
        }
    }

    open func onDispatch(_ action: Action) {
        // Subclasses should override this
    }

}
