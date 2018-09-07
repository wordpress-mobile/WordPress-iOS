/// FeatureFlag exposes a series of features to be conditionally enabled on
/// different builds.
@objc
enum FeatureFlag: Int {
    case exampleFeature
    case jetpackDisconnect
    case extractNotifications
    case quickStart
    case newsCard
    case giphy
    case automatedTransfer

    /// Returns a boolean indicating if the feature is enabled
    var enabled: Bool {
        switch self {
        case .exampleFeature:
            return true
        case .jetpackDisconnect:
            return BuildConfiguration.current == .localDeveloper
        case .extractNotifications:
            return true
        case .quickStart:
            return BuildConfiguration.current == .localDeveloper
        case .newsCard:
            return true
        case .giphy:
            return BuildConfiguration.current == .localDeveloper
        case .automatedTransfer:
            return true
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
