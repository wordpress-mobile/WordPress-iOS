/// FeatureFlag exposes a series of features to be conditionally enabled on
/// different builds.
@objc
enum FeatureFlag: Int {
    case exampleFeature
    case newMediaExports
    case pluginManagement
    case jetpackThemesBrowsing
    case googleLogin
    case jetpackDisconnect

    /// Returns a boolean indicating if the feature is enabled
    var enabled: Bool {
        switch self {
        case .exampleFeature:
            return true
        case .newMediaExports:
            return build(.localDeveloper, .a8cBranchTest)
        case .pluginManagement:
            return build(.localDeveloper)
        case .jetpackThemesBrowsing:
            return build(.a8cPrereleaseTesting, .a8cBranchTest, .localDeveloper)
        case .googleLogin:
            return build(.localDeveloper)
        case .jetpackDisconnect:
            return build(.localDeveloper)
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

/// Represents a build configuration.
enum Build: Int {
    /// Development build, usually run from Xcode
    case localDeveloper
    /// Continuous integration builds for Automattic employees to test branches & PRs
    case a8cBranchTest
    /// Beta released internally for Automattic employees
    case a8cPrereleaseTesting
    /// Production build released in the app store
    case appStore

    /// Returns the current build type
    static var current: Build {
        if let override = _overrideCurrent {
            return override
        }

        #if DEBUG
            return .localDeveloper
        #elseif ALPHA_BUILD
            return .a8cBranchTest
        #elseif INTERNAL_BUILD
            return .a8cPrereleaseTesting
        #else
            return .appStore
        #endif
    }

    /// For testing purposes only
    static var _overrideCurrent: Build? = nil
}

/// Returns true if any of the given build types matches the current build
///
/// Example:
///
///     let enableExperimentalStuff = build(.localDeveloper, .a8cBranchTest)
func build(_ any: Build...) -> Bool {
    return any.reduce(false, { previous, buildValue in
        previous || Build.current == buildValue
    })
}
