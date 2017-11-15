public class EventListener {
    fileprivate var dispatchToken: DispatchToken?
    fileprivate weak var emitter: EventEmitter?

    fileprivate init(dispatchToken: DispatchToken, emitter: EventEmitter) {
        self.dispatchToken = dispatchToken
        self.emitter = emitter
    }

    deinit {
        if dispatchToken != nil {
            stopListening()
        }
    }

    func stopListening() {
        emitter?.removeListener(self)
    }
}

public protocol EventEmitter: class {
    var dispatcher: GenericDispatcher<Void> { get }
    func onChange(_ handler: @escaping () -> Void) -> EventListener
}

public extension EventEmitter {
    func onChange(_ handler: @escaping () -> Void) -> EventListener {
        let token = dispatcher.register(callback: handler)
        return EventListener(dispatchToken: token, emitter: self)
    }

    func emitChange() {
        dispatcher.dispatch()
    }

    func removeListener(_ listener: EventListener) {
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
