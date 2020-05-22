import UIKit
import AutomatticTracks

fileprivate let UserOptedOutKey = "crashlytics_opt_out"

class WPCrashLoggingProvider: CrashLoggingDataProvider {

    static let QueuedLogsDidChangeNotification = NSNotification.Name("WPCrashLoggingQueueDidChange")

    init() {
        /// Upload any remaining files any time the app becomes active
        let willEnterForeground = UIApplication.willEnterForegroundNotification
        NotificationCenter.default.addObserver(forName: willEnterForeground, object: nil, queue: nil) { note in
            CrashLogging.eventLogging?.uploadNextLogFileIfNeeded()
            DDLogDebug("📜 Resumed encrypted log upload queue due to app entering foreground")
        }
    }

    var sentryDSN: String = ApiCredentials.sentryDSN()

    var buildType: String = BuildConfiguration.current.rawValue

    var userHasOptedOut: Bool {
        return UserDefaults.standard.bool(forKey: UserOptedOutKey)
    }

    var currentUser: TracksUser? {

        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        guard let account = service.defaultWordPressComAccount() else {
            return nil
        }

        return TracksUser(userID: account.userID.stringValue, email: account.email, username: account.username)
    }

    var loggingUploadDelegate: EventLoggingDelegate {
        return self
    }
}

extension WPCrashLoggingProvider: EventLoggingDelegate {
    var shouldUploadLogFiles: Bool {
        return
            !ProcessInfo.processInfo.isLowPowerModeEnabled
            && !self.userHasOptedOut
    }

    func didQueueLogForUpload(_ log: LogFile) {
        NotificationCenter.default.post(name: WPCrashLoggingProvider.QueuedLogsDidChangeNotification, object: log)
        DDLogDebug("📜 Added log to queue: \(log.uuid)")

        if let eventLogging = CrashLogging.eventLogging {
            DDLogDebug("📜\t There are \(eventLogging.queuedLogFiles.count) logs in the queue.")
        }
    }

    func didStartUploadingLog(_ log: LogFile) {
        NotificationCenter.default.post(name: WPCrashLoggingProvider.QueuedLogsDidChangeNotification, object: log)
        DDLogDebug("📜 Started uploading encrypted log: \(log.uuid)")
    }

    func didFinishUploadingLog(_ log: LogFile) {
        NotificationCenter.default.post(name: WPCrashLoggingProvider.QueuedLogsDidChangeNotification, object: log)
        DDLogDebug("📜 Finished uploading encrypted log: \(log.uuid)")
        if let eventLogging = CrashLogging.eventLogging {
            DDLogDebug("📜\t There are \(eventLogging.queuedLogFiles.count) logs remaining in the queue.")
        }
    }

    func uploadFailed(withError error: Error, forLog log: LogFile) {
        NotificationCenter.default.post(name: WPCrashLoggingProvider.QueuedLogsDidChangeNotification, object: log)
        DDLogError("📜 Error uploading encrypted log: \(log.uuid)")
        DDLogError("📜\t\(error.localizedDescription)")

        let nserror = error as NSError
        DDLogError("📜\t Code: \(nserror.code)")
        if let details = nserror.localizedFailureReason {
            DDLogError("📜\t Details: \(details)")
        }
    }
}

struct EventLoggingDataProvider: EventLoggingDataSource {

    typealias LogFilesCallback = (() -> [URL])

    /// A block that returns all existing log files
    private let fetchLogFiles: LogFilesCallback?

    /// Initialize the data provider using a block.
    ///
    /// Because the most recent log file path can change at runtime (for example; if a given session spans a day boundary the logging system may roll the
    /// log file transparently in the background) we must determine which is the most recent log file each time we access it.
    init(_ block: @escaping LogFilesCallback) {
        self.fetchLogFiles = block
    }

    /// The key used to encrypt log files
    let loggingEncryptionKey: String = ApiCredentials.encryptedLogKey()

    /// The previous session log will be the most recent one, because they're split by day
    var previousSessionLogPath: URL? {
        return fetchLogFiles?().first
    }

    /// The current session log will always be the most recent one
    var currentSessionLogPath: URL? {
        return fetchLogFiles?().first
    }



    static func fromDDFileLogger(_ logger: DDFileLogger) -> EventLoggingDataSource {
        EventLoggingDataProvider {
            logger.logFileManager.sortedLogFileInfos.map {
                URL(fileURLWithPath: $0.filePath)
            }
        }
    }
}

// MARK: - Static Property
extension WPCrashLoggingProvider {

    static var userHasOptedOut: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UserOptedOutKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserOptedOutKey)
        }
    }
}
