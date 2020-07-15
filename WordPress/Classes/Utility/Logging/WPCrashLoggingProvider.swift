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
        WPCrashLoggingProvider.userHasOptedOut
    }

    var currentUser: TracksUser? {

        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        guard let account = service.defaultWordPressComAccount() else {
            return nil
        }

        return TracksUser(userID: account.userID.stringValue, email: account.email, username: account.username)
    }

    var loggingUploadDelegate = EventLoggingDelegate()
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
