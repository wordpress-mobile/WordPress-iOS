import Foundation
import Logging

enum Loggers {
    /// Both the app and the share extensions use this module, so the label is the bundle identifier of the
    /// running process. This keeps the app's lines apart from each extension's.
    static let shareExtension = Logger(label: Bundle.main.bundleIdentifier!)
}
