/// FeatureFlag exposes a series of features to be conditionally enabled on
/// different builds.
@objc
enum FeatureFlag: Int {
    case mediaLibrary
    case nativeEditor
    case exampleFeature

    /// Returns a boolean indicating if the feature is enabled
    var enabled: Bool {
        switch self {
        case .exampleFeature:
            return true
        case .mediaLibrary:
            return build(.debug)
        case .nativeEditor:
            // At the moment this is only visible by default in non-app store builds
            if build(.alpha, .debug, .internal) {
                return true
            }
            return false
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
    /// Development build, usually what you get when you run from Xcode
    case debug
    /// Daily buiilds released internally for Automattic employees
    case alpha
    /// Beta released internally for Automattic employees
    case `internal`
    /// Production build released in the app store
    case appStore

    /// Returns the current build type
    static var current: Build {
        if let override = _overrideCurrent {
            return override
        }

        #if DEBUG
            return .debug
        #elseif ALPHA_BUILD
            return .alpha
        #elseif INTERNAL_BUILD
            return .`internal`
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
///     let enableExperimentalStuff = build(.Debug, .Internal)
func build(_ any: Build...) -> Bool {
    return any.reduce(false, { previous, buildValue in
        previous || Build.current == buildValue
    })
}
