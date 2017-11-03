class FluxListener {
    fileprivate var dispatchToken: Dispatcher<Void>.DispatchToken?
    fileprivate weak var emitter: FluxEmitter?

    fileprivate init(dispatchToken: Dispatcher<Void>.DispatchToken, emitter: FluxEmitter) {
        self.dispatchToken = dispatchToken
        self.emitter = emitter
    }

    deinit {
        stopListening()
    }

    func stopListening() {
        emitter?.removeListener(self)
    }
}

protocol FluxEmitter: class {
    var dispatcher: Dispatcher<Void> { get }
    func onChange(_ handler: @escaping () -> Void) -> FluxListener
}

extension FluxEmitter {
    func onChange(_ handler: @escaping () -> Void) -> FluxListener {
        let token = dispatcher.register(callback: handler)
        return FluxListener(dispatchToken: token, emitter: self)
    }

    func emitChange() {
        dispatcher.dispatch()
    }

    func removeListener(_ listener: FluxListener) {
        guard let token = listener.dispatchToken else {
            assertionFailure("Attempting to remove a listener that has already stopped listening.")
            return
        }
        guard let emitter = listener.emitter,
            emitter === self else {
            assertionFailure("Attempting to remove a listener that's registered to a different emitter.")
            return
        }
        dispatcher.unregister(token: token)
        listener.dispatchToken = nil
    }
}
