import Foundation
import AutomatticTracks
import AutomatticEncryptedLogs
import BuildSettingsKit
import WordPressData

struct EventLoggingDelegate: AutomatticEncryptedLogs.EventLoggingDelegate {

    var shouldUploadLogFiles: Bool {
        guard BuildSettingsEnvironment.current != .test else {
            return false
        }

        return
            !ProcessInfo.processInfo.isLowPowerModeEnabled
            && !UserSettings.userHasOptedOutOfCrashLogging
    }

    func didQueueLogForUpload(_ log: LogFile) {
        NotificationCenter.default.post(name: WPLoggingStack.QueuedLogsDidChangeNotification, object: log)
        Loggers.app.debug("📜 Added log to queue: \(log.uuid)")

        DispatchQueue.main.async {
            guard let eventLogging = WordPressAppDelegate.eventLogging else {
                return
            }

            Loggers.app.debug("📜\t There are \(eventLogging.queuedLogFiles.count) logs in the queue.")
        }
    }

    func didStartUploadingLog(_ log: LogFile) {
        NotificationCenter.default.post(name: WPLoggingStack.QueuedLogsDidChangeNotification, object: log)
        Loggers.app.debug("📜 Started uploading encrypted log: \(log.uuid)")
    }

    func didFinishUploadingLog(_ log: LogFile) {
        NotificationCenter.default.post(name: WPLoggingStack.QueuedLogsDidChangeNotification, object: log)
        Loggers.app.debug("📜 Finished uploading encrypted log: \(log.uuid)")

        DispatchQueue.main.async {
            guard let eventLogging = WordPressAppDelegate.eventLogging else {
                return
            }

            Loggers.app.debug("📜\t There are \(eventLogging.queuedLogFiles.count) logs remaining in the queue.")
        }
    }

    func uploadFailed(withError error: Error, forLog log: LogFile) {
        NotificationCenter.default.post(name: WPLoggingStack.QueuedLogsDidChangeNotification, object: log)
        Loggers.app.error("📜 Error uploading encrypted log: \(log.uuid)")
        Loggers.app.error("📜\t\(error.localizedDescription)")

        let nserror = error as NSError
        Loggers.app.error("📜\t Code: \(nserror.code)")
        if let details = nserror.localizedFailureReason {
            Loggers.app.error("📜\t Details: \(details)")
        }
    }
}
