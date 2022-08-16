import Foundation

final class UserPersistentStoreFactory {
    static func instance() -> UserPersistentRepository {
        FeatureFlag.sharedUserDefaults.enabled ? UserPersistentStore.standard : UserDefaults.standard
    }
}
