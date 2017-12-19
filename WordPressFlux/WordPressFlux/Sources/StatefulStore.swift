/// A store that holds all of its internal state in a generic State property.
///
/// This class provides some common functionality for stores that want to keep
/// all of their state in a single tree. When the state changes, it will
/// automatically dispatch the change events.
///
/// Besides the existing change events provided by Store, consumers of a
/// StatefulStore can also register with onStateChange(_:) and receive a tuple
/// containing the old and new state.
///
/// ## Subclassing Notes
///
/// When subclassing StatefulStore, it is recommended that you implement a
/// convenience initializer that sets an acceptable initialState.
///
/// StatefulStore provides a helper transaction method that's useful when you
/// need to do multiple changes to the state property, but only want one change
/// notification to be dispatched.
///
open class StatefulStore<State>: Store {
    private let stateDispatcher = Dispatcher<(State, State)>()

    /// The internal state of the store.
    ///
    public var state: State {
        didSet {
            emitStateChange(old: oldValue, new: state)
        }
    }

    /// Initializes a store with an initial state.
    ///
    public init(initialState: State, dispatcher: ActionDispatcher = .global) {
        state = initialState
        super.init(dispatcher: dispatcher)
    }

    /// Groups several state changes into one transaction.
    ///
    /// You can modify the state multiple times from the passed closure, but
    /// only one change event will be dispatched after the closure returns.
    ///
    public func transaction(_ modify: (inout State) -> Void) {
        var copy = state
        modify(&copy)
        state = copy
    }

    func emitStateChange(old: State, new: State) {
        stateDispatcher.dispatch((old, new))
        emitChange()
    }

    /// Registers a new observer, that will receive a tuple with the old and new
    /// state.
    ///
    public func onStateChange(_ handler: @escaping ((State, State)) -> Void) -> Receipt {
        return stateDispatcher.subscribe(handler)
    }
}
