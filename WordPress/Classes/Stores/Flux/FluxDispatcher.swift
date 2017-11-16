class FluxDispatcher: Dispatcher<FluxAction> {
    static let global = FluxDispatcher()

    static func dispatch(_ action: FluxAction, dispatcher: FluxDispatcher = .global) {
        dispatcher.dispatch(action)
    }
}
