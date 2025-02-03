import Foundation
import WordPressShared
import NSObject_SafeExpectations
import UserNotifications

/// The purpose of this helper is to encapsulate all the tasks related to Push Notifications Registration + Handling,
/// including iOS "Actionable" Notifications.
///
final public class PushNotificationsManager: NSObject {

    // MARK: Initializer

    override init() {
        super.init()
        registerForNotifications()
    }

    /// Returns the shared PushNotificationsManager instance.
    ///
    @objc static let shared = PushNotificationsManager()

    /// Stores the Apple's Push Notifications Token
    ///
    @objc var deviceToken: String? {
        get {
            return UserPersistentStoreFactory.instance().string(forKey: Device.tokenKey) ?? String()
        }
        set {
            UserPersistentStoreFactory.instance().set(newValue, forKey: Device.tokenKey)
        }
    }

    /// Stores the WordPress.com Device identifier
    ///
    @objc var deviceId: String? {
        get {
            return UserPersistentStoreFactory.instance().string(forKey: Device.idKey) ?? String()
        }
        set {
            UserPersistentStoreFactory.instance().set(newValue, forKey: Device.idKey)
        }
    }

    /// Returns the SharedApplication instance. This is meant for Unit Testing purposes.
    ///
    @objc var sharedApplication: UIApplication {
        return UIApplication.shared
    }

    /// Returns the Application Execution State. This is meant for Unit Testing purposes.
    ///
    @objc var applicationState: UIApplication.State {
        return sharedApplication.applicationState
    }

    private var didRegisterForRemoteNotifications = false

    /// Enables or disables remote notifications based on current settings.
    /// Registers the device for Remote Notifications: Badge + Sounds + Alerts
    ///
    @objc func setupRemoteNotifications() {
        guard JetpackNotificationMigrationService.shared.shouldPresentNotifications() else {
            disableRemoteNotifications()
            return
        }

        sharedApplication.registerForRemoteNotifications()
        didRegisterForRemoteNotifications = true
        return
    }

    private func disableRemoteNotifications() {
        if !didRegisterForRemoteNotifications {
            sharedApplication.registerForRemoteNotifications()
        }
        sharedApplication.unregisterForRemoteNotifications()
        sharedApplication.applicationIconBadgeNumber = 0
        didRegisterForRemoteNotifications = false
    }

    /// Checks asynchronously if Notifications are enabled in the Device's Settings, or not.
    ///
    @objc func loadAuthorizationStatus(completion: @escaping ((_ authorized: UNAuthorizationStatus) -> Void)) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    // MARK: - Token Setup

    /// Registers the Device Token agains WordPress.com backend, if there's a default account.
    ///
    /// - Note: Support will also be initialized. The token will be persisted across App Sessions.
    ///
    @objc func registerDeviceToken(_ tokenData: Data) {

        // Don't bother registering for WordPress anything if the user isn't logged in
        guard AccountHelper.isDotcomAvailable() else {
            return
        }

        // Token Cleanup
        let newToken = tokenData.hexString

        // Register device with Zendesk
        ZendeskUtils.setNeedToRegisterDevice(newToken)

        if deviceToken != newToken {
            DDLogInfo("Device Token has changed! OLD Value: \(String(describing: deviceToken)), NEW value: \(newToken)")
        } else {
            DDLogInfo("Device Token received in didRegisterForRemoteNotificationsWithDeviceToken: \(newToken)")
        }

        deviceToken = newToken

        // Register against WordPress.com
        let noteService = NotificationSettingsService(coreDataStack: ContextManager.sharedInstance())

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
    @objc func registrationDidFail(_ error: NSError) {
        DDLogError("Failed to register for push notifications: \(error)")
        unregisterDeviceToken()
    }

    /// Unregister the device from WordPress.com notifications
    ///
    @objc func unregisterDeviceToken() {
        wpAssert(Thread.isMainThread)

        // It's possible for the unregister server call to fail, so always unregister the device locally
        // to fix https://github.com/wordpress-mobile/WordPress-iOS/issues/11779.
        if UIApplication.shared.isRegisteredForRemoteNotifications {
            UIApplication.shared.unregisterForRemoteNotifications()
        }

        guard let knownDeviceId = deviceId else {
            return
        }

        ZendeskUtils.unregisterDevice()

        /// - warning: It's important to use a separate WordPressComRestApi not
        /// managed by `WPAccount` to ensure it can complete its tasks without
        /// the session getting invalidated on logout.
        /// - issue: https://github.com/wordpress-mobile/WordPress-iOS/issues/24040
        let noteService = NotificationSettingsService(
            coreDataStack: ContextManager.sharedInstance(),
            wordPressComRestApi: WordPressComRestApi.defaultV2Api(in: ContextManager.shared.mainContext)
        )

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
    ///     - userInteraction: Indicates if the user interacted with the Push Notification
    ///     - completionHandler: A callback, to be executed on completion
    ///
    @objc func handleNotification(_ userInfo: NSDictionary, userInteraction: Bool = false, completionHandler: ((UIBackgroundFetchResult) -> Void)?) {
        DDLogVerbose("Received push notification:\nPayload: \(userInfo)\n")
        DDLogVerbose("Current Application state: \(applicationState.rawValue)")

        // Badge: Update
        if let badgeCountNumber = userInfo.number(forKeyPath: Notification.badgePath)?.intValue {
            sharedApplication.applicationIconBadgeNumber = badgeCountNumber
        }

        // Badge: Reset
        guard let type = userInfo.string(forKey: Notification.typeKey), type != Notification.badgeResetValue else {
            return
        }

        // Handling!
        let handlers = [handleSupportNotification,
                        handleAuthenticationNotification,
                        handleInactiveNotification,
                        handleBackgroundNotification]

        for handler in handlers {
            if handler(userInfo, userInteraction, completionHandler) {
                break
            }
        }
    }

    /// Tracks a Notification Event
    ///
    /// - Parameter userInfo: The Notification's Payload
    ///
    func trackNotification(with userInfo: NSDictionary, response: UNNotificationResponse? = nil) {
        let event: WPAnalyticsStat? = {
            if let response {
                return response.actionIdentifier == UNNotificationDefaultActionIdentifier ? .pushNotificationAlertPressed : nil
            }
            return .pushNotificationReceived
        }()

        guard let event else {
            return
        }

        var properties = [String: String]()

        if let noteId = userInfo.number(forKey: Notification.identifierKey) {
            properties[Tracking.identifierKey] = noteId.stringValue
        }

        if let type = userInfo.string(forKey: Notification.typeKey) {
            properties[Tracking.typeKey] = type
        }

        if let theToken = deviceToken {
            properties[Tracking.tokenKey] = theToken
        }

        WPAnalytics.track(event, withProperties: properties)
    }

    // MARK: Observing Notifications

    private func registerForNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(setupRemoteNotifications), name: .WPAppUITypeChanged, object: nil)
    }
}

// MARK: - Handlers: Should be private, but... are open due to Unit Testing requirements!
//
extension PushNotificationsManager {

    /// Handles a Support Remote Notification
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
    @objc func handleSupportNotification(_ userInfo: NSDictionary, userInteraction: Bool, completionHandler: ((UIBackgroundFetchResult) -> Void)?) -> Bool {

        guard let type = userInfo.string(forKey: ZendeskUtils.PushNotificationIdentifiers.key),
            type == ZendeskUtils.PushNotificationIdentifiers.type else {
                return false
        }
        DispatchQueue.main.async {
            ZendeskUtils.pushNotificationReceived()
        }

        WPAnalytics.track(.supportReceivedResponseFromSupport)

        if applicationState == .background {
            RootViewCoordinator.sharedPresenter.showMeScreen()
        }

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
    @objc func handleAuthenticationNotification(_ userInfo: NSDictionary, userInteraction: Bool, completionHandler: ((UIBackgroundFetchResult) -> Void)?) -> Bool {
        // WordPress.com Push Authentication Notification
        // Due to the Background Notifications entitlement, any given Push Notification's userInfo might be received
        // while the app is in BG, and when it's about to become active. In order to prevent UI glitches, let's skip
        // notifications when in BG mode. Still, we don't wanna relay that BG notification!
        //
        let authenticationManager = PushAuthenticationManager()
        guard authenticationManager.isAuthenticationNotification(userInfo) else {
            return false
        }

        /// This is a (hopefully temporary) workaround. A Push Authentication must be dealt with whenever:
        ///
        ///     1.  When the user interacts with a Push Notification
        ///     2.  When the App is in Foreground
        ///
        /// As per iOS 13 there are certain scenarios in which the `applicationState` may be `.background` when the user pressed over the Alert.
        /// By means of the `userInteraction` flag, we're just working around the new SDK behavior.
        ///
        /// Proper fix involves a full refactor, and definitely stop checking on `applicationState`, since it's not reliable anymore.
        ///
        if applicationState != .background || userInteraction {
            authenticationManager.handleAuthenticationNotification(userInfo)
        } else {
            DDLogInfo("Skipping handling authentication notification due to app being in background or user not interacting with it.")
        }

        completionHandler?(.newData)

        return true
    }

    /// A handler for a 2fa auth notification approval action.
    ///
    /// - Parameter userInfo: The Notification's Payload
    /// - Returns: True if successful. False otherwise.
    ///
    @objc func handleAuthenticationApprovedAction(_ userInfo: NSDictionary) -> Bool {
        let authenticationManager = PushAuthenticationManager()
        guard authenticationManager.isAuthenticationNotification(userInfo) else {
            return false
        }
        authenticationManager.handleAuthenticationApprovedAction(userInfo)
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
    @objc func handleInactiveNotification(_ userInfo: NSDictionary, userInteraction: Bool, completionHandler: ((UIBackgroundFetchResult) -> Void)?) -> Bool {
        guard applicationState == .inactive else {
            return false
        }

        guard let notificationId = userInfo.number(forKey: Notification.identifierKey)?.stringValue else {
            return false
        }

        RootViewCoordinator.sharedPresenter.showNotificationsTabForNote(withID: notificationId)
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
    @objc func handleBackgroundNotification(_ userInfo: NSDictionary, userInteraction: Bool, completionHandler: ((UIBackgroundFetchResult) -> Void)?) -> Bool {
        guard userInfo.number(forKey: Notification.identifierKey)?.stringValue != nil else {
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

// MARK: - Application Delegate

extension PushNotificationsManager: UIApplicationDelegate {

    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let dictionary = userInfo as NSDictionary
        self.trackNotification(with: dictionary)
        self.handleNotification(dictionary, completionHandler: completionHandler)
    }
}

// MARK: - Nested Types
//
extension PushNotificationsManager {

    enum Device {
        static let tokenKey = "apnsDeviceToken"
        static let idKey = "notification_device_id"
    }

    enum Notification {
        static let badgePath = "aps.badge"
        static let identifierKey = "note_id"
        static let typeKey = "type"
        static let originKey = "origin"
        static let badgeResetValue = "badge-reset"
        static let local = "qs-local-notification"
    }

    enum Tracking {
        static let identifierKey = "push_notification_note_id"
        static let typeKey = "push_notification_type"
        static let tokenKey = "push_notification_token"
    }
}
