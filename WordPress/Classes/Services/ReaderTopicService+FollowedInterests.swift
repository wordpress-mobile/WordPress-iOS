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
}

// MARK: - CoreData Fetching
extension ReaderTopicService: ReaderFollowedInterestsService {
    public func fetchFollowedInterestsLocally(completion: @escaping ([ReaderTagTopic]?) -> Void) {
        completion(followedInterests())
    }

    public func fetchFollowedInterestsRemotely(completion: @escaping ([ReaderTagTopic]?) -> Void) {
        fetchReaderMenu(success: { [weak self] in
            self?.fetchFollowedInterestsLocally(completion: completion)
        }) { error in
            DDLogError("Could not fetch remotely followed interests: \(String(describing: error))")
            completion(nil)
        }
    }

    // MARK: - Private: Helpers
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
