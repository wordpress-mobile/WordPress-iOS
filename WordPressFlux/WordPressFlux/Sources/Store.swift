/// A store holds the data associated to a specific domain of the application.
///
/// Every store is subscribed to the global action dispatcher (although it can
/// be initialized with a custom dispatcher), and should respond to relevant
/// Actions by implementing onDispatch(_:), and change its internal state
/// according to those actions.
///
/// A store should expose some public accessors for consumers to access its
/// state, and call emitChange() whenever the state changes, to notify any
/// observers.
///
/// Consumers of the Store should register their handlers calling onChange(_:)
/// and keeping the returned receipt until they don't want more updates.
///
open class Store: Observable {

    /// The dispatcher used to subscribe to Actions.
    public let actionDispatcher: ActionDispatcher

    private var dispatchReceipt: Receipt?

    /// The dispatcher used to notify observer of changes.
    public let changeDispatcher = Dispatcher<Void>()

    /// Initializes a new Store.
    ///
    /// - Parameters:
    ///   - dispatcher: the Dispatcher to use to receive Actions.
    ///
    public init(dispatcher: ActionDispatcher = .global) {
        actionDispatcher = dispatcher
        dispatchReceipt = dispatcher.subscribe { [weak self] (action) in
            self?.onDispatch(action)
        }
    }

    /// This method is called for every Action.
    ///
    /// Subclasses should implement this and deal with the Actions relevant to
    /// them.
    ///
    open func onDispatch(_ action: Action) {
        // Subclasses should override this
    }
}
