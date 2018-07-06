import Foundation

enum ReaderRoute {
    case root
    case discover
    case search
    case a8c
    case likes
    case manageFollowing
    case list
    case tag
    case feedsPost
    case blogsPost
}

extension ReaderRoute: Route {
    var path: String {
        switch self {
        case .root:
            return "/read"
        case .discover:
            return "/discover"
        case .search:
            return "/read/search"
        case .a8c:
            return "/read/a8c"
        case .likes:
            return "/activities/likes"
        case .manageFollowing:
            return "/following/manage"
        case .list:
            return "/read/list/:username/:list_name"
        case .tag:
            return "/tag/:tag_name"
        case .feedsPost:
            return "/read/feeds/:feed_id/posts/:post_id"
        case .blogsPost:
            return "/read/blogs/:blog_id/posts/:post_id"
        }
    }

    var action: NavigationAction {
        return self
    }
}

extension ReaderRoute: NavigationAction {
    func perform(_ values: [String: String]?) {
        guard let coordinator = WPTabBarController.sharedInstance().readerCoordinator else {
            return
        }

        switch self {
        case .root:
            coordinator.showReaderTab()
        case .discover:
            coordinator.showDiscover()
        case .search:
            coordinator.showSearch()
        case .a8c:
            coordinator.showA8CTeam()
        case .likes:
            break
        case .manageFollowing:
            break
        case .list:
            break
        case .tag:
            break
        case .feedsPost:
            break
        case .blogsPost:
            break
        }
    }
}
