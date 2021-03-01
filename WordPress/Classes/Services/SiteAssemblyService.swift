
import Foundation

// MARK: - EnhancedSiteCreationService

/// Working implementation of a `SiteAssemblyService`.
///
final class EnhancedSiteCreationService: LocalCoreDataService, SiteAssemblyService {

    // MARK: Properties

    /// A service for interacting with WordPress accounts.
    private let accountService: AccountService

    /// A service for interacting with WordPress blogs.
    private let blogService: BlogService

    /// A facade for WPCOM services.
    private let remoteService: WordPressComServiceRemote

    /// The site creation request that's been enqueued.
    private var creationRequest: SiteCreationRequest?

    /// This handler is called with changes to the site assembly status.
    private var statusChangeHandler: SiteAssemblyStatusChangedHandler?

    /// The most recently created blog corresponding to the site creation request; `nil` otherwise.
    private(set) var createdBlog: Blog?

    // MARK: LocalCoreDataService

    override init(managedObjectContext context: NSManagedObjectContext) {
        self.accountService = AccountService(managedObjectContext: context)
        self.blogService = BlogService(managedObjectContext: context)

        let api: WordPressComRestApi
        if let wpcomApi = accountService.defaultWordPressComAccount()?.wordPressComRestApi {
            api = wpcomApi
        } else {
            api = WordPressComRestApi.defaultApi(userAgent: WPUserAgent.wordPress())
        }
        self.remoteService = WordPressComServiceRemote(wordPressComRestApi: api)

        super.init(managedObjectContext: context)
    }

    // MARK: SiteAssemblyService

    private(set) var currentStatus: SiteAssemblyStatus = .idle {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.statusChangeHandler?(self.currentStatus)
            }
        }
    }

    /// This method serves as the entry point for creating an enhanced site. It consists of a few steps:
    /// 1. The creation request is first validated.
    /// 2. If a site passes validation, a new service invocation triggers creation.
    /// 3. The details of the created Blog are persisted to the client.
    ///
    /// Previously the site's theme & tagline were set post-creation. This is now handled on the server via Headstart.
    ///
    /// - Parameters:
    ///   - creationRequest:    the request with which to initiate site creation.
    ///   - changeHandler:      this closure is invoked when site assembly status changes occur.
    ///
    func createSite(creationRequest: SiteCreationRequest, changeHandler: SiteAssemblyStatusChangedHandler? = nil) {
        self.creationRequest = creationRequest
        self.statusChangeHandler = changeHandler

        beginAssembly()
        validatePendingRequest()
    }

    // MARK: Private behavior

    private func beginAssembly() {
        currentStatus = .inProgress
    }

    private func endFailedAssembly() {
        currentStatus = .failed
    }

    private func endSuccessfulAssembly() {
        // Here we designate the new site as the last used, so that it will be presented post-creation
        if let siteUrl = createdBlog?.url {
            RecentSitesService().touch(site: siteUrl)
            StoreContainer.shared.statsWidgets.refreshStatsWidgetsSiteList()
        }

        currentStatus = .succeeded
    }

    private func performRemoteSiteCreation() {
        guard let request = creationRequest else {
            self.endFailedAssembly()
            return
        }

        let validatedRequest = SiteCreationRequest(request: request)

        remoteService.createWPComSite(request: validatedRequest) { result in
            // Our result is of type SiteCreationResult, which can be either success or failure
            switch result {
            case .success(let response):
                // A successful response includes a separate success field advising of the outcome of the call.
                // In my testing, this has never been `false`, but we will be cautious.
                guard response.success == true else {
                    DDLogError("The service response indicates that it failed.")
                    self.endFailedAssembly()

                    return
                }

                self.synchronize(createdSite: response.createdSite)
            case .failure(let creationError):
                DDLogError("\(creationError)")
                self.endFailedAssembly()
            }
        }
    }

    private func synchronize(createdSite: CreatedSite) {
        guard let defaultAccount = accountService.defaultWordPressComAccount() else {
            endFailedAssembly()
            return
        }

        let xmlRpcUrlString = createdSite.xmlrpcString

        let blog: Blog
        if let existingBlog = blogService.findBlog(withXmlrpc: xmlRpcUrlString, in: defaultAccount) {
            blog = existingBlog
        } else {
            blog = blogService.createBlog(with: defaultAccount)
            blog.xmlrpc = xmlRpcUrlString
        }

        // The response payload returns a number encoded as a JSON string
        if let wpcomSiteIdentifier = Int(createdSite.identifier) {
            blog.dotComID = NSNumber(value: wpcomSiteIdentifier)
        }

        blog.url = createdSite.urlString
        blog.settings?.name = createdSite.title

        // the original service required a separate call to update the tagline post-creation
        blog.settings?.tagline = creationRequest?.tagline

        defaultAccount.defaultBlog = blog

        ContextManager.sharedInstance().save(managedObjectContext) { [weak self] in
            guard let self = self else {
                return
            }
            self.blogService.syncBlogAndAllMetadata(blog, completionHandler: {
                self.accountService.updateUserDetails(for: defaultAccount,
                                                      success: {
                                                        self.createdBlog = blog
                                                        self.endSuccessfulAssembly()
                },
                                                      failure: { error in self.endFailedAssembly() })
            })
        }
    }

    private func validatePendingRequest() {
        guard let requestPendingValidation = creationRequest else {
            endFailedAssembly()
            return
        }

        remoteService.createWPComSite(request: requestPendingValidation) { result in
            switch result {
            case .success:
                self.performRemoteSiteCreation()
            case .failure(let validationError):
                DDLogError("\(validationError)")
                self.endFailedAssembly()
            }
        }
    }
}
