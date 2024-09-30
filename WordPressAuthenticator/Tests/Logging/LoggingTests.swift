import XCTest
import WordPressShared

@testable import WordPressAuthenticator

private class CaptureLogs: NSObject, WordPressLoggingDelegate {
    var verboseLogs = [String]()
    var debugLogs = [String]()
    var infoLogs = [String]()
    var warningLogs = [String]()
    var errorLogs = [String]()

    func logError(_ str: String) {
        errorLogs.append(str)
    }

    func logWarning(_ str: String) {
        warningLogs.append(str)
    }

    func logInfo(_ str: String) {
        infoLogs.append(str)
    }

    func logDebug(_ str: String) {
        debugLogs.append(str)
    }

    func logVerbose(_ str: String) {
        verboseLogs.append(str)
    }

}

class LoggingTest: XCTestCase {

    private let logger = CaptureLogs()

    override func setUp() {
        WPAuthenticatorSetLoggingDelegate(logger)
    }

    func testLogging() {
        WPAuthenticatorLogVerbose("This is a verbose log")
        WPAuthenticatorLogVerbose("This is a verbose log %@", "with an argument")
        XCTAssertEqual(self.logger.verboseLogs, ["This is a verbose log", "This is a verbose log with an argument"])

        WPAuthenticatorLogDebug("This is a debug log")
        WPAuthenticatorLogDebug("This is a debug log %@", "with an argument")
        XCTAssertEqual(self.logger.debugLogs, ["This is a debug log", "This is a debug log with an argument"])

        WPAuthenticatorLogInfo("This is an info log")
        WPAuthenticatorLogInfo("This is an info log %@", "with an argument")
        XCTAssertEqual(self.logger.infoLogs, ["This is an info log", "This is an info log with an argument"])

        WPAuthenticatorLogWarning("This is a warning log")
        WPAuthenticatorLogWarning("This is a warning log %@", "with an argument")
        XCTAssertEqual(self.logger.warningLogs, ["This is a warning log", "This is a warning log with an argument"])

        WPAuthenticatorLogError("This is an error log")
        WPAuthenticatorLogError("This is an error log %@", "with an argument")
        XCTAssertEqual(self.logger.errorLogs, ["This is an error log", "This is an error log with an argument"])
    }

    func testNoLogging() {
        WPAuthenticatorSetLoggingDelegate(nil)
        XCTAssertNoThrow(WPAuthenticatorLogInfo("this log should not be printed"))
        XCTAssertEqual(self.logger.infoLogs.count, 0)
    }

}
