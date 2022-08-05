protocol UserPersistentRepositoryReader {

}

protocol UserPersistentRepositoryWriter {
    func set(_ value: Int, forKey defaultName: String)
    func set(_ value: Float, forKey defaultName: String)
    func set(_ value: Double, forKey defaultName: String)
    func set(_ value: Bool, forKey defaultName: String)
}

typealias UserPersistentRepository = UserPersistentRepositoryReader & UserPersistentRepositoryWriter

extension UserDefaults: UserPersistentRepository { }
