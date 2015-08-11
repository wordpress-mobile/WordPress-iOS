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
    *  @param       success     A closure to be called on success, which will receive the parsed settings entities.
    *  @param       failure     Optional closure to be called on failure. Will receive the error that was encountered.
    */
    public func getAllSettings(deviceId: String, success: ([RemoteNotificationSettings] -> Void)?, failure: (NSError! -> Void)?) {
        let path = String(format: "me/notifications/settings/?device_id=%@", deviceId)

        remoteApi.GET(path,
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) -> Void in
                let settings = RemoteNotificationSettings.fromDictionary(response as? NSDictionary)
                success?(settings)
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
                failure?(error)
            })
    }
    
    
    /**
    *  @details     Updates the specified Notification Settings
    *  @param       settings    The complete (or partial) dictionary of settings to be updated.
    *  @param       success     Optional closure to be called on success.
    *  @param       failure     Optional closure to be called on failure.
    */
    public func updateSettings(settings: [String: AnyObject], success: (() -> ())?, failure: (NSError! -> Void)?) {
        let path = String(format: "me/notifications/settings/")
        let parameters = settings as NSDictionary
        
        remoteApi.POST(path,
            parameters: parameters,
            success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) -> Void in
                success?()
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
                failure?(error)
            })
    }
    
    
    // MARK: - Private Internal Constants
    private let remoteApi: WordPressComApi!
}
