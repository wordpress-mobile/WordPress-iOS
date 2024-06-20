import Foundation

/// The purpose of this class is to encapsulate all of the interaction with the REST endpoint,
/// required to handle WordPress.com 2FA Code Veritication via Push Notifications
///
@objc open class PushAuthenticationServiceRemote: ServiceRemoteWordPressComREST {
    /// Verifies a WordPress.com Login.
    ///
    /// - Parameters:
    ///     - token: The token passed on by WordPress.com's 2FA Push Notification.
    ///     - success: Closure to be executed on success. Can be nil.
    ///     - failure: Closure to be executed on failure. Can be nil.
    ///
    @objc open func authorizeLogin(_ token: String, success: (() -> Void)?, failure: (() -> Void)?) {
        let path = "me/two-step/push-authentication"
        let requestUrl = self.path(forEndpoint: path, withVersion: ._1_1)

        let parameters  = [
            "action": "authorize_login",
            "push_token": token
        ]

        wordPressComRESTAPI.post(requestUrl, parameters: parameters,
                                 success: { _, _ in
                                    success?()
                                 },
                                 failure: { _, _ in
                                    failure?()
                                 })
    }
}
