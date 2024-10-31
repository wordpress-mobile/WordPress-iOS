import Foundation

class ReaderSelectInterestsCoordinator {
    private let interestsService: ReaderFollowedInterestsService
    private let userId: NSNumber?

    /// Creates a new instance of the coordinator
    /// - Parameter service: An Optional `ReaderFollowedInterestsService` to use. If this is `nil` one will be created on the main context
    ///   - store: An optional backing store to keep track of if the user has seen the select interests view or not
    ///   - userId: The logged in user account, this makes sure the tracking is a per-user basis
    init(service: ReaderFollowedInterestsService? = nil,
         store: KeyValueDatabase = UserPersistentStoreFactory.instance(),
         userId: NSNumber? = nil,
         context: NSManagedObjectContext = ContextManager.sharedInstance().mainContext) {

        self.interestsService = service ?? ReaderTopicService(coreDataStack: ContextManager.shared)
        self.userId = userId ?? {
            return try? WPAccount.lookupDefaultWordPressComAccount(in: context)?.userID
        }()
    }

    // MARK: - Saving
    public func saveInterests(interests: [RemoteReaderInterest], completion: @escaping (Bool) -> Void) {
        let isLoggedIn = userId != nil

        interestsService.followInterests(interests, success: { _ in
            completion(true)

        }, failure: { _ in
            completion(false)

        }, isLoggedIn: isLoggedIn)
    }

    // MARK: - Display Logic

    /// Determines whether or not the select interests view should be displayed
    /// - Returns: true
    public func isFollowingInterests(completion: @escaping (Bool) -> Void) {
        interestsService.fetchFollowedInterestsLocally { followedInterests in
            guard let interests = followedInterests else {
                return
            }

            let isFollowingInterests = {
                // New users are automatically subscribed to the 'dailyprompt' tag by default.
                // Let's ignore this value and keep showing the Select Interests view if the user
                // is not subscribed to any other tags.
                if let interest = interests.first,
                   interests.count == 1 {
                    return interest.slug != Post.Strings.promptTag
                }
                return interests.count > 0
            }()

            completion(isFollowingInterests)
        }
    }
}
