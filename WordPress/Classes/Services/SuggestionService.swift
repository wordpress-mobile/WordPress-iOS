import Foundation

/// A service to fetch and persist a list of users that can be @-mentioned in a post or comment.
class SuggestionService {

    private var blogsCurrentlyBeingRequested = [Blog]()

    static let shared = SuggestionService()

    /**
    Fetch cached suggestions if available, otherwise from the network if the device is online.

    @param the blog/site to retrieve suggestions for
    @param completion callback containing list of suggestions, or nil if unavailable
    */
    func suggestions(for blog: Blog, completion: @escaping ([UserSuggestion]?) -> Void) {

        if let suggestions = retrievePersistedSuggestions(for: blog), suggestions.isEmpty == false {
            completion(suggestions)
        } else if ReachabilityUtils.isInternetReachable() {
            fetchAndPersistSuggestions(for: blog, completion: completion)
        } else {
            completion(nil)
        }
    }

    /**
    Performs a REST API request for the given blog.
    Persists response objects to Core Data.

    @param blog/site to retrieve suggestions for
    */
    private func fetchAndPersistSuggestions(for blog: Blog, completion: @escaping ([UserSuggestion]?) -> Void) {

        // if there is already a request in place for this blog, just wait
        guard !blogsCurrentlyBeingRequested.contains(blog) else { return }

        guard let siteID = blog.dotComID else { return }

        let suggestPath = "rest/v1.1/users/suggest"
        let params = ["site_id": siteID]

        // add this blog to currently being requested list
        blogsCurrentlyBeingRequested.append(blog)

        defaultAccount()?.wordPressComRestApi.GET(suggestPath, parameters: params, success: { [weak self] responseObject, httpResponse in
            guard let `self` = self else { return }
            guard let payload = responseObject as? [String: Any] else { return }
            guard let restSuggestions = payload["suggestions"] as? [[String: Any]] else { return }

            let context = ContextManager.shared.mainContext

            // Delete any existing `UserSuggestion` objects
            self.retrievePersistedSuggestions(for: blog)?.forEach { suggestion in
                context.delete(suggestion)
            }

            // Create new `UserSuggestion` objects
            let suggestions = restSuggestions.compactMap { UserSuggestion(dictionary: $0, context: context) }

            // Associate `UserSuggestion` objects with blog
            blog.userSuggestions = Set(suggestions)

            // Save the changes
            try? blog.managedObjectContext?.save()

            completion(suggestions)

            // remove blog from the currently being requested list
            self.blogsCurrentlyBeingRequested.removeAll { $0 == blog }
        }, failure: { [weak self] error, _ in
            guard let `self` = self else { return }

            completion(nil)

            // remove blog from the currently being requested list
            self.blogsCurrentlyBeingRequested.removeAll { $0 == blog}

            DDLogVerbose("[Rest API] ! \(error.localizedDescription)")
        })
    }

    /**
    Tells the caller if it is a good idea to show suggestions right now for a given blog/site.

    @param blog blog/site to check for
    @return BOOL Whether the caller should show suggestions
    */
    func shouldShowSuggestions(for blog: Blog) -> Bool {

        // The device must be online or there must be already persisted suggestions
        guard ReachabilityUtils.isInternetReachable() || retrievePersistedSuggestions(for: blog)?.isEmpty == false else {
            return false
        }

        return blog.supports(.mentions)
    }

    private func defaultAccount() -> WPAccount? {
        let context = ContextManager.shared.mainContext
        let accountService = AccountService(managedObjectContext: context)
        return accountService.defaultWordPressComAccount()
    }

    private func retrievePersistedSuggestions(for blog: Blog) -> [UserSuggestion]? {
        guard let suggestions = blog.userSuggestions else { return nil }
        return Array(suggestions)
    }

    /**
     Retrieve the persisted blog/site for a given site ID

     @param siteID the dotComID to retrieve
     @return Blog the blog/site
     */
    func persistedBlog(for siteID: NSNumber) -> Blog? {
        let context = ContextManager.shared.mainContext
        return BlogService(managedObjectContext: context).blog(byBlogId: siteID)
    }
}
