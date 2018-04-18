import Foundation
import CocoaLumberjack
import WordPressShared



typealias SignupSocialSuccessBlock = (_ newAccount: Bool) -> Void
typealias SignupFailureBlock = (_ error: Error?) -> Void


/// SignupService is responsible for creating a new WPCom user and blog.
///
open class SignupService: LocalCoreDataService {

    /// Create a new WPcom account using Google signin token
    ///
    /// - Parameters:
    ///   - token: the token from a successful Google login
    ///   - success: block called when account is created successfully
    ///   - failure: block called when account creation fails
    func createWPComUserWithGoogle(token: String,
                                   success: @escaping SignupSocialSuccessBlock,
                                   failure: @escaping SignupFailureBlock) {

        let remote = WordPressComServiceRemote(wordPressComRestApi: self.anonymousApi())
        let locale = WordPressComLanguageDatabase().deviceLanguage.slug

        remote.createWPComAccount(withGoogle: token,
                                   andLocale: locale,
                                   andClientID: ApiCredentials.client(),
                                   andClientSecret: ApiCredentials.secret(),
                                   success: { (responseDictionary) in
                                        guard let username = responseDictionary?[ResponseKeys.username] as? String,
                                            let bearer_token = responseDictionary?[ResponseKeys.bearerToken] as? String else {
                                                // without these we can't proceed.
                                                failure(nil)
                                                return
                                        }

                                        // create the local account
                                        let service = AccountService(managedObjectContext: self.managedObjectContext)
                                        let account = service.createOrUpdateAccount(withUsername: username, authToken: bearer_token)
                                        if service.defaultWordPressComAccount() == nil {
                                            service.setDefaultWordPressComAccount(account)
                                        }

                                        let createdAccount = (responseDictionary?[ResponseKeys.createdAccount] as? Int ?? 0) == 1
                                        if createdAccount {
                                            defer {
                                                WPAppAnalytics.track(.createdAccount)
                                            }
                                            success(createdAccount)
                                        } else {
                                            defer {
                                                WPAppAnalytics.track(.signupSocialToLogin)
                                            }
                                            // we need to sync the blogs for existing accounts to be able to display the Login Epilogue
                                            BlogSyncFacade().syncBlogs(for: account, success: {
                                                success(createdAccount)
                                            }, failure: { (_) in
                                                // the blog sync failed but the user is already logged in
                                                success(createdAccount)
                                            })
                                        }
                                    },
                                    failure: failure)
    }



    // MARK: Private Instance Methods

    @objc func anonymousApi() -> WordPressComRestApi {
        return WordPressComRestApi(userAgent: WPUserAgent.wordPress())
    }


    /// A convenience struct for response keys
    private struct ResponseKeys {
        static let bearerToken = "bearer_token"
        static let username = "username"
        static let createdAccount = "created_account"
    }
}
