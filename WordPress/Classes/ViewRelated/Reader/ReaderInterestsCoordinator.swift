import Foundation

class ReaderSelectInterestsCoordinator {
    private struct Constants {
        static let userDefaultsKeyFormat: String = "Reader.SelectInterests.hasSeenBefore.%@"
        static let loggedOutUserKey: String = "logged-out"
    }

    private let interestsService: ReaderFollowedInterestsService
    private let store: KeyValueDatabase
    private let userId: NSNumber?

    /// Generates the user defaults key for the current user
    private var userDefaultsKey: String {
        return String(format: Constants.userDefaultsKeyFormat, userId ?? Constants.loggedOutUserKey)
    }

    /// Creates a new instance of the coordinator
    /// - Parameter service: An Optional `ReaderFollowedInterestsService` to use. If this is `nil` one will be created on the main context
    ///   - store: An optional backing store to keep track of if the user has seen the select interests view or not
    ///   - userId: The logged in user account, this makes sure the tracking is a per-user basis
    init(service: ReaderFollowedInterestsService? = nil,
         store: KeyValueDatabase = UserDefaults.standard,
         userId: NSNumber? = nil,
         context: NSManagedObjectContext = ContextManager.sharedInstance().mainContext) {

        self.interestsService = service ?? ReaderTopicService(managedObjectContext: context)
        self.store = store
        self.userId = userId ?? {
            let acctServ = AccountService(managedObjectContext: context)
            let account = acctServ.defaultWordPressComAccount()

            return account?.userID
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
    public func shouldDisplay(completion: @escaping (Bool) -> Void) {
        interestsService.fetchFollowedInterestsLocally { [weak self] (followedInterests) in
            let shouldDisplay: Bool = self?.shouldDisplaySelectInterests(with: followedInterests) ?? false
            completion(shouldDisplay)
        }
    }

    private func shouldDisplaySelectInterests(with interests: [ReaderTagTopic]?) -> Bool {
        guard let interests = interests else {
            return false
        }

        return !hasSeenBefore() && interests.count <= 0
    }

    // MARK: - View Tracking
    /// Determines whether the select interests view has been seen before
    func hasSeenBefore() -> Bool {
        return store.bool(forKey: userDefaultsKey)
    }

    /// Marks the view as seen for the user
    func markAsSeen() {
        store.set(true, forKey: userDefaultsKey)
    }
}
