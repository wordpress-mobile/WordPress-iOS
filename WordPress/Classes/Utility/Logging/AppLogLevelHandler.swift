import CocoaLumberjack
import CocoaLumberjackSwiftLogBackend
import Foundation
import Logging
import os

/// The swift-log level shared by every logger in the app.
///
/// A `Logger` is a value that keeps its own copy of its handler, so the "extra debug" setting can't reach
/// the loggers that already exist by setting their `logLevel`. They read the level from here instead.
final class AppLogLevel: Sendable {
    static let shared = AppLogLevel(.info)

    private let level: OSAllocatedUnfairLock<Logging.Logger.Level>

    var current: Logging.Logger.Level {
        get { level.withLock { $0 } }
        set { level.withLock { $0 = newValue } }
    }

    init(_ level: Logging.Logger.Level) {
        self.level = OSAllocatedUnfairLock(initialState: level)
    }
}

/// Filters messages by an ``AppLogLevel``, then passes them to `handler`.
struct AppLogLevelHandler: LogHandler {
    private var handler: any LogHandler
    private let appLogLevel: AppLogLevel

    /// Set when code calls `logger.logLevel = …` on one logger. Only that logger stops following ``AppLogLevel``.
    private var overriddenLogLevel: Logging.Logger.Level?

    init(handler: any LogHandler, appLogLevel: AppLogLevel = .shared) {
        self.handler = handler
        self.appLogLevel = appLogLevel
    }

    /// The handler behind every logger in the app.
    ///
    /// The CocoaLumberjack handler is created at `.trace` so that the filtering happens only here.
    static func makeAppHandler(label: String, appLogLevel: AppLogLevel = .shared) -> AppLogLevelHandler {
        let ddLogHandlerFactory: (String) -> LogHandler = DDLogHandler.handlerFactory(defaultLogLevel: .trace)
        return AppLogLevelHandler(
            handler: MultiplexLogHandler([
                ddLogHandlerFactory(label),
                ExtensiveLogger(label: label)
            ]),
            appLogLevel: appLogLevel
        )
    }

    var logLevel: Logging.Logger.Level {
        get { overriddenLogLevel ?? appLogLevel.current }
        set { overriddenLogLevel = newValue }
    }

    var metadata: Logging.Logger.Metadata {
        get { handler.metadata }
        set { handler.metadata = newValue }
    }

    var metadataProvider: Logging.Logger.MetadataProvider? {
        get { handler.metadataProvider }
        set { handler.metadataProvider = newValue }
    }

    subscript(metadataKey key: String) -> Logging.Logger.Metadata.Value? {
        get { handler[metadataKey: key] }
        set { handler[metadataKey: key] = newValue }
    }

    func log(event: LogEvent) {
        handler.log(event: event)
    }
}

extension Logging.Logger.Level {
    /// The swift-log level that lets through the same messages as a CocoaLumberjack level.
    ///
    /// swift-log has no level for "off", so `.off` keeps the most serious messages.
    init(_ level: DDLogLevel) {
        switch level {
        case .off, .error: self = .error
        case .warning: self = .warning
        case .info: self = .info
        case .debug: self = .debug
        case .verbose, .all: self = .trace
        @unknown default: self = .info
        }
    }
}
