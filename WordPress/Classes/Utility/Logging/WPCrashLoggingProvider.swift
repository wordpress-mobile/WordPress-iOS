import Foundation
import AutomatticTracks

fileprivate let UserOptedOutKey = "crashlytics_opt_out"

class WPCrashLoggingProvider: CrashLoggingDataProvider {

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
