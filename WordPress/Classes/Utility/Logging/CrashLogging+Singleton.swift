import Foundation
import AutomatticTracks

extension CrashLogging {

    static let main: CrashLogging = {
        if let crashLogging = WordPressAppDelegate.crashLogging {
            return crashLogging
        }
        let stack = WPLoggingStack()
        return stack.crashLogging
    }()
}
