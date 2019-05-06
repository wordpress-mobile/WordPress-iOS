import WordPressAuthenticator

@objc extension WordPressAppDelegate {
    internal func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        DDLogInfo("Application launched with URL: \(url)")

        guard !handleHockey(url: url, options: options) else {
            return true
        }

        guard !handleGoogleAuth(url: url, options: options) else {
            return true
        }

        // 3. let's see if it's our wpcom scheme
        guard url.scheme == WPComScheme else {
            return false
        }

        // this works with our custom ~=
        switch url.host {
        case "newpost":
            return handleNewPost(url: url)
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

    private func handleHockey(url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        var hockeyOptions: [String: Any] = [:]
        for (key, value) in options {
            hockeyOptions[key.rawValue] = value
        }

        if hockey.handleOpen(url, options: hockeyOptions) {
            return true
        }
        return false
    }

    private func handleGoogleAuth(url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        if WordPressAuthenticator.shared.handleGoogleAuthUrl(url,
                                                             sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                                                             annotation: options[UIApplication.OpenURLOptionsKey.annotation]) {
            return true
        }

        return false
    }

    private func handleMagicLogin(url: URL) -> Bool {
        DDLogInfo("App launched with authentication link")
        let allowWordPressComAuth = !AccountHelper.isDotcomAvailable()
        guard let rvc = window.rootViewController else {
            return false
        }
        return WordPressAuthenticator.openAuthenticationURL(url,
                                                            allowWordPressComAuth: allowWordPressComAuth,
                                                            fromRootViewController: rvc)
    }

    private func handleViewPost(url: URL) -> Bool {
        guard let params = url.queryItems,
            let blogId = params.intValue(of: "blogId"),
            let postId = params.intValue(of: "postId") else {
            return false
        }

        WPTabBarController.sharedInstance()?.showReaderTab(forPost: NSNumber(value: postId), onBlog: NSNumber(value: blogId))

        return true
    }

    private func handleViewStats(url: URL) -> Bool {
        let blogService = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        guard let params = url.queryItems,
            let siteId = params.intValue(of: "siteId"),
            let blog = blogService.blog(byBlogId: NSNumber(value: siteId)) else {
            return false
        }

        let statsViewController = StatsViewController()
        statsViewController.blog = blog
        statsViewController.dismissBlock = {
            WPTabBarController.sharedInstance()?.dismiss(animated: true, completion: nil)
        }

        let navController = UINavigationController(rootViewController: statsViewController)
        navController.modalPresentationStyle = .currentContext
        navController.navigationBar.isTranslucent = false

        WPTabBarController.sharedInstance()?.present(navController, animated: true, completion: nil)

        return true
    }

    private func handleDebugging(url: URL) -> Bool {
        guard let params = url.queryItems,
            let debugType = params.value(of: "type"),
            let debugKey = params.value(of: "key") else {
            return false
        }

        if debugKey == ApiCredentials.debuggingKey(), debugType == "force_crash" {
            WPCrashLogging.crash()
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
        let blogService = BlogService(managedObjectContext: context)
        guard let blog = blogService.lastUsedOrFirstBlog() else {
            return false
        }

        // Should more formats be accepted be accepted in the future, this line would have to be expanded to accomodate it.
        let contentEscaped = contentRaw.escapeHtmlNamedEntities()

        let post = PostService(managedObjectContext: context).createDraftPost(for: blog)
        post.postTitle = title
        post.content = contentEscaped
        post.tags = tags

        let postVC = EditPostViewController(post: post)
        postVC.modalPresentationStyle = .fullScreen

        WPTabBarController.sharedInstance()?.present(postVC, animated: true, completion: nil)

        WPAppAnalytics.track(.editorCreatedPost, withProperties: ["tap_source": "url_scheme"])

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
