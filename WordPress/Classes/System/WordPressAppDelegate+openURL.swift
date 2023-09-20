import WordPressAuthenticator
import AutomatticTracks

@objc extension WordPressAppDelegate {
    internal func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {

        let redactedURL = LoggingURLRedactor.redactedURL(url)
        DDLogInfo("Application launched with URL: \(redactedURL)")

        if QRLoginCoordinator.didHandle(url: url) {
            return true
        }

        if UniversalLinkRouter.shared.canHandle(url: url) {
            UniversalLinkRouter.shared.handle(url: url, shouldTrack: true)
            return true
        }

        /// WordPress only. Handle deeplink from JP that requests data export.
        let wordPressExportRouter = MigrationDeepLinkRouter(urlForScheme: URL(string: AppScheme.wordpressMigrationV1.rawValue),
                                                            routes: [WordPressExportRoute()])
        if AppConfiguration.isWordPress,
           wordPressExportRouter.canHandle(url: url) {
            wordPressExportRouter.handle(url: url)
            return true
        }

        if url.scheme == JetpackNotificationMigrationService.wordPressScheme {
            return JetpackNotificationMigrationService.shared.handleNotificationMigrationOnWordPress()
        }

        guard url.scheme == WPComScheme else {
            return false
        }

        // this works with our custom ~=
        switch url.host {
        case "newpost":
            return handleNewPost(url: url)
        case "newpage":
            return handleNewPage(url: url)
        case "magic-login":
            return handleMagicLogin(url: url)
        case "viewpost":
            return handleViewPost(url: url)
        case "viewstats":
            return handleViewStats(url: url)
        case "debugging":
            return handleDebugging(url: url)
        default:
            return false
        }
    }

    private func handleMagicLogin(url: URL) -> Bool {
        DDLogInfo("App launched with authentication link")

        guard AccountHelper.noWordPressDotComAccount || url.isJetpackConnect else {
            DDLogInfo("The user clicked on a login or signup magic link when already logged into a WPCom account.  Since this is not a Jetpack connection attempt we're cancelling the operation.")
            return false
        }

        guard let rvc = window?.rootViewController else {
            return false
        }

        return WordPressAuthenticator.openAuthenticationURL(url, fromRootViewController: rvc)
    }

    private func handleViewPost(url: URL) -> Bool {
        guard let params = url.queryItems,
            let blogId = params.intValue(of: "blogId"),
            let postId = params.intValue(of: "postId") else {
            return false
        }

        RootViewCoordinator.sharedPresenter.showReaderTab(forPost: NSNumber(value: postId), onBlog: NSNumber(value: blogId))

        return true
    }

    private func handleViewStats(url: URL) -> Bool {

        guard let params = url.queryItems,
            let siteId = params.intValue(of: "siteId"),
            let blog = try? Blog.lookup(withID: siteId, in: ContextManager.shared.mainContext) else {
            return false
        }

        guard JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled() else {
            // Display overlay
            RootViewCoordinator.sharedPresenter.mySitesCoordinator.displayJetpackOverlayForDisabledEntryPoint()

            // Track incorrect access
            let properties = ["calling_function": "deep_link", "url": url.absoluteString]
            WPAnalytics.track(.jetpackFeatureIncorrectlyAccessed, properties: properties)
            return false
        }

        let statsViewController = StatsViewController()
        statsViewController.blog = blog

        let currentSiteID = SiteStatsInformation.sharedInstance.siteID

        statsViewController.dismissBlock = {
            // The currently selected site could be different from the URL site.
            // After the Stats modal is dismissed, restore the selected site's ID
            // so the Stats view displays the correct stats.
            SiteStatsInformation.sharedInstance.siteID = currentSiteID

            RootViewCoordinator.sharedPresenter.rootViewController.dismiss(animated: true, completion: nil)
        }

        let navController = UINavigationController(rootViewController: statsViewController)
        navController.modalPresentationStyle = .currentContext
        navController.navigationBar.isTranslucent = false

        RootViewCoordinator.sharedPresenter.rootViewController.present(navController, animated: true, completion: nil)

        return true
    }

    private func handleDebugging(url: URL) -> Bool {
        guard let params = url.queryItems,
            let debugType = params.value(of: "type"),
            let debugKey = params.value(of: "key") else {
            return false
        }

        if debugKey == ApiCredentials.debuggingKey, debugType == "force_crash" {
            WordPressAppDelegate.crashLogging?.crash()
        }

        return true
    }

    /// Handle a call of wordpress://newpost?…
    ///
    /// - Parameter url: URL of the request
    /// - Returns: true if the url was handled
    /// - Note: **url** must contain param for `content` at minimum. Also supports `title` and `tags`. Currently `content` is assumed to be
    ///         text. May support other formats, such as HTML or Markdown in the future.
    ///
    /// This is mostly a return of the old functionality: https://github.com/wordpress-mobile/WordPress-iOS/blob/d89b7ec712be1f2e11fb1228089771a25f5587c5/WordPress/Classes/ViewRelated/System/WPTabBarController.m#L388```
    private func handleNewPost(url: URL) -> Bool {
        guard let params = url.queryItems,
            let contentRaw = params.value(of: NewPostKey.content) else {
                return false
        }

        let title = params.value(of: NewPostKey.title)
        let tags = params.value(of: NewPostKey.tags)

        let context = ContextManager.sharedInstance().mainContext
        guard let blog = Blog.lastUsedOrFirst(in: context) else {
            return false
        }

        // Should more formats be accepted in the future, this line would have to be expanded to accomodate it.
        let contentEscaped = contentRaw.escapeHtmlNamedEntities()

        let post = blog.createDraftPost()
        post.postTitle = title
        post.content = contentEscaped
        post.tags = tags

        let postVC = EditPostViewController(post: post)
        postVC.modalPresentationStyle = .fullScreen

        RootViewCoordinator.sharedPresenter.rootViewController.present(postVC, animated: true, completion: nil)

        WPAppAnalytics.track(.editorCreatedPost, withProperties: [WPAppAnalyticsKeyTapSource: "url_scheme", WPAppAnalyticsKeyPostType: "post"])

        return true
    }

    /// Handle a call of wordpress://newpage?…
    ///
    /// - Parameter url: URL of the request
    /// - Returns: true if the url was handled
    /// - Note: **url** must contain param for `content` at minimum. Also supports `title`. Currently `content` is assumed to be
    ///         text. May support other formats, such as HTML or Markdown in the future.
    private func handleNewPage(url: URL) -> Bool {
        guard let params = url.queryItems,
            let contentRaw = params.value(of: NewPostKey.content) else {
                return false
        }

        let title = params.value(of: NewPostKey.title)

        let context = ContextManager.sharedInstance().mainContext
        guard let blog = Blog.lastUsedOrFirst(in: context) else {
            return false
        }

        // Should more formats be accepted be accepted in the future, this line would have to be expanded to accomodate it.
        let contentEscaped = contentRaw.escapeHtmlNamedEntities()

        RootViewCoordinator.sharedPresenter.showPageEditor(blog: blog, title: title, content: contentEscaped, source: "url_scheme")

        return true
    }


    private enum NewPostKey {
        static let title = "title"
        static let content = "content"
        static let tags = "tags"
        static let image = "image"
    }
}

private extension Array where Element == URLQueryItem {
    func value(of key: String) -> String? {
        return self.first(where: { $0.name == key })?.value
    }

    func intValue(of key: String) -> Int? {
        guard let value = value(of: key) else {
            return nil
        }
        return Int(value)
    }
}

private extension URL {
    var queryItems: [URLQueryItem]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
            let queryItems = components.queryItems,
            queryItems.count > 0 else {
                return nil
        }
        return queryItems
    }
}
