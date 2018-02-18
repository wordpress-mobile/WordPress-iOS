import Foundation
import CocoaLumberjack
import WordPressShared


/// Individual cases represent each step in the signup process.
///
enum SignupStatus: Int {
    case validating
    case creatingUser
    case authenticating
    case creatingBlog
    case syncing
}

typealias SignupStatusBlock = (_ status: SignupStatus) -> Void
typealias SignupSuccessBlock = () -> Void
typealias SignupFailureBlock = (_ error: Error?) -> Void


/// SignupService is responsible for creating a new WPCom user and blog.
/// The entry point is `createBlogAndSigninToWPCom` and the service takes care of the rest.
///
open class SignupService: LocalCoreDataService {

    /// Starts the process of creating a new blog and wpcom account for the user.
    ///
    /// - Parameters:
    ///     - url: The url for the new wpcom site
    ///     - blogTitle: The title of the blog
    ///     - emailAddress: The user's email address
    ///     - username: The desired username
    ///     - password: The user's password
    ///     - status: The status callback
    ///     - success: A success calback
    ///     - failure: A failure callback
    ///
    func createBlogAndSigninToWPCom(blogURL url: String,
                                            blogTitle: String,
                                            emailAddress: String,
                                            username: String,
                                            password: String,
                                            status: @escaping SignupStatusBlock,
                                            success: @escaping SignupSuccessBlock,
                                            failure: @escaping SignupFailureBlock) {

        // Organize parameters into a struct for easy sharing
        let signupParams = SignupParams(email: emailAddress, username: username, password: password)
        let siteCreationParams = SiteCreationParams(siteUrl: url, siteTitle: blogTitle)

        // Create call back blocks for the various methods we'll call to create the user account and blog.
        // Each success block calls the next step in the process.
        // NOTE: The steps below are constructed in reverse order.

        let createWPComBlogSuccessBlock = { (blog: Blog) in
            // When the blog is successfully created, update and sync all the things.
            // Since this is the last step in the process, pass the caller's success block.
            self.updateAndSyncBlogAndAccountInfo(blog, status: status, success: success, failure: failure)
        }

        let signinWPComUserSuccessBlock = { (account: WPAccount) in
            // When authenticated successfully, create the blog for the user.
            self.createWPComBlogForParams(siteCreationParams, account: account, status: status, success: createWPComBlogSuccessBlock, failure: failure)
        }

        let createAccountFailureBlock: SignupFailureBlock = { error in
            self.trackAccountCreationError(error)

            WPAppAnalytics.track(.createAccountFailed)
            failure(error)
        }

        let createWPComUserSuccessBlock = {
            // When the user is successfully created, authenticate.
            self.signinWPComUserWithParams(signupParams, status: status, success: signinWPComUserSuccessBlock, failure: failure)
        }

        let validateBlogSuccessBlock = {
            // When the blog is successfully validated, create the WPCom user.
            self.createWPComUserWithParams(signupParams, status: status, success: createWPComUserSuccessBlock, failure: createAccountFailureBlock)
        }

        // To start the process, validate the blog information.
        validateWPComBlogWithParams(siteCreationParams, status: status, success: validateBlogSuccessBlock, failure: createAccountFailureBlock)

    }


    /// Validates that the blog can be created and is not already taken.
    ///
    /// - Paramaters:
    ///     - params: Blog information
    ///     - status: The status callback
    ///     - success: A success calback
    ///     - failure: A failure callback
    ///
    func validateWPComBlogWithParams(_ params: SiteCreationParams,
                                     status: SignupStatusBlock,
                                     success: @escaping SignupSuccessBlock,
                                     failure: @escaping SignupFailureBlock) {

        status(.validating)

        let siteSuccessBlock: SiteCreationSuccessBlock = success
        let siteFailBlock: SiteCreationFailureBlock = failure
        let siteStatusBlock = { (status: SiteCreationStatus) in
        }

        let siteCreationService = SiteCreationService(managedObjectContext: managedObjectContext)

        siteCreationService.validateWPComBlogWithParams(params, status: siteStatusBlock, success: siteSuccessBlock, failure: siteFailBlock)
    }


    /// Creates a WPCom user account
    ///
    /// - Paramaters:
    ///     - params: Account information with which to sign up the user.
    ///     - status: The status callback
    ///     - success: A success calback
    ///     - failure: A failure callback
    ///
    func createWPComUserWithParams(_ params: SignupParams,
                                   status: SignupStatusBlock,
                                   success: @escaping SignupSuccessBlock,
                                   failure: @escaping SignupFailureBlock) {

        status(.creatingUser)
        let locale = WordPressComLanguageDatabase().deviceLanguage.slug
        let remote = WordPressComServiceRemote(wordPressComRestApi: self.anonymousApi())
        remote?.createWPComAccount(withEmail: params.email,
                                            andUsername: params.username,
                                            andPassword: params.password,
                                            andLocale: locale,
                                            andClientID: ApiCredentials.client(),
                                            andClientSecret: ApiCredentials.secret(),
                                            success: { (responseDictionary) in
                                                // Note: User creation is deferred until we have a WPCom auth token.
//                                                signin
                                            },
                                            failure: failure)
    }

    /*

 */
    func createWPComeUserWithGoogle(token: String,
                                   success: @escaping SignupSuccessBlock,
                                   failure: @escaping SignupFailureBlock) {
        let remote = WordPressComServiceRemote(wordPressComRestApi: self.anonymousApi())

        remote?.createWPComAccount(withGoogle: token,
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

                                        success()
                                    },
                                    failure: failure)
    }


    /// Authenticates a newly created WPCom user.
    ///
    /// - Paramaters:
    ///     - params: Account information with which to sign up the user.
    ///     - status: The status callback
    ///     - success: A success calback
    ///     - failure: A failure callback
    ///
    func signinWPComUserWithParams(_ params: SignupParams,
                                  status: SignupStatusBlock,
                                  success: @escaping (_ account: WPAccount) -> Void,
                                  failure: @escaping SignupFailureBlock) {

        status(.authenticating)
        let client = WordPressComOAuthClient.client(clientID: ApiCredentials.client(), secret: ApiCredentials.secret())
        client.authenticateWithUsername(params.username,
                                        password: params.password,
                                        multifactorCode: nil,
                                        success: { (authToken: String?) in

                                            guard let authToken = authToken else {
                                                DDLogError("Faied signing in the user. Success block was called but the auth token was nil.")
                                                assertionFailure()

                                                let error = SignupError.invalidResponse as NSError
                                                failure(error)
                                                return
                                            }

                                            // Now that we have an auth token, create the user account.
                                            let service = AccountService(managedObjectContext: self.managedObjectContext)

                                            let account = service.createOrUpdateAccount(withUsername: params.username, authToken: authToken)
                                            account.email = params.email
                                            if service.defaultWordPressComAccount() == nil {
                                                service.setDefaultWordPressComAccount(account)
                                            }

                                            success(account)
                                        },
                                        failure: failure)
    }


    /// Creates a WPCom blog
    ///
    /// - Paramaters:
    ///     - params: Blog information
    ///     - account: The WPAccount for the newly created user
    ///     - status: The status callback
    ///     - success: A success calback
    ///     - failure: A failure callback
    ///
    func createWPComBlogForParams(_ params: SiteCreationParams,
                                    account: WPAccount,
                                    status: SignupStatusBlock,
                                    success: @escaping (_ blog: Blog) -> Void,
                                    failure: @escaping SignupFailureBlock) {

        status(.creatingBlog)

        let siteFailBlock: SiteCreationFailureBlock = failure
        let siteStatusBlock = { (status: SiteCreationStatus) in
        }

        let siteCreationService = SiteCreationService(managedObjectContext: managedObjectContext)

        siteCreationService.createWPComBlogForParams(params, account: account, status: siteStatusBlock, success: success, failure: siteFailBlock)
    }


    /// Syncs blog and account info.
    ///
    /// - Paramaters:
    ///     - blog: The newly created blog entity.
    ///     - status: The status callback
    ///     - success: A success calback
    ///     - failure: A failure callback
    ///
    func updateAndSyncBlogAndAccountInfo(_ blog: Blog,
                                         status: SignupStatusBlock,
                                         success: @escaping SignupSuccessBlock,
                                         failure: @escaping SignupFailureBlock) {

        status(.syncing)

        let siteSuccessBlock: SiteCreationSuccessBlock = success
        let siteFailBlock: SiteCreationFailureBlock = failure
        let siteStatusBlock = { (status: SiteCreationStatus) in
        }

        let siteCreationService = SiteCreationService(managedObjectContext: managedObjectContext)

        siteCreationService.updateAndSyncBlogAndAccountInfo(blog, status: siteStatusBlock, success: siteSuccessBlock, failure: siteFailBlock)
    }


    // MARK: Private Instance Methods

    @objc func anonymousApi() -> WordPressComRestApi {
        return WordPressComRestApi(userAgent: WPUserAgent.wordPress())
    }

    @objc func trackAccountCreationError(_ error: Error?) {
        if let error = error as NSError?,
            let errorCode = error.userInfo[WordPressComRestApi.ErrorKeyErrorCode] as? String {
            switch errorCode {
            case "username_exists":
                WPAppAnalytics.track(.createAccountUsernameExists)
            case "email_exists":
                WPAppAnalytics.track(.createAccountEmailExists)
            default: break
            }

        }
    }

    /// An internal struct for conveniently sharing params between the different
    /// sign up steps.
    ///
    struct SignupParams {

        // Email address for wpcom account.
        var email: String

        // wpcom username
        var username: String

        // wpcom password
        var password: String
    }


    /// A convenience enum for creating meaningful NSError objects.
    ///
    enum SignupError: Error {
        case invalidResponse
        case missingRESTAPI
        case missingDefaultWPComAccount
    }

    /// A convenience struct for response keys
    private struct ResponseKeys {
        static let bearerToken = "bearer_token"
        static let username = "username"
    }
}
