import Foundation

/// UniversalLinkRouter keeps a list of possible URL routes that are exposed
/// via universal links, and handles incoming links to trigger the appropriate route.
///
struct UniversalLinkRouter {
    private let matcher: RouteMatcher

    init(routes: [Route]) {
        matcher = RouteMatcher(routes: routes)
    }

    // A singleton is less than ideal, but we're currently using this from the
    // app delegate, and because it's primarily written in objective-c we can't
    // add a struct property there.
    //
    static let shared = UniversalLinkRouter(
        routes: defaultRoutes)

    static let defaultRoutes: [Route] =
        redirects +
        meRoutes +
        newPostRoutes +
        notificationsRoutes +
        readerRoutes +
        statsRoutes +
        mySitesRoutes +
        appBannerRoutes

    static let meRoutes: [Route] = [
        MeRoute(),
        MeAccountSettingsRoute(),
        MeNotificationSettingsRoute()
    ]

    static let newPostRoutes: [Route] = [
        NewPostRoute(),
        NewPostForSiteRoute()
    ]

    static let notificationsRoutes: [Route] = [
        NotificationsRoute()
    ]

    static let readerRoutes: [Route] = [
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

    static let statsRoutes: [Route] = [
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

    static let mySitesRoutes: [Route] = [
        MySitesRoute.pages,
        MySitesRoute.posts,
        MySitesRoute.media,
        MySitesRoute.comments,
        MySitesRoute.sharing,
        MySitesRoute.people,
        MySitesRoute.plugins,
        MySitesRoute.managePlugins
    ]

    static let appBannerRoutes: [Route] = [
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

    /// Attempts to find a route that matches the url's path, and perform its
    /// associated action.
    ///
    /// - parameter url: The URL to match against.
    /// - parameter track: If false, don't post an analytics event for this URL.
    ///
    func handle(url: URL, shouldTrack track: Bool = true, source: UIViewController? = nil) {
        let matches = matcher.routesMatching(url)

        if track {
            trackDeepLink(matchCount: matches.count, url: url)
        }

        if matches.isEmpty {
            UIApplication.shared.open(url,
                                      options: [:],
                                      completionHandler: nil)
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
