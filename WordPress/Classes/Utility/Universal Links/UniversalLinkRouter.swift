import Foundation

/// UniversalLinkRouter keeps a list of possible URL routes that are exposed
/// via universal links, and handles incoming links to trigger the appropriate route.
///
struct UniversalLinkRouter {
    private let matcher: RouteMatcher

    init(routes: [Route], redirects: [Route] = []) {
        matcher = RouteMatcher(routes: routes, redirects: redirects)
    }

    // A singleton is less than ideal, but we're currently using this from the
    // app delegate, and because it's primarily written in objective-c we can't
    // add a struct property there.
    //
    static let shared = UniversalLinkRouter(routes: routes,
                                            redirects: redirects)

    static let routes: [Route] =
        MeRoutes +
        NewPostRoutes +
        NotificationsRoutes +
        ReaderRoutes +
        StatsRoutes +
        MySitesRoutes +
        AppBannerRoutes

    static let MeRoutes: [Route] = [
        MeRoute(),
        MeAccountSettingsRoute(),
        MeNotificationSettingsRoute()
    ]

    static let NewPostRoutes: [Route] = [
        NewPostRoute(),
        NewPostForSiteRoute()
    ]

    static let NotificationsRoutes: [Route] = [
        NotificationsRoute()
    ]

    static let ReaderRoutes: [Route] = [
        ReaderRoute.root,
        ReaderRoute.discover,
        ReaderRoute.search,
        ReaderRoute.a8c,
        ReaderRoute.likes,
        ReaderRoute.manageFollowing,
        ReaderRoute.list,
        ReaderRoute.tag,
        ReaderRoute.feed,
        ReaderRoute.blog,
        ReaderRoute.feedsPost,
        ReaderRoute.blogsPost
    ]

    static let StatsRoutes: [Route] = [
        StatsRoute.root,
        StatsRoute.site,
        StatsRoute.daySite,
        StatsRoute.weekSite,
        StatsRoute.monthSite,
        StatsRoute.yearSite,
        StatsRoute.insights,
        StatsRoute.dayCategory,
        StatsRoute.annualStats,
        StatsRoute.activityLog
    ]

    static let MySitesRoutes: [Route] = [
        MySitesRoute.pages,
        MySitesRoute.posts,
        MySitesRoute.media,
        MySitesRoute.comments,
        MySitesRoute.sharing,
        MySitesRoute.people,
        MySitesRoute.plugins,
        MySitesRoute.managePlugins
    ]

    static let AppBannerRoutes: [Route] = [
        AppBannerRoute()
    ]

    static let redirects: [Route] = [
        MbarRoute()
    ]

    /// - returns: True if the URL routing system can handle the given URL,
    ///            but does not perform any actions or tracking.
    ///
    func canHandle(url: URL) -> Bool {
        let matcherCanHandle = matcher.routesMatching(url).count > 0

        guard let host = url.host else {
            return matcherCanHandle
        }

        // If there's a hostname, check it's WordPress.com
        return host == "wordpress.com" && matcherCanHandle
    }

    /// Attempts to find a redirect or route that matches the url's path, and perform its
    /// associated action.
    ///
    /// - parameter url: The URL to match against.
    /// - parameter track: If false, don't post an analytics event for this URL.
    ///
    func handle(url: URL, shouldTrack track: Bool = true, source: UIViewController? = nil) {
        guard !handleRedirect(url: url, source: source) else {
            return
        }

        handleRoute(for: url, shouldTrack: track, source: source)
    }

    /// Attempts to find a redirect that matches the url's path, and perform its
    /// associated action.
    ///
    /// - parameter url: The URL to match against.
    ///
    /// - returns: `true` if a matching redirect was found and executed, `false` otherwise.
    ///
    private func handleRedirect(url: URL, source: UIViewController? = nil) -> Bool {
        let redirects = matcher.redirectsMatching(url)

        if let redirect = redirects.first {
            redirect.action.perform(redirect.values, source: source)
            return true
        }

        return false
    }

    /// Attempts to find a Route that matches the url's path, and perform its
    /// associated action.
    ///
    /// - parameter url: The URL to match against a route.
    /// - parameter track: If false, don't post an analytics event for this URL.
    ///
    private func handleRoute(for url: URL, shouldTrack track: Bool = true, source: UIViewController? = nil) {
        let matches = matcher.routesMatching(url)

        if track {
            trackDeepLink(matchCount: matches.count, url: url)
        }

        for matchedRoute in matches {
            matchedRoute.action.perform(matchedRoute.values, source: source)
        }
    }

    private func trackDeepLink(matchCount: Int, url: URL) {
        let stat: WPAnalyticsStat = (matchCount > 0) ? .deepLinked : .deepLinkFailed
        let properties = ["url": url.absoluteString]

        WPAppAnalytics.track(stat, withProperties: properties)
    }
}
