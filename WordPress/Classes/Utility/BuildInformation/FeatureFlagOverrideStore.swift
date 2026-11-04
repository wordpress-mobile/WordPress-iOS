import Foundation
import WordPressShared

// Protocol allows easier unit testing, so we can implement mock
// feature flags to use in test cases.
//
protocol OverridableFlag: CustomStringConvertible {
    var originalValue: Bool { get }
    var key: String { get }

    /// Whether an override is persisted even when it matches the currently resolved value.
    ///
    /// Overrides are normally dropped once they agree with the default so that the flag
    /// resumes tracking it. Return `true` for a flag whose default can change underneath
    /// the user — a remote rollout, say — and whose explicit choice must outlive that
    /// change in both directions.
    var isStickyOverride: Bool { get }
}

extension OverridableFlag {
    var isStickyOverride: Bool { false }
}

/// Used to override values for feature flags at runtime in debug builds
///
struct FeatureFlagOverrideStore {
    static let didChangeNotification = Notification.Name("FeatureFlagOverrideStore.didChange")
    static let notificationFeatureFlagKey = "featureFlag"

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

        // The order matters: `originalValue` resolves a `RemoteFeatureFlag` through
        // default-constructed stores, i.e. `UserDefaults.standard`, whatever store this one
        // was given. Short-circuiting on `isStickyOverride` keeps a sticky write hermetic.
        if featureFlag.isStickyOverride || value != featureFlag.originalValue {
            store.set(value, forKey: key)
        }

        postDidChangeNotification(for: featureFlag)
    }

    func removeOverride(for featureFlag: OverridableFlag) {
        store.removeObject(forKey: featureFlag.key)
        postDidChangeNotification(for: featureFlag)
    }

    /// - returns: The overridden value for the specified feature flag, if one exists.
    /// If no override exists, returns `nil`.
    ///
    func overriddenValue(for featureFlag: OverridableFlag) -> Bool? {
        guard let object = store.object(forKey: featureFlag.key) else {
            return nil
        }
        switch object {
        case let value as Bool:
            return value
        case let value as String:
            return (value as NSString).boolValue
        default:
            return nil
        }
    }

    private func postDidChangeNotification(for featureFlag: OverridableFlag) {
        NotificationCenter.default.post(
            name: Self.didChangeNotification,
            object: nil,
            userInfo: [Self.notificationFeatureFlagKey: featureFlag]
        )
    }
}

enum FeatureFlagError: Error {
    case cannotBeOverridden
}
