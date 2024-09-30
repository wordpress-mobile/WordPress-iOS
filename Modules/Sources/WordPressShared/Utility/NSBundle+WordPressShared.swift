import Foundation

private class BundleFinder: NSObject {}

extension Bundle {

    /// Returns the WordPressShared Bundle
    /// If installed via CocoaPods, this will be WordPressShared.bundle,
    /// otherwise it will be the framework bundle.
    ///
    @objc public class var wordPressSharedBundle: Bundle {
#if DEBUG
        // Workaround for https://forums.swift.org/t/swift-5-3-swiftpm-resources-in-tests-uses-wrong-bundle-path/37051
        if let testBundlePath = ProcessInfo.processInfo.environment["XCTestBundlePath"],
           let bundle = Bundle(path: "\(testBundlePath)/Modules_WordPressShared.bundle") {
            return bundle
        }
#endif
        return Bundle.module
    }
}
