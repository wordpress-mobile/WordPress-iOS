import Foundation

enum BuildSettingsEnvironment {
    case live
    case preview

    static let current: BuildSettingsEnvironment = {
#if DEBUG
        let environment = ProcessInfo.processInfo.environment
        if environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return .preview
        }
        if NSClassFromString("XCTestCase") != nil {
            fatalError("BuildSettings are unavailable when running unit tests. Make sure to inject the values manually in system under test.")
        }
#endif
        return .live
    }()
}
