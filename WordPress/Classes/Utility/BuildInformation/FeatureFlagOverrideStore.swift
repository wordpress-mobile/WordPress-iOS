import Foundation
import WordPressShared

// Protocol allows easier unit testing, so we can implement mock
// feature flags to use in test cases.
//
protocol OverridableFlag: CustomStringConvertible {
    var originalValue: Bool { get }
    var key: String { get }
}

/// Used to override values for feature flags at runtime in debug builds
///
struct FeatureFlagOverrideStore {
    private let store: KeyValueDatabase

    init(store: KeyValueDatabase = UserDefaults.standard) {
        self.store = store
    }

    /// - returns: True if the specified feature flag is overridden
    ///
    func isOverridden(_ featureFlag: OverridableFlag) -> Bool {
        return overriddenValue(for: featureFlag) != nil
    }

    /// Removes any existing overridden value and stores the new value
    ///
    func override(_ featureFlag: OverridableFlag, withValue value: Bool) {
        let key = featureFlag.key

        if isOverridden(featureFlag) {
            store.removeObject(forKey: key)
        }

        if value != featureFlag.originalValue {
            store.set(value, forKey: key)
        }
    }

    func removeOverride(for featureFlag: OverridableFlag) {
        store.removeObject(forKey: featureFlag.key)
    }

    /// - returns: The overridden value for the specified feature flag, if one exists.
    /// If no override exists, returns `nil`.
    ///
    func overriddenValue(for featureFlag: OverridableFlag) -> Bool? {
        guard store.object(forKey: featureFlag.key) != nil else {
            return nil
        }
        return store.bool(forKey: featureFlag.key)
    }
}

enum FeatureFlagError: Error {
    case cannotBeOverridden
}
