import Foundation

public class LockingHashMap<Value>: @unchecked Sendable {
    let lock = NSLock()

    var list: [AnyHashable: Value] = [:]

    public init(_ values: [AnyHashable: Value] = [:]) {
        self.list = values
    }

    public subscript(_ key: AnyHashable) -> Value? {
        get {
            lock.withLock {
                list[key]
            }
        }
        set {
            lock.withLock {
                list[key] = newValue
            }
        }
    }

    public var values: Dictionary<AnyHashable, Value>.Values {
        lock.withLock {
            self.list.values
        }
    }

    @discardableResult
    public func removeValue(forKey key: AnyHashable) -> Value? {
        lock.withLock {
            self.list.removeValue(forKey: key)
        }
    }

    public func removeAll() {
        lock.withLock {
            self.list.removeAll()
        }
    }
}

public class LockingTaskHashMap<T, E>: LockingHashMap<Task<T, E>>, @unchecked Sendable where T: Sendable, E: Error {

    @discardableResult
    public override func removeValue(forKey key: AnyHashable) -> Task<T, E>? {
        lock.withLock {
            let task = self.list.removeValue(forKey: key)
            task?.cancel()
            return task
        }
    }

    public override func removeAll() {
        lock.withLock {
            for key in self.list.keys {
                let task = self.list.removeValue(forKey: key)
                task?.cancel()
            }
        }
    }
}
