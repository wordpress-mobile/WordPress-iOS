@objc
class Build: NSObject {
    @objc
    enum BuildConfiguration: Int {
        /// Development build, usually run from Xcode
        case localDeveloper
        /// Continuous integration builds for Automattic employees to test branches & PRs
        case a8cBranchTest
        /// Beta released internally for Automattic employees
        case a8cPrereleaseTesting
        /// Production build released in the app store
        case appStore
    }

    /// Returns true if any of the given build types matches the current build
    ///
    /// Example:
    ///
    ///     let enableExperimentalStuff = build(.localDeveloper, .a8cBranchTest)
    ///
    static func `is`(_ testConfiguration: BuildConfiguration) -> Bool {
        return testConfiguration == configuration()
    }

    /// Returns true if any of the given build types matches the current build
    ///
    /// Example:
    ///
    ///     let enableExperimentalStuff = build(.localDeveloper, .a8cBranchTest)
    ///
    static func `is`(_ testConfigurations: Set<BuildConfiguration>) -> Bool {
        return testConfigurations.contains(configuration())
    }

    /// Returns the current build type
    private static func configuration() -> BuildConfiguration {
        #if DEBUG
            if let overriddenConfiguration = overriddenConfiguration {
                return overriddenConfiguration
            }

            return .localDeveloper
        #elseif ALPHA_BUILD
            return .a8cBranchTest
        #elseif INTERNAL_BUILD
            return .a8cPrereleaseTesting
        #else
            return .appStore
        #endif
    }

    #if DEBUG
    // MARK: - Automated Testing Utilities

    private static var overriddenConfiguration: BuildConfiguration? = nil

    @objc
    static func overrideConfiguration(_ configuration: BuildConfiguration) {
        overriddenConfiguration = configuration
    }

    @objc
    static func clearConfigurationOverride() {
        overriddenConfiguration = nil
    }

    static func withCurrent(_ value: BuildConfiguration, block: () -> Void) {
        Build.overrideConfiguration(value)
        block()
        Build.clearConfigurationOverride()
    }
    #endif
}
