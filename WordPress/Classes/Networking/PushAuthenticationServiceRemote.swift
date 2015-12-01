import Foundation
import AFNetworking

/**
*  @class           PushAuthenticationServiceRemote
*  @brief           The purpose of this class is to encapsulate all of the interaction with the REST endpoint,
*                   required to handle WordPress.com 2FA Code Veritication via Push Notifications
*/

@objc public class PushAuthenticationServiceRemote : ServiceRemoteREST
{
    /**
    *  @details     Verifies a WordPress.com Login.
    *  @param       token       The token passed on by WordPress.com's 2FA Push Notification.
    *  @param       success     Closure to be executed on success. Can be nil.
    *  @param       failure     Closure to be executed on failure. Can be nil.
    */
    public func authorizeLogin(token: String, success: (() -> ())?, failure: (() -> ())?) {
        let path = "me/two-step/push-authentication"
        let requestUrl = self.pathForEndpoint(path, withVersion: ServiceRemoteRESTApiVersion_1_1)
        
        let parameters  = [
            "action"        : "authorize_login",
            "push_token"    : token
        ]
        
        api.POST(requestUrl,
            parameters: parameters,
            success: { (operation: AFHTTPRequestOperation, response: AnyObject) -> Void in
                success?()
            },
            failure:{ (operation: AFHTTPRequestOperation?, error: NSError) -> Void in
                failure?()
            })
    }
}
