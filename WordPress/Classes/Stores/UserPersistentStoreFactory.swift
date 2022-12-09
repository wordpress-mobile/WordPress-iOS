import Foundation

/// Factory was used to sync WP & JP UserDefaults. It was decided to do it as one-off instead.
/// Instead of refactoring the call-sites, we simply return `standard` here. Although it looks
/// redundant, it gives us more flexibility to go back to syncing or apply similar changes and effect is isolated.
/// If it is evident that this kind of thing is no longer needed after migration is complete, we can remove this
/// and update call-sites to call `standard` directly.
@objc
final class UserPersistentStoreFactory: NSObject {
    static func instance() -> UserPersistentRepository {
        UserDefaults.standard
    }

    @objc
    static func userDefaultsInstance() -> UserDefaults {
        return UserDefaults.standard
    }
}
