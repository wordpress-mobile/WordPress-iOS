import Foundation

extension Bundle {
    @objc public class var wordPressUIBundle: Bundle {
#if DEBUG
        // Workaround for https://forums.swift.org/t/swift-5-3-swiftpm-resources-in-tests-uses-wrong-bundle-path/37051
        if let testBundlePath = ProcessInfo.processInfo.environment["XCTestBundlePath"],
           let bundle = Bundle(path: "\(testBundlePath)/Modules_WordPressUI.bundle") {
            return bundle
        }
#endif
        return Bundle.module
    }
}
