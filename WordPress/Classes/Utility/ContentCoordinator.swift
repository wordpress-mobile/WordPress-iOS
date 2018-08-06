
import WordPressComStatsiOS

protocol ContentCoordinator {
    func displayReaderWithPostId(_ postID: NSNumber?, siteID: NSNumber?) throws
    func displayCommentsWithPostId(_ postID: NSNumber?, siteID: NSNumber?) throws
    func displayStatsWithSiteID(_ siteID: NSNumber?) throws
    func displayFollowersWithSiteID(_ siteID: NSNumber?, expirationTime: TimeInterval) throws
    func displayStreamWithSiteID(_ siteID: NSNumber?) throws
    func displayWebViewWithURL(_ url: URL)
    func displayFullscreenImage(_ image: UIImage)
    func displayPlugin(withSlug pluginSlug: String, on siteSlug: String) throws
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

    func displayCommentsWithPostId(_ postID: NSNumber?, siteID: NSNumber?) throws {
        guard let postID = postID, let siteID = siteID else {
            throw DisplayError.missingParameter
        }

        let commentsViewController = ReaderCommentsViewController(postID: postID, siteID: siteID)
        commentsViewController?.allowsPushingPostDetails = true
        controller?.navigationController?.pushViewController(commentsViewController!, animated: true)
    }

    func displayStatsWithSiteID(_ siteID: NSNumber?) throws {
        guard let blog = blogWithBlogID(siteID), blog.supports(.stats) else {
            throw DisplayError.missingParameter
        }

        let statsViewController = StatsViewController()
        statsViewController.blog = blog
        controller?.navigationController?.pushViewController(statsViewController, animated: true)
    }

    func displayFollowersWithSiteID(_ siteID: NSNumber?, expirationTime: TimeInterval) throws {
        guard let blog = blogWithBlogID(siteID) else {
            throw DisplayError.missingParameter
        }

        let statsViewController = newStatsViewController()
        statsViewController.selectedDate = Date()
        statsViewController.statsSection = .followers
        statsViewController.statsSubSection = .followersDotCom
        statsViewController.statsService = newStatsServiceWithBlog(blog, expirationTime: expirationTime)
        controller?.navigationController?.pushViewController(statsViewController, animated: true)
    }

    func displayStreamWithSiteID(_ siteID: NSNumber?) throws {
        guard let siteID = siteID else {
            throw DisplayError.missingParameter
        }

        let browseViewController = ReaderStreamViewController.controllerWithSiteID(siteID, isFeed: false)
        controller?.navigationController?.pushViewController(browseViewController, animated: true)
    }

    func displayWebViewWithURL(_ url: URL) {
        let webViewController = WebViewControllerFactory.controllerAuthenticatedWithDefaultAccount(url: url)
        let navController = UINavigationController(rootViewController: webViewController)
        controller?.present(navController, animated: true, completion: nil)
    }

    func displayFullscreenImage(_ image: UIImage) {
        let imageViewController = WPImageViewController(image: image)
        imageViewController.modalTransitionStyle = .crossDissolve
        imageViewController.modalPresentationStyle = .fullScreen
        controller?.present(imageViewController, animated: true, completion: nil)
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

    private func blogWithBlogID(_ blogID: NSNumber?) -> Blog? {
        guard let blogID = blogID else {
            return nil
        }

        let service = BlogService(managedObjectContext: mainContext)
        return service.blog(byBlogId: blogID)
    }

    private func newStatsServiceWithBlog(_ blog: Blog, expirationTime: TimeInterval) -> WPStatsService {
        let blogService = BlogService(managedObjectContext: mainContext)
        return WPStatsService(siteId: blog.dotComID,
                              siteTimeZone: blogService.timeZone(for: blog),
                              oauth2Token: blog.authToken,
                              andCacheExpirationInterval: expirationTime)
    }

    private func newStatsViewController() -> StatsViewAllTableViewController {
        let statsBundle = Bundle(for: WPStatsViewController.self)
        let storyboard = UIStoryboard(name: "SiteStats", bundle: statsBundle)
        let identifier = StatsViewAllTableViewController.classNameWithoutNamespaces()
        let statsViewController = storyboard.instantiateViewController(withIdentifier: identifier)

        return statsViewController as! StatsViewAllTableViewController
    }
}
