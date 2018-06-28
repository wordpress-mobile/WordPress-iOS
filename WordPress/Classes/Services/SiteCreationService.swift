import Foundation
import CocoaLumberjack
import WordPressShared


/// Individual cases represent each step in the site creation process.
///
enum SiteCreationStatus: Int {
    case validating
    case gettingDefaultAccount
    case creatingSite
    case settingTagline
    case settingTheme
    case syncing
}

/// A struct for conveniently sharing params between the different site creation steps.
/// Public to be used by other services that need to call specific methods in this class.
///
struct SiteCreationParams {
    var siteUrl: String
    var siteTitle: String
    var siteTagline: String?
    var siteTheme: Theme

    init(siteUrl: String, siteTitle: String, siteTagline: String? = nil, siteTheme: Theme) {
        self.siteUrl = siteUrl
        self.siteTitle = siteTitle
        self.siteTagline = siteTagline
        self.siteTheme = siteTheme
    }
}

typealias SiteCreationStatusBlock = (_ status: SiteCreationStatus) -> Void
typealias SiteCreationSuccessBlock = () -> Void
typealias SiteCreationRequestSuccessBlock = (_ blog: Blog) -> Void
typealias SiteCreationFailureBlock = (_ error: Error?) -> Void

/// Blocks retained for kicking off the process from these steps.
/// Currently used for retrying failed steps during site creation.
///
private var taglineBlock: (() -> Void)?
private var themeBlock: (() -> Void)?
private var syncBlock: (() -> Void)?

/// SiteCreationService is responsible for creating a new site.
/// The entry point is `createSite` and the service takes care of the rest.
///
open class SiteCreationService: LocalCoreDataService {

    /// Starts the process of creating a new site.
    ///
    /// - Parameters:
    ///     - url: The url for the new wpcom site
    ///     - siteTitle: The title of the site
    ///     - status: The status callback
    ///     - success: A request success callback
    ///       - This returns the new site to the caller.
    ///     - failure: A failure callback
    ///
    func createSite(siteURL url: String,
                    siteTitle: String,
                    siteTagline: String?,
                    siteTheme: Theme,
                    status: @escaping SiteCreationStatusBlock,
                    success: @escaping SiteCreationRequestSuccessBlock,
                    failure: @escaping SiteCreationFailureBlock) {

        // Organize parameters into a struct for easy sharing
        let params = SiteCreationParams(siteUrl: url,
                                        siteTitle: siteTitle,
                                        siteTagline: siteTagline,
                                        siteTheme: siteTheme)

        // Create call back blocks for the various methods we'll call to create the site.
        // Each success block calls the next step in the process.
        // NOTE: The steps below are constructed in reverse order.

        let createBlogSuccessBlock = { (blog: Blog) in

            // Set up possible post blog creation steps

            let updateAndSyncBlock = {
                let syncSuccessBlock = {
                    // Since this is the last step in the process, return the new site to the caller.
                    success(blog)
                }

                self.updateAndSyncBlogAndAccountInfo(blog,
                                                     status: status,
                                                     success: syncSuccessBlock,
                                                     failure: failure)
            }

            syncBlock = updateAndSyncBlock

            let setThemeFailureBlock: SiteCreationFailureBlock = { error in
                WPAppAnalytics.track(.createSiteSetThemeFailed)
                DDLogError("Error while creating site: \(String(describing: error))")
                failure(error)
            }

            let setThemeBlock = {
                self.setWPComBlogTheme(blog: blog,
                                       params: params,
                                       status: status,
                                       success: updateAndSyncBlock,
                                       failure: setThemeFailureBlock)
            }

            themeBlock = setThemeBlock

            let setTaglineFailureBlock: SiteCreationFailureBlock = { error in
                print("service > setTaglineFailureBlock")
                WPAppAnalytics.track(.createSiteSetTaglineFailed)
                DDLogError("Error while creating site: \(String(describing: error))")
                failure(error)
            }

            let setTaglineBlock = {
                self.setWPComBlogTagline(blog: blog,
                                         params: params,
                                         status: status,
                                         success: setThemeBlock,
                                         failure: setTaglineFailureBlock)
            }

            taglineBlock = setTaglineBlock

            // Call blocks depending on what's needed.
            // If there is a Tagline, start there. It will call Theme and Sync during it's flow.
            // If there is no Tagline, start with Theme. It will call Sync during it's flow.
            // If there is no Tagline or Theme, go directly to Sync.

            // Since the UI needs to update, always send this status to indicate where the process is.
            status(.settingTagline)

            if let siteTagline = siteTagline,
                !siteTagline.isEmpty {
                setTaglineBlock()
            } else {
                setThemeBlock()
            }
        }

        let createBlogFailureBlock: SiteCreationFailureBlock = { error in
            WPAppAnalytics.track(.createSiteCreationFailed)
            DDLogError("Error while creating site: \(String(describing: error))")
            failure(error)
        }

        let validateBlogSuccessBlock = {

            status(.gettingDefaultAccount)

            // Verify we have an account.
            let accountService = AccountService(managedObjectContext: self.managedObjectContext)

            guard let defaultAccount = accountService.defaultWordPressComAccount() else {
                let error = SiteCreationError.missingDefaultWPComAccount
                DDLogError("Error while creating site: The default wpcom account was not found.")
                failure(error)
                return
            }

            // When the blog is successfully validated, create the WPCom blog.
            self.createWPComBlogForParams(params,
                                          account: defaultAccount,
                                          status: status,
                                          success: createBlogSuccessBlock,
                                          failure: createBlogFailureBlock)
        }

        let validateBlogFailureBlock: SiteCreationFailureBlock = { error in
            WPAppAnalytics.track(.createSiteValidationFailed)
            DDLogError("Error while creating site: \(String(describing: error))")
            failure(error)
        }

        // To start the process, validate the blog information.
        validateWPComBlogWithParams(params,
                                    status: status,
                                    success: validateBlogSuccessBlock,
                                    failure: validateBlogFailureBlock)
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

        let accountService = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        let api = accountService.defaultWordPressComAccount()?.wordPressComRestApi ??
                  WordPressComRestApi(userAgent: WPUserAgent.wordPress())

        let remote = WordPressComServiceRemote(wordPressComRestApi: api)
        remote.validateWPComBlog(withUrl: params.siteUrl,
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

        status(.creatingSite)

        guard let api = account.wordPressComRestApi else {
            let error = SiteCreationError.missingRESTAPI
            DDLogError("Error while creating site: Missing REST API.")
            assertionFailure()
            failure(error)
            return
        }

        let currentLanguage = WordPressComLanguageDatabase().deviceLanguageIdNumber()
        let languageId = currentLanguage.stringValue

        let remote = WordPressComServiceRemote(wordPressComRestApi: api)
        remote.createWPComBlog(withUrl: params.siteUrl,
                                andBlogTitle: params.siteTitle,
                                andLanguageId: languageId,
                                andBlogVisibility: .public,
                                andClientID: ApiCredentials.client(),
                                andClientSecret: ApiCredentials.secret(),
                                success: {  (responseDictionary) in

                                    // The site was created so bump the stat, even if there are problems later on.
                                    WPAppAnalytics.track(.createdSite)
                                    guard let blogOptions = responseDictionary?[BlogKeys.blogDetails] as? [String: AnyObject] else {
                                        let error = SiteCreationError.invalidResponse
                                        DDLogError("Error while creating site: The Blog response dictionary did not contain the expected results.")
                                        assertionFailure()
                                        failure(error)
                                        return
                                    }

                                    guard let blog = self.createBlogFromBlogOptions(blogOptions, failure: failure) else {
                                        // No need to call the failure block here. It will be called from
                                        // `createBlogFromBlogOptions` if needed.
                                        return
                                    }

                                    // Touch site so the app recognizes it as the last used.
                                    if let siteUrl = blog.url {
                                        RecentSitesService().touch(site: siteUrl)
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

        status(.syncing)

        let accountService = AccountService(managedObjectContext: managedObjectContext)
        let blogService = BlogService(managedObjectContext: managedObjectContext)

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

    /// Set the Site Theme.
    ///
    /// - Paramaters:
    ///     - blog:    The newly created blog entity
    ///     - params:  Blog information
    ///     - status:  The status callback
    ///     - success: A success calback
    ///     - failure: A failure callback
    ///
    func setWPComBlogTheme(blog: Blog,
                           params: SiteCreationParams,
                           status: SiteCreationStatusBlock,
                           success: @escaping SiteCreationSuccessBlock,
                           failure: @escaping SiteCreationFailureBlock) {

        status(.settingTheme)

        let themeService = ThemeService(managedObjectContext: managedObjectContext)

        let themeServiceSuccessBlock = { (theme: Theme?) in
            success()
        }

        _ = themeService.activate(params.siteTheme, for: blog, success: themeServiceSuccessBlock, failure: failure)
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
    private func createBlogFromBlogOptions(_ blogOptions: [String: AnyObject], failure: SiteCreationFailureBlock) -> Blog? {
        let accountService = AccountService(managedObjectContext: managedObjectContext)
        let blogService = BlogService(managedObjectContext: managedObjectContext)

        // Treat missing dictionary keys as an api issue. If we've reached this point
        // the account/blog creation was probably successful and the app might be able
        // to recover the next time it tries to sync blogs.

        guard let blogName = (blogOptions[BlogKeys.blogNameLowerCaseN] ??
                             blogOptions[BlogKeys.blogNameUpperCaseN]) as? String,
            let xmlrpc = blogOptions[BlogKeys.XMLRPC] as? String,
            let blogURL = blogOptions[BlogKeys.URL] as? String,
            let stringID = blogOptions[BlogKeys.blogID] as? String,
            let dotComID = Int(stringID)
            else {
                let error = SiteCreationError.invalidResponse
                DDLogError("Error while creating site: The blogOptions dictionary was missing expected data.")
                assertionFailure()
                failure(error)
                return nil
        }

        guard let defaultAccount = accountService.defaultWordPressComAccount() else {
            let error = SiteCreationError.missingDefaultWPComAccount
            DDLogError("Error while creating site: The default wpcom account was not found.")
            assertionFailure()
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


    /// Kick off the process starting from setting the tagline.
    /// i.e. set tagline, set theme, synch account.
    ///
    func retryFromTagline() {
        if let taglineBlock = taglineBlock {
            taglineBlock()
        }
    }

    /// Kick off the process starting from setting the theme.
    /// i.e. set theme, synch account.
    ///
    func retryFromTheme() {
        if let themeBlock = themeBlock {
            themeBlock()
        }
    }

    /// Kick off the process starting from syncing account.
    ///
    func retryFromAccountSync() {
        if let syncBlock = syncBlock {
            syncBlock()
        }
    }

    /// A convenience enum for creating meaningful NSError objects.
    private enum SiteCreationError: Error {
        case invalidResponse
        case missingRESTAPI
        case missingDefaultWPComAccount
        case missingTheme
    }

    /// A convenience struct for Blog keys
    private struct BlogKeys {
        static let blogDetails = "blog_details"
        static let blogNameLowerCaseN = "blogname"
        static let blogNameUpperCaseN = "blogName"
        static let XMLRPC = "xmlrpc"
        static let blogID = "blogid"
        static let URL = "url"
    }

}
