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
    ///     - success The block that will be executed on success.
    ///     - failure The block that will be executed on failure.
    public func connectToSocialService(_ service: SocialServiceName, serviceIDToken token: String, success:@escaping (() -> Void), failure:@escaping ((NSError) -> Void)) {
        guard let path = self.path(forEndpoint: "me/social-login/connect", with: .version_1_1) else {
            // This should never fail but if it does we don't want to ignore the problem.
            fatalError("There was a problem creating a valid path for the supplied endpoint and REST API version.")
        }
        let params = [
            "service": service.rawValue,
            "id_token": token
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
    ///     - success The block that will be executed on success.
    ///     - failure The block that will be executed on failure.
    public func disconnectFromSocialService(_ service: SocialServiceName, success:@escaping(() -> Void), failure:@escaping((NSError) -> Void)) {
        guard let path = self.path(forEndpoint: "me/social-login/disconnect", with: .version_1_1) else {
            // This should never fail but if it does we don't want to ignore the problem.
            fatalError("There was a problem creating a valid path for the supplied endpoint and REST API version.")
        }
        let params = [
            "service": service.rawValue,
        ] as [String: AnyObject]
        wordPressComRestApi.POST(path, parameters: params, success: { (responseObject, httpResponse) in
            success()
        }, failure: { (error, httpResponse) in
            failure(error)
        })
    }
}
