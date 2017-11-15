open class ReducerStore<State>: Store {
    public var state: State {
        didSet {
            emitChange()
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

    override func onDispatch(_ action: Action) {
        state = reduce(action: action, state: state)
    }
}
