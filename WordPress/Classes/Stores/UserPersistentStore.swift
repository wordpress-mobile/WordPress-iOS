class UserPersistentStore: UserPersistentRepository {
    static let standard = UserPersistentStore(defaultsSuiteName: defaultsSuiteName)
    private static let defaultsSuiteName = "temporary.suite.name"

    private let userDefaults: UserDefaults

    init?(defaultsSuiteName: String) {
        guard let suiteDefaults = UserDefaults(suiteName: defaultsSuiteName) else {
            return nil
        }
        userDefaults = suiteDefaults
    }

    // MARK: - UserePersistentRepositoryWriter
    func set(_ value: Any?, forKey defaultName: String) {
        userDefaults.set(value, forKey: defaultName)
    }

    func set(_ value: Int, forKey defaultName: String) {
        userDefaults.set(value, forKey: defaultName)
    }

    func set(_ value: Float, forKey defaultName: String) {
        userDefaults.set(value, forKey: defaultName)
    }

    func set(_ value: Double, forKey defaultName: String) {
        userDefaults.set(value, forKey: defaultName)
    }

    func set(_ value: Bool, forKey defaultName: String) {
        userDefaults.set(value, forKey: defaultName)
    }

    func set(_ url: URL?, forKey defaultName: String) {
        userDefaults.set(url, forKey: defaultName)
    }
}

