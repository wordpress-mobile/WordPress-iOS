import Foundation
import CocoaLumberjack
import WordPressShared
import WordPressKit



// MARK: - SignupService: Responsible for creating a new WPCom user and blog.
//
class SignupService {

    /// Create a new WPcom account using Google signin token
    ///
    /// - Parameters:
    ///   - googleToken: the token from a successful Google login
    ///   - success: block called when account is created successfully
    ///   - failure: block called when account creation fails
    ///
    func createWPComUser(googleToken: String,
                         success: @escaping (_ newAccount: Bool, _ username: String, _ wpcomToken: String) -> Void,
                         failure: @escaping (_ error: Error) -> Void) {

        let remote = WordPressComServiceRemote(wordPressComRestApi: anonymousAPI)
        let locale = WordPressComLanguageDatabase().deviceLanguage.slug

        remote.createWPComAccount(withGoogle: googleToken,
                                   andLocale: locale,
                                   andClientID: configuration.wpcomClientId,
                                   andClientSecret: configuration.wpcomSecret,
                                   success: { responseDictionary in
                                        guard let username = responseDictionary?[ResponseKeys.username] as? String,
                                            let bearer_token = responseDictionary?[ResponseKeys.bearerToken] as? String else {
                                                failure(ServiceError.unknown)
                                                return
                                        }

                                        let createdAccount = (responseDictionary?[ResponseKeys.createdAccount] as? Int ?? 0) == 1

                                        success(createdAccount, username, bearer_token)

// TODO: Fixme
//                                        // create the local account
//                                        let service = AccountService(managedObjectContext: self.managedObjectContext)
//                                        let account = service.createOrUpdateAccount(withUsername: username, authToken: bearer_token)
//                                        if service.defaultWordPressComAccount() == nil {
//                                            service.setDefaultWordPressComAccount(account)
//                                        }
//
//                                        let createdAccount = (responseDictionary?[ResponseKeys.createdAccount] as? Int ?? 0) == 1
//                                        if createdAccount {
//                                            success(createdAccount)
//                                        } else {
//                                            // we need to sync the blogs for existing accounts to be able to display the Login Epilogue
//                                            BlogSyncFacade().syncBlogs(for: account, success: {
//                                                success(createdAccount)
//                                            }, failure: { (_) in
//                                                // the blog sync failed but the user is already logged in
//                                                success(createdAccount)
//                                            })
//                                        }
                                    },
                                    failure: { error in
                                        failure(error ?? ServiceError.unknown)
        })
    }
}


// MARK: - Private
//
private extension SignupService {

    private var anonymousAPI: WordPressComRestApi {
        return WordPressComRestApi(oAuthToken: nil, userAgent: configuration.userAgent)
    }

    private var configuration: WordPressAuthenticatorConfiguration {
        return WordPressAuthenticator.shared.configuration
    }

    private struct ResponseKeys {
        static let bearerToken = "bearer_token"
        static let username = "username"
        static let createdAccount = "created_account"
    }
}


// MARK: - Errors
//
extension SignupService {

    enum ServiceError: Error {
        case unknown
    }
}
