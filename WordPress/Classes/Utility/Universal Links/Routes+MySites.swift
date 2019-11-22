import Foundation

enum MySitesRoute {
    case pages
    case posts
    case media
    case comments
    case sharing
    case people
    case plugins
    case managePlugins
}

extension MySitesRoute: Route {
    var action: NavigationAction {
        return self
    }

    var path: String {
        switch self {
        case .pages:
            return "/pages/:domain"
        case .posts:
            return "/posts/:domain"
        case .media:
            return "/media/:domain"
        case .comments:
            return "/comments/:domain"
        case .sharing:
            return "/sharing/:domain"
        case .people:
            return "/people/:domain"
        case .plugins:
            return "/plugins/:domain"
        case .managePlugins:
            return "/plugins/manage/:domain"
        }
    }
}

extension MySitesRoute: NavigationAction {
    func perform(_ values: [String: String], source: UIViewController? = nil) {
        guard let coordinator = WPTabBarController.sharedInstance().mySitesCoordinator else {
            return
        }

        guard let blog = blog(from: values) else {
            WPAppAnalytics.track(.deepLinkFailed, withProperties: ["route": path])

            if failAndBounce(values) == false {
                coordinator.showMySites()
                postFailureNotice(title: NSLocalizedString("Site not found",
                                                           comment: "Error notice shown if the app can't find a specific site belonging to the user"))
            }
            return
        }

        switch self {
        case .pages:
            coordinator.showPages(for: blog)
        case .posts:
            coordinator.showPosts(for: blog)
        case .media:
            coordinator.showMedia(for: blog)
        case .comments:
            coordinator.showComments(for: blog)
        case .sharing:
            coordinator.showSharing(for: blog)
        case .people:
            coordinator.showPeople(for: blog)
        case .plugins:
            coordinator.showPlugins(for: blog)
        case .managePlugins:
            coordinator.showManagePlugins(for: blog)
        }
    }
}
