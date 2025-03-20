/// The configuration the app was compiled with.
public enum BuildConfiguration: String, Sendable {
    /// Development build, usually run from Xcode.
    case debug = "debug"

    /// Preproduction builds for Automattic employees.
    case alpha = "alpha"

    /// Production build released in the app store.
    case appStore = "release"

    public static var current: BuildConfiguration {
        BuildSettings.current.configuration
    }

    public static func ~=(a: BuildConfiguration, b: Set<BuildConfiguration>) -> Bool {
        return b.contains(a)
    }

    public var isInternal: Bool {
        self ~= [.debug, .alpha]
    }
}
