@testable import WordPress


/// A null mock implementation of the KeyValueDatabase protocol 
class NullMockUserDefaults: KeyValueDatabase {
    func object(forKey defaultName: String) -> Any? {
        return nil
    }

    func bool(forKey: String) -> Bool {
        return false
    }

    func set(_ value: Any?, forKey defaultName: String) {
        //
    }

    func removeObject(forKey defaultName: String) {
        //
    }
}
