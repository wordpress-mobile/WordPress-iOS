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
    case postReblogging

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
            return true
        case .debugMenu:
            return BuildConfiguration.current ~= [.localDeveloper,
                                                  .a8cBranchTest]
        case .postReblogging:
            return BuildConfiguration.current == .localDeveloper
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

extension FeatureFlag: OverrideableFlag {
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
        case .postReblogging:
            return "Post Reblogging"
        }
    }

    var canOverride: Bool {
        switch self {
        case .debugMenu, .exampleFeature:
            return false
        default:
            return true
        }
    }
}
