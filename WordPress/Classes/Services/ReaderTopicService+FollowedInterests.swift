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

    func followInterests(slugs: [String],
                         success: @escaping ([ReaderTagTopic]?) -> Void,
                         failure: @escaping (Error) -> Void)
}

// MARK: - CoreData Fetching
extension ReaderTopicService: ReaderFollowedInterestsService {
    public func fetchFollowedInterestsLocally(completion: @escaping ([ReaderTagTopic]?) -> Void) {
        completion(followedInterests())
    }

    public func fetchFollowedInterestsRemotely(completion: @escaping ([ReaderTagTopic]?) -> Void) {
        fetchReaderMenu(success: { [weak self] in
            guard let `self` = self else {
                completion(nil)
                return
            }

            self.fetchFollowedInterestsLocally(completion: completion)
        }) { (error) in
            DDLogError("Could not fetch remotely followed interests: \(String(describing: error))")
            completion(nil)
        }
    }

    func followInterests(slugs: [String],
                         success: @escaping ([ReaderTagTopic]?) -> Void,
                         failure: @escaping (Error) -> Void) {
        let topicService = ReaderTopicServiceRemote(wordPressComRestApi: apiRequest())
        topicService.followInterests(withSlugs: slugs, success: { [weak self] in
            self?.fetchFollowedInterestsRemotely(completion: success)
        }) { error in
            failure(error)
        }
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
        let predicate = NSPredicate(format: "following = YES")
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
