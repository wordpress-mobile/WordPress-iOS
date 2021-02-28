import Foundation

private struct Constants {
    static let userDefaultsKeyFormat = "PostSignUpInterstitial.hasSeenBefore.%@"
}

class PostSignUpInterstitialCoordinator {
    private let database: KeyValueDatabase
    private let userId: NSNumber?

    init(database: KeyValueDatabase = UserDefaults.standard, userId: NSNumber? = nil ) {
        self.database = database

        let context = ContextManager.shared.mainContext
        self.userId = try? userId ?? WPAccount.lookupDefaultWordPressComAccount(in: context)?.userID
    }

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

    /// Determines whether or not the PSI should be displayed for the logged in user
    /// - Parameters:
    ///   - numberOfBlogs: The number of blogs the account has
    @objc func shouldDisplay(numberOfBlogs: Int) -> Bool {
        if hasSeenBefore() {
            return false
        }

        return numberOfBlogs == 0
    }

    /// Determines whether the PSI has been displayed to the logged in user
    func hasSeenBefore() -> Bool {
        guard let key = userDefaultsKey else {
            return false
        }

        return database.bool(forKey: key)
    }

    /// Marks the PSI as seen for the logged in user
    func markAsSeen() {
        guard let key = userDefaultsKey else {
            return
        }

        database.set(true, forKey: key)
    }
}
