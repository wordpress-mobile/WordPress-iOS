import Foundation

extension AccountService {

    /// Connect an account a social service via an ID token.
    ///
    /// - Parameters:
    ///     - service The name of the social service.
    ///     - token The service's OpenID Connect (JWT) ID token for the user.
    ///     - success
    ///     - failure
    func connectToSocialService(_ service: SocialServiceName, serviceIDToken token: String, success:@escaping (() -> Void), failure:@escaping ((NSError) -> Void)) {
        guard let api = defaultWordPressComAccount()?.wordPressComRestApi  else {
            fatalError("Failed to initialize a valid remote via the default WordPress.com account.")
        }

        let remote = AccountServiceRemoteREST(wordPressComRestApi: api)
        remote.connectToSocialService(service, serviceIDToken: token, oAuthClientID: ApiCredentials.client(), oAuthClientSecret: ApiCredentials.secret(), success: success, failure: failure)
    }

    /// Disconnect an account a social service via an ID token.
    /// - Parameters:
    ///     - service The name of the social service.
    ///     - success
    ///     - failure
    func disconnectFromSocialService(_ service: SocialServiceName, success:@escaping (() -> Void), failure:@escaping ((NSError) -> Void)) {
        guard let api = defaultWordPressComAccount()?.wordPressComRestApi else {
            fatalError("Failed to initialize a valid remote via the default WordPress.com account.")
        }

        let remote = AccountServiceRemoteREST(wordPressComRestApi: api)
        remote.disconnectFromSocialService(service, oAuthClientID: ApiCredentials.client(), oAuthClientSecret: ApiCredentials.secret(), success: success, failure: failure)
    }

}
