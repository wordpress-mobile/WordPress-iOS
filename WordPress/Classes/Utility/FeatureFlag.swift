/// FeatureFlag exposes a series of features to be conditionally enabled on
/// different builds.
@objc
enum FeatureFlag: Int {
    case ReaderMenu
    /// My Sites > Site > People
    /// Development on hold while we focus on Me
    case People
    /// Me > My Profile
    case MyProfile
    /// Me > Account Settings
    /// Account Settings already existed prior to 6.0, and included application settings
    case AccountSettings
    /// Returns a boolean indicating if the feature is enabled
    var enabled: Bool {
        switch self {
        case .ReaderMenu:
            return build(.Debug)
        case .People:
            return build(.Debug)
        case .MyProfile, .AccountSettings:
            return true
        }
    }
}

/// Objective-C bridge for FeatureFlag.
///
/// Since we can't expose properties on Swift enums we use a class instead
class Feature: NSObject {
    /// Returns a boolean indicating if the feature is enabled
    static func enabled(feature: FeatureFlag) -> Bool {
        return feature.enabled
    }
}

/// Represents a build configuration.
enum Build: Int {
    /// Development build, usually what you get when you run from Xcode
    case Debug
    /// Daily buiilds released internally for Automattic employees
    case Alpha
    /// Beta released internally for Automattic employees
    case Internal
    /// Production build released in the app store
    case AppStore

    /// Returns the current build type
    static var current: Build {
        if let override = _overrideCurrent {
            return override
        }

        #if DEBUG
            return .Debug
        #elseif ALPHA_BUILD
            return .Alpha
        #elseif INTERNAL_BUILD
            return .Internal
        #else
            return .AppStore
        #endif
    }

    /// For testing purposes only
    static var _overrideCurrent: Build? = nil
}

/// Returns true if any of the given build types matches the current build
///
/// Example:
///
///     let enableExperimentalStuff = build(.Debug, .Internal)
func build(any: Build...) -> Bool {
    return any.reduce(false, combine: { previous, buildValue in
        previous || Build.current == buildValue
    })
}
