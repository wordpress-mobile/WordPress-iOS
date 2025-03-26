import Foundation

public typealias UserPersistentRepository = UserPersistentRepositoryReader & UserPersistentRepositoryWriter & UserPersistentRepositoryUtility

extension UserDefaults: UserPersistentRepository {}
