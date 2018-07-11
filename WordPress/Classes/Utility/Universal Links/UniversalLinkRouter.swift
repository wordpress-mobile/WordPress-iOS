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
    static let shared = UniversalLinkRouter(routes: MeRoutes +
        NewPostRoutes +
        NotificationsRoutes +
        ReaderRoutes +
        StatsRoutes)

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
        StatsRoute.activityLog
    ]

    /// Attempts to find a Route that matches the url's path, and perform its
    /// associated action.
    ///
    func handle(url: URL) {
        let matches = matcher.routesMatching(url.path)

        for matchedRoute in matches {
            matchedRoute.action.perform(matchedRoute.values)
        }
    }
}
