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
                if let rawSettingsDict = response as? NSDictionary {
                    let settings = RemoteNotificationsSettings(rawSettings: rawSettingsDict)
                    success?(settings)
                }
// TODO: Handle failure
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
                failure?(error)
            })
    }
    
    // MARK: - Private Internal Constants
    private var remoteApi: WordPressComApi!
}
