import Foundation
import WordPressComStatsiOS

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
    func perform(_ values: [String: String]?) {
        guard let coordinator = WPTabBarController.sharedInstance().mySitesCoordinator,
            let blog = blog(from: values) else {
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

    private func blog(from values: [String: String]?) -> Blog? {
        guard let domain = values?["domain"] else {
            return nil
        }

        let context = ContextManager.sharedInstance().mainContext
        let service = BlogService(managedObjectContext: context)

        return service.blog(byHostname: domain)
    }
}
