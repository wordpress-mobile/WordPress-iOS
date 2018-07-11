import Foundation

enum StatsRoute {
    case root
    case site
    case activityLog
}

extension StatsRoute: Route {
    var action: NavigationAction {
        return self
    }

    var path: String {
        switch self {
        case .root:
            return "/stats"
        case .site:
            return "/stats/:domain"
        case .activityLog:
            return "/stats/activity/:domain"
        }
    }
}

extension StatsRoute: NavigationAction {
    func perform(_ values: [String: String]?) {
        guard let coordinator = WPTabBarController.sharedInstance().mySitesCoordinator else {
            return
        }

        switch self {
        case .root:
            if let blog = defaultBlog() {
                coordinator.showStats(for: blog)
            }
        case .site:
            if let blog = blog(from: values) {
                coordinator.showStats(for: blog)
            }
        case .activityLog:
            if let blog = blog(from: values) {
                coordinator.showActivityLog(for: blog)
            }
        }
    }

    private func defaultBlog() -> Blog? {
        let context = ContextManager.sharedInstance().mainContext
        let service = BlogService(managedObjectContext: context)

        return service.lastUsedOrFirstBlog()
    }

    private func blog(from values: [String: String]?) -> Blog? {
        guard let domain = values?["domain"] else {
            return nil
        }

        let context = ContextManager.sharedInstance().mainContext
        let service = BlogService(managedObjectContext: context)

        return service.blog(byHostname: domain)
    }
}
