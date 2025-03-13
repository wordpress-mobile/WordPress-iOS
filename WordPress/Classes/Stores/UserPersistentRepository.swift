import WordPressShared

typealias UserPersistentRepository = UserPersistentRepositoryReader & UserPersistentRepositoryWriter & UserPersistentRepositoryUtility

extension UserDefaults: UserPersistentRepository {}
