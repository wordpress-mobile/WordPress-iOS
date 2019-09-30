enum BuildConfiguration: String {
    /// Development build, usually run from Xcode
    case localDeveloper

    /// Continuous integration builds for Automattic employees to test branches & PRs
    case a8cBranchTest

    /// Beta released internally for Automattic employees
    case a8cPrereleaseTesting

    /// Production build released in the app store
    case appStore

    static var current: BuildConfiguration {
        #if DEBUG
            return testingOverride ?? .localDeveloper
        #elseif ALPHA_BUILD
            return .a8cBranchTest
        #elseif INTERNAL_BUILD
            return .a8cPrereleaseTesting
        #else
            return .appStore
        #endif
    }

    static func ~=(a: BuildConfiguration, b: Set<BuildConfiguration>) -> Bool {
        return b.contains(a)
    }

    #if DEBUG
    private static var testingOverride: BuildConfiguration?

    func test(_ closure: () -> ()) {
        BuildConfiguration.testingOverride = self
        closure()
        BuildConfiguration.testingOverride = nil
    }
    #endif
}
