import Foundation

protocol KeyValueStorage {
    func valueForKey(key: String) -> AnyObject?
    func setValue(value: AnyObject, forKey key: String)
    func removeValueForKey(key: String)
}

// MARK: - Storage implementations

struct KeyValueDatabase {
    /// `DefaultsDatabase` stores values using `NSUserDefaults` and is persisted
    /// between app launches.
    struct DefaultsDatabase: KeyValueStorage {
        func setValue(value: AnyObject, forKey key: String) {
            NSUserDefaults.standardUserDefaults().setObject(value, forKey: key)
        }
        func valueForKey(key: String) -> AnyObject? {
            return NSUserDefaults.standardUserDefaults().objectForKey(key)
        }
        func removeValueForKey(key: String) {
            NSUserDefaults.standardUserDefaults().removeObjectForKey(key)
        }
    }

    /// `InMemoryDatabase` stores values in a dictionary in memory, and is
    /// never persisted between app launches.
    class InMemoryDatabase: KeyValueStorage {
        private var memory = [String: AnyObject]()
        
        func setValue(value: AnyObject, forKey key: String) {
            memory[key] = value
        }
        
        func valueForKey(key: String) -> AnyObject? {
            return memory[key]
        }
        
        func removeValueForKey(key: String) {
            memory[key] = nil
        }
    }
}
