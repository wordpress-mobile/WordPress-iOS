import Foundation

/// This API purposefully matches that of `NSUserDefaults`. As such, objects
/// stored in a `KeyValueDatabase` can be only property list objects: `NSData`,
/// `NSString`, `NSNumber`, `NSDate`, `NSArray`, or `NSDictionary`.
/// For `NSArray` and `NSDictionary` objects, their contents must be property
/// list objects.
protocol KeyValueDatabase {
    func objectForKey(_ key: String) -> AnyObject?
    func setObject(_ object: AnyObject?, forKey key: String)
    func removeObjectForKey(_ key: String)
}

// MARK: - Storage implementations

extension UserDefaults: KeyValueDatabase {}

/// `EphemeralKeyValueDatabase` stores values in a dictionary in memory, and is
/// never persisted between app launches.
class EphemeralKeyValueDatabase: KeyValueDatabase {
    fileprivate var memory = [String: AnyObject]()

    func setObject(_ object: AnyObject?, forKey key: String) {
        memory[key] = object
    }

    func objectForKey(_ key: String) -> AnyObject? {
        return memory[key]
    }

    func removeObjectForKey(_ key: String) {
        memory[key] = nil
    }
}
