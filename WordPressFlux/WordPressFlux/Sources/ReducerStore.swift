open class ReducerStore<State>: StatefulStore<State> {
    open func reduce(action: Action, state: State) -> State {
        // Subclasses should override this
        return state
    }

    override open func onDispatch(_ action: Action) {
        state = reduce(action: action, state: state)
    }
}
