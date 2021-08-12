import Foundation

// Protocol allows easier unit testing, so we can implement mock
// feature flags to use in test cases.
//
protocol OverrideableFlag: CustomStringConvertible {
    var enabled: Bool { get }
    var canOverride: Bool { get }

    /// An optional key identifying this flag server-side. Not all flags will have this key – they may not use remote feature flagging
    var remoteKey: String? { get }

    /// Called whenever the override value has changed for cleanup / extra logic purposes.
    func overrideChanged()
}

/// Used to override values for feature flags at runtime in debug builds
///
struct FeatureFlagOverrideStore {
    private let store: KeyValueDatabase

    init(store: KeyValueDatabase = UserDefaults.standard) {
        self.store = store
    }

    private func key(for flag: OverrideableFlag) -> String {
        return "ff-override-\(String(describing: flag))"
    }

    /// - returns: True if the specified feature flag is overridden
    ///
    func isOverridden(_ featureFlag: OverrideableFlag) -> Bool {
        return overriddenValue(for: featureFlag) != nil
    }

    /// Removes any existing overridden value and stores the new value
    ///
    func override(_ featureFlag: OverrideableFlag, withValue value: Bool) throws {
        guard featureFlag.canOverride == true else {
            throw FeatureFlagError.cannotBeOverridden
        }

        let key = self.key(for: featureFlag)

        if isOverridden(featureFlag) {
            store.removeObject(forKey: key)
            featureFlag.overrideChanged()
        }

        if value != featureFlag.enabled {
            store.set(value, forKey: key)
            featureFlag.overrideChanged()
        }
    }

    /// - returns: The overridden value for the specified feature flag, if one exists.
    /// If no override exists, returns `nil`.
    ///
    func overriddenValue(for featureFlag: OverrideableFlag) -> Bool? {
        guard let value = store.object(forKey: key(for: featureFlag)) as? Bool else {
            return nil
        }

        return value
    }
}

enum FeatureFlagError: Error {
    case cannotBeOverridden
}
