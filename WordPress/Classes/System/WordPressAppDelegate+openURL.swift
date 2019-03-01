import WordPressAuthenticator

/// Custom pattern matcher used for our URL scheme
private func ~=(pattern: String, value: URL) -> Bool {
    return value.absoluteString.contains(pattern)
}

@objc extension WordPressAppDelegate {
    internal func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        DDLogInfo("Application launched with URL: \(url)");
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
        guard url.absoluteString.hasPrefix(WPComScheme) else {
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
        guard let query = url.query,
            let params = query.dictionaryFromQueryString(),
            params.count > 0 else {
                return false
        }

        let blogId = params.number(forKey: "blogId")
        let postId = params.number(forKey: "postId")

        WPTabBarController.sharedInstance()?.showReaderTab(forPost: postId, onBlog: blogId)

        return true
    }

    private func handleViewStats(url: URL) -> Bool {
        guard let query = url.query,
            let params = query.dictionaryFromQueryString(),
            params.count > 0 else {
                return false
        }

        let blogService = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        guard let siteId = params.number(forKey: "siteId"),
            let blog = blogService.blog(byBlogId: siteId) else {
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
        guard let query = url.query,
            let params = query.dictionaryFromQueryString(),
            let debugType = params.string(forKey: "type"),
            let debugKey = params.string(forKey: "key") else {
                return
        }

        if debugKey == ApiCredentials.debuggingKey(), debugType == "crashlytics_crash" {
            Crashlytics.sharedInstance().crash()
        }
    }

    /// Handle a call of wordpress://newpost?…
    ///
    /// This is partially a return of the old functionality: https://github.com/wordpress-mobile/WordPress-iOS/blob/d89b7ec712be1f2e11fb1228089771a25f5587c5/WordPress/Classes/ViewRelated/System/WPTabBarController.m#L388
    private func handleNewPost(url: URL) -> Bool {
        guard let query = url.query,
            let params = query.dictionaryFromQueryString() else {
                return false
        }

        let title = params.string(forKey: NewPostKey.title)
        let content = params.string(forKey: NewPostKey.content)
        let tags = params.string(forKey: NewPostKey.tags)

        // TODO: add ability to attach and image
        //let image = params.string(forKey: NewPostKey.image)

        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)
        guard let blog = blogService.lastUsedOrFirstBlog() else {
            return false
        }
        let post = PostService(managedObjectContext: context).createDraftPost(for: blog)
        post.postTitle = title
        post.setPostFormatText(content ?? "no")
        post.content = content
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
