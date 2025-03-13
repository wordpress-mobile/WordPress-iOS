public protocol UserPersistentRepositoryWriter: KeyValueDatabase {
    func set(_ value: Any?, forKey key: String)
    func set(_ value: Int, forKey key: String)
    func set(_ value: Float, forKey key: String)
    func set(_ value: Double, forKey key: String)
    func set(_ value: Bool, forKey key: String)
    func set(_ url: URL?, forKey key: String)
    func removeObject(forKey key: String)
}
