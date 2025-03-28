import Foundation
import WordPressShared

struct AssertionLogger: WordPressShared.AssertionLogging {
    func trackAssertion(message: String, filename: String, line: UInt, userInfo: [String: Any]?) {
        DDLogError("WPAssertionFailure in \(filename)–\(line): \(message)\n\(userInfo ?? [:])")

        WPAnalytics.track(.assertionFailure, properties: {
            var properties: [String: Any] = [
                "assertion": "\(filename)–\(line): \(message)"
            ]
            for (key, value) in userInfo ?? [:] {
                properties[key] = value
            }
            return properties
        }())

        if shouldSendAssertion(withID: "\(filename)-\(line)") {
            WPLoggingStack.shared.crashLogging.logError(
                NSError(
                    domain: "WPAssertionFailure",
                    code: -1,
                    userInfo: [NSDebugDescriptionErrorKey: "\(filename)–\(line): \(message)"]
                ),
                userInfo: userInfo
            )
        }
    }
}
