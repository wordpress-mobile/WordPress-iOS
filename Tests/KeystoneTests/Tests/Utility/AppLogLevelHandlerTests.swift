import CocoaLumberjack
import Foundation
import Logging
import os
import Testing
@testable import WordPress

struct AppLogLevelHandlerTests {

    private let appLogLevel = AppLogLevel(.info)
    private let recorder = RecordingLogHandler()

    private var logger: Logging.Logger {
        Logging.Logger(label: "test") { _ in
            AppLogLevelHandler(handler: recorder, appLogLevel: appLogLevel)
        }
    }

    @Test func dropsMessagesBelowTheLevel() {
        logger.debug("dropped")
        logger.info("kept")

        #expect(recorder.messages == ["kept"])
    }

    @Test func existingLoggersFollowLevelChanges() {
        let logger = self.logger
        logger.debug("dropped")

        appLogLevel.current = .trace
        logger.trace("kept")

        appLogLevel.current = .info
        logger.debug("dropped")

        #expect(recorder.messages == ["kept"])
    }

    @Test func doesNotBuildTheMessageWhenItIsDropped() {
        var built = false
        logger.debug("\({ built = true; return "dropped" }())")

        #expect(!built)
    }

    @Test func settingTheLevelOnOneLoggerOnlyAffectsThatLogger() {
        var verbose = logger
        verbose.logLevel = .trace

        verbose.trace("kept")
        logger.trace("dropped")

        #expect(recorder.messages == ["kept"])
    }

    @Test(arguments: [
        (DDLogLevel.off, Logging.Logger.Level.error),
        (.error, .error),
        (.warning, .warning),
        (.info, .info),
        (.debug, .debug),
        (.verbose, .trace),
        (.all, .trace)
    ])
    func convertsCocoaLumberjackLevels(level: DDLogLevel, expected: Logging.Logger.Level) {
        #expect(Logging.Logger.Level(level) == expected)
    }
}

struct AppLoggingWiringTests {

    @Test func extraDebugLevelsReachCocoaLumberjack() {
        let log = RecordingDDLogger()
        DDLog.add(log, with: .all)
        defer { DDLog.remove(log) }

        let appLogLevel = AppLogLevel(.info)
        let logger = Logging.Logger(label: "test") { label in
            AppLogLevelHandler.makeAppHandler(label: label, appLogLevel: appLogLevel)
        }
        let token = UUID().uuidString

        logger.debug("\(token) debug at info")
        logger.info("\(token) info at info")

        appLogLevel.current = .trace
        logger.debug("\(token) debug at trace")
        logger.trace("\(token) trace at trace")

        DDLog.flushLog()

        #expect(
            log.messages(containing: token) == [
                "\(token) info at info",
                "\(token) debug at trace",
                "\(token) trace at trace"
            ]
        )
    }

    @Test func setLogLevelUpdatesTheSharedLevel() {
        defer { WPLogger.configureLoggerLevelWithExtraDebug() }

        WordPressAppDelegate.setLogLevel(.verbose)
        #expect(AppLogLevel.shared.current == .trace)

        WordPressAppDelegate.setLogLevel(.info)
        #expect(AppLogLevel.shared.current == .info)
    }
}

private final class RecordingLogHandler: LogHandler, @unchecked Sendable {
    var logLevel: Logging.Logger.Level = .trace
    var metadata: Logging.Logger.Metadata = [:]

    private let recorded = OSAllocatedUnfairLock<[String]>(initialState: [])

    var messages: [String] { recorded.withLock { $0 } }

    subscript(metadataKey key: String) -> Logging.Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    func log(event: LogEvent) {
        recorded.withLock { $0.append(event.message.description) }
    }
}

private final class RecordingDDLogger: DDAbstractLogger, @unchecked Sendable {
    private let recorded = OSAllocatedUnfairLock<[String]>(initialState: [])

    func messages(containing token: String) -> [String] {
        recorded.withLock { $0.filter { $0.contains(token) } }
    }

    override func log(message logMessage: DDLogMessage) {
        recorded.withLock { $0.append(logMessage.message) }
    }
}
