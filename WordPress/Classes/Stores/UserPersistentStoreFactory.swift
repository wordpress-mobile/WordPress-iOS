import Foundation

@objc
final class UserPersistentStoreFactory: NSObject {
    static func instance() -> UserPersistentRepository {
        FeatureFlag.sharedUserDefaults.enabled ? UserPersistentStore.standard : UserDefaults.standard
    }

    @objc
    static func userDefaultsInstance() -> UserDefaults {
        guard FeatureFlag.sharedUserDefaults.enabled, let defaults = UserDefaults(suiteName: WPAppGroupName) else {
            return UserDefaults.standard
        }

        return defaults
    }
}
