import Foundation


/**
*  @class           NotificationsServiceRemote
*  @brief           The purpose of this class is to encapsulate all of the interaction with the Notifications
*                   REST endpoints. Note that Notification Sync'ing itself is handled via Simperium, and
*                   here we'll deal mostly with the Settings / Push Notifications API.
*/

public class NotificationsServiceRemote
{
    /**
    *  @details     Designated Initializer. Fails if the remoteApi is nil.
    *  @param       remoteApi   A Reference to the WordPressComApi that should be used to interact with WordPress.com
    */
    init?(api: WordPressComApi!) {
        remoteApi = api
        
        if api == nil {
            return nil
        }
    }

    
    /**
    *  @details     Retrieves all of the Notification Settings
    *  @param       deviceId    The ID of the current device. Can be nil.
    *  @param       success     A closure to be called on success, which will receive the parsed settings entity
    *  @param       failure     Optional closure to be called on failure. Will receive the error that was encountered.
    */
    public func getAllSettings(deviceId: String, success: (NotificationSettings -> Void)?, failure: (NSError! -> Void)?) {
        let unwrappedDeviceId = deviceId ?? String()
        let path = String(format: "me/notifications/settings/?device_id=%@", unwrappedDeviceId)

        remoteApi.POST(path,
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) -> Void in
                let settings = NotificationSettings(dictionary: response as? NSDictionary)
                success?(settings)
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
                failure?(error)
            })
    }
    
    
    /**
    *  @details     Retrieves all of the Notification Settings, for a specific Site and Device.
    *  @param       deviceId    The ID of the current device. Can be nil.
    *  @param       siteId      The ID of the related blog
    *  @param       success     A closure to be called on success, which will receive the parsed settings entity
    *  @param       failure     Optional closure to be called on failure. Will receive the error that was encountered.
    */
    public func getSiteSettings(deviceId: String, siteId: String, success: ([NotificationSettings.Site] -> Void)?, failure: (NSError! -> Void)?) {
        let path = String(format: "me/notifications/settings/sites/%@/?device_id=%@", siteId, deviceId)
        
        remoteApi.POST(path,
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) -> Void in
                let ettings = NotificationSettings.Site.fromDictionary(response as? NSDictionary)
                success?(ettings)
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
                failure?(error)
            })
    }
    
    
    /**
    *  @details     Retrieves all of the Notification Settings for 3rd party blogs
    *  @param       deviceId    The ID of the current device. Can be nil.
    *  @param       success     A closure to be called on success, which will receive the parsed settings entity
    *  @param       failure     Optional closure to be called on failure. Will receive the error that was encountered.
    */
    public func getOtherSettings(deviceId: String, success: ([NotificationSettings.Other] -> Void)?, failure: (NSError! -> Void)?) {
        let path = String(format: "me/notifications/settings/sites/other/?device_id=%@", deviceId)
        
        remoteApi.POST(path,
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) -> Void in
                let settings = NotificationSettings.Other.fromDictionary(response as? NSDictionary)
                success?(settings)
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
                failure?(error)
            })
    }
    
    
    /**
    *  @details     Retrieves all of the Notification Settings for Wordpress.com
    *  @param       success     A closure to be called on success, which will receive the parsed settings entity
    *  @param       failure     Optional closure to be called on failure. Will receive the error that was encountered.
    */
    public func getWordPressComSettings(success: (NotificationSettings.WordPressCom -> Void)?, failure: (NSError! -> Void)?) {
        let path = "me/notifications/settings/wpcom/"
        
        remoteApi.POST(path,
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) -> Void in
                let settings = NotificationSettings.WordPressCom.fromDictionary(response as? NSDictionary)
                success?(settings)
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
                failure?(error)
            })
    }
    
    
    // MARK: - Private Internal Constants
    private let remoteApi: WordPressComApi!
}
