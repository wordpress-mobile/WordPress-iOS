import Foundation

// MARK: - ReaderFollowedInterestsService

/// Protocol representing a service that retrieves the users followed interests/tags
protocol ReaderFollowedInterestsService: AnyObject {
    /// Fetches the users locally followed interests
    /// - Parameter completion: Called after a fetch, will return nil if the user has no interests or an error occurred
    func fetchFollowedInterestsLocally(completion: @escaping ([ReaderTagTopic]?) -> Void)

    /// Fetches the users followed interests from the network, then returns the sync'd interests
    /// - Parameter completion: Called after a fetch, will return nil if the user has no interests or an error occurred
    func fetchFollowedInterestsRemotely(completion: @escaping ([ReaderTagTopic]?) -> Void)


    /// Follow the provided interests
    /// If the user is not logged into a WP.com account, the interests will be saved locally.
    func followInterests(_ interests: [RemoteReaderInterest],
                         success: @escaping ([ReaderTagTopic]?) -> Void,
                         failure: @escaping (Error) -> Void,
                         isLoggedIn: Bool)
}

// MARK: - CoreData Fetching
extension ReaderTopicService: ReaderFollowedInterestsService {
    public func fetchFollowedInterestsLocally(completion: @escaping ([ReaderTagTopic]?) -> Void) {
        completion(followedInterests())
    }

    public func fetchFollowedInterestsRemotely(completion: @escaping ([ReaderTagTopic]?) -> Void) {
        fetchReaderMenu(success: { [weak self] in
            self?.fetchFollowedInterestsLocally(completion: completion)
        }) { [weak self] error in
            DDLogError("Could not fetch remotely followed interests: \(String(describing: error))")
            self?.fetchFollowedInterestsLocally(completion: completion)
        }
    }

    func followInterests(_ interests: [RemoteReaderInterest],
                         success: @escaping ([ReaderTagTopic]?) -> Void,
                         failure: @escaping (Error) -> Void,
                         isLoggedIn: Bool) {
        // Check if the user is logged in
        guard isLoggedIn else {
            followInterestsLocally(interests, success: success, failure: failure)
            return
        }

        //If they're not, attempt to save the interests on the server
        let slugs = interests.map { $0.slug }

        let topicService = ReaderTopicServiceRemote(wordPressComRestApi: apiRequest())
        topicService.followInterests(withSlugs: slugs, success: { [weak self] in
            self?.fetchFollowedInterestsRemotely(completion: success)
        }) { error in
            failure(error)
        }
    }

    private func followInterestsLocally(_ interests: [RemoteReaderInterest],
                                        success: @escaping ([ReaderTagTopic]?) -> Void,
                                        failure: @escaping (Error) -> Void) {
        // We create a "remote" service to get an accurate path for the tag
        // https://public-api.../tags/_tag_/posts
        let service = ReaderTopicServiceRemote(wordPressComRestApi: apiRequest())

        interests.forEach { interest in
            let topic = NSEntityDescription.insertNewObject(forEntityName: "ReaderTagTopic", into: managedObjectContext) as! ReaderTagTopic
            topic.tagID = ReaderTagTopic.loggedOutTagID
            topic.type = ReaderTagTopic.TopicType
            topic.path = service.pathForTopic(slug: interest.slug)
            topic.following = true
            topic.showInMenu = true
            topic.title = interest.title
            topic.slug = interest.slug
        }

        ContextManager.sharedInstance().save(managedObjectContext, withCompletionBlock: { [weak self] in
            self?.fetchFollowedInterestsLocally(completion: success)
        })
    }

    private func apiRequest() -> WordPressComRestApi {
        let accountService = AccountService(managedObjectContext: managedObjectContext)
        let defaultAccount = accountService.defaultWordPressComAccount()
        let token: String? = defaultAccount?.authToken

        return WordPressComRestApi.defaultApi(oAuthToken: token,
                                              userAgent: WPUserAgent.wordPress())
    }

    // MARK: - Private: Fetching Helpers
    private func followedInterestsFetchRequest() -> NSFetchRequest<ReaderTagTopic> {
        let entityName = "ReaderTagTopic"
        let predicate = NSPredicate(format: "following = YES AND showInMenu = YES")
        let fetchRequest = NSFetchRequest<ReaderTagTopic>(entityName: entityName)
        fetchRequest.predicate = predicate

        return fetchRequest
    }

    private func followedInterests() -> [ReaderTagTopic]? {
        let fetchRequest = followedInterestsFetchRequest()
        do {
            return try managedObjectContext.fetch(fetchRequest)
        } catch {
            DDLogError("Could not fetch followed interests: \(String(describing: error))")

            return nil
        }
    }
}
