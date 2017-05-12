import Foundation
import Mixpanel
import WordPressComAnalytics
import UserNotifications



/// The purpose of this helper is to encapsulate all the tasks related to Push Notifications Registration + Handling,
/// including iOS "Actionable" Notifications.
///
final public class PushNotificationsManager: NSObject {
    // MARK: - Public Properties


    /// Returns the shared PushNotificationsManager instance.
    ///
    static let sharedInstance = PushNotificationsManager()


    /// Stores the Apple's Push Notifications Token
    ///
    var deviceToken: String? {
        get {
            return UserDefaults.standard.string(forKey: deviceTokenKey) ?? String()
        }
        set {
            standardUserDefaults.set(newValue, forKey: deviceTokenKey)
            standardUserDefaults.synchronize()
        }
    }


    /// Stores the WordPress.com Device identifier
    ///
    var deviceId: String? {
        get {
            return standardUserDefaults.string(forKey: deviceIdKey) ?? String()
        }
        set {
            standardUserDefaults.set(newValue, forKey: deviceIdKey)
            standardUserDefaults.synchronize()
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




    // MARK: - Private Properties


    /// Returns the Standard User Defaults.
    ///
    fileprivate var standardUserDefaults: UserDefaults {
        return UserDefaults.standard
    }




    // MARK: - Public Methods: Registration


    /// Registers the device for Remote Notifications: Badge + Sounds + Alerts
    ///
    func registerForRemoteNotifications() {
        if sharedApplication.isRunningSimulator() || build(.buddy) {
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



    /// Registers the Device Token agains WordPress.com backend, if there's a default account.
    ///
    /// - Note: Both Helpshift and Mixpanel will also be initialized. The token will be persisted across App Sessions.
    ///
    func registerDeviceToken(_ tokenData: Data) {
        // We want to register Helpshift regardless so that way if a user isn't logged in
        // they can still get push notifications that we replied to their support ticket.
        HelpshiftCore.registerDeviceToken(tokenData)
        Mixpanel.sharedInstance()?.people.addPushDeviceToken(tokenData)

        // Don't bother registering for WordPress anything if the user isn't logged in
        guard AccountHelper.isDotcomAvailable() else {
            return
        }

        // Token Cleanup
        let newToken = parseTokenFromAppleData(tokenData)

        if deviceToken != newToken {
            DDLogSwift.logInfo("Device Token has changed! OLD Value: \(String(describing: deviceToken)), NEW value: \(newToken)")
        } else {
            DDLogSwift.logInfo("Device Token received in didRegisterForRemoteNotificationsWithDeviceToken: \(newToken)")
        }

        deviceToken = newToken

        // Register against WordPress.com
        let noteService = NotificationSettingsService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        noteService.registerDeviceForPushNotifications(newToken, success: { deviceId in
            DDLogSwift.logVerbose("Successfully registered Device ID \(deviceId) for Push Notifications")
            self.deviceId = deviceId
        }, failure: { error in
            DDLogSwift.logError("Unable to register Device for Push Notifications: \(error)")
        })
    }



    /// Perform cleanup when the registration for iOS notifications failed
    ///
    /// - Parameter error: Details the reason of failure
    ///
    func registrationDidFail(_ error: NSError) {
        DDLogSwift.logError("Failed to register for push notifications: \(error)")
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
            DDLogSwift.logInfo("Successfully unregistered Device ID \(knownDeviceId) for Push Notifications!")

            self.deviceToken = nil
            self.deviceId = nil
        }, failure: { error in
            DDLogSwift.logError("Unable to unregister push for Device ID \(knownDeviceId): \(error)")
        })
    }




    // MARK: - Public Methods: Handlers


    /// Handles a Remote Notification
    ///
    /// - Parameters:
    ///     - userInfo: The Notification's Payload
    ///     - completionHandler: A callback, to be executed on completion
    ///
    func handleNotification(_ userInfo: NSDictionary, completionHandler: ((UIBackgroundFetchResult) -> Void)?) {
        DDLogSwift.logVerbose("Received push notification:\nPayload: \(userInfo)\n")
        DDLogSwift.logVerbose("Current Application state: \(applicationState.rawValue)")

        // Badge: Update
        if let badgeCountNumber = userInfo.number(forKeyPath: notificationBadgePath)?.intValue {
            sharedApplication.applicationIconBadgeNumber = badgeCountNumber
        }

        // Badge: Reset
        if let type = userInfo.string(forKey: notificationTypeKey), type == notificationBadgeResetValue {
            return
        }

        // Analytics
        trackNotificationWithUserInfo(userInfo)

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




    // MARK: - Private Methods: Handlers


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
        guard let origin = userInfo.string(forKey: notificationOriginKey), origin == helpshiftOriginValue else {
            return false
        }

        let rootViewController = sharedApplication.keyWindow?.rootViewController
        let payload = userInfo as! [AnyHashable: Any]

        HelpshiftCore.handleRemoteNotification(payload, with: rootViewController)
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
        guard authenticationManager.isPushAuthenticationNotification(userInfo) else {
            return false
        }

        if applicationState != .background {
            authenticationManager.handlePushAuthenticationNotification(userInfo)
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

        guard let notificationId = userInfo.number(forKey: notificationIdentifierKey)?.stringValue else {
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
        guard userInfo.number(forKey: notificationIdentifierKey)?.stringValue != nil else {
            return false
        }

        guard applicationState == .background else {
            return false
        }

        guard let mediator = NotificationSyncMediator() else {
            completionHandler?(.failed)
            return true
        }

        DDLogSwift.logInfo("Running Notifications Background Fetch...")

        mediator.sync { error, newData in
            DDLogSwift.logInfo("Finished Notifications Background Fetch!")

            let result = newData ? UIBackgroundFetchResult.newData : .noData
            completionHandler?(result)
        }

        return true
    }




    // MARK: - Private Methods: Helpers


    /// Tracks a Notification Event
    ///
    /// - Parameter userInfo: The Notification's Payload
    ///
    fileprivate func trackNotificationWithUserInfo(_ userInfo: NSDictionary) {
        var properties = [String: String]()

        if let noteId = userInfo.number(forKey: notificationIdentifierKey) {
            properties[trackingIdentifierKey] = noteId.stringValue
        }

        if let type = userInfo.string(forKey: notificationTypeKey) {
            properties[trackingTypeKey] = type
        }

        if let theToken = deviceToken {
            properties[trackingTokenKey] = theToken
        }

        let event: WPAnalyticsStat = (applicationState == .background) ? .pushNotificationReceived : .pushNotificationAlertPressed
        WPAnalytics.track(event, withProperties: properties)
    }



    /// Parses the NSData sent by Apple's Push Service, and extracts the Device Token
    ///
    fileprivate func parseTokenFromAppleData(_ tokenData: Data) -> String {
        return tokenData.hexString
    }




    // MARK: - Private Constants: Device Keys
    fileprivate let deviceTokenKey              = "apnsDeviceToken"
    fileprivate let deviceIdKey                 = "notification_device_id"

    // MARK: - Private Constants: Notification Keys
    fileprivate let notificationBadgePath       = "aps.badge"
    fileprivate let notificationIdentifierKey   = "note_id"
    fileprivate let notificationTypeKey         = "type"
    fileprivate let notificationOriginKey       = "origin"
    fileprivate let notificationBadgeResetValue = "badge-reset"

    // MARK: - Private Constants: Helpshift
    fileprivate let helpshiftOriginValue        = "helpshift"

    // MARK: - Private Constants: Tracking
    fileprivate let trackingIdentifierKey       = "push_notification_note_id"
    fileprivate let trackingTypeKey             = "push_notification_type"
    fileprivate let trackingTokenKey            = "push_notification_token"
}
