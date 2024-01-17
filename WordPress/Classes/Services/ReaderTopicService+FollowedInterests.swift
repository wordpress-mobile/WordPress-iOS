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
    /// If the user is not logged into a WP.com account, the interests will only be saved locally.
    func followInterests(_ interests: [RemoteReaderInterest],
                         success: @escaping ([ReaderTagTopic]?) -> Void,
                         failure: @escaping (Error) -> Void,
                         isLoggedIn: Bool)

    /// Returns the API path of a given slug
    func path(slug: String) -> String
}

// MARK: - CoreData Fetching
extension ReaderTopicService: ReaderFollowedInterestsService {
    public func fetchFollowedInterestsLocally(completion: @escaping ([ReaderTagTopic]?) -> Void) {
        DispatchQueue.main.async {
            completion(self.followedInterests())
        }
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
        // If the user is logged in, attempt to save the interests on the server
        // If the user is not logged in, save the interests locally
        if isLoggedIn {
            let slugs = interests.map { $0.slug }

            let topicService = ReaderTopicServiceRemote(wordPressComRestApi: apiRequest())
            topicService.followInterests(withSlugs: slugs, success: { [weak self] in
                self?.fetchFollowedInterestsRemotely(completion: success)
            }) { error in
                failure(error)
            }
        } else {
           followInterestsLocally(interests, success: success, failure: failure)
        }
    }

    func path(slug: String) -> String {
        // We create a "remote" service to get an accurate path for the tag
        // https://public-api.../tags/_tag_/posts
        let service = ReaderTopicServiceRemote(wordPressComRestApi: apiRequest())
        return service.pathForTopic(slug: slug)
    }

    private func followInterestsLocally(_ interests: [RemoteReaderInterest],
                                        success: @escaping ([ReaderTagTopic]?) -> Void,
                                        failure: @escaping (Error) -> Void) {

        self.coreDataStack.performAndSave({ context in
            interests.forEach { interest in
                let topic = ReaderTagTopic(remoteInterest: interest, context: context, isFollowing: true)
                topic.path = self.path(slug: interest.slug)
            }
        }, completion: { [weak self] in
            self?.fetchFollowedInterestsLocally(completion: success)
        }, on: .main)
    }

    private func apiRequest() -> WordPressComRestApi {
        let token = self.coreDataStack.performQuery { context in
            try? WPAccount.lookupDefaultWordPressComAccount(in: context)?.authToken
        }

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
        assert(Thread.isMainThread, "\(#function) must be called from the main thread")

        let fetchRequest = followedInterestsFetchRequest()
        do {
            return try coreDataStack.mainContext.fetch(fetchRequest)
        } catch {
            DDLogError("Could not fetch followed interests: \(String(describing: error))")

            return nil
        }
    }
}
