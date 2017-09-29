import Foundation
import WordPressShared
import UserNotifications
import CocoaLumberjack



/// The purpose of this helper is to encapsulate all the tasks related to Push Notifications Registration + Handling,
/// including iOS "Actionable" Notifications.
///
final public class PushNotificationsManager: NSObject {

    /// Returns the shared PushNotificationsManager instance.
    ///
    static let shared = PushNotificationsManager()


    /// Stores the Apple's Push Notifications Token
    ///
    var deviceToken: String? {
        get {
            return UserDefaults.standard.string(forKey: Constants.deviceTokenKey) ?? String()
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.deviceTokenKey)
            UserDefaults.standard.synchronize()
        }
    }


    /// Stores the WordPress.com Device identifier
    ///
    var deviceId: String? {
        get {
            return UserDefaults.standard.string(forKey: Constants.deviceIdKey) ?? String()
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.deviceIdKey)
            UserDefaults.standard.synchronize()
        }
    }


    /// Returns the SharedApplication instance. This is meant for Unit Testing purposes.
    ///
    var sharedApplication: UIApplication {
        return UIApplication.shared
    }


    /// Returns the Application Execution State. This is meant for Unit Testing purposes.
    ///
    var applicationState: UIApplicationState {
        return sharedApplication.applicationState
    }


    /// Registers the device for Remote Notifications: Badge + Sounds + Alerts
    ///
    func registerForRemoteNotifications() {
        if sharedApplication.isRunningSimulator() || build(.a8cBranchTest) {
            return
        }

        sharedApplication.registerForRemoteNotifications()
    }



    /// Checks asynchronously if Notifications are enabled in the Device's Settings, or not.
    ///
    func loadAuthorizationStatus(completion: @escaping ((_ authorized: Bool) -> Void)) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let enabled = settings.authorizationStatus == .authorized
                completion(enabled)
            }
        }
    }


    // MARK: - Token Setup

    /// Registers the Device Token agains WordPress.com backend, if there's a default account.
    ///
    /// - Note: Helpshift will also be initialized. The token will be persisted across App Sessions.
    ///
    func registerDeviceToken(_ tokenData: Data) {
        // We want to register Helpshift regardless so that way if a user isn't logged in
        // they can still get push notifications that we replied to their support ticket.
        HelpshiftCore.registerDeviceToken(tokenData)

        // Don't bother registering for WordPress anything if the user isn't logged in
        guard AccountHelper.isDotcomAvailable() else {
            return
        }

        // Token Cleanup
        let newToken = tokenData.hexString

        if deviceToken != newToken {
            DDLogInfo("Device Token has changed! OLD Value: \(String(describing: deviceToken)), NEW value: \(newToken)")
        } else {
            DDLogInfo("Device Token received in didRegisterForRemoteNotificationsWithDeviceToken: \(newToken)")
        }

        deviceToken = newToken

        // Register against WordPress.com
        let noteService = NotificationSettingsService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        noteService.registerDeviceForPushNotifications(newToken, success: { deviceId in
            DDLogVerbose("Successfully registered Device ID \(deviceId) for Push Notifications")
            self.deviceId = deviceId
        }, failure: { error in
            DDLogError("Unable to register Device for Push Notifications: \(error)")
        })
    }


    /// Perform cleanup when the registration for iOS notifications failed
    ///
    /// - Parameter error: Details the reason of failure
    ///
    func registrationDidFail(_ error: NSError) {
        DDLogError("Failed to register for push notifications: \(error)")
        unregisterDeviceToken()
    }


    /// Unregister the device from WordPress.com notifications
    ///
    func unregisterDeviceToken() {
        guard let knownDeviceId = deviceId else {
            return
        }

        let noteService = NotificationSettingsService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        noteService.unregisterDeviceForPushNotifications(knownDeviceId, success: {
            DDLogInfo("Successfully unregistered Device ID \(knownDeviceId) for Push Notifications!")

            self.deviceToken = nil
            self.deviceId = nil
        }, failure: { error in
            DDLogError("Unable to unregister push for Device ID \(knownDeviceId): \(error)")
        })
    }


    // MARK: - Handling Notifications

    /// Handles a Remote Notification
    ///
    /// - Parameters:
    ///     - userInfo: The Notification's Payload
    ///     - completionHandler: A callback, to be executed on completion
    ///
    func handleNotification(_ userInfo: NSDictionary, completionHandler: ((UIBackgroundFetchResult) -> Void)?) {
        DDLogVerbose("Received push notification:\nPayload: \(userInfo)\n")
        DDLogVerbose("Current Application state: \(applicationState.rawValue)")

        // Badge: Update
        if let badgeCountNumber = userInfo.number(forKeyPath: Constants.notificationBadgePath)?.intValue {
            sharedApplication.applicationIconBadgeNumber = badgeCountNumber
        }

        // Badge: Reset
        if userInfo.string(forKey: Constants.notificationTypeKey) == Constants.notificationBadgeResetValue {
            return
        }

        // Analytics
        trackNotification(with: userInfo)

        // Handling!
        let handlers = [ handleHelpshiftNotification,
                         handleAuthenticationNotification,
                         handleInactiveNotification,
                         handleBackgroundNotification ]

        for handler in handlers {
            if handler(userInfo, completionHandler) {
                break
            }
        }
    }
}


// MARK: - Handlers: Should be private, but... are open due to Unit Testing requirements!
//
extension PushNotificationsManager {

    /// Handles a Helpshift Remote Notification
    ///
    /// - Note: This should actually be *private*. BUT: for unit testing purposes (within ObjC code, because of OCMock),
    ///         we'll temporarily keep it as public. Sorry.
    ///
    /// - Parameters:
    ///     - userInfo: The Notification's Payload
    ///     - completionHandler: A callback, to be executed on completion
    ///
    /// - Returns: True when handled. False otherwise
    ///
    func handleHelpshiftNotification(_ userInfo: NSDictionary, completionHandler: ((UIBackgroundFetchResult) -> Void)?) -> Bool {
        guard let origin = userInfo.string(forKey: Constants.notificationOriginKey), origin == Helpshift.originValue else {
            return false
        }

        let rootViewController = sharedApplication.keyWindow?.rootViewController
        let payload = userInfo as! [AnyHashable: Any]
        DispatchQueue.main.async {
            HelpshiftCore.handleRemoteNotification(payload, with: rootViewController)
        }
        WPAnalytics.track(.supportReceivedResponseFromSupport)

        completionHandler?(.newData)

        return true
    }


    /// Handles a WordPress.com Push Authentication Notification
    ///
    /// - Note: This should actually be *private*. BUT: for unit testing purposes (within ObjC code, because of OCMock),
    ///         we'll temporarily keep it as public. Sorry.
    ///
    /// - Parameters:
    ///     - userInfo: The Notification's Payload
    ///     - completionHandler: A callback, to be executed on completion
    ///
    /// - Returns: True when handled. False otherwise
    ///
    func handleAuthenticationNotification(_ userInfo: NSDictionary, completionHandler: ((UIBackgroundFetchResult) -> Void)?) -> Bool {
        // WordPress.com Push Authentication Notification
        // Due to the Background Notifications entitlement, any given Push Notification's userInfo might be received
        // while the app is in BG, and when it's about to become active. In order to prevent UI glitches, let's skip
        // notifications when in BG mode. Still, we don't wanna relay that BG notification!
        //
        let authenticationManager = PushAuthenticationManager()
        guard authenticationManager.isAuthenticationNotification(userInfo) else {
            return false
        }

        if applicationState != .background {
            authenticationManager.handleAuthenticationNotification(userInfo)
        }

        completionHandler?(.newData)

        return true
    }


    /// Handles a Notification while in Inactive Mode
    ///
    /// - Note: This should actually be *private*. BUT: for unit testing purposes (within ObjC code, because of OCMock),
    ///         we'll temporarily keep it as public. Sorry.
    ///
    /// - Parameters:
    ///     - userInfo: The Notification's Payload
    ///     - completionHandler: A callback, to be executed on completion
    ///
    /// - Returns: True when handled. False otherwise
    ///
    func handleInactiveNotification(_ userInfo: NSDictionary, completionHandler: ((UIBackgroundFetchResult) -> Void)?) -> Bool {
        guard applicationState == .inactive else {
            return false
        }

        guard let notificationId = userInfo.number(forKey: Constants.notificationIdentifierKey)?.stringValue else {
            return false
        }

        WPTabBarController.sharedInstance().showNotificationsTabForNote(withID: notificationId)
        completionHandler?(.newData)

        return true
    }


    /// Handles a Notification while in Active OR Background Modes
    ///
    /// - Note: This should actually be *private*. BUT: for unit testing purposes (within ObjC code, because of OCMock),
    ///         we'll temporarily keep it as public. Sorry.
    ///
    /// - Parameters:
    ///     - userInfo: The Notification's Payload
    ///     - completionHandler: A callback, to be executed on completion
    ///
    /// - Returns: True when handled. False otherwise
    ///
    func handleBackgroundNotification(_ userInfo: NSDictionary, completionHandler: ((UIBackgroundFetchResult) -> Void)?) -> Bool {
        guard userInfo.number(forKey: Constants.notificationIdentifierKey)?.stringValue != nil else {
            return false
        }

        guard applicationState == .background else {
            return false
        }

        guard let mediator = NotificationSyncMediator() else {
            completionHandler?(.failed)
            return true
        }

        DDLogInfo("Running Notifications Background Fetch...")

        mediator.sync { error, newData in
            DDLogInfo("Finished Notifications Background Fetch!")

            let result = newData ? UIBackgroundFetchResult.newData : .noData
            completionHandler?(result)
        }

        return true
    }
}


// MARK: - Private Methods
//
private extension PushNotificationsManager {

    /// Tracks a Notification Event
    ///
    /// - Parameter userInfo: The Notification's Payload
    ///
    func trackNotification(with userInfo: NSDictionary) {
        var properties = [String: String]()

        if let noteId = userInfo.number(forKey: Constants.notificationIdentifierKey) {
            properties[Tracking.identifierKey] = noteId.stringValue
        }

        if let type = userInfo.string(forKey: Constants.notificationTypeKey) {
            properties[Tracking.typeKey] = type
        }

        if let theToken = deviceToken {
            properties[Tracking.tokenKey] = theToken
        }

        let event: WPAnalyticsStat = (applicationState == .background) ? .pushNotificationReceived : .pushNotificationAlertPressed
        WPAnalytics.track(event, withProperties: properties)
    }
}


// MARK: - Nested Types
//
private extension PushNotificationsManager {

    enum Constants {
        static let deviceTokenKey = "apnsDeviceToken"
        static let deviceIdKey = "notification_device_id"
        static let notificationBadgePath = "aps.badge"
        static let notificationIdentifierKey = "note_id"
        static let notificationTypeKey = "type"
        static let notificationOriginKey = "origin"
        static let notificationBadgeResetValue = "badge-reset"
    }

    enum Helpshift {
        static let originValue = "helpshift"
    }

    enum Tracking {
        static let identifierKey = "push_notification_note_id"
        static let typeKey = "push_notification_type"
        static let tokenKey = "push_notification_token"
    }
}
