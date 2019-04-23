import Foundation
import Sentry

fileprivate let UserOptedOutKey = "crashlytics_opt_out"

class WPCrashLogging {

    fileprivate static let sharedInstance = WPCrashLogging()

    static func start() {
        // Create a Sentry client and start crash handler
        do {

            Client.shared = try Client(dsn: ApiCredentials.sentryDSN())

            // Store lots of breadcrumbs to trace errors
            Client.shared?.breadcrumbs.maxBreadcrumbs = 500

            // Automatically track screen transitions
            Client.shared?.enableAutomaticBreadcrumbTracking()

            // Automatically track low-memory events
            Client.shared?.trackMemoryPressureAsEvent()

            try Client.shared?.startCrashHandler()

            // Override event serialization to append the logs, if needed
            Client.shared?.beforeSerializeEvent = sharedInstance.beforeSerializeEvent
            Client.shared?.shouldSendEvent = sharedInstance.shouldSendEvent

        } catch let error {
            print("\(error)")
        }
    }

    func beforeSerializeEvent(_ event: Event) {
        event.extra = ["b": "c"]
    }

    func shouldSendEvent(_ event: Event?) -> Bool {
        return !userHasOptedOut
    }

    var userHasOptedOut: Bool = false

    static var userHasOptedOut: Bool {
        get {
            let value = UserDefaults.standard.bool(forKey: UserOptedOutKey)
            sharedInstance.userHasOptedOut = value

            return value
        }
        set(didOptIn) {
            UserDefaults.standard.set(didOptIn, forKey: UserOptedOutKey)
            sharedInstance.userHasOptedOut = didOptIn

            sharedInstance.applyUserTrackingPreferences()
        }
    }

    static func crash() {
        Client.shared?.crash()
    }
}

// Manual Error Logging
extension WPCrashLogging {
    static func logError(_ error: Error) {
        let event = Event(level: .error)
        event.message = error.localizedDescription

        Client.shared?.appendStacktrace(to: event)
        Client.shared?.send(event: event)
    }
}

// User Tracking
extension WPCrashLogging {

    func applyUserTrackingPreferences() {

        if !WPCrashLogging.userHasOptedOut {
            enableUserTracking()
        }
        else {
            disableUserTracking()
        }

        Client.shared?.releaseName = releaseName
        Client.shared?.environment = buildType
    }

    func enableUserTracking() {

        let context = ContextManager.sharedInstance().mainContext
        let accountService = AccountService(managedObjectContext: context)
        let blogService = BlogService(managedObjectContext: context)
        let defaultAccount = accountService.defaultWordPressComAccount()

        let userID = defaultAccount?.userID.intValue ?? 0
        let username = defaultAccount?.username ?? "anonymous"
        let displayName = defaultAccount?.displayName ?? "anon"

        let user = Sentry.User(userId: username)
        user.email = defaultAccount?.email
        user.extra = [
            "display_name": displayName,
            "user_id": userID,
            "number_of_blogs": blogService.blogCountForAllAccounts(),
            "logged_in": defaultAccount == nil,
            "connected_to_dotcom": defaultAccount == nil,
        ]

        Client.shared?.user = user
    }

    func disableUserTracking() {
        Client.shared?.clearContext()
    }

    var releaseName: String {
        let bundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String

        return "\(bundleVersion) (\(buildNumber)"
    }

    var buildType: String {
        return Mirror(reflecting: BuildConfiguration.current).children.first?.label ?? "unknown"
    }
}
