@testable import WordPress

/// Utilities to standardize how we use `BuildConfiguration`'s override from our automated tests.
///
extension Build {
    static func withCurrent(_ value: BuildConfiguration, block: () -> Void) {
        Build.overrideConfiguration(value)
        block()
        Build.clearConfigurationOverride()
    }
}
