import Foundation

/// A service to fetch and persist a list of users that can be @-mentioned in a post or comment.
class SuggestionService {

    private var siteIDsCurrentlyBeingRequested = [NSNumber]()

    static let shared = SuggestionService()

    /**
    Fetches the suggestions from the network if the device is online, otherwise retrieves previously persisted suggestions.

    @param siteID ID of the blog/site to retrieve suggestions for
    @param completion callback containing list of suggestions
    */
    func suggestions(for siteID: NSNumber, completion: @escaping ([AtMentionSuggestion]?) -> Void) {

        // If the device is offline, use persisted (cached) suggestions if available
        guard ReachabilityUtils.isInternetReachable() else {
            completion(retrievePersistedSuggestions(for: siteID))
            return
        }

        fetchAndPersistSuggestions(for: siteID, completion: completion)
    }

    /**
    Performs a REST API request for the siteID given.
    Persists response objects to Core Data.

    @param siteID ID of the blog/site to retrieve suggestions for
    */
    private func fetchAndPersistSuggestions(for siteID: NSNumber, completion: @escaping ([AtMentionSuggestion]?) -> Void) {

        // if there is already a request in place for this siteID, just wait
        guard !siteIDsCurrentlyBeingRequested.contains(siteID) else { return }

        // add this siteID to currently being requested list
        siteIDsCurrentlyBeingRequested.append(siteID)

        let suggestPath = "rest/v1.1/users/suggest"
        let params = ["site_id": siteID]

        defaultAccount()?.wordPressComRestApi.GET(suggestPath, parameters: params, success: { [weak self] responseObject, httpResponse in
            guard let `self` = self else { return }
            guard let payload = responseObject as? [String: Any] else { return }
            guard let restSuggestions = payload["suggestions"] as? [[String: Any]] else { return }

            let context = ContextManager.shared.mainContext

            // Persist `AtMentionSuggestion` objects
            let suggestions = restSuggestions.compactMap { AtMentionSuggestion(dictionary: $0, context: context) }

            // Associate `AtMentionSuggestion` objects with site ID
            let blog = self.persistedBlog(for: siteID)
            blog?.atMentionSuggestions = Set(suggestions)
            try? context.save()

            completion(suggestions)

            // remove siteID from the currently being requested list
            self.siteIDsCurrentlyBeingRequested.removeAll { $0 == siteID}
        }, failure: { [weak self] error, _ in
            guard let `self` = self else { return }

            completion(nil)

            // remove siteID from the currently being requested list
            self.siteIDsCurrentlyBeingRequested.removeAll { $0 == siteID}

            DDLogVerbose("[Rest API] ! \(error.localizedDescription)")
        })
    }

    /**
    Tells the caller if it is a good idea to show suggestions right now for a given siteID.

    @param siteID ID of the blog/site to check for
    @return BOOL Whether the caller should show suggestions
    */
    func shouldShowSuggestions(for siteID: NSNumber) -> Bool {

        // The device must be online or there must be already persisted suggestions
        guard ReachabilityUtils.isInternetReachable() || retrievePersistedSuggestions(for: siteID)?.isEmpty == false else {
            return false
        }

        return persistedBlog(for: siteID)?.supports(.mentions) == true
    }

    private func defaultAccount() -> WPAccount? {
        let context = ContextManager.shared.mainContext
        let accountService = AccountService(managedObjectContext: context)
        return accountService.defaultWordPressComAccount()
    }

    private func retrievePersistedSuggestions(for siteID: NSNumber) -> [AtMentionSuggestion]? {
        guard let suggestions = persistedBlog(for: siteID)?.atMentionSuggestions else { return nil }
        return Array(suggestions)
    }

    private func persistedBlog(for siteID: NSNumber) -> Blog? {
        let context = ContextManager.shared.mainContext
        return BlogService(managedObjectContext: context).blog(byBlogId: siteID)
    }
}
