open class StatefulStore<State>: Store {
    private let stateDispatcher = Dispatcher<(State, State)>()

    public var state: State {
        didSet {
            emitStateChange(old: oldValue, new: state)
        }
    }

    public init(initialState: State, dispatcher: ActionDispatcher = .global) {
        state = initialState
        super.init(dispatcher: dispatcher)
    }

    public func transaction(_ modify: (inout State) -> Void) {
        var copy = state
        modify(&copy)
        state = copy
    }

    func emitStateChange(old: State, new: State) {
        stateDispatcher.dispatch((old, new))
        emitChange()
    }

    public func onStateChange(_ handler: @escaping ((State, State)) -> Void) -> Receipt {
        return stateDispatcher.subscribe(handler)
    }
}
