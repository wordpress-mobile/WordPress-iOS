/// FeatureFlag exposes a series of features to be conditionally enabled on
/// different builds.
@objc
enum FeatureFlag: Int {
    case exampleFeature
    case socialSignup
    case jetpackDisconnect
    case jetpackSignup
    case activity
    case siteCreation
    case usernameChanging
    case asyncPosting

    /// Returns a boolean indicating if the feature is enabled
    var enabled: Bool {
        switch self {
        case .exampleFeature:
            return true
        case .socialSignup:
            return true
        case .jetpackDisconnect:
            return BuildConfiguration.current == .localDeveloper
        case .jetpackSignup:
            return BuildConfiguration.current == .localDeveloper
        case .activity:
            return BuildConfiguration.current ~= [.localDeveloper, .a8cBranchTest, .a8cPrereleaseTesting]
        case .siteCreation:
            return true
        case .usernameChanging:
            return BuildConfiguration.current == .localDeveloper
        case .asyncPosting:
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
