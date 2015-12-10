import Foundation
import Mixpanel



/**
 *  @details        These notifications are sent when the user Registers / Unregisters for Push Notifications.
 */
public let NotificationsManagerDidRegisterDeviceToken   = "NotificationsManagerDidRegisterDeviceToken"
public let NotificationsManagerDidUnregisterDeviceToken = "NotificationsManagerDidUnregisterDeviceToken"



/**
 *  @class          PushNotificationsManager
 *  @details        The purpose of this helper is to encapsulate all the tasks related to
 *                  Push Notifications Registration + Handling, including iOS "Actionable" Notifications.
 */

final public class PushNotificationsManager : NSObject
{
    // MARK: - Public Properties
    
    /**
     *  @details    Returns the shared PushNotificationsManager instance.
     */
    static let sharedInstance = PushNotificationsManager()
    
    
    /**
     *  @details    Returns the SharedApplication instance. This is meant for Unit Testing purposes.
     */
    var sharedApplication : UIApplication {
        return UIApplication.sharedApplication()
    }
    


    /**
     *  @details    Stores the Apple's Push Notifications Token
     */
    var deviceToken : String? {
        didSet {
            save()
        }
    }

    
    /**
     *  @details    Stores the WordPress.com Device identifier
     */
    var deviceId : String? {
        didSet {
            save()
        }
    }
    
    
    
    // MARK: - Public Methods
    
    /**
     *  @brief      Registers the device for Remote + User Notifications.
     *  @details    We'll wire Badge + Sound + Alert notifications, along with support for
     *              iOS User Notifications Actions.
     */
    func registerForPushNotifications() {
        if sharedApplication.isRunningSimulator() || sharedApplication.isAlphaBuild() {
            return;
        }
        
        // Remote Notifications Registration
        sharedApplication.registerForRemoteNotifications()

        // User Notifications Registration
        let categories  = interactiveHandler.supportedNotificationCategories()
        let settings    = UIUserNotificationSettings(forTypes: [.Badge, .Sound, .Alert], categories: categories)
        sharedApplication.registerUserNotificationSettings(settings)
    }
    

    
    /**
     *  @details    Indicates whether Push Notifications are enabled in Settings.app, or not.
     */
    func notificationsEnabledInDeviceSettings() -> Bool {
        return (sharedApplication.currentUserNotificationSettings()?.types ?? .None) != .None
    }
    
    
    
    /**
     *  @brief      Registers the Device Token agains WordPress.com backend, if there's a default account.
     *  @details    Both Helpshift and Mixpanel will also be initialized. The token will be persisted across
     *              App Sessions.
     */
    func registerDeviceToken(tokenData: NSData) {
        // We want to register Helpshift regardless so that way if a user isn't logged in
        // they can still get push notifications that we replied to their support ticket.
        Helpshift.sharedInstance().registerDeviceToken(tokenData)
        Mixpanel.sharedInstance().people?.addPushDeviceToken(tokenData)

        // Don't bother registering for WordPress anything if the user isn't logged in
        if wordPressDotComAvailable() == false {
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
    
    
    
    /**
     *  @brief     Perform cleanup when the registration for iOS notifications failed
     *  @param     error detailing the reason for failure
     */
    func registrationDidFail(error: NSError) {
        DDLogSwift.logError("Failed to register for push notifications: \(error)")
        unregisterDeviceToken()
    }
    
    
    
    /**
     *  @brief      Unregister the device from WordPress.com notifications
     */
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
    
    
    

    // MARK: - Private Methods
    
    /**
     *  @brief      Indicates whether there is a default WordPress.com accounta available, or not
     */
    private func wordPressDotComAvailable() -> Bool {
        let mainContext = ContextManager.sharedInstance().mainContext
        let accountService = AccountService(managedObjectContext: mainContext)
        
        return accountService.defaultWordPressComAccount() != nil
    }

    
    
    /**
     *  @brief      Parses the NSData sent by Apple's Push Service, and extracts the Device Token
     */
    private func parseTokenFromAppleData(tokenData: NSData) -> String {
        var newToken = tokenData.description.stringByReplacingOccurrencesOfString("<", withString: "")
        newToken = newToken.stringByReplacingOccurrencesOfString(">", withString: "")
        newToken = newToken.stringByReplacingOccurrencesOfString(" ", withString: "")
        
        return newToken
    }
    
    
    
    /**
    *  @brief      Persists the deviceToken + deviceId
    */
    private func save() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(deviceToken, forKey: deviceTokenKey)
        defaults.setObject(deviceId, forKey: deviceIdKey)
        defaults.synchronize()
    }
    
    
    
    /**
     *  @brief      Default Initializer
     */
    private override init() {
        let defaults    = NSUserDefaults.standardUserDefaults()
        deviceToken     = defaults.stringForKey(deviceTokenKey) ?? String()
        deviceId        = defaults.stringForKey(deviceIdKey) ?? String()
        
        super.init()
    }
    
    
    
    // MARK: - Private Properties
    private let interactiveHandler = InteractiveNotificationsHandler()
    
    // MARK: - Private Constants
    private let deviceTokenKey  = "apnsDeviceToken"
    private let deviceIdKey     = "notification_device_id"
}
