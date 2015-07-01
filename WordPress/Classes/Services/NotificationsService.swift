import Foundation


/**
*  @class           NotificationsService
*  @brief           This service encapsulates the Restful API related to WordPress Notifications.
*/

public class NotificationsService : NSObject, LocalCoreDataService
{
    /**
    *  @details     Designated Initializer
    *  @param       managedObjectContext    A Reference to the MOC that should be used to interact with
    *                                       the Core Data Persistent Store.
    */
    public required init(managedObjectContext context: NSManagedObjectContext) {
        super.init()
        managedObjectContext       = context
        notificationsServiceRemote = NotificationsServiceRemote(api: remoteApi())
    }
    

    /**
    *  @details     This method will retrieve all of the Notification Settings for the default WordPress.com account
    *  @param       success Closure to be called on success.
    *  @param       failure Closure to be called on failure, with the associated error.
    */
    public func getAllSettings(success: ([NotificationSettings] -> Void)?, failure: (NSError! -> Void)?) {
        let deviceId = NotificationsManager.registeredPushNotificationsDeviceId() ?? String()
        
        notificationsServiceRemote?.getAllSettings(deviceId,
            success: {
                (remote: [RemoteNotificationSettings]) in
                let parsed = NotificationSettings.fromRemoteArray(remote)
                success?(parsed)
            },
            failure: { (error: NSError!) in
                failure?(error)
            })
    }
    
    
    
    /**
    *  @details     Helper method to get the WordPress.com REST Api, if any
    *  @returns     WordPressComApi instance, if applicable, or nil.
    */
    private func remoteApi() -> WordPressComApi? {
        let accountService = AccountService(managedObjectContext: managedObjectContext)
        let unwrappedRestApi = accountService.defaultWordPressComAccount()?.restApi
        
        return unwrappedRestApi?.hasCredentials() == true ? unwrappedRestApi! : nil
    }

    
    // MARK: - Private Internal Properties
    private var managedObjectContext        : NSManagedObjectContext!
    private var notificationsServiceRemote  : NotificationsServiceRemote?
}
