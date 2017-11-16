open class ReducerStore<State: Equatable>: Store {
    public var state: State {
        didSet {
            if state != oldValue {
                emitChange()
            }
        }
    }

    public init(initialState: State, dispatcher: Dispatcher = .global) {
        state = initialState
        super.init(dispatcher: dispatcher)
    }

    open func reduce(action: Action, state: State) -> State {
        // Subclasses should override this
        return state
    }

    override open func onDispatch(_ action: Action) {
        state = reduce(action: action, state: state)
    }
}
