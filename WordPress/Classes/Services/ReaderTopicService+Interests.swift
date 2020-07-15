import Foundation
import WordPressKit

// MARK: - ReaderInterestsService

/// Protocol representing a service that retrieves a list of interests stored remotely
protocol ReaderInterestsService: AnyObject {
    /// Fetches a large list of interests from the server
    /// - Parameters:
    ///   - success: Called upon successful completion and parsing, provides an array of `RemoteReaderInterest` objects
    ///   - failure: Called upon network failure, or parsing errors, provides an Error object
    func fetchInterests(success: @escaping ([RemoteReaderInterest]) -> Void,
                        failure: @escaping (Error) -> Void)
}

// MARK: - Select Interests
extension ReaderTopicService: ReaderInterestsService {
    public func fetchInterests(success: @escaping ([RemoteReaderInterest]) -> Void,
                               failure: @escaping (Error) -> Void) {
        let service = ReaderTopicServiceRemote(wordPressComRestApi: apiRequest())

        service.fetchInterests({ (interests) in
            success(interests)
        }) { (error) in
            failure(error)
        }
    }


    /// Creates a new WP.com API instances that allows us to specify the LocaleKeyV2
    private func apiRequest() -> WordPressComRestApi {
        let accountService = AccountService(managedObjectContext: managedObjectContext)
        let defaultAccount = accountService.defaultWordPressComAccount()
        let token: String? = defaultAccount?.authToken

        return WordPressComRestApi.defaultApi(oAuthToken: token,
                                              userAgent: WPUserAgent.wordPress(),
                                              localeKey: WordPressComRestApi.LocaleKeyV2)
    }
}

// MARK: - ReaderLocalInterestsService

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
