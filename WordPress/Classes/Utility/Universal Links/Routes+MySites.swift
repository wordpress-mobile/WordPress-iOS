import Foundation
import WordPressComStatsiOS

enum MySitesRoute {
    case pages
    case posts
    case media
    case comments
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
