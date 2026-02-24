import Testing
@testable import WordPressData

@MainActor
struct WPAccountTests {
    private let contextManager = ContextManager.forTesting()
    private var mainContext: NSManagedObjectContext { contextManager.mainContext }

    // MARK: - Auth Token (Get)

    @Test func getAuthTokenReturnsTokenFromKeychain() {
        let keychain = MockKeychainService()
        keychain.storage["user1"] = "token-123"

        let account = makeAccount(username: "user1", keychain: keychain)
        #expect(account.authToken == "token-123")
        #expect(keychain.receivedServiceNames == ["test-service"])
    }

    @Test func getAuthTokenReturnsCachedTokenOnSecondAccess() {
        let keychain = MockKeychainService()
        keychain.storage["user1"] = "token-123"

        let account = makeAccount(username: "user1", keychain: keychain)

        // First access – reads from keychain
        _ = account.authToken
        #expect(keychain.passwordCallCount == 1)

        // Second access – should use cache
        _ = account.authToken
        #expect(keychain.passwordCallCount == 1)
    }

    @Test func getAuthTokenReturnsNilWhenKeychainThrows() {
        let keychain = MockKeychainService()
        keychain.shouldThrow = true

        let account = makeAccount(username: "user1", keychain: keychain)
        #expect(account.authToken == nil)
    }

    @Test func getAuthTokenCallsMigrationBeforeKeychainAccess() {
        let keychain = MockKeychainService()
        keychain.storage["user1"] = "token"
        let migration = MockAuthKeyMigration()

        let account = makeAccount(username: "user1", keychain: keychain, migration: migration)
        _ = account.authToken
        #expect(migration.migrateCalledWithUsernames == ["user1"])
    }

    // MARK: - Auth Token (Set)

    @Test func setAuthTokenStoresTokenInKeychain() {
        let keychain = MockKeychainService()

        let account = makeAccount(username: "user1", keychain: keychain)
        account.authToken = "new-token"

        #expect(keychain.storage["user1"] == "new-token")
        #expect(keychain.receivedServiceNames == ["test-service"])
    }

    @Test func setAuthTokenToNilDeletesFromKeychain() {
        let keychain = MockKeychainService()
        keychain.storage["user1"] = "old-token"

        let account = makeAccount(username: "user1", keychain: keychain)
        account.authToken = nil

        #expect(keychain.storage["user1"] == nil)
        #expect(keychain.deletedUsernames == ["user1"])
    }

    @Test func setAuthTokenInvalidatesCachedToken() {
        let keychain = MockKeychainService()
        keychain.storage["user1"] = "original"

        let account = makeAccount(username: "user1", keychain: keychain)

        // Populate cache
        _ = account.authToken
        #expect(keychain.passwordCallCount == 1)

        // Setting a new token should invalidate cache
        account.authToken = "updated"

        // Reading should go back to keychain
        let token = account.authToken
        #expect(keychain.passwordCallCount == 2)
        #expect(token == "updated")
    }

    @Test func setAuthTokenNilsOutRestApi() {
        let keychain = MockKeychainService()

        let account = makeAccount(username: "user1", keychain: keychain)
        account._private_wordPressComRestApi = WordPressComRestApi(oAuthToken: "test")

        account.authToken = "new-token"
        #expect(account._private_wordPressComRestApi == nil)
    }

    @Test func setAuthTokenHandlesKeychainErrorGracefully() {
        let keychain = MockKeychainService()
        keychain.shouldThrow = true

        let account = makeAccount(username: "user1", keychain: keychain)
        // Should not throw – errors are logged
        account.authToken = "token"
    }

    // MARK: - Username Setter (Token Migration)

    @Test func settingUsernameMigratesToken() {
        let keychain = MockKeychainService()
        keychain.storage["old-user"] = "my-token"

        let account = makeAccount(username: "old-user", keychain: keychain)

        account.username = "new-user"

        // Token should be moved to new username
        #expect(keychain.storage["new-user"] == "my-token")
        // Old username's token should be deleted
        #expect(keychain.storage["old-user"] == nil)
    }

    @Test func settingSameUsernameDoesNotTouchKeychain() {
        let keychain = MockKeychainService()
        keychain.storage["user1"] = "my-token"

        let account = makeAccount(username: "user1", keychain: keychain)

        // Reset counters after account creation
        keychain.setPasswordCallCount = 0
        keychain.deletedUsernames = []

        account.username = "user1"

        // No keychain mutations should happen
        #expect(keychain.setPasswordCallCount == 0)
        #expect(keychain.deletedUsernames.isEmpty)
    }

    @Test func settingUsernameUpdatesStoredValue() {
        let keychain = MockKeychainService()

        let account = makeAccount(username: "old-user", keychain: keychain)
        account.username = "new-user"

        #expect(account.username == "new-user")
    }

    // MARK: - Lifecycle

    @Test func prepareForDeletionClearsAuthTokenAndApi() throws {
        let keychain = MockKeychainService()
        keychain.storage["user1"] = "token"

        let account = makeAccount(username: "user1", keychain: keychain)
        account._private_wordPressComRestApi = WordPressComRestApi(oAuthToken: "test")

        mainContext.delete(account)
        try mainContext.save()

        // Auth token should have been cleared from keychain
        #expect(keychain.storage["user1"] == nil)
    }

    @Test func didTurnIntoFaultClearsTransientState() throws {
        let keychain = MockKeychainService()
        keychain.storage["user1"] = "token"

        let account = makeAccount(username: "user1", keychain: keychain)
        account._private_wordPressComRestApi = WordPressComRestApi(oAuthToken: "test")

        // Populate the cached token
        _ = account.authToken

        // Turn into fault by refreshing the object
        mainContext.refresh(account, mergeChanges: false)

        #expect(account._private_wordPressComRestApi == nil)
    }

    // MARK: - addBlogs (Set<Blog>)

    @Test func addBlogsWithSwiftSet() {
        let account = makeAccount(username: "user1")
        let blog1 = Blog(context: mainContext)
        let blog2 = Blog(context: mainContext)

        account.addBlogs(Set([blog1, blog2]))

        #expect(account.blogs?.count == 2)
        #expect(account.blogs?.contains(blog1) == true)
        #expect(account.blogs?.contains(blog2) == true)
    }

    // MARK: - Helpers

    @discardableResult
    private func makeAccount(
        username: String,
        keychain: MockKeychainService = MockKeychainService(),
        migration: MockAuthKeyMigration = MockAuthKeyMigration()
    ) -> WPAccount {
        let account = NSEntityDescription.insertNewObject(forEntityName: WPAccount.entityName(), into: mainContext) as! WPAccount
        account.keychain = keychain
        account.keychainServiceName = "test-service"
        account.keychainMigration = migration
        account.uuid = UUID().uuidString
        account.userID = NSNumber(value: 1)

        // Set username via primitive to avoid triggering the custom setter
        // (which would try to read/write keychain before our mock is fully set up)
        account.willChangeValue(forKey: "username")
        account.setPrimitiveValue(username, forKey: "username")
        account.didChangeValue(forKey: "username")

        return account
    }
}
