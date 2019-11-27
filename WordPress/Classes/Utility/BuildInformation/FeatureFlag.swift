/// FeatureFlag exposes a series of features to be conditionally enabled on
/// different builds.
@objc
enum FeatureFlag: Int, CaseIterable {
    case exampleFeature
    case jetpackDisconnect
    case domainCredit
    case signInWithApple
    case postScheduling
    case debugMenu

    /// Returns a boolean indicating if the feature is enabled
    var enabled: Bool {
        if let overriddenValue = FeatureFlagOverrideStore().overriddenValue(for: self) {
            return overriddenValue
        }

        switch self {
        case .exampleFeature:
            return true
        case .jetpackDisconnect:
            return BuildConfiguration.current == .localDeveloper
        case .domainCredit:
            return true
        case .signInWithApple:
            // SIWA can NOT be enabled for internal builds
            // Ref https://github.com/wordpress-mobile/WordPress-iOS/pull/12332#issuecomment-521994963
            if BuildConfiguration.current == .a8cBranchTest || BuildConfiguration.current == .a8cPrereleaseTesting {
                return false
            }
            return true
        case .postScheduling:
            return BuildConfiguration.current ~= [.localDeveloper,
                                                  .a8cBranchTest,
                                                  .a8cPrereleaseTesting]
        case .debugMenu:
            return BuildConfiguration.current ~= [.localDeveloper,
                                                  .a8cBranchTest]
        }
    }
}

/// Objective-C bridge for FeatureFlag.
///
/// Since we can't expose properties on Swift enums we use a class instead
class Feature: NSObject {
    /// Returns a boolean indicating if the feature is enabled
    @objc static func enabled(_ feature: FeatureFlag) -> Bool {
        return feature.enabled
    }
}


extension FeatureFlag: CustomStringConvertible {
    /// Descriptions used to display the feature flag override menu in debug builds
    var description: String {
        switch self {
        case .exampleFeature:
            return "Example feature"
        case .jetpackDisconnect:
            return "Jetpack disconnect"
        case .domainCredit:
            return "Use domain credits"
        case .signInWithApple:
            return "Sign in with Apple"
        case .postScheduling:
            return "Post scheduling improvements"
        case .debugMenu:
            return "Debug menu"
        }
    }
}

// MARK: - Overriding Feature Flags

// Protocol allows easier unit testing, so we can implement mock
// feature flags to use in test cases.
//
protocol OverrideableFlag: CustomStringConvertible {
    var enabled: Bool { get }
    var canOverride: Bool { get }
}

extension FeatureFlag: OverrideableFlag {
    var canOverride: Bool {
        switch self {
        case .debugMenu, .exampleFeature:
            return false
        default:
            return true
        }
    }
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
        }

        if value != featureFlag.enabled {
            store.set(value, forKey: key)
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
