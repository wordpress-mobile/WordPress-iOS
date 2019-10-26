class AsyncOperation: Operation {
    enum State: String {
        case isReady, isExecuting, isFinished
    }

    override var isAsynchronous: Bool {
        return true
    }

    var state = State.isReady {
        willSet {
            willChangeValue(forKey: state.rawValue)
            willChangeValue(forKey: newValue.rawValue)
        }
        didSet {
            didChangeValue(forKey: oldValue.rawValue)
            didChangeValue(forKey: state.rawValue)
        }
    }

    override var isExecuting: Bool {
        return state == .isExecuting
    }

    override var isFinished: Bool {
        return state == .isFinished
    }

    override func start() {
        if isCancelled {
            state = .isFinished
            return
        }

        state = .isExecuting
        main()
    }
}
