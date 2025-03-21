/// The configuration the app was compiled with.
public enum BuildConfiguration: String, Sendable {
    /// Development build, usually run from Xcode.
    case debug

    /// Preproduction builds for Automattic employees.
    case alpha

    /// Production build released in the app store.
    case release

    public static var current: BuildConfiguration {
        BuildSettings.current.configuration
    }

    /// Returns `true` if the build is intented only for internal use.
    public var isInternal: Bool {
        switch self {
        case .debug, .alpha: true
        case .release: false
        }
    }
}
