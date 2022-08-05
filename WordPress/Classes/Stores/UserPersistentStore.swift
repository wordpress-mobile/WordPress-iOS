class UserPersistentStore: UserPersistentRepository {
    static let standard = UserPersistentStore(defaultsSuiteName: defaultsSuiteName)
    private static let defaultsSuiteName = "temporary.suite.name"

    private let userDefaults: UserDefaults

    init(defaultsSuiteName: String) {
        userDefaults = UserDefaults(suiteName: defaultsSuiteName)!
    }

    // MARK: - UserePersistentRepositoryWriter
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
}

