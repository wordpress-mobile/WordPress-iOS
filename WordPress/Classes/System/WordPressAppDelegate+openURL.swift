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
}
