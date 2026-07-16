import AutomatticTracks
import BuildSettingsKit
import SwiftUI
import WordPressData
import WordPressShared
import WordPressUI

@objc extension WordPressAppDelegate {
    /// Routes an inbound URL (custom scheme deep links, magic-login, migration, OAuth).
    /// Called by `WordPressSceneDelegate` for inbound URLs.
    @discardableResult
    func handle(url: URL) -> Bool {
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
        let wordPressExportRouter = MigrationDeepLinkRouter(
            urlForScheme: URL(string: AppScheme.wordpressMigrationV1.rawValue),
            routes: [WordPressExportRoute()]
        )
        if AppConfiguration.isWordPress,
            wordPressExportRouter.canHandle(url: url)
        {
            wordPressExportRouter.handle(url: url)
            return true
        }

        if url.scheme == JetpackNotificationMigrationService.wordPressScheme {
            return JetpackNotificationMigrationService.shared.handleNotificationMigrationOnWordPress()
        }

        if WordPressDotComAuthenticator.handleAppOpeningURL(url) {
            return true
        }

        guard url.scheme == BuildSettings.current.appURLScheme else {
            return false
        }

        // this works with our custom ~=
        switch url.host {
        case "newpost":
            return handleNewPost(url: url)
        case "newpage":
            return handleNewPage(url: url)
        case "viewpost":
            return handleViewPost(url: url)
        case "viewstats":
            return handleViewStats(url: url)
        case "debugging":
            return handleDebugging(url: url)
        case "send-session":
            return handleSendSession(url: url)
        case "receive-session":
            return handleReceiveSession(url: url)
        default:
            return false
        }
    }

    private func handleViewPost(url: URL) -> Bool {
        guard let params = url.queryItems,
            let blogId = params.intValue(of: "blogId"),
            let postId = params.intValue(of: "postId")
        else {
            return false
        }
        RootViewCoordinator.sharedPresenter.showReader(path: .post(postID: postId, siteID: blogId))

        return true
    }

    private func handleViewStats(url: URL) -> Bool {

        guard let params = url.queryItems,
            let siteId = params.intValue(of: "siteId"),
            let blog = try? Blog.lookup(withID: siteId, in: ContextManager.shared.mainContext)
        else {
            return false
        }

        guard JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled() else {
            // Display overlay
            RootViewCoordinator.sharedPresenter.showJetpackOverlayForDisabledEntryPoint()

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

        RootViewCoordinator.sharedPresenter.rootViewController.present(navController, animated: true, completion: nil)

        return true
    }

    private func handleDebugging(url: URL) -> Bool {
        guard let params = url.queryItems,
            let debugType = params.value(of: "type"),
            let debugKey = params.value(of: "key")
        else {
            return false
        }

        if debugKey == BuildSettings.current.secrets.debuggingKey, debugType == "force_crash" {
            WordPressAppDelegate.crashLogging?.crash()
        }

        return true
    }

    /// Handle a `send-session` deep link (produced by scanning a receiver's QR code) by asking the
    /// developer to confirm, then POSTing this device's session to the receiver. Internal builds
    /// only, and only for local-network destinations, so a crafted link can't exfiltrate the token
    /// to a public host.
    private func handleSendSession(url: URL) -> Bool {
        guard BuildConfiguration.current.isInternal else {
            return false
        }
        guard let presenter = window?.topmostPresentedViewController else {
            return false
        }

        // With host/port/pk (from a QR / deep link) confirm and send directly; without them, open
        // the browser to pick a receiver discovered over Bonjour.
        if let params = url.queryItems,
            let host = params.value(of: "host"),
            let portString = params.value(of: "port"),
            let port = UInt16(portString),
            let publicKeyToken = params.value(of: "pk"),
            let publicKey = DebugSessionTransferCrypto.decodePublicKey(publicKeyToken),
            DebugSessionTransferSender.isLocalHost(host)
        {
            DebugSessionTransferSendFlow.present(from: presenter, host: host, port: port, publicKey: publicKey)
        } else {
            let hostingController = UIHostingController(rootView: DebugSessionTransferBrowserView())
            let navigationController = UINavigationController(rootViewController: hostingController)
            hostingController.navigationItem.leftBarButtonItem = UIBarButtonItem(
                systemItem: .close,
                primaryAction: UIAction { [weak navigationController] _ in
                    navigationController?.dismiss(animated: true)
                }
            )
            presenter.present(navigationController, animated: true)
        }
        return true
    }

    /// Open the receiver screen from a `receive-session` deep link — handy for launching the
    /// listener without navigating the debug menu (e.g. via `simctl openurl`). Internal builds only.
    private func handleReceiveSession(url: URL) -> Bool {
        guard BuildConfiguration.current.isInternal else {
            return false
        }
        guard let presenter = window?.topmostPresentedViewController else {
            return false
        }

        let hostingController = UIHostingController(rootView: DebugSessionTransferReceiverView())
        let navigationController = UINavigationController(rootViewController: hostingController)
        hostingController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak navigationController] _ in
                navigationController?.dismiss(animated: true)
            }
        )
        presenter.present(navigationController, animated: true)
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
            let contentRaw = params.value(of: NewPostKey.content)
        else {
            return false
        }

        let title = params.value(of: NewPostKey.title)
        let tags = params.value(of: NewPostKey.tags)

        let context = ContextManager.shared.mainContext
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

        WPAppAnalytics.track(
            .editorCreatedPost,
            withProperties: [WPAppAnalyticsKeyTapSource: "url_scheme", WPAppAnalyticsKeyPostType: "post"]
        )

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
            let contentRaw = params.value(of: NewPostKey.content)
        else {
            return false
        }

        let title = params.value(of: NewPostKey.title)

        let context = ContextManager.shared.mainContext
        guard let blog = Blog.lastUsedOrFirst(in: context) else {
            return false
        }

        // Should more formats be accepted be accepted in the future, this line would have to be expanded to accomodate it.
        let contentEscaped = contentRaw.escapeHtmlNamedEntities()

        RootViewCoordinator.sharedPresenter.showPageEditor(
            blog: blog,
            title: title,
            content: contentEscaped,
            source: "url_scheme"
        )

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
        self.first(where: { $0.name == key })?.value
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
            !queryItems.isEmpty
        else {
            return nil
        }
        return queryItems
    }
}
