import Foundation

class ReaderSelectInterestsCoordinator {
    private struct Constants {
        static let userDefaultsKeyFormat = "Reader.SelectInterests.hasSeenBefore.%@"
    }

    private let interestsService: ReaderFollowedInterestsService
    private let store: KeyValueDatabase
    private let userId: NSNumber?

    /// Creates a new instance of the coordinator
    /// - Parameter service: An Optional `ReaderFollowedInterestsService` to use. If this is `nil` one will be created on the main context
    ///   - store: An optional backing store to keep track of if the user has seen the select interests view or not
    ///   - userId: The logged in user account, this makes sure the tracking is a per-user basis
    init(service: ReaderFollowedInterestsService? = nil,
         store: KeyValueDatabase = UserDefaults.standard,
         userId: NSNumber? = nil) {

        let defaultContext = ContextManager.sharedInstance().mainContext

        self.interestsService = service ?? ReaderTopicService(managedObjectContext: defaultContext)
        self.store = store
        self.userId = userId ?? {
            let acctServ = AccountService(managedObjectContext: defaultContext)
            let account = acctServ.defaultWordPressComAccount()

            return account?.userID
        }()
    }

    // MARK: - Display Logic

    /// Deteremines whether or not the select interests view should be displayed
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

        let hasSeen = hasSeenBefore()
        DDLogDebug("Reader Improvements: Count: \(interests.count), has seen before? \(hasSeen)")
        return !hasSeen && interests.count <= 0
    }

    // MARK: - View Tracking

    /// Generates the user defaults key for the logged in user
    /// Returns nil if we can not get the default WP.com account
    private var userDefaultsKey: String? {
        get {
            guard let userId = self.userId else {
                return nil
            }

            return String(format: Constants.userDefaultsKeyFormat, userId)
        }
    }

    /// Determines whether the select interests view has been seen before
    func hasSeenBefore() -> Bool {
        guard let key = userDefaultsKey else {
            return false
        }

        return store.bool(forKey: key)
    }

    /// Marks the view as seen for the user
    func markAsSeen() {
        guard let key = userDefaultsKey else {
            return
        }

        store.set(true, forKey: key)
    }

    func _debugResetHasSeen() {
        guard let key = userDefaultsKey else {
            return
        }

        DDLogDebug("Resetting hasSeenBefore: \(key)")
        store.set(false, forKey: key)
    }
}
