/// FeatureFlag exposes a series of features to be conditionally enabled on
/// different builds.
@objc
enum FeatureFlag: Int {
    case exampleFeature
    case jetpackDisconnect
    case statsRefresh
    case domainCredit
    case notificationActions

    /// Returns a boolean indicating if the feature is enabled
    var enabled: Bool {
        switch self {
        case .exampleFeature:
            return true
        case .jetpackDisconnect:
            return BuildConfiguration.current == .localDeveloper
        case .statsRefresh:
            return BuildConfiguration.current == .localDeveloper
        case .domainCredit:
            return false
        case .notificationActions:
            return BuildConfiguration.current != .appStore
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
