import XCTest

@testable import WordPressShared

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
        WPSharedSetLoggingDelegate(logger)
    }

    func testLogging() {
        WPSharedLogVerbose("This is a verbose log")
        WPSharedLogVerbose("This is a verbose log %@", "with an argument")
        XCTAssertEqual(self.logger.verboseLogs, ["This is a verbose log", "This is a verbose log with an argument"])

        WPSharedLogDebug("This is a debug log")
        WPSharedLogDebug("This is a debug log %@", "with an argument")
        XCTAssertEqual(self.logger.debugLogs, ["This is a debug log", "This is a debug log with an argument"])

        WPSharedLogInfo("This is an info log")
        WPSharedLogInfo("This is an info log %@", "with an argument")
        XCTAssertEqual(self.logger.infoLogs, ["This is an info log", "This is an info log with an argument"])

        WPSharedLogWarning("This is a warning log")
        WPSharedLogWarning("This is a warning log %@", "with an argument")
        XCTAssertEqual(self.logger.warningLogs, ["This is a warning log", "This is a warning log with an argument"])

        WPSharedLogError("This is an error log")
        WPSharedLogError("This is an error log %@", "with an argument")
        XCTAssertEqual(self.logger.errorLogs, ["This is an error log", "This is an error log with an argument"])
    }

    func testNoLogging() {
        WPSharedSetLoggingDelegate(nil)
        XCTAssertNoThrow(WPSharedLogInfo("this log should not be printed"))
        XCTAssertEqual(self.logger.infoLogs.count, 0)
    }

}
