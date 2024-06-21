import Foundation

extension Bundle {
    /// Returns the `Bundle` for the target.
    ///
    /// If installed via CocoaPods, this will be `<target_name>.bundle`,  otherwise it will be the framework bundle.
    @objc public class var coreAPITestsBundle: Bundle {
#if SWIFT_PACKAGE
        return Bundle.module
#else
        let defaultBundle = Bundle(for: BundleFinder.self)

        guard let bundleURL = defaultBundle.resourceURL,
              let resourceBundle = Bundle(url: bundleURL.appendingPathComponent("CoreAPITests.bundle")) else {
            return defaultBundle
        }

        return resourceBundle
#endif
    }
}

#if !SWIFT_PACKAGE
private class BundleFinder: NSObject {}
#endif
