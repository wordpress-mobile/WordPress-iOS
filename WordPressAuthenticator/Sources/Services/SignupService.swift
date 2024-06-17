import Foundation
import WordPressShared
import WordPressKit

/// SignupService: Responsible for creating a new WPCom user and blog.
///
class SignupService: SocialUserCreating {

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

        remote.createWPComAccount(withGoogle: token,
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

    /// Create a new WPcom account using Apple ID
    ///
    /// - Parameters:
    ///   - token:      Token provided by Apple.
    ///   - email:      Email provided by Apple.
    ///   - fullName:   Formatted full name provided by Apple.
    ///   - success:    Block called when account is created successfully.
    ///   - failure:    Block called when account creation fails.
    ///
    func createWPComUserWithApple(token: String,
                                  email: String,
                                  fullName: String?,
                                  success: @escaping (_ newAccount: Bool,
                                                    _ existingNonSocialAccount: Bool,
                                                    _ existing2faAccount: Bool,
                                                    _ username: String,
                                                    _ wpcomToken: String) -> Void,
                                  failure: @escaping (_ error: Error) -> Void) {
        let remote = WordPressComServiceRemote(wordPressComRestApi: anonymousAPI)

        remote.createWPComAccount(withApple: token,
                                  andEmail: email,
                                  andFullName: fullName,
                                  andClientID: configuration.wpcomClientId,
                                  andClientSecret: configuration.wpcomSecret,
                                  success: { response in
                                    guard let username = response?[ResponseKeys.username] as? String,
                                        let bearer_token = response?[ResponseKeys.bearerToken] as? String else {
                                            failure(SignupError.unknown)
                                            return
                                    }

                                    let createdAccount = (response?[ResponseKeys.createdAccount] as? Int ?? 0) == 1
                                    success(createdAccount, false, false, username, bearer_token)
        }, failure: { error in
            if let error = (error as NSError?) {

                if (error.userInfo[ErrorKeys.errorCode] as? String ?? "") == ErrorKeys.twoFactorEnabled {
                    success(false, true, true, "", "")
                    return
                }

                if (error.userInfo[ErrorKeys.errorCode] as? String ?? "") == ErrorKeys.existingNonSocialUser {

                    // If an account already exists, the account email should be returned in the Error response.
                    // Extract it and return it.
                    var existingEmail = ""
                    if let errorData = error.userInfo[WordPressComRestApi.ErrorKeyErrorData] as? [String: String] {
                        let emailDict = errorData.first { $0.key == WordPressComRestApi.ErrorKeyErrorDataEmail }
                        let email = emailDict?.value ?? ""
                        existingEmail = email
                    }

                    success(false, true, false, existingEmail, "")
                    return
                }
            }

            failure(error ?? SignupError.unknown)
        })
    }

}

// MARK: - Private
//
private extension SignupService {

    var anonymousAPI: WordPressComRestApi {
        return WordPressComRestApi(oAuthToken: nil,
                                   userAgent: configuration.userAgent,
                                   baseURL: configuration.wpcomAPIBaseURL)
    }

    var configuration: WordPressAuthenticatorConfiguration {
        return WordPressAuthenticator.shared.configuration
    }

    struct ResponseKeys {
        static let bearerToken = "bearer_token"
        static let username = "username"
        static let createdAccount = "created_account"
    }

    struct ErrorKeys {
        static let errorCode = "WordPressComRestApiErrorCodeKey"
        static let existingNonSocialUser = "user_exists"
        static let twoFactorEnabled = "2FA_enabled"
    }
}

// MARK: - Errors
//
enum SignupError: Error {
    case unknown
}
