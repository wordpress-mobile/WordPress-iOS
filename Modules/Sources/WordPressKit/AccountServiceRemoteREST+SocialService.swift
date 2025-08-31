import Foundation

@frozen public enum SocialServiceName: String {
    case google
    case apple
}

extension AccountServiceRemoteREST {

    /// Connect to the specified social service via its OpenID Connect (JWT) token.
    ///
    /// - Parameters:
    ///     - service The name of the social service.
    ///     - token The OpenID Connect (JWT) ID token identifying the user on the social service.
    ///     - connectParameters Dictionary containing additional endpoint parameters. Currently only used for the Apple service.
    ///     - oAuthClientID The WPCOM REST API client ID.
    ///     - oAuthClientSecret The WPCOM REST API client secret.
    ///     - success The block that will be executed on success.
    ///     - failure The block that will be executed on failure.
    public func connectToSocialService(_ service: SocialServiceName,
                                       serviceIDToken token: String,
                                       connectParameters: [String: AnyObject]? = nil,
                                       oAuthClientID: String,
                                       oAuthClientSecret: String,
                                       success: @escaping (() -> Void),
                                       failure: @escaping ((Error) -> Void)) {
        let path = self.path(forEndpoint: "me/social-login/connect", withVersion: ._1_1)

        var params = [
            "client_id": oAuthClientID,
            "client_secret": oAuthClientSecret,
            "service": service.rawValue,
            "id_token": token
        ] as [String: AnyObject]

        if let connectParameters = connectParameters {
            params.merge(connectParameters, uniquingKeysWith: { (current, _) in current })
        }

        wordPressComRESTAPI.post(path, parameters: params, success: { (_, _) in
            success()
        }, failure: { (error, _) in
            failure(error)
        })
    }

    /// Get Apple connect parameters from provided account information.
    ///
    /// - Parameters:
    ///     - email Email from Apple account.
    ///     - fullName User's full name from Apple account.
    /// - Returns: Dictionary with endpoint parameters, to be used when connecting to social service.
    static public func appleSignInParameters(email: String, fullName: String) -> [String: AnyObject] {
        return [
            "user_email": email as AnyObject,
            "user_name": fullName as AnyObject
        ]
    }

    /// Disconnect fromm the specified social service.
    ///
    /// - Parameters:
    ///     - service The name of the social service.
    ///     - oAuthClientID The WPCOM REST API client ID.
    ///     - oAuthClientSecret The WPCOM REST API client secret.
    ///     - success The block that will be executed on success.
    ///     - failure The block that will be executed on failure.
    public func disconnectFromSocialService(_ service: SocialServiceName, oAuthClientID: String, oAuthClientSecret: String, success: @escaping(() -> Void), failure: @escaping((Error) -> Void)) {
        let path = self.path(forEndpoint: "me/social-login/disconnect", withVersion: ._1_1)
        let params = [
            "client_id": oAuthClientID,
            "client_secret": oAuthClientSecret,
            "service": service.rawValue
        ] as [String: AnyObject]

        wordPressComRESTAPI.post(path, parameters: params, success: { (_, _) in
            success()
        }, failure: { (error, _) in
            failure(error)
        })
    }
}
