/// FeatureFlag exposes a series of features to be conditionally enabled on
/// different builds.
@objc
enum FeatureFlag: Int {
    case exampleFeature
    case newMediaExports
    case pluginManagement
    case googleLogin
    case jetpackDisconnect

    /// Returns a boolean indicating if the feature is enabled
    var enabled: Bool {
        switch self {
        case .exampleFeature:
            return true
        case .newMediaExports:
            return Build.is([.localDeveloper, .a8cBranchTest])
        case .pluginManagement:
            return Build.is(.localDeveloper)
        case .googleLogin:
            return Build.is(.localDeveloper)
        case .jetpackDisconnect:
            return Build.is(.localDeveloper)
        }
    }
}

/// Objective-C bridge for FeatureFlag.
///
/// Since we can't expose properties on Swift enums we use a class instead
class Feature: NSObject {
    /// Returns a boolean indicating if the feature is enabled
    static func enabled(_ feature: FeatureFlag) -> Bool {
        return feature.enabled
    }
}
