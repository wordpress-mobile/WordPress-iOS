/// This structs helps encapsulate logic related to Gutenberg rollout phases.
///
struct GutenbergRollout {
    enum Key {
        static let userInRolloutGroup = "kUserInGutenbergRolloutGroup"
    }
    let database: KeyValueDatabase
    private let phase2Percentage = 100
    private let context = Environment.current.contextManager.mainContext

    var isUserInRolloutGroup: Bool {
        get {
            database.bool(forKey: Key.userInRolloutGroup)
        }
        set {
            database.set(newValue, forKey: Key.userInRolloutGroup)
        }
    }

    func shouldPerformPhase2Migration(userId: Int) -> Bool {
        return
            isUserInRolloutGroup == false &&
            atLeastOneSiteHasAztecEnabled() &&
            isUserIdInPhase2RolloutPercentage(userId)
    }

    private func isUserIdInPhase2RolloutPercentage(_ userId: Int) -> Bool {
        return userId % 100 >= (100 - phase2Percentage)
    }

    private func atLeastOneSiteHasAztecEnabled() -> Bool {
        let allBlogs = BlogService(managedObjectContext: context).blogsForAllAccounts()
        return allBlogs.contains { $0.editor == .aztec }
    }
}
