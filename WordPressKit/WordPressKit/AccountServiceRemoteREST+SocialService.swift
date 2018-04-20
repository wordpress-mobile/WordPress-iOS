import Foundation

public enum SocialServiceName: String {
    case google
}


extension AccountServiceRemoteREST {

    /// Connect to the specified social service via its OpenID Connect (JWT) token.
    ///
    /// - Parameters:
    ///     - service The name of the social service.
    ///     - token The OpenID Connect (JWT) ID token identifying the user on the social service.
    ///     - oAuthClientID The WPCOM REST API client ID.
    ///     - oAuthClientSecret The WPCOM REST API client secret.
    ///     - success The block that will be executed on success.
    ///     - failure The block that will be executed on failure.
    public func connectToSocialService(_ service: SocialServiceName, serviceIDToken token: String, oAuthClientID: String, oAuthClientSecret: String, success:@escaping (() -> Void), failure:@escaping ((NSError) -> Void)) {
        let path = self.path(forEndpoint: "me/social-login/connect", withVersion: ._1_1)

        let params = [
            "client_id": oAuthClientID,
            "client_secret": oAuthClientSecret,
            "service": service.rawValue,
            "id_token": token,
        ] as [String: AnyObject]
        wordPressComRestApi.POST(path, parameters: params, success: { (responseObject, httpResponse) in
            success()
        }, failure: { (error, httpResponse) in
            failure(error)
        })
    }

    /// Disconnect fromm the specified social service.
    ///
    /// - Parameters:
    ///     - service The name of the social service.
    ///     - oAuthClientID The WPCOM REST API client ID.
    ///     - oAuthClientSecret The WPCOM REST API client secret.
    ///     - success The block that will be executed on success.
    ///     - failure The block that will be executed on failure.
    public func disconnectFromSocialService(_ service: SocialServiceName, oAuthClientID: String, oAuthClientSecret: String, success:@escaping(() -> Void), failure:@escaping((NSError) -> Void)) {
        let path = self.path(forEndpoint: "me/social-login/disconnect", withVersion: ._1_1)
        let params = [
            "client_id": oAuthClientID,
            "client_secret": oAuthClientSecret,
            "service": service.rawValue,
        ] as [String: AnyObject]

        wordPressComRestApi.POST(path, parameters: params, success: { (responseObject, httpResponse) in
            success()
        }, failure: { (error, httpResponse) in
            failure(error)
        })
    }
}
