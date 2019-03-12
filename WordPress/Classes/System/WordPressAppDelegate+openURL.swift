import WordPressAuthenticator

/// Custom pattern matcher used for our URL scheme
private func ~=(pattern: String, value: URL) -> Bool {
    return value.absoluteString.contains(pattern)
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
    func queryParams() -> [URLQueryItem]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
            let queryItems = components.queryItems,
            queryItems.count > 0 else {
                return nil
        }
        return queryItems
    }
}

@objc extension WordPressAppDelegate {
    internal func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        DDLogInfo("Application launched with URL: \(url)")
        var returnValue = false

        // 1. check if hockey can open this URL
        var hockeyOptions: [String: Any] = [:]
        for (key, value) in options {
            hockeyOptions[key.rawValue] = value
        }
        if hockey.handleOpen(url, options: hockeyOptions) {
            returnValue = true
        }

        // 2. check if this is a Google login URL
        if WordPressAuthenticator.shared.handleGoogleAuthUrl(url,
                                                             sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                                                             annotation: options[UIApplication.OpenURLOptionsKey.annotation]) {
            returnValue = true
        }

        // 3. let's see if it's our wpcom scheme
        guard url.scheme == WPComScheme else {
            return returnValue
        }

        // this works with our custom ~=
        switch url {
        case "newpost":
            returnValue = handleNewPost(url: url)
        case "magic-login":
            returnValue = handleMagicLogin(url: url)
        case "viewpost":
            returnValue = handleViewPost(url: url)
        case "viewstats":
            returnValue = handleViewStats(url: url)
        case "debugging":
            handleDebugging(url: url)
        default:
            break
        }

        return returnValue
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
        guard let params = url.queryParams(),
            let blogId = params.intValue(of: "blogId"),
            let postId = params.intValue(of: "postId") else {
            return false
        }

        WPTabBarController.sharedInstance()?.showReaderTab(forPost: NSNumber(value: postId), onBlog: NSNumber(value: blogId))

        return true
    }

    private func handleViewStats(url: URL) -> Bool {
        let blogService = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        guard let params = url.queryParams(),
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

    @nonobjc private func handleDebugging(url: URL) {
        guard let params = url.queryParams(),
            let debugType = params.value(of: "type"),
            let debugKey = params.value(of: "key") else {
            return
        }

        if debugKey == ApiCredentials.debuggingKey(), debugType == "crashlytics_crash" {
            Crashlytics.sharedInstance().crash()
        }
    }

    /// Handle a call of wordpress://newpost?…
    ///
    /// - Parameter url: URL of the request
    /// - Returns: true if the url was handled
    /// - Note: **url** should contain param for `content` to be useful. Also supports `title` and `tags`. Currently `content` is assumed to be
    ///         text. May support other formats, such as HTML or Markdown in the future.
    ///
    /// This is mostly a return of the old functionality: https://github.com/wordpress-mobile/WordPress-iOS/blob/d89b7ec712be1f2e11fb1228089771a25f5587c5/WordPress/Classes/ViewRelated/System/WPTabBarController.m#L388```
    private func handleNewPost(url: URL) -> Bool {
        guard let params = url.queryParams() else {
            return false
        }

        let title = params.value(of: NewPostKey.title)
        let contentRaw = params.value(of: NewPostKey.content) ?? ""
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

        return true
    }

    private enum NewPostKey {
        static let title = "title"
        static let content = "content"
        static let tags = "tags"
        static let image = "image"
    }
}
