/// A router that handles routes that can be converted to /wp-admin links.
///
/// Note that this is a workaround for an infinite redirect issue between WordPress and Jetpack
/// when both apps are installed.
///
/// This can be removed once we remove the Universal Link routes for the WordPress app.
struct WPAdminConvertibleRouter: LinkRouter {
    static let shared = WPAdminConvertibleRouter(routes: [
        EditPostRoute()
    ])

    let routes: [Route]
    let matcher: RouteMatcher

    init(routes: [Route]) {
        self.routes = routes
        matcher = RouteMatcher(routes: routes)
    }

    func canHandle(url: URL) -> Bool {
        return matcher.routesMatching(url).count > 0
    }

    func handle(url: URL, shouldTrack track: Bool = false, source: DeepLinkSource? = nil) {
        matcher.routesMatching(url).forEach { route in
            route.action.perform(route.values, source: nil, router: self)
        }
    }
}

// MARK: - Routes

struct EditPostRoute: Route {
    let path = "/post/:domain/:postID"
    let section: DeepLinkSection? = nil
    let action: NavigationAction = WPAdminConvertibleNavigationAction.editPost
    let jetpackPowered: Bool = false
}

// MARK: - Navigation Action

enum WPAdminConvertibleNavigationAction: NavigationAction {
    case editPost

    func perform(_ values: [String: String], source: UIViewController?, router: LinkRouter) {
        let wpAdminURL: URL? = {
            switch self {
            case .editPost:
                guard let url = blogURLString(from: values),
                      let postID = postID(from: values) else {
                    return nil
                }

                var components = URLComponents(string: "https://\(url)/wp-admin/post.php")
                components?.queryItems = [
                    .init(name: "post", value: postID),
                    .init(name: "action", value: "edit"),
                    .init(name: "calypsoify", value: "1")
                ]
                return components?.url
            }
        }()

        guard let wpAdminURL else {
            return
        }

        UIApplication.shared.open(wpAdminURL)
    }
}

private extension WPAdminConvertibleNavigationAction {
    func blogURLString(from values: [String: String]?) -> String? {
        guard let domain = values?["domain"] else {
            return nil
        }

        // First, check if the provided domain is a siteID.
        // If it is, then try to look up existing blogs and return the URL instead.
        if let siteID = Int(domain),
           let blog = try? Blog.lookup(withID: siteID, in: ContextManager.shared.mainContext),
           let siteURL = blog.hostURL as? String {
            return siteURL
        }

        if let _ = URL(string: domain) {
            return domain
        }

        return nil
    }

    func postID(from values: [String: String]?) -> String? {
        return values?["postID"]
    }
}
