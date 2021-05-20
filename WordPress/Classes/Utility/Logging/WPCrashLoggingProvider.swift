import UIKit
import AutomatticTracks

/// A wrapper around the logging stack – provides shared initialization and configuration for Tracks Crash and Event Logging
struct WPLoggingStack {

    static let QueuedLogsDidChangeNotification = NSNotification.Name("WPCrashLoggingQueueDidChange")

    let crashLogging: CrashLogging
    let eventLogging: EventLogging

    private let eventLoggingDataProvider = EventLoggingDataProvider.fromDDFileLogger(WPLogger.shared().fileLogger)
    private let eventLoggingDelegate = EventLoggingDelegate()

    init() {

        let eventLogging = EventLogging(dataSource: eventLoggingDataProvider, delegate: eventLoggingDelegate)

        self.eventLogging = eventLogging
        self.crashLogging = CrashLogging(dataProvider: WPCrashLoggingDataProvider(), eventLogging: eventLogging)

        /// Upload any remaining files any time the app becomes active
        let willEnterForeground = UIApplication.willEnterForegroundNotification
        NotificationCenter.default.addObserver(forName: willEnterForeground, object: nil, queue: nil, using: self.willEnterForeground)
    }

    func start() throws {
        _ = try crashLogging.start()
    }

    private func willEnterForeground(note: Foundation.Notification) {
        self.eventLogging.uploadNextLogFileIfNeeded()
        DDLogDebug("📜 Resumed encrypted log upload queue due to app entering foreground")
    }
}

struct WPCrashLoggingDataProvider: CrashLoggingDataProvider {
    let sentryDSN: String = ApiCredentials.sentryDSN

    var userHasOptedOut: Bool {
        return UserSettings.userHasOptedOutOfCrashLogging
    }

    var buildType: String = BuildConfiguration.current.rawValue

    var shouldEnableAutomaticSessionTracking: Bool {
        return !UserSettings.userHasOptedOutOfCrashLogging
    }

    var currentUser: TracksUser? {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        guard let account = service.defaultWordPressComAccount() else {
            return nil
        }

        return TracksUser(userID: account.userID.stringValue, email: account.email, username: account.username)
    }
}
