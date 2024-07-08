import Foundation

extension Bundle {
    @objc public class var wordPressUIBundle: Bundle {
#if SWIFT_PACKAGE
#if DEBUG
        // Workaround for https://forums.swift.org/t/swift-5-3-swiftpm-resources-in-tests-uses-wrong-bundle-path/37051
        if let testBundlePath = ProcessInfo.processInfo.environment["XCTestBundlePath"],
           let bundle = Bundle(path: "\(testBundlePath)/Modules_WordPressUI.bundle") {
            return bundle
        }
#endif
        return Bundle.module
#else
        let defaultBundle = Bundle(for: FancyAlertViewController.self)
        // If installed with CocoaPods, resources will be in WordPressUIResources.bundle
        if let bundleUrl = defaultBundle.url(forResource: "WordPressUIResources", withExtension: "bundle"),
           let resourceBundle = Bundle(url: bundleUrl) {
            return resourceBundle
        }
        // Otherwise, the default bundle is used for resources
        return defaultBundle
#endif
    }
}
