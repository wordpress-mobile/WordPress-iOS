import WordPressData

final class MockAuthKeyMigration: AuthKeyMigrationProtocol {
    var migrateCalledWithUsernames: [String] = []

    func migrateIfNeeded(username: String) {
        migrateCalledWithUsernames.append(username)
    }
}
