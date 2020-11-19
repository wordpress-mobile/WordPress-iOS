import Foundation

class ReaderDetailCoordinator {

    /// Key for restoring the VC post
    static let restorablePostObjectURLKey: String = "RestorablePostObjectURLKey"

    /// A post to be displayed
    var post: ReaderPost? {
        didSet {
            postInUse(true)
            indexReaderPostInSpotlight()
        }
    }

    /// A post URL to be loaded and be displayed
    var postURL: URL?

    /// Called if the view controller's post fails to load
    var postLoadFailureBlock: (() -> Void)? = nil

    /// An authenticator to ensure any request made to WP sites is properly authenticated
    lazy var authenticator: RequestAuthenticator? = {
        guard let account = AccountService(managedObjectContext: coreDataStack.mainContext).defaultWordPressComAccount() else {
            DDLogInfo("Account not available for Reader authentication")
            return nil
        }

        return RequestAuthenticator(account: account)
    }()

    /// Core Data stack manager
    private let coreDataStack: CoreDataStack

    /// Reader Post Service
    private let service: ReaderPostService

    /// Reader Topic Service
    private let topicService: ReaderTopicService

    /// Post Sharing Controller
    private let sharingController: PostSharingController

    /// Reader Link Router
    private let readerLinkRouter: UniversalLinkRouter

    /// Reader View
    private weak var view: ReaderDetailView?

    /// Reader View Controller
    private var viewController: UIViewController? {
        return view as? UIViewController
    }

    /// A post ID to fetch
    private(set) var postID: NSNumber?

    /// A site ID to be used to fetch a post
    private(set) var siteID: NSNumber?

    /// If the site is an external feed (not hosted at WPcom and not using Jetpack)
    private(set) var isFeed: Bool?

    /// The perma link URL for the loaded post
    private var permaLinkURL: URL? {
        guard let postURLString = post?.permaLink else {
            return nil
        }

        return URL(string: postURLString)
    }

    /// Initialize the Reader Detail Coordinator
    ///
    /// - Parameter service: a Reader Post Service
    init(coreDataStack: CoreDataStack = ContextManager.shared,
         service: ReaderPostService = ReaderPostService(managedObjectContext: ContextManager.sharedInstance().mainContext),
         topicService: ReaderTopicService = ReaderTopicService(managedObjectContext: ContextManager.sharedInstance().mainContext),
         sharingController: PostSharingController = PostSharingController(),
         readerLinkRouter: UniversalLinkRouter = UniversalLinkRouter(routes: UniversalLinkRouter.readerRoutes),
         view: ReaderDetailView) {
        self.coreDataStack = coreDataStack
        self.service = service
        self.topicService = topicService
        self.sharingController = sharingController
        self.readerLinkRouter = readerLinkRouter
        self.view = view
    }

    deinit {
        postInUse(false)
    }

    /// Start the cordinator
    ///
    func start() {
        view?.showLoading()

        if post != nil {
            renderPostAndBumpStats()
        } else if let siteID = siteID, let postID = postID, let isFeed = isFeed {
            fetch(postID: postID, siteID: siteID, isFeed: isFeed)
        } else if let postURL = postURL {
            fetch(postURL)
        }
    }

    /// Share the current post
    ///
    func share(fromView anchorView: UIView) {
        guard let post = post, let view = viewController else {
            return
        }

        sharingController.shareReaderPost(post, fromView: anchorView, inViewController: view)

        WPAnalytics.track(.readerSharedItem)
    }

    /// Set a postID, siteID and isFeed
    ///
    /// - Parameter postID: A post ID to fetch
    /// - Parameter siteID: A site ID to fetch
    /// - Parameter isFeed: If the site is an external feed (not hosted at WPcom and not using Jetpack)
    func set(postID: NSNumber, siteID: NSNumber, isFeed: Bool) {
        self.postID = postID
        self.siteID = siteID
        self.isFeed = isFeed
    }

    /// Show more about a specific site in Discovery
    ///
    func showMore() {
        guard let post = post, post.sourceAttribution != nil else {
            return
        }

        if let blogID = post.sourceAttribution.blogID {
            let controller = ReaderStreamViewController.controllerWithSiteID(blogID, isFeed: false)
            viewController?.navigationController?.pushViewController(controller, animated: true)
            return
        }

        var path: String?
        if post.sourceAttribution.attributionType == SourcePostAttributionTypePost {
            path = post.sourceAttribution.permalink
        } else {
            path = post.sourceAttribution.blogURL
        }

        if let path = path, let linkURL = URL(string: path) {
            presentWebViewController(linkURL)
        }
    }

    /// Loads an image (or GIF) from a URL and displays it in fullscreen
    ///
    /// - Parameter url: URL of the image or gif
    func presentImage(_ url: URL) {
        let imageViewController = WPImageViewController(url: url)
        imageViewController.readerPost = post
        imageViewController.modalTransitionStyle = .crossDissolve
        imageViewController.modalPresentationStyle = .fullScreen

        viewController?.present(imageViewController, animated: true)
    }

    /// Open the postURL in a separated view controller
    ///
    func openInBrowser() {
        guard
            let permaLink = post?.permaLink,
            let postURL = URL(string: permaLink)
        else {
            return
        }

        WPAnalytics.track(.readerArticleVisited)
        presentWebViewController(postURL)
    }

    /// Some posts have content from private sites that need special cookies
    ///
    /// Use this method to make sure these cookies are downloaded.
    /// - Parameter webView: the webView where the post will be rendered
    /// - Parameter completion: a completion block
    func storeAuthenticationCookies(in webView: WKWebView, completion: @escaping () -> Void) {
        guard let authenticator = authenticator,
            let postURL = permaLinkURL else {
            completion()
            return
        }

        authenticator.request(url: postURL, cookieJar: webView.configuration.websiteDataStore.httpCookieStore) { _ in
            completion()
        }
    }

    /// Requests a ReaderPost from the service and updates the View.
    ///
    /// Use this method to fetch a ReaderPost.
    /// - Parameter postID: a post identification
    /// - Parameter siteID: a site identification
    /// - Parameter isFeed: a Boolean indicating if the site is an external feed (not hosted at WPcom and not using Jetpack)
    private func fetch(postID: NSNumber, siteID: NSNumber, isFeed: Bool) {
        service.fetchPost(postID.uintValue,
                          forSite: siteID.uintValue,
                          isFeed: isFeed,
                          success: { [weak self] post in
                            self?.post = post
                            self?.renderPostAndBumpStats()
        }, failure: { [weak self] _ in
            self?.postURL == nil ? self?.view?.showError() : self?.view?.showErrorWithWebAction()
            self?.reportPostLoadFailure()
        })
    }


    /// Requests a ReaderPost from the service and updates the View.
    ///
    /// Use this method to fetch a ReaderPost from a URL.
    /// - Parameter url: a post URL
    private func fetch(_ url: URL) {
        service.fetchPost(at: url,
                          success: { [weak self] post in
                            self?.post = post
                            self?.renderPostAndBumpStats()
        }, failure: { [weak self] error in
            DDLogError("Error fetching post for detail: \(String(describing: error?.localizedDescription))")
            self?.postURL == nil ? self?.view?.showError() : self?.view?.showErrorWithWebAction()
            self?.reportPostLoadFailure()
        })
    }

    private func renderPostAndBumpStats() {
        guard let post = post else {
            return
        }

        view?.render(post)

        bumpStats()
        bumpPageViewsForPost()
    }

    /// If the loaded URL contains a hash/anchor then jump to that spot in the post content
    /// once it loads
    ///
    private func scrollToHashIfNeeded() {
        guard
            let url = postURL,
            let hash = URLComponents(url: url, resolvingAgainstBaseURL: true)?.fragment
        else {
            return
        }

        view?.scroll(to: hash)
    }

    /// Shows the current post site posts in a new screen
    ///
    private func previewSite() {
        guard let post = post else {
            return
        }

        let controller = ReaderStreamViewController.controllerWithSiteID(post.siteID, isFeed: post.isExternal)
        viewController?.navigationController?.pushViewController(controller, animated: true)

        let properties = ReaderHelpers.statsPropertiesForPost(post, andValue: post.blogURL as AnyObject?, forKey: "URL")
        WPAppAnalytics.track(.readerSitePreviewed, withProperties: properties)
    }

    /// Show a menu with options forthe current post's site
    ///
    private func showMenu(_ anchorView: UIView) {
        guard let post = post,
            let context = post.managedObjectContext else {
            return
        }

        guard post.isFollowing else {
            ReaderPostMenu.showMenuForPost(post, fromView: anchorView, inViewController: viewController)
            return
        }

        let service: ReaderTopicService = ReaderTopicService(managedObjectContext: context)
        let siteTopic: ReaderSiteTopic? = service.findSiteTopic(withSiteID: post.siteID)

        ReaderPostMenu.showMenuForPost(post, topic: siteTopic, fromView: anchorView, inViewController: viewController)
    }

    private func showTopic(_ topic: String) {
        let controller = ReaderStreamViewController.controllerWithTagSlug(topic)
        viewController?.navigationController?.pushViewController(controller, animated: true)
    }

    /// Show a list with posts contianing this tag
    ///
    private func showTag() {
        guard let post = post else {
            return
        }

        let controller = ReaderStreamViewController.controllerWithTagSlug(post.primaryTagSlug)
        viewController?.navigationController?.pushViewController(controller, animated: true)

        let properties = ReaderHelpers.statsPropertiesForPost(post, andValue: post.primaryTagSlug as AnyObject?, forKey: "tag")
        WPAppAnalytics.track(.readerTagPreviewed, withProperties: properties)
    }

    /// Given a URL presents it the best way possible.
    ///
    /// If it's an image, shows it fullscreen.
    /// If it's a fullscreen Story link, open it in the webview controller.
    /// If it's a post, open a new detail screen.
    /// If it's a link protocol (tel: / sms: / mailto:), take the correct action.
    /// If it's a regular URL, open it in the webview controller.
    ///
    /// - Parameter url: the URL to be handled
    func handle(_ url: URL) {
        // If the URL has an anchor (#)
        // and the URL is equal to the current post URL
        if
            let hash = URLComponents(url: url, resolvingAgainstBaseURL: true)?.fragment,
            let postURL = permaLinkURL,
            postURL.isHostAndPathEqual(to: url)
        {
            view?.scroll(to: hash)
        } else if url.pathExtension.contains("gif") || url.pathExtension.contains("jpg") || url.pathExtension.contains("jpeg") || url.pathExtension.contains("png") {
            presentImage(url)
        } else if url.query?.contains("wp-story") ?? false {
            presentWebViewController(url)
        } else if readerLinkRouter.canHandle(url: url) {
            readerLinkRouter.handle(url: url, shouldTrack: false, source: viewController)
        } else if url.isWordPressDotComPost {
            presentReaderDetail(url)
        } else if url.isLinkProtocol {
            readerLinkRouter.handle(url: url, shouldTrack: false, source: viewController)
        } else {
            presentWebViewController(url)
        }
    }


    /// Called after the webView fully loads
    func webViewDidLoad() {
        scrollToHashIfNeeded()
    }

    /// Show the featured image fullscreen
    ///
    private func showFeaturedImage(_ sender: CachedAnimatedImageView) {
        guard let post = post else {
            return
        }

        var controller: WPImageViewController
        if post.featuredImageURL.isGif, let data = sender.animatedGifData {
            controller = WPImageViewController(gifData: data)
        } else if let featuredImage = sender.image {
            controller = WPImageViewController(image: featuredImage)
        } else {
            return
        }

        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        viewController?.present(controller, animated: true)
    }

    private func followSite() {
        guard let post = post else {
            return
        }

        ReaderFollowAction().execute(with: post,
                                     context: coreDataStack.mainContext,
                                     completion: { [weak self] in
                                         self?.view?.updateHeader()
                                     },
                                     failure: { [weak self] in
                                         self?.view?.updateHeader()
                                     })
    }

    /// Given a URL presents it in a new Reader detail screen
    ///
    private func presentReaderDetail(_ url: URL) {
        let readerDetail = ReaderDetailViewController.controllerWithPostURL(url)
        viewController?.navigationController?.pushViewController(readerDetail, animated: true)
    }

    /// Given a URL presents it in a web view controller screen
    ///
    /// - Parameter url: the URL to be loaded
    private func presentWebViewController(_ url: URL) {
        var url = url
        if url.host == nil {
            if let postURL = permaLinkURL {
                url = URL(string: url.absoluteString, relativeTo: postURL)!
            }
        }
        let configuration = WebViewControllerConfiguration(url: url)
        configuration.authenticateWithDefaultAccount()
        configuration.addsWPComReferrer = true
        let controller = WebViewControllerFactory.controller(configuration: configuration)
        let navController = UINavigationController(rootViewController: controller)
        viewController?.present(navController, animated: true)
    }

    /// Report to the callback that the post failed to load
    private func reportPostLoadFailure() {
        postLoadFailureBlock?()

        // We'll nil out the failure block so we don't perform multiple callbacks
        postLoadFailureBlock = nil
    }

    /// Change post's inUse property and saves the context
    private func postInUse(_ inUse: Bool) {
        guard let context = post?.managedObjectContext else {
            return
        }

        post?.inUse = inUse
        coreDataStack.save(context)
    }

    /// Index the post in Spotlight
    private func indexReaderPostInSpotlight() {
        guard let post = post else {
            return
        }

        SearchManager.shared.indexItem(post)
    }

    // MARK: - Analytics

    /// Bump WP App Analytics
    ///
    private func bumpStats() {
        guard let readerPost = post else {
            return
        }

        let isOfflineView = ReachabilityUtils.isInternetReachable() ? "no" : "yes"
        let detailType = readerPost.topic?.type == ReaderSiteTopic.TopicType ? DetailAnalyticsConstants.TypePreviewSite : DetailAnalyticsConstants.TypeNormal


        var properties = ReaderHelpers.statsPropertiesForPost(readerPost, andValue: nil, forKey: nil)
        properties[DetailAnalyticsConstants.TypeKey] = detailType
        properties[DetailAnalyticsConstants.OfflineKey] = isOfflineView
        WPAppAnalytics.track(.readerArticleOpened, withProperties: properties)

        if let railcar = readerPost.railcarDictionary() {
            WPAppAnalytics.trackTrainTracksInteraction(.readerArticleOpened, withProperties: railcar)
        }
    }

    /// Bum post page view
    ///
    private func bumpPageViewsForPost() {
        guard let readerPost = post else {
            return
        }

        ReaderHelpers.bumpPageViewForPost(readerPost)
    }

    private struct DetailAnalyticsConstants {
        static let TypeKey = "post_detail_type"
        static let TypeNormal = "normal"
        static let TypePreviewSite = "preview_site"
        static let OfflineKey = "offline_view"
        static let PixelStatReferrer = "https://wordpress.com/"
    }
}

// MARK: - ReaderDetailHeaderViewDelegate
extension ReaderDetailCoordinator: ReaderDetailHeaderViewDelegate {
    func didTapBlogName() {
        previewSite()
    }

    func didTapMenuButton(_ sender: UIView) {
        showMenu(sender)
    }

    func didTapTagButton() {
        showTag()
    }

    func didTapHeaderAvatar() {
        previewSite()
    }

    func didTapFollowButton() {
        followSite()
    }

    func didSelectTopic(_ topic: String) {
        showTopic(topic)
    }
}

// MARK: - ReaderDetailFeaturedImageViewDelegate
extension ReaderDetailCoordinator: ReaderDetailFeaturedImageViewDelegate {
    func didTapFeaturedImage(_ sender: CachedAnimatedImageView) {
        showFeaturedImage(sender)
    }
}

// MARK: - State Restoration

extension ReaderDetailCoordinator {
    static func viewController(withRestorationIdentifierPath identifierComponents: [String],
                                      coder: NSCoder) -> UIViewController? {
        guard let path = coder.decodeObject(forKey: restorablePostObjectURLKey) as? String else {
            return nil
        }

        let context = ContextManager.sharedInstance().mainContext
        guard let url = URL(string: path),
            let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url) else {
            return nil
        }

        guard let post = (try? context.existingObject(with: objectID)) as? ReaderPost else {
            return nil
        }

        return ReaderDetailViewController.controllerWithPost(post)
    }


    func encodeRestorableState(with coder: NSCoder) {
        if let post = post {
            coder.encode(post.objectID.uriRepresentation().absoluteString, forKey: type(of: self).restorablePostObjectURLKey)
        }
    }
}
