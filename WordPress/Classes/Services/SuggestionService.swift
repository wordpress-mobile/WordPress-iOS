import Foundation

extension NSNotification.Name {
    static let suggestionListUpdated = NSNotification.Name("SuggestionListUpdated")
}

@objc extension NSNotification {
    public static let suggestionListUpdated = NSNotification.Name.suggestionListUpdated
}

/// A service to fetch and persist a list of users that can be @-mentioned in a post or comment.
class SuggestionService {

    private var siteIDsCurrentlyBeingRequested = [NSNumber]()

    static let shared = SuggestionService()

    /**
    Fetches the suggestions from the network if the device is online, otherwise retrieves previously persisted suggestions.
    If fetch is performed, sends a notification `suggestionListUpdated` to notify caller when fetch is complete.

    @param siteID ID of the blog/site to retrieve suggestions for
    @return An array of suggestions
    */
    func suggestions(for siteID: NSNumber) -> [AtMentionSuggestion]? {

        guard ReachabilityUtils.isInternetReachable() else {
            return retrievePersistedSuggestions(for: siteID)
        }

        updateSuggestions(for: siteID)
        return nil
    }

    /**
    Performs a REST API request for the siteID given.

    @param siteID ID of the blog/site to retrieve suggestions for
    */
    private func updateSuggestions(for siteID: NSNumber) {

        // if there is already a request in place for this siteID, just wait
        guard !siteIDsCurrentlyBeingRequested.contains(siteID) else { return }

        // add this siteID to currently being requested list
        siteIDsCurrentlyBeingRequested.append(siteID)

        let suggestPath = "rest/v1.1/users/suggest"
        let context = ContextManager.shared.mainContext
        let accountService = AccountService(managedObjectContext: context)
        let defaultAccount = accountService.defaultWordPressComAccount()
        let params = ["site_id": siteID]

        defaultAccount?.wordPressComRestApi.GET(suggestPath, parameters: params, success: { [weak self] responseObject, httpResponse in
            guard let `self` = self else { return }
            guard let payload = responseObject as? [String: Any] else { return }
            guard let restSuggestions = payload["suggestions"] as? [[String: Any]] else { return }

            let suggestions = restSuggestions.compactMap { AtMentionSuggestion(dictionary: $0, context: context) }

            let context = ContextManager.shared.mainContext
            let blog = BlogService(managedObjectContext: context).blog(byBlogId: siteID)
            blog?.atMentionSuggestions = Set(suggestions)
            try? context.save()

            // send the siteID with the notification so it could be filtered out
            NotificationCenter.default.post(name: .suggestionListUpdated, object: siteID)

            // remove siteID from the currently being requested list
            self.siteIDsCurrentlyBeingRequested.removeAll { $0 == siteID}
        }, failure: { [weak self] error, _ in
            guard let `self` = self else { return }

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

    private func persistedBlog(for siteID: NSNumber) -> Blog? {
        let context = ContextManager.shared.mainContext
        return BlogService(managedObjectContext: context).blog(byBlogId: siteID)
    }

    private func retrievePersistedSuggestions(for siteID: NSNumber) -> [AtMentionSuggestion]? {
        guard let suggestions = persistedBlog(for: siteID)?.atMentionSuggestions else { return nil }
        return Array(suggestions)
    }
}
