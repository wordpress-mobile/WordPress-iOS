import Foundation


/**
*  @class           PushAuthenticationServiceRemote
*  @brief           The purpose of this class is to encapsulate all of the interaction with the REST endpoint,
*                   required to handle WordPress.com 2FA Code Veritication via Push Notifications
*/

@objc public class PushAuthenticationServiceRemote
{
    /**
    *  @details     Designated Initializer. Fails if the remoteApi is nil.
    *  @param       remoteApi A Reference to the WordPressComApi that should be used to interact with WordPress.com
    */
    init?(remoteApi: WordPressComApi!) {
        self.remoteApi = remoteApi
        if remoteApi == nil {
            return nil
        }
    }
    

    /**
    *  @details     Verifies a WordPress.com Login.
    *  @param       token       The token passed on by WordPress.com's 2FA Push Notification.
    *  @param       success     Closure to be executed on success. Can be nil.
    *  @param       failure     Closure to be executed on failure. Can be nil.
    */
    public func authorizeLogin(token: String, success: (() -> ())?, failure: (() -> ())?) {
        let path        = "me/two-step/push-authentication"
        let parameters  = [
            "action"        : "authorize_login",
            "push_token"    : token
        ]
        
        remoteApi.POST(path,
            parameters: parameters,
            success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) -> Void in
                success?()
            },
            failure:{ (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
                failure?()
            })
    }

    
    // MARK: - Private Internal Constants
    private var remoteApi: WordPressComApi!
}
