import AutomatticEncryptedLogs
import Foundation
import WordPressData

/// Queues the application logs for encrypted upload, and returns the IDs the support team reads them with.
///
/// The logs themselves never leave the device unencrypted: they're uploaded in the background, and the reply only
/// carries their IDs.
struct EncryptedLogUploader: Sendable {

    enum Failure: Error, LocalizedError {
        /// The app has no encrypted logging, which only happens when the logging stack failed to start.
        case loggingUnavailable

        var errorDescription: String? {
            NSLocalizedString(
                "com.jetpack.support.unified.logs.unavailable",
                value: "The application logs aren't available right now.",
                comment: "Shown when a support reply can't be sent because its logs couldn't be uploaded."
            )
        }
    }

    private let logFiles: @MainActor @Sendable () -> [URL]
    private let enqueue: @MainActor @Sendable (LogFile) throws -> Void
    private let hasOptedOutOfCrashLogging: @MainActor @Sendable () -> Bool

    init(
        logFiles: @escaping @MainActor @Sendable () -> [URL] = {
            WPLogger.shared().fileLogger
                .logFileManager
                .sortedLogFileInfos
                .map { URL(fileURLWithPath: $0.filePath) }
        },
        enqueue: @escaping @MainActor @Sendable (LogFile) throws -> Void = { log in
            guard let eventLogging = WordPressAppDelegate.eventLogging else {
                throw Failure.loggingUnavailable
            }
            try eventLogging.enqueueLogForUpload(log: log)
        },
        hasOptedOutOfCrashLogging: @escaping @MainActor @Sendable () -> Bool = {
            UserSettings.userHasOptedOutOfCrashLogging
        }
    ) {
        self.logFiles = logFiles
        self.enqueue = enqueue
        self.hasOptedOutOfCrashLogging = hasOptedOutOfCrashLogging
    }

    /// Queues every log file on the device, newest first, and returns their IDs.
    ///
    /// Returns no ID when the user opted out of sharing logs, so the reply is still sent without them.
    @MainActor
    func uploadLogs() throws -> [String] {
        guard !hasOptedOutOfCrashLogging() else {
            Loggers.app.info("Application logs not attached to the support reply: the user opted out")
            return []
        }

        return try logFiles()
            .map { url in
                let log = LogFile(url: url)
                try enqueue(log)
                return log.uuid
            }
    }
}
