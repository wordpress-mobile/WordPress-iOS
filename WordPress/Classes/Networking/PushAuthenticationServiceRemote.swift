import Foundation

/// The purpose of this class is to encapsulate all of the interaction with the REST endpoint,
/// required to handle WordPress.com 2FA Code Veritication via Push Notifications
///
@objc public class PushAuthenticationServiceRemote : ServiceRemoteWordPressComREST
{
    /// Verifies a WordPress.com Login.
    ///
    /// - Parameters:
    ///     - token: The token passed on by WordPress.com's 2FA Push Notification.
    ///     - success: Closure to be executed on success. Can be nil.
    ///     - failure: Closure to be executed on failure. Can be nil.
    ///
    public func authorizeLogin(token: String, success: (() -> ())?, failure: (() -> ())?) {
        let path = "me/two-step/push-authentication"
        let requestUrl = self.pathForEndpoint(path, withVersion: .Version_1_1)

        let parameters  = [
            "action"        : "authorize_login",
            "push_token"    : token
        ]

        wordPressComRestApi.POST(requestUrl,
            parameters: parameters,
            success: { (response: AnyObject, httpResponse: NSHTTPURLResponse?) -> Void in
                success?()
            },
            failure:{ (error: NSError, httpResponse: NSHTTPURLResponse?) -> Void in
                failure?()
            })
    }
}
