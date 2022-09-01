class UserPersistentStore: UserPersistentRepository {
    static let standard = UserPersistentStore(defaultsSuiteName: defaultsSuiteName)!
    private static let defaultsSuiteName = WPAppGroupName // TBD

    private let userDefaults: UserDefaults

    init?(defaultsSuiteName: String) {
        guard let suiteDefaults = UserDefaults(suiteName: defaultsSuiteName) else {
            return nil
        }
        userDefaults = suiteDefaults
    }

    // MARK: - UserPeresistentRepositoryReader
    func object(forKey key: String) -> Any? {
        if let object = userDefaults.object(forKey: key) {
            return object
        }

        return UserDefaults.standard.object(forKey: key)
    }

    func string(forKey key: String) -> String? {
        if let string = userDefaults.string(forKey: key) {
            return string
        }

        return UserDefaults.standard.string(forKey: key)
    }

    func bool(forKey key: String) -> Bool {
        userDefaults.bool(forKey: key) || UserDefaults.standard.bool(forKey: key)
    }

    func integer(forKey key: String) -> Int {
        let suiteValue = userDefaults.integer(forKey: key)
        if suiteValue != 0 {
            return suiteValue
        }

        return UserDefaults.standard.integer(forKey: key)
    }

    func float(forKey key: String) -> Float {
        let suiteValue = userDefaults.float(forKey: key)
        if suiteValue != 0 {
            return suiteValue
        }

        return UserDefaults.standard.float(forKey: key)
    }

    func double(forKey key: String) -> Double {
        let suiteValue = userDefaults.double(forKey: key)
        if suiteValue != 0 {
            return suiteValue
        }

        return UserDefaults.standard.double(forKey: key)
    }

    func array(forKey key: String) -> [Any]? {
        let suiteValue = userDefaults.array(forKey: key)
        if suiteValue != nil {
            return suiteValue
        }

        return UserDefaults.standard.array(forKey: key)
    }

    func dictionary(forKey key: String) -> [String: Any]? {
        let suiteValue = userDefaults.dictionary(forKey: key)
        if suiteValue != nil {
            return suiteValue
        }

        return UserDefaults.standard.dictionary(forKey: key)
    }

    func url(forKey key: String) -> URL? {
        if let url = userDefaults.url(forKey: key) {
            return url
        }

        return UserDefaults.standard.url(forKey: key)
    }

    // MARK: - UserPersistentRepositoryWriter
    func set(_ value: Any?, forKey key: String) {
        userDefaults.set(value, forKey: key)
        UserDefaults.standard.removeObject(forKey: key)
    }

    func set(_ value: Int, forKey key: String) {
        userDefaults.set(value, forKey: key)
        UserDefaults.standard.removeObject(forKey: key)
    }

    func set(_ value: Float, forKey key: String) {
        userDefaults.set(value, forKey: key)
        UserDefaults.standard.removeObject(forKey: key)
    }

    func set(_ value: Double, forKey key: String) {
        userDefaults.set(value, forKey: key)
        UserDefaults.standard.removeObject(forKey: key)
    }

    func set(_ value: Bool, forKey key: String) {
        userDefaults.set(value, forKey: key)
        UserDefaults.standard.removeObject(forKey: key)
    }

    func set(_ url: URL?, forKey key: String) {
        userDefaults.set(url, forKey: key)
        UserDefaults.standard.removeObject(forKey: key)
    }

    func removeObject(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
}
