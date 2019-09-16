/// FeatureFlag exposes a series of features to be conditionally enabled on
/// different builds.
@objc
enum FeatureFlag: Int {
    case exampleFeature
    case jetpackDisconnect
    case statsRefresh
    case statsFileDownloads
    case statsInsightsManagement
    case domainCredit
    case signInWithApple
    case statsAsyncLoading

    /// Returns a boolean indicating if the feature is enabled
    var enabled: Bool {
        switch self {
        case .exampleFeature:
            return true
        case .jetpackDisconnect:
            return BuildConfiguration.current == .localDeveloper
        case .statsRefresh:
            return true
        case .statsFileDownloads:
            return true
        case .statsInsightsManagement:
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
        case .statsAsyncLoading:
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
