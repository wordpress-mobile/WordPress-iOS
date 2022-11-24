import XCTest
@testable import WordPress

class DataMigratorTests: XCTestCase {

    private var context: NSManagedObjectContext!
    private var migrator: DataMigrator!
    private var coreDataStack: CoreDataStackMock!
    private var keychainUtils: KeychainUtilsMock!
    private var mockLocalStore: MockLocalFileStore!

    override func setUp() {
        super.setUp()

        context = try! createInMemoryContext()
        coreDataStack = CoreDataStackMock(mainContext: context)
        keychainUtils = KeychainUtilsMock()
        mockLocalStore = MockLocalFileStore()
        migrator = DataMigrator(coreDataStack: coreDataStack,
                                backupLocation: URL(string: "/dev/null"),
                                keychainUtils: keychainUtils,
                                localFileStore: mockLocalStore)
    }

    func testExportSucceeds() {
        // Given
        context.addDraftPost(remoteStatus: .sync)
        context.addDraftPost(remoteStatus: .sync)

        // When
        var successful = false
        migrator.exportData { result in
            switch result {
            case .success:
                successful = true
                break
            case .failure:
                break
            }
        }

        // Then
        XCTAssertTrue(successful)
    }

    func testExportFailsWithLocalDrafts() {
        // Given
        context.addDraftPost(remoteStatus: .local)
        context.addDraftPost(remoteStatus: .sync)

        // When
        let migratorError = getExportDataMigratorError(migrator)

        // Then
        XCTAssertEqual(migratorError, .localDraftsNotSynced)
    }

    func testExportFailsWithPushingDrafts() {
        // Given
        context.addDraftPost(remoteStatus: .pushing)
        context.addDraftPost(remoteStatus: .sync)

        // When
        let migratorError = getExportDataMigratorError(migrator)

        // Then
        XCTAssertEqual(migratorError, .localDraftsNotSynced)
    }

    func testExportFailsWithPushingMediaDrafts() {
        // Given
        context.addDraftPost(remoteStatus: .pushingMedia)
        context.addDraftPost(remoteStatus: .sync)

        // When
        let migratorError = getExportDataMigratorError(migrator)

        // Then
        XCTAssertEqual(migratorError, .localDraftsNotSynced)
    }

    func testExportFailsWithFailedUploadDrafts() {
        // Given
        context.addDraftPost(remoteStatus: .failed)
        context.addDraftPost(remoteStatus: .sync)

        // When
        let migratorError = getExportDataMigratorError(migrator)

        // Then
        XCTAssertEqual(migratorError, .localDraftsNotSynced)
    }

    func testUserDefaultsCopiesToSharedOnExport() {
        // Given
        let value = "Test"
        let keys = [UUID().uuidString, UUID().uuidString, UUID().uuidString]
        keys.forEach { key in UserDefaults.standard.set(value, forKey: key) }
        guard let sharedDefaults = UserDefaults(suiteName: WPAppGroupName) else {
            XCTFail("Unable to create shared user defaults")
            return
        }

        // When
        migrator.exportData()

        keys.forEach { key in
            // Then
            let sharedValue = sharedDefaults.value(forKey: key) as? String
            XCTAssertEqual(value, sharedValue)

            UserDefaults.standard.removeObject(forKey: key)
            sharedDefaults.removeObject(forKey: key)
        }
    }

    func testExportFailsWhenSharedUserDefaultsNil() {
        // Given
        migrator = DataMigrator(coreDataStack: coreDataStack, keychainUtils: keychainUtils, sharedDefaults: nil)

        // When
        let migratorError = getExportDataMigratorError(migrator)

        // Then
        XCTAssertEqual(migratorError, .sharedUserDefaultsNil)
    }

    // MARK: Widget Migration Tests

    func test_widgetMigration_keychainShouldMigrateSuccessfully() {
        // Given
        let expectedUsername = "OAuth2Token"
        let expectedPassword = "password"
        let expectedServiceName = "JetpackTodayWidget"
        keychainUtils.passwordToReturn = expectedPassword

        // When
        migrator.copyTodayWidgetDataToJetpack()

        // Then
        XCTAssertNotNil(keychainUtils.storedPassword)
        XCTAssertEqual(keychainUtils.storedPassword, expectedPassword)
        XCTAssertNotNil(keychainUtils.storedUsername)
        XCTAssertEqual(keychainUtils.storedUsername, expectedUsername)
        XCTAssertNotNil(keychainUtils.storedServiceName)
        XCTAssertEqual(keychainUtils.storedServiceName, expectedServiceName)
        XCTAssertNil(keychainUtils.storedAccessGroup)
    }

    func test_widgetMigration_whenKeychainDoesNotExist_itShouldNotBeCopied() {
        // When
        migrator.copyTodayWidgetDataToJetpack()

        // Then
        XCTAssertNil(keychainUtils.storedPassword)
    }

    func test_widgetMigration_userDefaultsShouldMigrateSuccessfully() {
        // TODO: This will be added later.
    }

    func test_widgetMigration_plistFileShouldMigrateSuccessfully() {
        // Given
        let expectedSourceFilename = "HomeWidgetTodayData.plist"
        mockLocalStore.fileShouldExistClosure = { url in
            guard let url else {
                return false
            }
            return url.lastPathComponent == expectedSourceFilename
        }

        // When
        migrator.copyTodayWidgetDataToJetpack()

        // Then
        XCTAssertEqual(mockLocalStore.removeItemCallCount, 0)
        XCTAssertEqual(mockLocalStore.copyItemCallCount, 1)
    }

    func test_widgetMigration_whenTargetPlistFileExists_itShouldBeDeletedFirst() {
        // Given
        let expectedSourceFilename = "HomeWidgetTodayData.plist"
        let expectedTargetFilename = "JetpackHomeWidgetTodayData.plist"
        mockLocalStore.fileShouldExistClosure = { url in
            guard let url else {
                return false
            }
            return [expectedSourceFilename, expectedTargetFilename].contains(url.lastPathComponent)
        }

        // When
        migrator.copyTodayWidgetDataToJetpack()

        // Then
        // migrator tries to remove any existing item in the target location first.
        XCTAssertEqual(mockLocalStore.removeItemCallCount, 1)
        XCTAssertEqual(mockLocalStore.copyItemCallCount, 1)
    }

}

// MARK: - CoreDataStackMock

private final class CoreDataStackMock: CoreDataStack {
    var mainContext: NSManagedObjectContext

    init(mainContext: NSManagedObjectContext) {
        self.mainContext = mainContext
    }

    func newDerivedContext() -> NSManagedObjectContext {
        return mainContext
    }

    func saveContextAndWait(_ context: NSManagedObjectContext) {}
    func save(_ context: NSManagedObjectContext) {}
    func save(_ context: NSManagedObjectContext, withCompletionBlock completionBlock: @escaping () -> Void) {}
}

// MARK: - KeychainUtilsMock

private final class KeychainUtilsMock: KeychainUtils {

    var sourceAccessGroup: String?
    var destinationAccessGroup: String?
    var shouldThrowError = false
    var passwordToReturn: String? = nil
    var storeShouldThrow = false
    var storedPassword: String? = nil
    var storedUsername: String? = nil
    var storedServiceName: String? = nil
    var storedAccessGroup: String? = nil

    override func copyKeychain(from sourceAccessGroup: String?, to destinationAccessGroup: String?, updateExisting: Bool = true) throws {
        if shouldThrowError {
            throw NSError(domain: "", code: 0)
        }

        self.sourceAccessGroup = sourceAccessGroup
        self.destinationAccessGroup = destinationAccessGroup
    }

    override func password(for username: String, serviceName: String, accessGroup: String? = nil) throws -> String? {
        return passwordToReturn
    }

    override func store(username: String, password: String, serviceName: String, accessGroup: String? = nil, updateExisting: Bool) throws {
        if storeShouldThrow {
            throw NSError(domain: "", code: 0)
        }

        storedUsername = username
        storedPassword = password
        storedServiceName = serviceName
        storedAccessGroup = accessGroup
    }

}

// MARK: - Helpers

private extension DataMigratorTests {

    func createInMemoryContext() throws -> NSManagedObjectContext {
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        try persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator

        return managedObjectContext
    }

    func getExportDataMigratorError(_ migrator: DataMigrator) -> DataMigrator.DataMigratorError? {
        var migratorError: DataMigrator.DataMigratorError?
        migrator.exportData { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                migratorError = error
            }
        }
        return migratorError
    }
}

private extension NSManagedObjectContext {

    func createBlog() -> Blog {
        let blog = NSEntityDescription.insertNewObject(forEntityName: "Blog", into: self) as! Blog
        blog.url = ""
        blog.xmlrpc = ""
        return blog
    }

    func addDraftPost(remoteStatus: AbstractPostRemoteStatus) {
        let post = NSEntityDescription.insertNewObject(forEntityName: "Post", into: self) as! Post
        post.blog = createBlog()
        post.remoteStatus = remoteStatus
        post.dateModified = Date()
        post.status = .draft
        try! save()
    }

}

// MARK: - Mock Local File Store

private final class MockLocalFileStore: LocalFileStore {
    var fileShouldExistClosure: (URL?) -> Bool = { _ in return false }
    var removeItemCallCount: Int = 0
    var copyItemCallCount: Int = 0

    var removeShouldThrowError: Bool = false
    var copyShouldThrowError: Bool = false

    func fileExists(at url: URL) -> Bool {
        return fileShouldExistClosure(url)
    }

    func save(contents: Data, at url: URL) -> Bool {
        return true
    }

    func containerURL(forAppGroup appGroup: String) -> URL? {
        return URL(string: "/dev/null")
    }

    func removeItem(at url: URL) throws {
        if removeShouldThrowError {
            throw NSError(domain: "", code: 0)
        }
        removeItemCallCount += 1
    }

    func copyItem(at srcURL: URL, to dstURL: URL) throws {
        if copyShouldThrowError {
            throw NSError(domain: "", code: 0)
        }
        copyItemCallCount += 1
    }
}
