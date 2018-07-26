import Foundation

/// UniversalLinkRouter keeps a list of possible URL routes that are exposed
/// via universal links, and handles incoming links to trigger the appropriate route.
///
struct UniversalLinkRouter {
    private let matcher: RouteMatcher

    private init(routes: [Route]) {
        matcher = RouteMatcher(routes: routes)
    }

    // A singleton is less than ideal, but we're currently using this from the
    // app delegate, and because it's primarily written in objective-c we can't
    // add a struct property there.
    //
    static let shared = UniversalLinkRouter(routes:
        MeRoutes +
        NewPostRoutes +
        NotificationsRoutes +
        ReaderRoutes +
        StatsRoutes +
        MySitesRoutes +
        AppBannerRoutes)

    private static let MeRoutes: [Route] = [
        MeRoute(),
        MeAccountSettingsRoute(),
        MeNotificationSettingsRoute()
    ]

    private static let NewPostRoutes: [Route] = [
        NewPostRoute(),
        NewPostForSiteRoute()
    ]

    private static let NotificationsRoutes: [Route] = [
        NotificationsRoute()
    ]

    private static let ReaderRoutes: [Route] = [
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

    private static let StatsRoutes: [Route] = [
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

    private static let MySitesRoutes: [Route] = [
        MySitesRoute.pages,
        MySitesRoute.posts,
        MySitesRoute.media,
        MySitesRoute.comments,
        MySitesRoute.sharing,
        MySitesRoute.people,
        MySitesRoute.plugins,
        MySitesRoute.managePlugins
    ]

    private static let AppBannerRoutes: [Route] = [
        AppBannerRoute()
    ]

    /// Attempts to find a Route that matches the url's path, and perform its
    /// associated action.
    ///
    /// - parameter url: The URL to match against a route.
    /// - parameter track: If false, don't post an analytics event for this URL.
    ///
    /// - returns: True if the route was handled, or false if it didn't match any routes.
    ///
    func handle(url: URL, shouldTrack track: Bool = true) {
        let matches = matcher.routesMatching(url)

        if track {
            trackDeepLink(matchCount: matches.count, url: url)
        }

        for matchedRoute in matches {
            matchedRoute.action.perform(matchedRoute.values)
        }
    }

    private func trackDeepLink(matchCount: Int, url: URL) {
        let stat: WPAnalyticsStat = (matchCount > 0) ? .deepLinked : .deepLinkFailed
        let properties = ["url": url.absoluteString]

        WPAppAnalytics.track(stat, withProperties: properties)
    }
}
