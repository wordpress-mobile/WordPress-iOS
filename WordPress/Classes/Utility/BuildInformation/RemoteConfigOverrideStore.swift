import Foundation

/// Used to override values for remote config parameters at runtime in debug builds
///
struct RemoteConfigOverrideStore {
    private let store: KeyValueDatabase

    init(store: KeyValueDatabase = UserDefaults.standard) {
        self.store = store
    }

    private func key(for param: RemoteParameter) -> String {
        return "remote-config-override-\(String(describing: param))"
    }

    /// - returns: True if the specified parameter is overridden
    ///
    func isOverridden(_ param: RemoteParameter) -> Bool {
        return overriddenValue(for: param) != nil
    }

    /// Stores the new overridden value
    ///
    func override(_ param: RemoteParameter, withValue value: String) {
        let key = self.key(for: param)
        store.set(value, forKey: key)
    }

    /// Removes any existing overridden value
    ///
    func reset(_ param: RemoteParameter) {
        let key = self.key(for: param)
        store.removeObject(forKey: key)
    }

    /// - returns: The overridden value for the specified parameter, if one exists.
    /// If no override exists, returns `nil`.
    ///
    func overriddenValue(for param: RemoteParameter) -> String? {
        guard let value = store.object(forKey: key(for: param)) as? String else {
            return nil
        }

        return value
    }
}
