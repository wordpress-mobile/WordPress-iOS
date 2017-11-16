class Dispatcher<Payload> {
    typealias DispatchToken = UUID
    typealias Callback = (Payload) -> Void

    private var observers = [DispatchToken: Callback]()
    var observerCount: Int {
        return observers.count
    }

    func register(callback: @escaping Callback) -> DispatchToken {
        assertMainThread()
        let token = DispatchToken()
        observers[token] = callback
        return token
    }

    func unregister(token: DispatchToken) {
        assertMainThread()
        observers[token] = nil
    }

    func dispatch(_ payload: Payload) {
        assertMainThread()
        self.observers.forEach { (_, callback) in
            callback(payload)
        }
    }

    private func assertMainThread(file: StaticString = #file, line: UInt = #line) {
        assert(Thread.current.isMainThread, "Dispatcher should only be called from the main thread", file: file, line: line)
    }
}
