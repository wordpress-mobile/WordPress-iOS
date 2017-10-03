import Foundation
import WordPressComKit

extension AccountService {

    /// Connect an account a social service via an ID token.
    ///
    /// - Parameters:
    ///     - service The name of the social service.
    ///     - token The service's OpenID Connect (JWT) ID token for the user.
    ///     - success
    ///     - failure
    func connectToSocialService(_ service: SocialServiceName, serviceIDToken token:String, success:@escaping (() -> Void), failure:@escaping ((NSError) -> Void)) {
        guard let api = defaultWordPressComAccount()?.wordPressComRestApi,
            let remote = AccountServiceRemoteREST(wordPressComRestApi: api) else {
                fatalError("Failed to initialize a valid remote via the default WordPress.com account.")
        }
        remote.connectToSocialService(service, serviceIDToken: token, success: success, failure: failure)
    }

    /// Disconnect an account a social service via an ID token.
    /// - Parameters:
    ///     - service The name of the social service.
    ///     - success
    ///     - failure
    func disconnectFromSocialService(_ service: SocialServiceName, success:@escaping (() -> Void), failure:@escaping ((NSError) -> Void)) {
        guard let api = defaultWordPressComAccount()?.wordPressComRestApi,
            let remote = AccountServiceRemoteREST(wordPressComRestApi: api) else {
                fatalError("Failed to initialize a valid remote via the default WordPress.com account.")
        }
        remote.disconnectFromSocialService(service, success: success, failure: failure)
    }

}
