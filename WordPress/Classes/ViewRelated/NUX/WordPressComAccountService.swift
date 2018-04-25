import Foundation
import WordPressKit


// MARK: - WordPressComAccountService
//
class WordPressComAccountService {

    /// Indicates if a WordPress.com account is "PasswordLess": This kind of account must be authenticated via a Magic Link.
    ///
    func isPasswordlessAccount(username: String, success: @escaping (Bool) -> Void, failure: @escaping (Error) -> Void) {
        let remote = AccountServiceRemoteREST(wordPressComRestApi: anonymousAPI)

        remote.isPasswordlessAccount(username, success: { isPasswordless in
            success(isPasswordless)
        }, failure: { error in
            let result = error ?? ServiceError.unknown
            failure(result)
        })
    }

    /// Connects a WordPress.com account with the specified Social Service.
    ///
    func connect(wpcomAuthToken: String, serviceName: SocialServiceName, serviceToken: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let loggedAPI  = WordPressComRestApi(oAuthToken: wpcomAuthToken, userAgent: configuration.userAgent)
        let remote = AccountServiceRemoteREST(wordPressComRestApi: loggedAPI)

        remote.connectToSocialService(serviceName,
                                      serviceIDToken: serviceToken,
                                      oAuthClientID: configuration.wpcomClientId,
                                      oAuthClientSecret: configuration.wpcomSecret,
                                      success: success,
                                      failure: { error in
            failure(error)
        })
    }

    /// Requests a WordPress.com Authentication Link to be sent to the specified email address.
    ///
    func requestAuthenticationLink(for email: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let remote = AccountServiceRemoteREST(wordPressComRestApi: anonymousAPI)

        remote.requestWPComAuthLink(forEmail: email,
                                    clientID: configuration.wpcomClientId,
                                    clientSecret: configuration.wpcomSecret,
                                    wpcomScheme: configuration.wpcomScheme,
                                    success: success,
                                    failure: { error in
            let result = error ?? ServiceError.unknown
            failure(result)
        })
    }

    /// Requests a WordPress.com SignUp Link to be sent to the specified email address.
    ///
    func requestSignupLink(for email: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let remote = AccountServiceRemoteREST(wordPressComRestApi: anonymousAPI)

        remote.requestWPComSignupLink(forEmail: email,
                                      clientID: configuration.wpcomClientId,
                                      clientSecret: configuration.wpcomSecret,
                                      wpcomScheme: configuration.wpcomScheme,
                                      success: success,
                                      failure: { error in
            let result = error ?? ServiceError.unknown
            failure(result)
        })
    }

    /// Returns an anonymous WordPressComRestApi Instance.
    ///
    private var anonymousAPI: WordPressComRestApi {
        return WordPressComRestApi(oAuthToken: nil, userAgent: configuration.userAgent)
    }

    /// Returns the current WordPressAuthenticatorConfiguration Instance.
    ///
    private var configuration: WordPressAuthenticatorConfiguration {
        return WordPressAuthenticator.shared.configuration
    }
}


// MARK: - Nested Types
//
extension WordPressComAccountService {

    enum ServiceError: Error {
        case unknown
    }
}
