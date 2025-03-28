import Foundation

// MARK: - Assertions

/// The system that logs assertions in production.
public protocol AssertionLogging {
    func trackAssertion(message: String, filename: String, line: UInt, userInfo: [String: Any]?)
}

extension AssertionLogging {
    public func shouldSendAssertion(withID assertionID: String) -> Bool {
        WPAssertion.shouldSendAssertion(withID: assertionID)
    }
}

public enum AssertionLoggerDependencyContainer {
    /// - warning: Not thread-safe. Set it once and early in the program.
    public static var logger: AssertionLogging?
}

/// Logs an assertion. If compiled using debug configuration, crashes.
public func wpAssert(_ closure: @autoclosure () -> Bool, _ message: StaticString = "–", userInfo: [String: Any]? = nil, file: StaticString = #file, line: UInt = #line) {
    guard !closure() else {
        return
    }

    if let logger = AssertionLoggerDependencyContainer.logger {
        let filename = (file.description as NSString).lastPathComponent
        logger.trackAssertion(message: message.description, filename: filename, line: line, userInfo: userInfo)
    }

#if DEBUG
    assertionFailure(message.description + "\n\(userInfo ?? [:])", file: file, line: line)
#endif
}

public func wpAssertionFailure(_ message: StaticString, userInfo: [String: Any]? = nil, file: StaticString = #file, line: UInt = #line) {
    wpAssert(false, message, userInfo: userInfo, file: file, line: line)
}

private enum WPAssertion {
    /// The minimum delay between the reports for the same assetion.
    static let assertionDelay: TimeInterval = 7 * 86400

    static func shouldSendAssertion(withID assertionID: String) -> Bool {
        let key = "WPAssertionLastReportDateKey-" + assertionID
        if let lastReportDate = UserDefaults.standard.object(forKey: key) as? Date,
           Date().timeIntervalSince(lastReportDate) < WPAssertion.assertionDelay {
            return false
        }
        UserDefaults.standard.set(Date(), forKey: key)
        return true
    }
}
