protocol UserPersistentRepositoryReader {
    func object(forKey key: String) -> Any?
    func string(forKey key: String) -> String?
    func bool(forKey key: String) -> Bool
    func integer(forKey key: String) -> Int
    func float(forKey key: String) -> Float
    func double(forKey key: String) -> Double
    func array(forKey key: String) -> [Any]?
    func dictionary(forKey key: String) -> [String: Any]?
    func url(forKey key: String) -> URL?
}

protocol UserPersistentRepositoryWriter {
    func set(_ value: Any?, forKey key: String)
    func set(_ value: Int, forKey key: String)
    func set(_ value: Float, forKey key: String)
    func set(_ value: Double, forKey key: String)
    func set(_ value: Bool, forKey key: String)
    func set(_ url: URL?, forKey key: String)
    func removeObject(forKey key: String)
}

protocol UserPersistentRepository: UserPersistentRepositoryReader, UserPersistentRepositoryWriter {
    var isOneOffMigrationComplete: Bool { get set }
    static var isOneOffMigrationCompleteKey: String { get }
}

extension UserPersistentRepository {
    static var isOneOffMigrationCompleteKey: String {
        "defaults_one_off_migration"
    }
}

extension UserDefaults: UserPersistentRepository {
    var isOneOffMigrationComplete: Bool {
        get {
            UserDefaults.standard.bool(forKey: Self.isOneOffMigrationCompleteKey)
        } set {
            UserDefaults.standard.set(newValue, forKey: Self.isOneOffMigrationCompleteKey)
        }
    }
}
