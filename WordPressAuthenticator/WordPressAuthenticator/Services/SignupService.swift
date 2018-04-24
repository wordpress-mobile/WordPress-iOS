import Foundation
import CocoaLumberjack
import WordPressShared
import WordPressKit



/// SignupService: Responsible for creating a new WPCom user and blog.
///
class SignupService {

    /// Create a new WPcom account using Google signin token
    ///
    /// - Parameters:
    ///   - googleToken: the token from a successful Google login
    ///   - success: block called when account is created successfully
    ///   - failure: block called when account creation fails
    ///
    func createWPComUserWithGoogle(token: String,
                                   success: @escaping (_ newAccount: Bool, _ username: String, _ wpcomToken: String) -> Void,
                                   failure: @escaping (_ error: Error) -> Void) {

        let remote = WordPressComServiceRemote(wordPressComRestApi: anonymousAPI)
        let locale = WordPressComLanguageDatabase().deviceLanguage.slug

        remote.createWPComAccount(withGoogle: token,
                                  andLocale: locale,
                                  andClientID: configuration.wpcomClientId,
                                  andClientSecret: configuration.wpcomSecret,
                                  success: { response in

            guard let username = response?[ResponseKeys.username] as? String,
                let bearer_token = response?[ResponseKeys.bearerToken] as? String else {
                    failure(SignupError.unknown)
                    return
            }

            let createdAccount = (response?[ResponseKeys.createdAccount] as? Int ?? 0) == 1
            success(createdAccount, username, bearer_token)
        }, failure: { error in
            failure(error ?? SignupError.unknown)
        })
    }
}


// MARK: - Private
//
private extension SignupService {

    var anonymousAPI: WordPressComRestApi {
        return WordPressComRestApi(oAuthToken: nil, userAgent: configuration.userAgent)
    }

    var configuration: WordPressAuthenticatorConfiguration {
        return WordPressAuthenticator.shared.configuration
    }

    struct ResponseKeys {
        static let bearerToken = "bearer_token"
        static let username = "username"
        static let createdAccount = "created_account"
    }
}


// MARK: - Errors
//
enum SignupError: Error {
    case unknown
}
