import Foundation

/// This API purposefully matches that of `NSUserDefaults`. As such, objects
/// stored in a `KeyValueDatabase` can be only property list objects: `NSData`,
/// `NSString`, `NSNumber`, `NSDate`, `NSArray`, or `NSDictionary`.
/// For `NSArray` and `NSDictionary` objects, their contents must be property
/// list objects.
protocol KeyValueDatabase {
    func object(forKey defaultName: String) -> Any?
    func set(_ value: Any?, forKey defaultName: String)
    func removeObject(forKey defaultName: String)
}

extension KeyValueDatabase {
    func bool(forKey key: String) -> Bool {
        return object(forKey: key) as? Bool ?? false
    }

    subscript<T>(key: String) -> T? {
        get {
            return object(forKey: key) as? T
        }
        set(newValue) {
            set(newValue, forKey: key)
        }
    }
}

// MARK: - Storage implementations

extension UserDefaults: KeyValueDatabase {}

/// `EphemeralKeyValueDatabase` stores values in a dictionary in memory, and is
/// never persisted between app launches.
class EphemeralKeyValueDatabase: KeyValueDatabase {
    fileprivate var memory = [String: Any]()

    open func set(_ value: Any?, forKey defaultName: String) {
        memory[defaultName] = value
    }

    open func object(forKey defaultName: String) -> Any? {
        return memory[defaultName]
    }

    open func removeObject(forKey defaultName: String) {
        memory[defaultName] = nil
    }
}
