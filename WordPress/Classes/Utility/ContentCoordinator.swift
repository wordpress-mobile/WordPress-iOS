
protocol ContentCoordinator {
    func displayReaderWithPostId(_ postID: NSNumber?, siteID: NSNumber?) throws
    func displayCommentsWithPostId(_ postID: NSNumber?, siteID: NSNumber?, commentID: NSNumber?, source: ReaderCommentsSource) throws
    func displayStatsWithSiteID(_ siteID: NSNumber?, url: URL?) throws
    func displayFollowersWithSiteID(_ siteID: NSNumber?, expirationTime: TimeInterval) throws
    func displayStreamWithSiteID(_ siteID: NSNumber?) throws
    func displayWebViewWithURL(_ url: URL, source: String)
    func displayFullscreenImage(_ image: UIImage)
    func displayPlugin(withSlug pluginSlug: String, on siteSlug: String) throws
    func displayBackupWithSiteID(_ siteID: NSNumber?) throws
    func displayScanWithSiteID(_ siteID: NSNumber?) throws
}


/// `ContentCoordinator` is intended to be used to easily navigate and display common elements natively
/// like Posts, Site streams, Comments, etc...
///
struct DefaultContentCoordinator: ContentCoordinator {
    enum DisplayError: Error {
        case missingParameter
        case unsupportedFeature
        case unsupportedType
    }

    private let mainContext: NSManagedObjectContext
    private weak var controller: UIViewController?

    init(controller: UIViewController, context: NSManagedObjectContext) {
        self.controller = controller
        mainContext = context
    }

    func displayReaderWithPostId(_ postID: NSNumber?, siteID: NSNumber?) throws {
        guard let postID = postID, let siteID = siteID else {
            throw DisplayError.missingParameter
        }

        let readerViewController = ReaderDetailViewController.controllerWithPostID(postID, siteID: siteID)
        controller?.navigationController?.pushFullscreenViewController(readerViewController, animated: true)
    }

    func displayCommentsWithPostId(_ postID: NSNumber?, siteID: NSNumber?, commentID: NSNumber?, source: ReaderCommentsSource) throws {
        guard let postID = postID, let siteID = siteID else {
            throw DisplayError.missingParameter
        }

        let commentsViewController = ReaderCommentsViewController(postID: postID, siteID: siteID, source: source)
        commentsViewController?.navigateToCommentID = commentID
        commentsViewController?.allowsPushingPostDetails = true
        controller?.navigationController?.pushViewController(commentsViewController!, animated: true)
    }

    func displayStatsWithSiteID(_ siteID: NSNumber?, url: URL? = nil) throws {
        guard let siteID = siteID,
              let blog = Blog.lookup(withID: siteID, in: mainContext),
              blog.supports(.stats)
        else {
            throw DisplayError.missingParameter
        }

        // Stats URLs should be of the form /stats/:time_period/:domain
        if let url = url {
            setTimePeriodForStatsURLIfPossible(url)
        }

        let statsViewController = StatsViewController()
        statsViewController.blog = blog
        controller?.navigationController?.pushViewController(statsViewController, animated: true)
    }

    private func setTimePeriodForStatsURLIfPossible(_ url: URL) {
        guard let key = SiteStatsDashboardViewController.lastSelectedStatsPeriodTypeKey else {
            return
        }

        let matcher = RouteMatcher(routes: UniversalLinkRouter.statsRoutes)
        let matches = matcher.routesMatching(url)
        if let match = matches.first,
           let action = match.action as? StatsRoute,
           let timePeriod = action.timePeriod {
            // Initializing a StatsPeriodType to ensure we have a valid period
            UserDefaults.standard.set(timePeriod.rawValue, forKey: key)
        }
    }

    func displayBackupWithSiteID(_ siteID: NSNumber?) throws {
        guard let siteID = siteID,
              let blog = Blog.lookup(withID: siteID, in: mainContext),
              let backupListViewController = BackupListViewController(blog: blog)
        else {
            throw DisplayError.missingParameter
        }

        controller?.navigationController?.pushViewController(backupListViewController, animated: true)
    }

    func displayScanWithSiteID(_ siteID: NSNumber?) throws {
        guard let siteID = siteID,
              let blog = Blog.lookup(withID: siteID, in: mainContext),
              blog.isScanAllowed()
        else {
            throw DisplayError.missingParameter
        }

        let scanViewController = JetpackScanViewController(blog: blog)
        controller?.navigationController?.pushViewController(scanViewController, animated: true)
    }

    func displayFollowersWithSiteID(_ siteID: NSNumber?, expirationTime: TimeInterval) throws {
        guard let siteID = siteID,
              let blog = Blog.lookup(withID: siteID, in: mainContext)
        else {
            throw DisplayError.missingParameter
        }

        SiteStatsInformation.sharedInstance.siteTimeZone = blog.timeZone
        SiteStatsInformation.sharedInstance.oauth2Token = blog.authToken
        SiteStatsInformation.sharedInstance.siteID = blog.dotComID

        let detailTableViewController = SiteStatsDetailTableViewController.loadFromStoryboard()
        detailTableViewController.configure(statSection: StatSection.insightsFollowersWordPress)
        controller?.navigationController?.pushViewController(detailTableViewController, animated: true)
    }

    func displayStreamWithSiteID(_ siteID: NSNumber?) throws {
        guard let siteID = siteID else {
            throw DisplayError.missingParameter
        }

        let browseViewController = ReaderStreamViewController.controllerWithSiteID(siteID, isFeed: false)
        controller?.navigationController?.pushViewController(browseViewController, animated: true)
    }

    func displayWebViewWithURL(_ url: URL, source: String) {
        if UniversalLinkRouter(routes: UniversalLinkRouter.readerRoutes).canHandle(url: url) {
            UniversalLinkRouter(routes: UniversalLinkRouter.readerRoutes).handle(url: url, source: .inApp(presenter: controller))
            return
        }

        let webViewController = WebViewControllerFactory.controllerAuthenticatedWithDefaultAccount(url: url, source: source)
        let navController = UINavigationController(rootViewController: webViewController)
        controller?.present(navController, animated: true)
    }

    func displayFullscreenImage(_ image: UIImage) {
        let imageViewController = WPImageViewController(image: image)
        imageViewController.modalTransitionStyle = .crossDissolve
        imageViewController.modalPresentationStyle = .fullScreen
        controller?.present(imageViewController, animated: true)
    }

    func displayPlugin(withSlug pluginSlug: String, on siteSlug: String) throws {
        guard let jetpack = jetpackSiteReff(with: siteSlug) else {
            throw DisplayError.missingParameter
        }
        let pluginVC = PluginViewController(slug: pluginSlug, site: jetpack)
        controller?.navigationController?.pushViewController(pluginVC, animated: true)
    }

    private func jetpackSiteReff(with slug: String) -> JetpackSiteRef? {
        let service = BlogService(managedObjectContext: mainContext)
        guard let blog = service.blog(byHostname: slug), let jetpack = JetpackSiteRef(blog: blog) else {
            return nil
        }
        return jetpack
    }
}
