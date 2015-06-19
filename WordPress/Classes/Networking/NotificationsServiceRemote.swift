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
    *  @param       success     A closure to be called on success, which will receive the parsed settings entity
    *  @param       failure     Optional closure to be called on failure. Will receive the error that was encountered.
    */
    public func getAllSettings(success: (RemoteNotificationsSettings -> Void)?, failure: (NSError -> Void)?) {
        let path = "/me/notifications/settings/"

        remoteApi.GET(path,
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) -> Void in
                if let settings = RemoteNotificationsSettings(rawSettings: response as? NSDictionary) {
                    success?(settings)
                } else {
                    let error = NSError(domain: NotificationsServiceRemote.domain,
                                          code: Errors.invalidResponse.rawValue,
                                      userInfo: nil)
                    failure?(error)
                }
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
                failure?(error)
            })
    }

    
    // MARK: - Errors
    public enum Errors : Int {
        case invalidResponse = -1
    }
    
    // MARK: - Public Static Constants
    public static let domain = "com.wordpress.notifications.service-remote"
    
    // MARK: - Private Internal Constants
    private let remoteApi: WordPressComApi!
}
