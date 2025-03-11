open class AsyncOperation: Operation, @unchecked Sendable {
    public enum State: String {
        case isReady, isExecuting, isFinished
    }

    public override var isAsynchronous: Bool {
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

    public override var isExecuting: Bool {
        return state == .isExecuting
    }

    public override var isFinished: Bool {
        return state == .isFinished
    }

    public override func start() {
        if isCancelled {
            state = .isFinished
            return
        }

        state = .isExecuting
        main()
    }
}
