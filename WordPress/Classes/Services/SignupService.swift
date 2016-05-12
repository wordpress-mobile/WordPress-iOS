import Foundation
import WordPressComAnalytics
import WordPressShared


/// Individual cases represent each step in the signup process.
///
enum SignupStatus: Int {
    case Validating
    case CreatingUser
    case Authenticating
    case CreatingBlog
    case Syncing
}


typealias SignupStatusBlock = (status: SignupStatus) -> Void
typealias SignupSuccessBlock = () -> Void
typealias SignupFailureBlock = (error: NSError?) -> Void


/// SignupService is responsible for creating a new WPCom user and blog.
/// The entry point is `createBlogAndSigninToWPCom` and the service takes care of the rest.
///
public class SignupService : LocalCoreDataService
{
    private let LanguageIDKey = "lang_id"
    private let BlogDetailsKey = "blog_details"
    private let BlogNameLowerCaseNKey = "blogname"
    private let BlogNameUpperCaseNKey = "blogName"
    private let XMLRPCKey = "xmlrpc"
    private let BlogIDKey = "blogid"
    private let URLKey = "url"


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
    func createBlogAndSigninToWPCom(blogURL url:String,
                                            blogTitle: String,
                                            emailAddress: String,
                                            username: String,
                                            password: String,
                                            status: SignupStatusBlock,
                                            success: SignupSuccessBlock,
                                            failure: SignupFailureBlock) {

        // Organize parameters into a struct for easy sharing
        let params = SignupParams(url: url, title: blogTitle, email: emailAddress, username: username, password: password)

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
            self.createWPComBlogForParams(params, account: account, status: status, success: createWPComBlogSuccessBlock, failure: failure)
        }

        let createWPComUserSuccessBlock = {
            // When the user is successfully created, authenticate.
            self.signinWPComUserWithParams(params, status: status, success: signinWPComUserSuccessBlock, failure: failure)
        }

        let validateBlogSuccessBlock = {
            // When the blog is successfully validated, create the WPCom user.
            self.createWPComUserWithParams(params, status: status, success: createWPComUserSuccessBlock, failure: failure)
        }

        // To start the process, validate the blog information.
        validateWPComBlogWithParams(params, status: status, success: validateBlogSuccessBlock, failure: failure)
    }


    /// Validates that the blog can be created and is not already taken.
    ///
    /// - Paramaters:
    ///     - params: Account and blog information with which to sign up the user.
    ///     - status: The status callback
    ///     - success: A success calback
    ///     - failure: A failure callback
    ///
    func validateWPComBlogWithParams(params: SignupParams,
                                     status: SignupStatusBlock,
                                     success: SignupSuccessBlock,
                                     failure: SignupFailureBlock) {

        status(status: .Validating)
        let currentLanguage = WordPressComLanguageDatabase().deviceLanguageIdNumber()
        let languageId = currentLanguage.stringValue

        let remote = WordPressComServiceRemote(api: WordPressComApi.anonymousApi())
        remote.validateWPComBlogWithUrl(params.url,
                                        andBlogTitle: params.title,
                                        andLanguageId: languageId,
                                        success:{ (responseDictionary) in
                                            success()
                                        },
                                        failure: failure)
    }


    /// Creates a WPCom user account
    ///
    /// - Paramaters:
    ///     - params: Account and blog information with which to sign up the user.
    ///     - status: The status callback
    ///     - success: A success calback
    ///     - failure: A failure callback
    ///
    func createWPComUserWithParams(params: SignupParams,
                                   status: SignupStatusBlock,
                                   success: SignupSuccessBlock,
                                   failure: SignupFailureBlock) {

        status(status: .CreatingUser)
        let remote = WordPressComServiceRemote(api: WordPressComApi.anonymousApi())
        remote.createWPComAccountWithEmail(params.email,
                                            andUsername: params.username,
                                            andPassword: params.password,
                                            success: { (responseDictionary) in
                                                // Note: User creation is deferred until we have a WPCom auth token.
                                                success()
                                            },
                                            failure: failure)
    }


    /// Authenticates a newly created WPCom user.
    ///
    /// - Paramaters:
    ///     - params: Account and blog information with which to sign up the user.
    ///     - status: The status callback
    ///     - success: A success calback
    ///     - failure: A failure callback
    ///
    func signinWPComUserWithParams(params: SignupParams,
                                  status: SignupStatusBlock,
                                  success: (account: WPAccount) -> Void,
                                  failure: SignupFailureBlock) {

        status(status: .Authenticating)
        let client = WordPressComOAuthClient.client()
        client.authenticateWithUsername(params.username,
                                        password: params.password,
                                        multifactorCode: nil,
                                        success: { (authToken: String?) in

                                            guard let authToken = authToken else {
                                                DDLogSwift.logError("Faied signing in the user. Success block was called but the auth token was nil.")
                                                assertionFailure()

                                                let error = SignupError.InvalidResponse as NSError
                                                failure(error: error)
                                                return
                                            }

                                            // Now that we have an auth token, create the user account.
                                            let service = AccountService(managedObjectContext: self.managedObjectContext)

                                            let account = service.createOrUpdateAccountWithUsername(params.username, authToken: authToken)
                                            account.email = params.email
                                            if service.defaultWordPressComAccount() == nil {
                                                service.setDefaultWordPressComAccount(account)
                                            }

                                            success(account: account)
                                        },
                                        failure: failure)
    }


    /// Creates a WPCom blog
    ///
    /// - Paramaters:
    ///     - params: Account and blog information with which to sign up the user.
    ///     - account: The WPAccount for the newly created user
    ///     - status: The status callback
    ///     - success: A success calback
    ///     - failure: A failure callback
    ///
    func createWPComBlogForParams(params: SignupParams,
                                    account: WPAccount,
                                    status: SignupStatusBlock,
                                    success: (blog: Blog) -> Void,
                                    failure: SignupFailureBlock) {

        guard let api = account.restApi else {
            DDLogSwift.logError("Failed to get the REST API from the account.")
            assertionFailure()

            let error = SignupError.MissingRESTAPI as NSError
            failure(error: error)
            return
        }

        let currentLanguage = WordPressComLanguageDatabase().deviceLanguageIdNumber()
        let languageId = currentLanguage.stringValue

        status(status: .CreatingBlog)
        let remote = WordPressComServiceRemote(api: api)
        remote.createWPComBlogWithUrl(params.url,
                                        andBlogTitle: params.title,
                                        andLanguageId: languageId,
                                        andBlogVisibility: .Public,
                                        success: {  (responseDictionary) in

                                            // The account was created so bump the stat, even if there are problems later on.
                                            WPAppAnalytics.track(.CreatedAccount)

                                            guard let blogOptions = responseDictionary[self.BlogDetailsKey] as? [String: AnyObject] else {
                                                DDLogSwift.logError("Failed creating blog. The response dictionary did not contain the expected results")
                                                assertionFailure()

                                                let error = SignupError.InvalidResponse as NSError
                                                failure(error: error)
                                                return
                                            }

                                            guard let blog = self.createBlogFromBlogOptions(blogOptions, failure: failure) else {
                                                // No need to call the failure block here. It will be called from
                                                // `createBlogFromBlogOptions` if needed.
                                                return
                                            }

                                            success(blog: blog)
                                        },
                                        failure: failure)
    }


    /// Syncs blog and account info.
    ///
    /// - Paramaters:
    ///     - blog: The newly created blog entity.
    ///     - status: The status callback
    ///     - success: A success calback
    ///     - failure: A failure callback
    ///
    func updateAndSyncBlogAndAccountInfo(blog: Blog,
                                         status: SignupStatusBlock,
                                         success: SignupSuccessBlock,
                                         failure: SignupFailureBlock) {

        let accountService = AccountService(managedObjectContext: managedObjectContext)
        let blogService = BlogService(managedObjectContext: managedObjectContext)

        status(status: .Syncing)
        blogService.syncBlog(blog, completionHandler: {
            // The final step
            accountService.updateUserDetailsForAccount(blog.account!, success: success, failure: failure)
        })
    }


    /// Create a new blog entity from the supplied blog options. Calls the supplied
    /// failure block if the blog can not be created.
    ///
    /// - Parameters:
    ///     - blogOptions: A dictionary of blog options.
    ///     - failure: A failure block.
    ///
    /// - Returns: A blog or nil.
    ///
    func createBlogFromBlogOptions(blogOptions: [String: AnyObject], failure: SignupFailureBlock) -> Blog? {
        let accountService = AccountService(managedObjectContext: managedObjectContext)
        let blogService = BlogService(managedObjectContext: managedObjectContext)

        // Treat missing dictionary keys as an api issue. If we've reached this point
        // the account/blog creation was probably successful and the app might be able
        // to recover the next time it tries to sync blogs.
        guard let blogName = (blogOptions[BlogNameLowerCaseNKey] ?? blogOptions[BlogNameUpperCaseNKey]) as? String,
            xmlrpc = blogOptions[XMLRPCKey] as? String,
            blogURL = blogOptions[URLKey] as? String,
            stringID = blogOptions[BlogIDKey] as? String,
            dotComID = Int(stringID)
            else {
                DDLogSwift.logError("Failed finishing account creation. The blogOptions dictionary was missing expected data.")
                assertionFailure()

                let error = SignupError.InvalidResponse as NSError
                failure(error: error)
                return nil
        }

        guard let defaultAccount = accountService.defaultWordPressComAccount() else {
            DDLogSwift.logError("Failed finishing account creation. The default wpcom account was not found.")
            assertionFailure()

            let error = SignupError.MissingDefaultWPComAccount as NSError
            failure(error: error)
            return nil
        }

        var blog: Blog
        if let existingBlog = blogService.findBlogWithXmlrpc(xmlrpc, inAccount: defaultAccount) {
            blog = existingBlog
        } else {
            blog = blogService.createBlogWithAccount(defaultAccount)
            blog.xmlrpc = xmlrpc
        }

        blog.dotComID = NSNumber(integer: dotComID)
        blog.url = blogURL
        blog.settings?.name = blogName.stringByDecodingXMLCharacters()

        defaultAccount.defaultBlog = blog

        ContextManager.sharedInstance().saveContext(managedObjectContext)

        return blog
    }


    // MARK: Private Instance Methods


    /// An internal struct for conveniently sharing params between the different
    /// sign up steps.
    ///
    struct SignupParams {
        // WPCom blog url
        var url: String

        // WPCom blog title
        var title: String

        // Email address for wpcom account.
        var email: String

        // wpcom username
        var username: String

        // wpcom password
        var password: String
    }


    /// A conveniece enum for creating meaningful NSError objects.
    ///
    enum SignupError : ErrorType {
        case InvalidResponse
        case MissingRESTAPI
        case MissingDefaultWPComAccount
    }

}
