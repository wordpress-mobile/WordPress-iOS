import Foundation


public class NotificationsServiceRemote
{
    /**
    *  @details     Designated Initializer. Fails if the remoteApi is nil.
    *  @param       remoteApi A Reference to the WordPressComApi that should be used to interact with WordPress.com
    */
    init?(api: WordPressComApi!) {
        if api == nil {
            return nil
        }

        remoteApi = api
    }

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
    
    // MARK: - Public Static COnstants
    public static let domain = "com.wordpress.notifications.service-remote"
    
    // MARK: - Private Internal Constants
    private var remoteApi: WordPressComApi!
}
