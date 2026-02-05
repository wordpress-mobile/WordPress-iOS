import Foundation

/// A thread-safe wrapper for a single value, using NSLock for synchronization.
/// Use this for mutable state in `Sendable` types that need manual thread safety.
public final class LockingValue<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: Value

    public init(_ value: Value) {
        self._value = value
    }

    public var value: Value {
        get { lock.withLock { _value } }
        set { lock.withLock { _value = newValue } }
    }

    /// Atomically reads and updates the value, returning a result.
    public func withLock<T>(_ body: (inout Value) -> T) -> T {
        lock.withLock { body(&_value) }
    }
}
