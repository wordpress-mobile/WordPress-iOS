import Foundation

public struct DispatchToken: Hashable, Equatable {
    private let uuid = UUID()

    public var hashValue: Int {
        return uuid.hashValue
    }

    public static func ==(lhs: DispatchToken, rhs: DispatchToken) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}

public class Dispatcher<Payload> {
    public typealias Callback = (Payload) -> Void

    public init() {}

    private var observers = [DispatchToken: Callback]()

    public func register(callback: @escaping Callback) -> DispatchToken {
        assertMainThread()
        let token = DispatchToken()
        observers[token] = callback
        return token
    }

    public func unregister(token: DispatchToken) {
        assertMainThread()
        observers[token] = nil
    }

    public func dispatch(_ payload: Payload) {
        assertMainThread()
        self.observers.forEach { (_, callback) in
            callback(payload)
        }
    }

    private func assertMainThread(file: StaticString = #file, line: UInt = #line) {
        assert(Thread.current.isMainThread, "Dispatcher should only be called from the main thread", file: file, line: line)
    }
}

// Cleaner syntax for Void payloads
extension Dispatcher where Payload == Void {
    func dispatch() {
        dispatch(())
    }
}
