import UIKit

enum ReaderRoute {
    case root
    case discover
    case search
    case a8c
    case p2
    case likes
    case manageFollowing
    case list
    case tag
    case feed
    case blog
    case feedsPost
    case blogsPost
    case wpcomPost
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
        case .p2:
            return "/read/p2"
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
        case .wpcomPost:
            return "/:post_year/:post_month/:post_day/:post_name"
        }
    }

    var section: DeepLinkSection? {
        return .reader
    }

    var action: NavigationAction {
        return self
    }

    var jetpackPowered: Bool {
        return true
    }
}

extension ReaderRoute: NavigationAction {
    func perform(_ values: [String: String], source: UIViewController? = nil, router: LinkRouter) {
        guard JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled() else {
            RootViewCoordinator.sharedPresenter.showReader() // Show static reader tab
            return
        }
        let presenter = RootViewCoordinator.sharedPresenter

        switch self {
        case .root:
            presenter.showReader()
        case .discover:
            presenter.showReader(path: .discover)
        case .search:
            presenter.showReader(path: .search)
        case .a8c:
            presenter.showReaderTeam(named: ReaderTeamTopic.a8cSlug)
        case .p2:
            presenter.showReaderTeam(named: ReaderTeamTopic.p2Slug)
        case .likes:
            presenter.showReader(path: .likes)
        case .manageFollowing:
            presenter.showReader(path: .subscriptions)
        case .list:
            if let username = values["username"], let list = values["list_name"] {
                presenter.showReaderList(named: list, forUser: username)
            }
        case .tag:
            if let tagName = values["tag_name"] {
                presenter.showReader(path: .makeWithTagName(tagName))
            }
        case .feed:
            if let feedIDValue = values["feed_id"], let feedID = Int(feedIDValue) {
                presenter.showReaderStream(with: feedID, isFeed: true)
            }
        case .blog:
            if let blogIDValue = values["blog_id"], let blogID = Int(blogIDValue) {
                presenter.showReaderStream(with: blogID, isFeed: false)
            }
        case .feedsPost:
            if let (feedID, postID) = feedAndPostID(from: values) {
                presenter.showReader(path: .post(postID: postID, siteID: feedID, isFeed: true))
            }
        case .blogsPost:
            if let (blogID, postID) = blogAndPostID(from: values) {
                presenter.showReader(path: .post(postID: postID, siteID: blogID))
            }
        case .wpcomPost:
            if let urlString = values[MatchedRouteURLComponentKey.url.rawValue],
               let url = URL(string: urlString),
               isValidWpcomUrl(values) {
                presenter.showReader(path: .postURL(url))
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

    func isValidWpcomUrl(_ values: [String: String]) -> Bool {
        let year = Int(values["post_year"] ?? "") ?? 0
        let month = Int(values["post_month"] ?? "") ?? 0
        let day = Int(values["post_day"] ?? "") ?? 0

        // we assume no posts were made in the 1800's or earlier
        func isYear(_ year: Int) -> Bool {
            year > 1900
        }

        func isMonth(_ month: Int) ->  Bool {
            (1...12).contains(month)
        }

        func isDay(_ day: Int) -> Bool {
            (1...31).contains(day)
        }

        return isYear(year) && isMonth(month) && isDay(day)
    }
}

// MARK: - RootViewPresenter (Extensions)

private extension RootViewPresenter {
    func showReaderTeam(named teamName: String) {
        let topic = ContextManager.shared.mainContext.firstObject(
            ofType: ReaderTeamTopic.self,
            matching: NSPredicate(format: "slug = %@", teamName)
        )
        if let topic {
            showReader(path: .topic(topic))
        }
    }

    func showReaderList(named listName: String, forUser user: String) {
        let context = ContextManager.shared.mainContext
        if let topic = ReaderListTopic.named(listName, forUser: user, in: context) {
            showReader(path: .topic(topic))
        }
    }

    /// - warning: This method performs the navigation asyncronously after
    /// fetching the information about the stream from the backend.
    func showReaderStream(with siteID: Int, isFeed: Bool) {
        getSiteTopic(siteID: NSNumber(value: siteID), isFeed: isFeed) { [weak self] topic in
            guard let topic else { return }
            self?.showReader(path: .topic(topic))
        }
    }

    private func getSiteTopic(siteID: NSNumber, isFeed: Bool, completion: @escaping (ReaderSiteTopic?) -> Void) {
        let service = ReaderTopicService(coreDataStack: ContextManager.shared)
        service.siteTopicForSite(withID: siteID, isFeed: isFeed, success: { objectID, isFollowing in
            guard let objectID,
                  let topic = try? ContextManager.shared.mainContext.existingObject(with: objectID) as? ReaderSiteTopic else {
                DDLogError("Reader: Error retriving site topic - invalid Site Id")
                completion(nil)
                return
            }
            completion(topic)
        }, failure: { error in
            DDLogError("Reader: Error retriving site topic - \(error?.localizedDescription ?? "unknown failure reason")")
            completion(nil)
        })
    }
}
