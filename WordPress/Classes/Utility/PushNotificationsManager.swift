import Foundation
import Mixpanel
import WordPressComAnalytics



/// These notifications are sent when the user Registers / Unregisters for Push Notifications.
///
public let NotificationsManagerDidRegisterDeviceToken   = "NotificationsManagerDidRegisterDeviceToken"
public let NotificationsManagerDidUnregisterDeviceToken = "NotificationsManagerDidUnregisterDeviceToken"



/// The purpose of this helper is to encapsulate all the tasks related to Push Notifications Registration + Handling, 
/// including iOS "Actionable" Notifications.
///
final public class PushNotificationsManager : NSObject
{
    // MARK: - Public Properties
    
    
    /// Returns the shared PushNotificationsManager instance.
    ///
    static let sharedInstance = PushNotificationsManager()
    
    
    /// Stores the Apple's Push Notifications Token
    ///
    var deviceToken : String? {
        get {
            return NSUserDefaults.standardUserDefaults().stringForKey(deviceTokenKey) ?? String()
        }
        set {
            standardUserDefaults.setObject(newValue, forKey: deviceTokenKey)
            standardUserDefaults.synchronize()
        }
    }

    
    /// Stores the WordPress.com Device identifier
    ///
    var deviceId : String? {
        get {
            return standardUserDefaults.stringForKey(deviceIdKey) ?? String()
        }
        set {
            standardUserDefaults.setObject(newValue, forKey: deviceIdKey)
            standardUserDefaults.synchronize()
        }
    }
    
    
    /// Returns the SharedApplication instance. This is meant for Unit Testing purposes.
    ///
    var sharedApplication : UIApplication {
        return UIApplication.sharedApplication()
    }
    
    
    /// Returns the Application Execution State. This is meant for Unit Testing purposes.
    ///
    var applicationState : UIApplicationState {
        return sharedApplication.applicationState
    }
    
    
    
    
    // MARK: - Private Properties
    
    
    /// Returns the Standard User Defaults.
    ///
    private var standardUserDefaults : NSUserDefaults {
        return NSUserDefaults.standardUserDefaults()
    }
    
    
    /// Indicates whether there is a default WordPress.com accounta available, or not
    ///
    private var wordPressDotComAvailable : Bool {
        let accountService = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        return accountService.defaultWordPressComAccount() != nil
    }
    
    
    
    
    // MARK: - Public Methods: Registration
    
    
    /// Registers the device for Remote Notifications: Badge + Sounds + Alerts
    ///
    func registerForRemoteNotifications() {
        if sharedApplication.isRunningSimulator() || sharedApplication.isAlphaBuild() {
            return;
        }
        
        sharedApplication.registerForRemoteNotifications()
    }
    
    
    
    /// Indicates whether Push Notifications are enabled in Settings.app, or not.
    func notificationsEnabledInDeviceSettings() -> Bool {
        return (sharedApplication.currentUserNotificationSettings()?.types ?? .None) != .None
    }
    
    
    
    /// Registers the Device Token agains WordPress.com backend, if there's a default account.
    ///
    /// - Note: Both Helpshift and Mixpanel will also be initialized. The token will be persisted across App Sessions.
    ///
    func registerDeviceToken(tokenData: NSData) {
        // We want to register Helpshift regardless so that way if a user isn't logged in
        // they can still get push notifications that we replied to their support ticket.
        HelpshiftCore.registerDeviceToken(tokenData)
        Mixpanel.sharedInstance().people.addPushDeviceToken(tokenData)

        // Don't bother registering for WordPress anything if the user isn't logged in
        if !wordPressDotComAvailable {
            return
        }

        // Token Cleanup
        let newToken = parseTokenFromAppleData(tokenData)
        
        if deviceToken != newToken {
            DDLogSwift.logInfo("Device Token has changed! OLD Value: \(deviceToken), NEW value: \(newToken)")
        } else {
            DDLogSwift.logInfo("Device Token received in didRegisterForRemoteNotificationsWithDeviceToken: \(newToken)")
        }
        
        deviceToken = newToken
        
        // Register against WordPress.com
        let noteService = NotificationsService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        
        noteService.registerDeviceForPushNotifications(newToken,
            success: { (deviceId: String) -> () in
                DDLogSwift.logVerbose("Successfully registered Device ID \(deviceId) for Push Notifications")
                self.deviceId = deviceId
            },
            failure: { (error: NSError) -> Void in
                DDLogSwift.logError("Unable to register Device for Push Notifications: \(error)")
            })
        
        // Notify Listeners
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.postNotificationName(NotificationsManagerDidRegisterDeviceToken, object: newToken)
    }
    
    
    
    /// Perform cleanup when the registration for iOS notifications failed
    ///
    /// - Parameters:
    ///     - error: Details the reason of failure
    ///
    func registrationDidFail(error: NSError) {
        DDLogSwift.logError("Failed to register for push notifications: \(error)")
        unregisterDeviceToken()
    }
    
    
    
    /// Unregister the device from WordPress.com notifications
    ///
    func unregisterDeviceToken() {
        guard let knownDeviceId = deviceId else {
            return
        }
        
        let noteService = NotificationsService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        
        noteService.unregisterDeviceForPushNotifications(knownDeviceId,
            success: {
                DDLogSwift.logInfo("Successfully unregistered Device ID \(knownDeviceId) for Push Notifications!")
                
                self.deviceToken = nil
                self.deviceId = nil
                
                let notificationCenter = NSNotificationCenter.defaultCenter()
                notificationCenter.postNotificationName(NotificationsManagerDidUnregisterDeviceToken, object: nil)
                
            },
            failure: { (error: NSError) -> Void in
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
    func handleNotification(userInfo: NSDictionary, completionHandler: (UIBackgroundFetchResult -> Void)?) {
        DDLogSwift.logVerbose("Received push notification:\nPayload: \(userInfo)\n")
        DDLogSwift.logVerbose("Current Application state: \(applicationState.rawValue)");
        
        // Badge: Update
        if let badgeCountNumber = userInfo.numberForKeyPath(notificationBadgePath)?.integerValue {
            sharedApplication.applicationIconBadgeNumber = badgeCountNumber
        }
        
        // Badge: Reset
        if let type = userInfo.stringForKey(notificationTypeKey) where type == notificationBadgeResetValue {
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
            if handler(userInfo, completionHandler: completionHandler) {
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
    func handleHelpshiftNotification(userInfo: NSDictionary, completionHandler: (UIBackgroundFetchResult -> Void)?) -> Bool {
        guard let origin = userInfo.stringForKey(notificationOriginKey) where origin == helpshiftOriginValue else {
            return false
        }
        
        let rootViewController = sharedApplication.keyWindow?.rootViewController
        let payload = userInfo as [NSObject : AnyObject]
        
        HelpshiftCore.handleRemoteNotification(payload, withController: rootViewController)
        WPAnalytics.track(.SupportReceivedResponseFromSupport)
        
        completionHandler?(.NewData)
        
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
    func handleAuthenticationNotification(userInfo: NSDictionary, completionHandler: (UIBackgroundFetchResult -> Void)?) -> Bool {
        // WordPress.com Push Authentication Notification
        // Due to the Background Notifications entitlement, any given Push Notification's userInfo might be received
        // while the app is in BG, and when it's about to become active. In order to prevent UI glitches, let's skip
        // notifications when in BG mode. Still, we don't wanna relay that BG notification!
        //
        let authenticationManager = PushAuthenticationManager()
        guard authenticationManager.isPushAuthenticationNotification(userInfo) else {
            return false
        }
        
        if applicationState != .Background {
            authenticationManager.handlePushAuthenticationNotification(userInfo)
        }
        
        completionHandler?(.NewData)
        
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
    func handleInactiveNotification(userInfo: NSDictionary, completionHandler: (UIBackgroundFetchResult -> Void)?) -> Bool {
        guard applicationState == .Inactive else {
            return false
        }
        
        guard let notificationId = userInfo.numberForKey(notificationIdentifierKey)?.stringValue else {
            return false
        }

        WPTabBarController.sharedInstance().showNotificationsTabForNoteWithID(notificationId)
        completionHandler?(.NewData)
        
        return true
    }
    
    
    /// Handles a Notification while in Background Mode
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
    func handleBackgroundNotification(userInfo: NSDictionary, completionHandler: (UIBackgroundFetchResult -> Void)?) -> Bool {
        guard applicationState == .Background else {
            return false
        }
        
        let simperium = WordPressAppDelegate.sharedInstance().simperium
        simperium.backgroundFetchWithCompletion({ (result: UIBackgroundFetchResult) in
            if result == .NewData {
                DDLogSwift.logVerbose("Background Fetch Completed with New Data!")
            } else {
                DDLogSwift.logVerbose("Background Fetch Completed with No Data..")
            }
            completionHandler?(result)
        })
        
        return true
    }
    
    
    
    
    // MARK: - Private Methods: Helpers
    
    
    /// Tracks a Notification Event
    ///
    /// - Parameters:
    ///     - userInfo: The Notification's Payload
    ///
    private func trackNotificationWithUserInfo(userInfo: NSDictionary) {
        var properties = [String : String]()
        
        if let noteId = userInfo.numberForKey(notificationIdentifierKey) {
            properties[trackingIdentifierKey] = noteId.stringValue
        }
        
        if let type = userInfo.stringForKey(notificationTypeKey) {
            properties[trackingTypeKey] = type
        }
        
        if let theToken = deviceToken {
            properties[trackingTokenKey] = theToken
        }
        
        let event : WPAnalyticsStat = (applicationState == .Background) ? .PushNotificationReceived : .PushNotificationAlertPressed
        WPAnalytics.track(event, withProperties: properties)
    }
    
    
    
    /// Parses the NSData sent by Apple's Push Service, and extracts the Device Token
    ///
    private func parseTokenFromAppleData(tokenData: NSData) -> String {
        var newToken = tokenData.description.stringByReplacingOccurrencesOfString("<", withString: "")
        newToken = newToken.stringByReplacingOccurrencesOfString(">", withString: "")
        newToken = newToken.stringByReplacingOccurrencesOfString(" ", withString: "")
        
        return newToken
    }
    
    
    
    
    // MARK: - Private Constants: Device Keys
    private let deviceTokenKey              = "apnsDeviceToken"
    private let deviceIdKey                 = "notification_device_id"

    // MARK: - Private Constants: Notification Keys
    private let notificationBadgePath       = "aps.badge"
    private let notificationIdentifierKey   = "note_id"
    private let notificationTypeKey         = "type"
    private let notificationOriginKey       = "origin"
    private let notificationBadgeResetValue = "badge-reset"
    
    // MARK: - Private Constants: Helpshift
    private let helpshiftOriginValue        = "helpshift"
    
    // MARK: - Private Constants: Tracking
    private let trackingIdentifierKey       = "push_notification_note_id"
    private let trackingTypeKey             = "push_notification_type"
    private let trackingTokenKey            = "push_notification_token"
}
