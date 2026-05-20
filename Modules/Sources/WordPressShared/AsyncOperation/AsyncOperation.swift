open class AsyncOperation: Operation, @unchecked Sendable {
    public enum State: String {
        case isReady, isExecuting, isFinished
    }

    override public var isAsynchronous: Bool {
        return true
    }

    public var state = State.isReady {
        willSet {
            willChangeValue(forKey: state.rawValue)
            willChangeValue(forKey: newValue.rawValue)
        }
        didSet {
            didChangeValue(forKey: oldValue.rawValue)
            didChangeValue(forKey: state.rawValue)
        }
    }

    override public var isExecuting: Bool {
        return state == .isExecuting
    }

    override public var isFinished: Bool {
        return state == .isFinished
    }

    override public func start() {
        if isCancelled {
            state = .isFinished
            return
        }

        state = .isExecuting
        main()
    }
}
