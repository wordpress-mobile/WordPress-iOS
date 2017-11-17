public protocol Observable {
    var changeDispatcher: Dispatcher<Void> { get }
    func onChange(_ handler: @escaping () -> Void) -> Receipt
}

public extension Observable {
    func onChange(_ handler: @escaping () -> Void) -> Receipt {
        return changeDispatcher.subscribe(handler)
    }

    func emitChange() {
        changeDispatcher.dispatch()
    }
}
