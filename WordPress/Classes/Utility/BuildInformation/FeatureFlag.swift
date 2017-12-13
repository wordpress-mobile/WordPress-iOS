/// FeatureFlag exposes a series of features to be conditionally enabled on
/// different builds.
@objc
enum FeatureFlag: Int {
    case exampleFeature
    case iCloudFilesSupport
    case pluginManagement
    case googleLogin
    case socialSignup
    case jetpackDisconnect
    case asyncUploadsInMediaLibrary
    case activity
    case siteCreation
    case portfolio

    /// Returns a boolean indicating if the feature is enabled
    var enabled: Bool {
        switch self {
        case .exampleFeature:
            return true
        case .iCloudFilesSupport:
            return BuildConfiguration.current ~= [.localDeveloper, .a8cBranchTest, .a8cPrereleaseTesting]
        case .pluginManagement:
            return BuildConfiguration.current == .localDeveloper
        case .googleLogin:
            return true
        case .socialSignup:
            return false // placeholder until the first social signup screen is added
        case .jetpackDisconnect:
            return BuildConfiguration.current == .localDeveloper
        case .asyncUploadsInMediaLibrary:
            return BuildConfiguration.current == .localDeveloper
        case .activity:
            return BuildConfiguration.current ~= [.localDeveloper, .a8cBranchTest]
        case .siteCreation:
            return BuildConfiguration.current == .localDeveloper
        case .portfolio:
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
