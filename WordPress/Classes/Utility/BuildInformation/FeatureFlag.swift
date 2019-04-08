/// FeatureFlag exposes a series of features to be conditionally enabled on
/// different builds.
@objc
enum FeatureFlag: Int {
    case exampleFeature
    case jetpackDisconnect
    case newsCard
    case giphy
    case automatedTransfersCustomDomain
    case revisions
    case statsRefresh
    case gutenberg
    case quickStartV2
    case jetpackRemoteInstallation

    /// Returns a boolean indicating if the feature is enabled
    var enabled: Bool {
        switch self {
        case .exampleFeature:
            return true
        case .jetpackDisconnect:
            return BuildConfiguration.current == .localDeveloper
        case .automatedTransfersCustomDomain:
            return true
        case .newsCard:
            return true
        case .giphy:
            return true
        case .revisions:
            return true
        case .statsRefresh:
            return BuildConfiguration.current == .localDeveloper
        case .gutenberg:
            return true
        case .quickStartV2:
            return true
        case .jetpackRemoteInstallation:
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
