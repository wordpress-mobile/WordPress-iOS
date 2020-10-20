import Foundation

/// A service to fetch and persist a list of suggestions, which can be either:
/// - a list of users that can be @-mentioned in a post or comment, or;
/// - a list of sites that can be cross-posted to from within the Gutenberg editor
class SuggestionService {

    // Used to keep track of requests made to the suggestions endpoints
    struct Request: Equatable {
        let type: SuggestionType
        let blog: Blog

        static func ==(lhs: Request, rhs: Request) -> Bool {
            return lhs.type == rhs.type && lhs.blog == rhs.blog
        }
    }

    static let shared = SuggestionService()
    private var suggestionsRequested = [Request]()
    var requestDates = [Blog: Date]()

    /**
     Fetch cached suggestions if available, otherwise from the network if the device is online.

     @param type The type of suggestion
     @param blog The blog/site to retrieve suggestions for
     @param completion A callback containing list of suggestions, or nil if unavailable
    */
    func suggestionsOf(type: SuggestionType, for blog: Blog, completion: (([NSManagedObject]?) -> Void)?) {

        let throttleDuration: TimeInterval = 60 // seconds
        if let requestDate = requestDates[blog], Date().timeIntervalSince(requestDate) < throttleDuration {
            completion?(nil)
            return
        }

        if let suggestions = retrievePersistedSuggestionsOf(type: type, for: blog), suggestions.isEmpty == false {
            completion?(suggestions)
        } else if ReachabilityUtils.isInternetReachable() {
            requestDates[blog] = Date()
            fetchAndPersistSuggestionsOf(type: type, for: blog, completion: completion)
        } else {
            completion?(nil)
        }
    }

    /**
     Performs a REST API request to fetch user or site suggestions for the given blog.
     Persists response objects to Core Data.
     @param type The type of suggestion
     @param blog The blog/site to retrieve suggestions for
     @param completion A callback containing list of suggestions, or nil if unavailable
    */
    private func fetchAndPersistSuggestionsOf(type: SuggestionType, for blog: Blog, completion: (([NSManagedObject]?) -> Void)?) {

        let request = Request(type: type, blog: blog)

        // if there is already a request in place for this blog, just wait
        guard !suggestionsRequested.contains(request) else { return }

        let path: String
        let params: [String: AnyObject]

        switch type {
        case .mention:
            path = "rest/v1.1/users/suggest"
            guard let siteID = blog.dotComID else {
                completion?(nil)
                return
            }
            params = [ "site_id": siteID ]
        case .xpost:
            guard let hostname = blog.hostname else {
                completion?(nil)
                return
            }
            path = "/wpcom/v2/sites/\(hostname)/xposts"
            params = [ "decode_html": true ] as [String: AnyObject]
        }

        // add this blog to currently being requested list
        suggestionsRequested.append(request)

        defaultAccount()?.wordPressComRestApi.GET(path, parameters: params, success: { [weak self] responseObject, httpResponse in
            guard let `self` = self else { return }

            do {
                let context = ContextManager.shared.mainContext
                let data = try JSONSerialization.data(withJSONObject: responseObject)
                let decoder = JSONDecoder()
                decoder.userInfo[CodingUserInfoKey.managedObjectContext] = context

                try self.purgeManagedObjectsOf(type: type, in: blog, using: context)

                switch type {
                case .mention:
                    let payload = try decoder.decode(UserSuggestionsPayload.self, from: data)
                    blog.userSuggestions = Set(payload.suggestions)
                case .xpost:
                    let suggestions = try decoder.decode([SiteSuggestion].self, from: data)
                    blog.siteSuggestions = Set(suggestions)
                }

                try ContextManager.shared.mainContext.save()

                completion?(self.retrievePersistedSuggestionsOf(type: .xpost, for: blog))
            } catch {
                completion?(nil)
            }

            // remove blog from the currently being requested list
            self.suggestionsRequested.removeAll { $0 == request }
        }, failure: { [weak self] error, _ in
            guard let `self` = self else { return }

            completion?(nil)

            // remove blog from the currently being requested list
            self.suggestionsRequested.removeAll { $0 == request}

            DDLogVerbose("[Rest API] ! \(error.localizedDescription)")
        })
    }

    /**
     Tells the caller if it is a good idea to show suggestions right now for a given blog/site.

     @param type The type of suggestion
     @param blog The blog/site to check for
     @return BOOL Whether the caller should show suggestions
    */
    func shouldShowSuggestionsOf(type: SuggestionType, for blog: Blog) -> Bool {

        // The device must be online or there must be already persisted suggestions
        guard ReachabilityUtils.isInternetReachable() || retrievePersistedSuggestionsOf(type: type, for: blog)?.isEmpty == false else { return false }

        switch type {
        case .mention: return blog.supports(.mentions)
        case .xpost: return blog.supports(.xposts)
        }
    }

    private func purgeManagedObjectsOf(type: SuggestionType, in blog: Blog, using managedObjectContext: NSManagedObjectContext) throws {
        retrievePersistedSuggestionsOf(type: type, for: blog)?.forEach { managedObjectContext.delete($0) }
        try managedObjectContext.save()
    }

    private func defaultAccount() -> WPAccount? {
        let context = ContextManager.shared.mainContext
        let accountService = AccountService(managedObjectContext: context)
        return accountService.defaultWordPressComAccount()
    }

    func retrievePersistedSuggestionsOf(type: SuggestionType, for blog: Blog) -> [NSManagedObject]? {
        switch type {
        case .mention: return blog.userSuggestions?.sorted()
        case .xpost: return blog.siteSuggestions?.sorted()
        }
    }

    /**
     Retrieve the persisted blog/site for a given site ID.

     @param siteID the dotComID to retrieve
     @return The blog/site for the given site ID
     */
    func persistedBlog(for siteID: NSNumber) -> Blog? {
        let context = ContextManager.shared.mainContext
        return BlogService(managedObjectContext: context).blog(byBlogId: siteID)
    }
}
