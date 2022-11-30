import Foundation
@testable import WordPress

class InMemoryUserDefaults: UserPersistentRepository {

    private var dictionary: [String: Any?] = [:]

    func string(forKey key: String) -> String? {
        return dictionary[key] as? String
    }

    func integer(forKey key: String) -> Int {
        if let value = dictionary[key] as? Int {
            return value
        }
        return 0
    }

    func float(forKey key: String) -> Float {
        if let value = dictionary[key] as? Float {
            return value
        }
        return 0
    }

    func double(forKey key: String) -> Double {
        if let value = dictionary[key] as? Double {
            return value
        }
        return 0
    }

    func array(forKey key: String) -> [Any]? {
        return dictionary[key] as? [Any]
    }

    func dictionary(forKey key: String) -> [String: Any]? {
        return dictionary[key] as? [String: Any]
    }

    func url(forKey key: String) -> URL? {
        return dictionary[key] as? URL
    }

    func dictionaryRepresentation() -> [String: Any] {
        return dictionary as [String: Any]
    }

    func set(_ value: Any?, forKey key: String) {
        dictionary[key] = value
    }

    func set(_ value: Int, forKey key: String) {
        dictionary[key] = value
    }

    func set(_ value: Float, forKey key: String) {
        dictionary[key] = value
    }

    func set(_ value: Double, forKey key: String) {
        dictionary[key] = value
    }

    func set(_ value: Bool, forKey key: String) {
        dictionary[key] = value
    }

    func set(_ url: URL?, forKey key: String) {
        dictionary[key] = url
    }

    func removeObject(forKey key: String) {
        dictionary[key] = nil
    }

    func object(forKey defaultName: String) -> Any? {
        return dictionary[defaultName] as Any?
    }
}
