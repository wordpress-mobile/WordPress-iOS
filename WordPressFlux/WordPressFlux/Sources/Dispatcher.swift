/// An opaque type used by Dispatcher to keep track of registered handlers.
///
public struct DispatchToken: Hashable, Equatable {
    private let uuid = UUID()

    public var hashValue: Int {
        return uuid.hashValue
    }

    public static func ==(lhs: DispatchToken, rhs: DispatchToken) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}

/// A Dispatcher broadcasts a Payload to all registered subscribers.
///
/// You can think of it as a strongly typed NotificationCenter, if it had been
/// written for Swift instead of Objective-C.
///
/// Dispatcher is not thread safe yet, and it expects its methods to be called
/// from the main thread only.
///
public class Dispatcher<Payload> {

    /// Initializes a new Dispatcher.
    ///
    public init() {}

    private var observers = [DispatchToken: (Payload) -> Void]()

    /// Register a new handler to call on dispatch.
    ///
    /// - Parameters:
    ///     - callback: a closure to be called on dispatch with the payload as a
    ///     parameter.
    /// - Returns: a DispatchToken necessary to unregister the given callback.
    ///
    public func register(_ callback: @escaping (Payload) -> Void) -> DispatchToken {
        assertMainThread()
        let token = DispatchToken()
        observers[token] = callback
        return token
    }

    /// Unregisters the callback associated with the given token.
    ///
    /// - Parameters:
    ///     - token: the token that was returned by register.
    ///
    public func unregister(token: DispatchToken) {
        assertMainThread()
        observers[token] = nil
    }

    /// Dispatches the given payload to all registered handlers.
    ///
    /// - Parameters:
    ///     - payload: the payload to broadcast to handlers.
    ///
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

extension Dispatcher: Unsubscribable {
    /// Registers a new handler with a subscription bound to the lifetime of the
    /// returned Receipt.
    ///
    /// When the returned Receipt is released from memory, the handler will be
    /// automatically unregistered.
    ///
    /// - Parameters:
    ///   - callback: a closure to be called on dispatch with the payload as a
    ///               parameter.
    /// - Returns: a Receipt bound to the handler subscription.
    ///
    public func subscribe(_ callback: @escaping (Payload) -> Void) -> Receipt {
        let token = register(callback)
        return Receipt(token: token, owner: self)
    }

    /// Unregisters the callback associated with the given Receipt.
    ///
    /// - Parameters:
    ///     - receipt: the receipt that was returned by subscribe.
    ///
    public func unsubscribe(receipt: Receipt) {
        unregister(token: receipt.token)
    }
}

// Cleaner syntax for Void payloads
extension Dispatcher where Payload == Void {
    /// Dispatches an event to all the registered handlers.
    ///
    public func dispatch() {
        dispatch(())
    }
}
