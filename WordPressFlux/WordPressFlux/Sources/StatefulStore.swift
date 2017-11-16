open class StatefulStore<State>: Store {
    public var state: State {
        didSet {
            // We should only emit a change if state != oldValue
            // But it's usually a pain to implement Equatable for State structures
            // We can enforce it if needed, but automatic equality synthesis is coming to Swift 4.1
            // https://github.com/apple/swift-evolution/blob/master/proposals/0185-synthesize-equatable-hashable.md
            emitChange()
        }
    }

    public init(initialState: State, dispatcher: Dispatcher = .global) {
        state = initialState
        super.init(dispatcher: dispatcher)
    }
}
