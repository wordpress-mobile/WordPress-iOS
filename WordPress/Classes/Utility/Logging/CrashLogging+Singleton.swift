import Foundation
import AutomatticTracks

extension CrashLogging {

    static let main: CrashLogging = {
        if let crashLogging = WordPressAppDelegate.crashLogging {
            return crashLogging
        }
        // `WordPressAppDelegate.crashLogging` is probably never going to be nil
        // So the following code won't be executed at runtime.
        let stack = WPLoggingStack()
        return stack.crashLogging
    }()
}
