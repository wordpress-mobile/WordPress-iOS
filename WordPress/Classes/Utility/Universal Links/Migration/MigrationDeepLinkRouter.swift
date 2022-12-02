/// A router that specifically handles deeplinks.
/// Note that the capability of this router is very limited; it can only handle up to one path component (e.g.: `wordpress://intent`).
///
/// This is meant to be used during the WP->JP migratory period. Once we decide to move on from this phase, this class may be removed.
///
struct MigrationDeepLinkRouter: LinkRouter {

    let routes: [Route]

    /// when this is set, the router ensures that the URL has a scheme that matches this value.
    private var scheme: String? = nil

    init(routes: [Route]) {
        self.routes = routes
    }

    init(scheme: String?, routes: [Route]) {
        self.init(routes: routes)
        self.scheme = scheme
    }

    init(urlForScheme: URL?, routes: [Route]) {
        self.init(scheme: urlForScheme?.scheme, routes: routes)
    }

    func canHandle(url: URL) -> Bool {
        // if the scheme is set, check if the URL fulfills the requirement.
        if let scheme, url.scheme != scheme {
            return false
        }

        /// deeplinks have their paths start at `host`, unlike universal links.
        /// e.g. wordpress://intent -> "intent" is the URL's host.
        ///
        /// Ensure that the deeplink URL has a "host" that we can run against the `routes`' path.
        guard let deepLinkPath = url.host else {
            return false
        }

        return routes
            .map { $0.path.removingPrefix("/") }
            .contains { $0 == deepLinkPath }
    }

    func handle(url: URL, shouldTrack track: Bool = false, source: DeepLinkSource? = nil) {
        guard let deepLinkPath = url.host,
              let route = routes.filter({ $0.path.removingPrefix("/") == deepLinkPath }).first else {
            return
        }

        // there's no need to pass any arguments or parameters since most of the migration deeplink routes are standalone.
        route.action.perform([:], source: nil, router: self)
    }
}
