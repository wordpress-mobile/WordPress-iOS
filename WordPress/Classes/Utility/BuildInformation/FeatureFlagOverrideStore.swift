import Foundation

// Protocol allows easier unit testing, so we can implement mock
// feature flags to use in test cases.
//
protocol OverridableFlag: CustomStringConvertible {
    var originalValue: Bool { get }
    var canOverride: Bool { get }
}

/// Used to override values for feature flags at runtime in debug builds
///
struct FeatureFlagOverrideStore {
    private let store: KeyValueDatabase

    init(store: KeyValueDatabase = UserDefaults.standard) {
        self.store = store
    }

    private func key(for flag: OverridableFlag) -> String {
        return "ff-override-\(String(describing: flag))"
    }

    /// - returns: True if the specified feature flag is overridden
    ///
    func isOverridden(_ featureFlag: OverridableFlag) -> Bool {
        return overriddenValue(for: featureFlag) != nil
    }

    /// Removes any existing overridden value and stores the new value
    ///
    func override(_ featureFlag: OverridableFlag, withValue value: Bool) throws {
        guard featureFlag.canOverride == true else {
            throw FeatureFlagError.cannotBeOverridden
        }

        let key = self.key(for: featureFlag)

        if isOverridden(featureFlag) {
            store.removeObject(forKey: key)
        }

        if value != featureFlag.originalValue {
            store.set(value, forKey: key)
        }
    }

    func removeOverride(for featureFlag: OverridableFlag) {
        store.removeObject(forKey: key(for: featureFlag))
    }

    /// - returns: The overridden value for the specified feature flag, if one exists.
    /// If no override exists, returns `nil`.
    ///
    func overriddenValue(for featureFlag: OverridableFlag) -> Bool? {
        guard store.object(forKey: key(for: featureFlag)) != nil else {
            return nil
        }
        return store.bool(forKey: key(for: featureFlag))
    }
}

enum FeatureFlagError: Error {
    case cannotBeOverridden
}
