@testable import WordPress
import WordPressShared

/// A null mock implementation of the KeyValueDatabase protocol
class NullMockUserDefaults: KeyValueDatabase {
    func object(forKey defaultName: String) -> Any? {
        return nil
    }

    func set(_ value: Any?, forKey defaultName: String) {
        //
    }

    func removeObject(forKey defaultName: String) {
        //
    }
}
