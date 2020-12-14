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
    case feed
    case blog
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
        case .feed:
            return "/read/feeds/:feed_id"
        case .blog:
            return "/read/blogs/:blog_id"
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
    func perform(_ values: [String: String], source: UIViewController? = nil) {
        guard let coordinator = WPTabBarController.sharedInstance().readerCoordinator else {
            return
        }

        // Bounce back to Safari on failure
        coordinator.failureBlock = {
            self.failAndBounce(values)
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
            coordinator.showMyLikes()
        case .manageFollowing:
            coordinator.showManageFollowing()
        case .list:
            if let username = values["username"],
                let listName = values["list_name"] {
                coordinator.showList(named: listName, forUser: username)
            }
        case .tag:
            if let tagName = values["tag_name"] {
                coordinator.showTag(named: tagName)
            }
        case .feed:
            if let feedIDValue = values["feed_id"],
                let feedID = Int(feedIDValue) {
                coordinator.showStream(with: feedID, isFeed: true)
            }
        case .blog:
            if let blogIDValue = values["blog_id"],
                let blogID = Int(blogIDValue) {
                coordinator.showStream(with: blogID, isFeed: false)
            }
        case .feedsPost:
            if let (feedID, postID) = feedAndPostID(from: values) {
                coordinator.showPost(with: postID, for: feedID, isFeed: true)
            }
        case .blogsPost:
            if let (blogID, postID) = blogAndPostID(from: values) {
                coordinator.showPost(with: postID, for: blogID, isFeed: false)
            }
        }
    }

    private func feedAndPostID(from values: [String: String]?) -> (Int, Int)? {
        guard let feedIDValue = values?["feed_id"],
            let postIDValue = values?["post_id"],
            let feedID = Int(feedIDValue),
            let postID = Int(postIDValue) else {
                return nil
        }

        return (feedID, postID)
    }

    private func blogAndPostID(from values: [String: String]?) -> (Int, Int)? {
        guard let blogIDValue = values?["blog_id"],
            let postIDValue = values?["post_id"],
            let blogID = Int(blogIDValue),
            let postID = Int(postIDValue) else {
                return nil
        }

        return (blogID, postID)
    }
}
