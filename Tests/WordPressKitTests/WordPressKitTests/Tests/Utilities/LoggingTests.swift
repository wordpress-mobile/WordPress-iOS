import XCTest

@testable import WordPressKit

private class CaptureLogs: NSObject, WordPressKitLoggingDelegate {
    private(set) var verboseLogs = [String]()
    private(set) var debugLogs = [String]()
    private(set) var infoLogs = [String]()
    private(set) var warningLogs = [String]()
    private(set)var errorLogs = [String]()

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
        WPKitSetLoggingDelegate(logger)
    }

    func testLogging() {
        WPKitLogVerbose("This is a verbose log")
        WPKitLogVerbose("This is a verbose log %@", "with an argument")
        XCTAssertEqual(self.logger.verboseLogs, ["This is a verbose log", "This is a verbose log with an argument"])

        WPKitLogDebug("This is a debug log")
        WPKitLogDebug("This is a debug log %@", "with an argument")
        XCTAssertEqual(self.logger.debugLogs, ["This is a debug log", "This is a debug log with an argument"])

        WPKitLogInfo("This is an info log")
        WPKitLogInfo("This is an info log %@", "with an argument")
        XCTAssertEqual(self.logger.infoLogs, ["This is an info log", "This is an info log with an argument"])

        WPKitLogWarning("This is a warning log")
        WPKitLogWarning("This is a warning log %@", "with an argument")
        XCTAssertEqual(self.logger.warningLogs, ["This is a warning log", "This is a warning log with an argument"])

        WPKitLogError("This is an error log")
        WPKitLogError("This is an error log %@", "with an argument")
        XCTAssertEqual(self.logger.errorLogs, ["This is an error log", "This is an error log with an argument"])
    }

    func testNoLogging() {
        WPKitSetLoggingDelegate(nil)
        XCTAssertNoThrow(WPKitLogInfo("this log should not be printed"))
        XCTAssertEqual(self.logger.infoLogs.count, 0)
    }

}
