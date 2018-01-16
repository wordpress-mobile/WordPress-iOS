import Foundation
import CocoaLumberjack
import WordPressShared


/// Individual cases represent each step in the site creation process.
///
enum SiteCreationStatus: Int {
    case validating
    case creatingSite
    case syncing
    case settingTagline
}

/// A struct for conveniently sharing params between the different site creation steps.
/// Public to be used by other services that need to call specific methods in this class.
///
struct SiteCreationParams {
    var siteUrl: String
    var siteTitle: String
    var siteTagline: String?
}

typealias SiteCreationStatusBlock = (_ status: SiteCreationStatus) -> Void
typealias SiteCreationSuccessBlock = () -> Void
typealias SiteCreationFailureBlock = (_ error: Error?) -> Void


/// SiteCreationService is responsible for creating a new site.
/// The entry point is `createSite` and the service takes care of the rest.
///
open class SiteCreationService: LocalCoreDataService {
    private let LanguageIDKey = "lang_id"
    private let BlogDetailsKey = "blog_details"
    private let BlogNameLowerCaseNKey = "blogname"
    private let BlogNameUpperCaseNKey = "blogName"
    private let XMLRPCKey = "xmlrpc"
    private let BlogIDKey = "blogid"
    private let URLKey = "url"


    /// Starts the process of creating a new site.
    ///
    /// - Parameters:
    ///     - url: The url for the new wpcom site
    ///     - siteTitle: The title of the site
    ///     - status: The status callback
    ///     - success: A success calback
    ///     - failure: A failure callback
    ///
    func createSite(siteURL url: String,
                    siteTitle: String,
                    siteTagline: String?,
                    status: @escaping SiteCreationStatusBlock,
                    success: @escaping SiteCreationSuccessBlock,
                    failure: @escaping SiteCreationFailureBlock) {

        // Verify we have an account.
        let accountService = AccountService(managedObjectContext: self.managedObjectContext)
        guard let defaultAccount = accountService.defaultWordPressComAccount() else {
            DDLogError("Failed creating site. The default wpcom account was not found.")
            return
        }

        // Organize parameters into a struct for easy sharing
        let params = SiteCreationParams(siteUrl: url, siteTitle: siteTitle, siteTagline: siteTagline)

        // Create call back blocks for the various methods we'll call to create the site.
        // Each success block calls the next step in the process.
        // NOTE: The steps below are constructed in reverse order.

        let createBlogSuccessBlock = { (blog: Blog) in
            if siteTagline != nil {

                let setTaglineSuccessBlock = {
                    self.updateAndSyncBlogAndAccountInfo(blog, status: status, success: success, failure: failure)
                }

                let setTaglineFailureBlock: SiteCreationFailureBlock = { error in
                    WPAppAnalytics.track(.createSiteSetTaglineFailed)
                    failure(error)
                }

                self.setWPComBlogTagline(blog: blog, params: params, status: status, success: setTaglineSuccessBlock, failure: setTaglineFailureBlock)
            }
            else {
                // When the site is successfully created, update and sync all the things.
                // Since this is the last step in the process, pass the caller's success block.
                self.updateAndSyncBlogAndAccountInfo(blog, status: status, success: success, failure: failure)
            }
        }

        let createBlogFailureBlock: SiteCreationFailureBlock = { error in
            WPAppAnalytics.track(.createSiteCreationFailed)
            failure(error)
        }

        let validateBlogSuccessBlock = {
            // When the blog is successfully validated, create the WPCom blog.
            self.createWPComBlogForParams(params, account: defaultAccount, status: status, success: createBlogSuccessBlock, failure: createBlogFailureBlock)
        }

        let validateBlogFailureBlock: SiteCreationFailureBlock = { error in
            WPAppAnalytics.track(.createSiteValidationFailed)
            failure(error)
        }

        // To start the process, validate the blog information.
        validateWPComBlogWithParams(params, status: status, success: validateBlogSuccessBlock, failure: validateBlogFailureBlock)
    }

    /// Validates that the site can be created and is not already taken.
    ///
    /// - Paramaters:
    ///     - params: New Blog information
    ///     - status: The status callback
    ///     - success: A success calback
    ///     - failure: A failure callback
    ///
    func validateWPComBlogWithParams(_ params: SiteCreationParams,
                                     status: SiteCreationStatusBlock,
                                     success: @escaping SiteCreationSuccessBlock,
                                     failure: @escaping SiteCreationFailureBlock) {

        status(.validating)
        let currentLanguage = WordPressComLanguageDatabase().deviceLanguageIdNumber()
        let languageId = currentLanguage.stringValue

        let remote = WordPressComServiceRemote(wordPressComRestApi: self.anonymousApi())
        remote?.validateWPComBlog(withUrl: params.siteUrl,
                                  andBlogTitle: params.siteTitle,
                                  andLanguageId: languageId,
                                  andClientID: ApiCredentials.client(),
                                  andClientSecret: ApiCredentials.secret(),
                                  success: { (responseDictionary) in
                                    success()
        },
                                  failure: failure)
    }

    /// Creates a WPCom site
    ///
    /// - Paramaters:
    ///     - params: New blog information
    ///     - account: The WPAccount for the user
    ///     - status: The status callback
    ///     - success: A success calback
    ///     - failure: A failure callback
    ///
    func createWPComBlogForParams(_ params: SiteCreationParams,
                                  account: WPAccount,
                                  status: SiteCreationStatusBlock,
                                  success: @escaping (_ blog: Blog) -> Void,
                                  failure: @escaping SiteCreationFailureBlock) {

        guard let api = account.wordPressComRestApi else {
            DDLogError("Failed to get the REST API from the account.")
            assertionFailure()

            let error = SiteCreationError.missingRESTAPI as NSError
            failure(error)
            return
        }

        status(.creatingSite)

        let currentLanguage = WordPressComLanguageDatabase().deviceLanguageIdNumber()
        let languageId = currentLanguage.stringValue

        let remote = WordPressComServiceRemote(wordPressComRestApi: api)
        remote?.createWPComBlog(withUrl: params.siteUrl,
                                andBlogTitle: params.siteTitle,
                                andLanguageId: languageId,
                                andBlogVisibility: .public,
                                andClientID: ApiCredentials.client(),
                                andClientSecret: ApiCredentials.secret(),
                                success: {  (responseDictionary) in

                                    // The site was created so bump the stat, even if there are problems later on.
                                    WPAppAnalytics.track(.createdSite)

                                    guard let blogOptions = responseDictionary?[self.BlogDetailsKey] as? [String: AnyObject] else {
                                        DDLogError("Failed creating site. The response dictionary did not contain the expected results")
                                        assertionFailure()

                                        let error = SiteCreationError.invalidResponse as NSError
                                        failure(error)
                                        return
                                    }

                                    guard let blog = self.createBlogFromBlogOptions(blogOptions, failure: failure) else {
                                        // No need to call the failure block here. It will be called from
                                        // `createBlogFromBlogOptions` if needed.
                                        return
                                    }

                                    success(blog)
        },
                                failure: failure)
    }

    /// Syncs blog and account info.
    ///
    /// - Paramaters:
    ///     - blog: The newly created blog entity
    ///     - status: The status callback
    ///     - success: A success calback
    ///     - failure: A failure callback
    ///
    func updateAndSyncBlogAndAccountInfo(_ blog: Blog,
                                         status: SiteCreationStatusBlock,
                                         success: @escaping SiteCreationSuccessBlock,
                                         failure: @escaping SiteCreationFailureBlock) {

        let accountService = AccountService(managedObjectContext: managedObjectContext)
        let blogService = BlogService(managedObjectContext: managedObjectContext)

        status(.syncing)
        blogService.syncBlogAndAllMetadata(blog, completionHandler: {
            // The final step
            accountService.updateUserDetails(for: blog.account!, success: success, failure: failure)
        })
    }

    /// Set the Site Tagline.
    ///
    /// - Paramaters:
    ///     - blog:    The newly created blog entity
    ///     - params:  Blog information
    ///     - status:  The status callback
    ///     - success: A success calback
    ///     - failure: A failure callback
    ///
    func setWPComBlogTagline(blog: Blog,
                             params: SiteCreationParams,
                             status: SiteCreationStatusBlock,
                             success: @escaping SiteCreationSuccessBlock,
                             failure: @escaping SiteCreationFailureBlock) {

        status(.settingTagline)
        blog.settings?.tagline = params.siteTagline
        let blogService = BlogService(managedObjectContext: managedObjectContext)
        blogService.updateSettings(for: blog, success: success, failure: failure)
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
    func createBlogFromBlogOptions(_ blogOptions: [String: AnyObject], failure: SiteCreationFailureBlock) -> Blog? {
        let accountService = AccountService(managedObjectContext: managedObjectContext)
        let blogService = BlogService(managedObjectContext: managedObjectContext)

        // Treat missing dictionary keys as an api issue. If we've reached this point
        // the account/blog creation was probably successful and the app might be able
        // to recover the next time it tries to sync blogs.
        guard let blogName = (blogOptions[BlogNameLowerCaseNKey] ?? blogOptions[BlogNameUpperCaseNKey]) as? String,
            let xmlrpc = blogOptions[XMLRPCKey] as? String,
            let blogURL = blogOptions[URLKey] as? String,
            let stringID = blogOptions[BlogIDKey] as? String,
            let dotComID = Int(stringID)
            else {
                DDLogError("Failed finishing account creation. The blogOptions dictionary was missing expected data.")
                assertionFailure()

                let error = SiteCreationError.invalidResponse as NSError
                failure(error)
                return nil
        }

        guard let defaultAccount = accountService.defaultWordPressComAccount() else {
            DDLogError("Failed finishing account creation. The default wpcom account was not found.")
            assertionFailure()

            let error = SiteCreationError.missingDefaultWPComAccount as NSError
            failure(error)
            return nil
        }

        var blog: Blog
        if let existingBlog = blogService.findBlog(withXmlrpc: xmlrpc, in: defaultAccount) {
            blog = existingBlog
        } else {
            blog = blogService.createBlog(with: defaultAccount)
            blog.xmlrpc = xmlrpc
        }

        blog.dotComID = NSNumber(value: dotComID as Int)
        blog.url = blogURL
        blog.settings?.name = blogName.decodingXMLCharacters()

        defaultAccount.defaultBlog = blog

        ContextManager.sharedInstance().save(managedObjectContext)

        return blog
    }

    // MARK: - WP API

    func anonymousApi() -> WordPressComRestApi {
        return WordPressComRestApi(userAgent: WPUserAgent.wordPress())
    }

    /// A convenience enum for creating meaningful NSError objects.
    ///
    enum SiteCreationError: Error {
        case invalidResponse
        case missingRESTAPI
        case missingDefaultWPComAccount
    }

}
