import Foundation

/// A service to fetch and persist a list of sites that can be xpost to from a post.
class SiteSuggestionService {

    private var blogsCurrentlyBeingRequested = [NSNumber]()
    private var requests = [NSNumber: Date]()
    private var disabledBlogs = [NSNumber]()

    static let shared = SiteSuggestionService()

    /**
    Fetch cached suggestions if available, otherwise from the network if the device is online.

    @param the blog/site to retrieve suggestions for
    @param completion callback containing list of suggestions, or nil if unavailable
    */
    func suggestions(for blog: Blog, completion: @escaping ([SiteSuggestion]?) -> Void) {

        let throttleDuration: TimeInterval = 60 // seconds
        let isBelowThrottleThreshold: Bool
        if let id = blog.dotComID, let requestDate = requests[id] {
            isBelowThrottleThreshold = Date().timeIntervalSince(requestDate) < throttleDuration
        } else {
            isBelowThrottleThreshold = false
        }


        if isBelowThrottleThreshold, let suggestions = retrievePersistedSuggestions(for: blog), suggestions.isEmpty == false {
            completion(suggestions)
        } else if ReachabilityUtils.isInternetReachable() {
            fetchAndPersistSuggestions(for: blog, completion: completion)
        } else {
            completion(nil)
        }
    }

    /**
     If no suggestions already in Core Data, fetch them from the network and store them in Core Data.
     Aborts and calls callback if the site does not support suggestions.
     @param blog The blog/site to prefetch suggestions for
     */
    func prefetchSuggestionsIfNeeded(for blog: Blog, completion: @escaping () -> Void) {
        guard shouldShowSuggestions(for: blog) else {
            completion()
            return
        }
        let persistedSuggestions = retrievePersistedSuggestions(for: blog)
        if persistedSuggestions == nil || persistedSuggestions?.isEmpty == true {
            fetchAndPersistSuggestions(for: blog, completion: { _ in
                completion()
            })
        }
    }

    /**
    Performs a REST API request for the given blog.
    Persists response objects to Core Data.

    @param blog/site to retrieve suggestions for
    */
    private func fetchAndPersistSuggestions(for blog: Blog, completion: @escaping ([SiteSuggestion]?) -> Void) {

        guard let blogId = blog.dotComID, let hostname = blog.hostname else { return }

        // if there is already a request in place for this blog, just wait
        guard !blogsCurrentlyBeingRequested.contains(blogId) else { return }

        let suggestPath = "/wpcom/v2/sites/\(hostname)/xposts"
        let params = ["decode_html": true] as [String: AnyObject]

        // add this blog to currently being requested list
        blogsCurrentlyBeingRequested.append(blogId)

        defaultAccount()?.wordPressComRestApi.GET(suggestPath, parameters: params, success: { [weak self] responseObject, httpResponse in
            guard let `self` = self else { return }

            let context = ContextManager.shared.mainContext
            guard let data = try? JSONSerialization.data(withJSONObject: responseObject) else { return }
            let decoder = JSONDecoder()
            decoder.userInfo[CodingUserInfoKey.managedObjectContext] = context
            guard let suggestions = try? decoder.decode([SiteSuggestion].self, from: data) else { return }

            // Delete any existing `SiteSuggestion` objects
            self.retrievePersistedSuggestions(for: blog)?.forEach { suggestion in
                context.delete(suggestion)
            }

            // Associate `SiteSuggestion` objects with blog
            blog.siteSuggestions = Set(suggestions)

            // Save the changes
            try? ContextManager.shared.mainContext.save()

            self.requests[blogId] = Date()

            self.disabledBlogs.removeAll { $0 == blogId }
            completion(suggestions)

            // remove blog from the currently being requested list
            self.blogsCurrentlyBeingRequested.removeAll { $0 == blogId }
        }, failure: { [weak self] error, response in
            guard let `self` = self else { return }

            if response?.statusCode == 400 {    // blog/site does not have Xposts available
                self.disabledBlogs.append(blogId)
            }
            completion([])

            // remove blog from the currently being requested list
            self.blogsCurrentlyBeingRequested.removeAll { $0 == blogId}

            DDLogVerbose("[Rest API] ! \(error.localizedDescription)")
        })
    }

    /**
    Tells the caller if it is a good idea to show suggestions right now for a given blog/site.

    @param blog blog/site to check for
    @return BOOL Whether the caller should show suggestions
    */
    func shouldShowSuggestions(for blog: Blog) -> Bool {

        // Any blog/site that has previously returned an error indicating Xposts are not available is marked as disabled.
        guard let blogId = blog.dotComID, disabledBlogs.contains(blogId) == false else {
            return false
        }

        // The device must be online or there must be already persisted suggestions
        guard ReachabilityUtils.isInternetReachable() || retrievePersistedSuggestions(for: blog)?.isEmpty == false else {
            return false
        }

        return blog.supports(.xposts)
    }

    private func defaultAccount() -> WPAccount? {
        let context = ContextManager.shared.mainContext
        let accountService = AccountService(managedObjectContext: context)
        return accountService.defaultWordPressComAccount()
    }

    func retrievePersistedSuggestions(for blog: Blog) -> [SiteSuggestion]? {
        guard let suggestions = blog.siteSuggestions else { return nil }
        return Array(suggestions)
    }
}
