/// FeatureFlag exposes a series of features to be conditionally enabled on
/// different builds.
@objc
enum FeatureFlag: Int {
    case exampleFeature
    case jetpackDisconnect
    case giphy
    case automatedTransfersCustomDomain
    case revisions
    case statsRefresh
    case gutenberg
    case domainCredit

    /// Returns a boolean indicating if the feature is enabled
    var enabled: Bool {
        switch self {
        case .exampleFeature:
            return true
        case .jetpackDisconnect:
            return BuildConfiguration.current == .localDeveloper
        case .automatedTransfersCustomDomain:
            return true
        case .giphy:
            return true
        case .revisions:
            return true
        case .statsRefresh:
            return BuildConfiguration.current == .localDeveloper
        case .gutenberg:
            return true
        case .domainCredit:
            return false
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
