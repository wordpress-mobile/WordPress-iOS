import Foundation

/// A lazy property that can be reset and allows you accessing the stored value
/// without initializing it if needed.
@propertyWrapper
public final class Lazy<Value> {
    private let closure: () -> Value
    public var value: Value?

    public init(wrappedValue: @autoclosure @escaping () -> Value) {
        self.closure = wrappedValue
    }

    public var wrappedValue: Value {
        if let value {
            return value
        }
        let value = closure()
        self.value = value
        return value
    }

    public var projectedValue: Lazy<Value> { self }

    public func reset() {
        self.value = nil
    }
}
