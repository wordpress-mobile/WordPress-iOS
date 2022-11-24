import XCTest
@testable import WordPress

class DataMigratorTests: XCTestCase {

    private var context: NSManagedObjectContext!
    private var migrator: DataMigrator!
    private var coreDataStack: CoreDataStackMock!
    private var keychainUtils: KeychainUtilsMock!

    override func setUp() {
        super.setUp()

        context = try! createInMemoryContext()
        coreDataStack = CoreDataStackMock(mainContext: context)
        keychainUtils = KeychainUtilsMock()
        migrator = DataMigrator(coreDataStack: coreDataStack, backupLocation: URL(string: "/dev/null"), keychainUtils: keychainUtils)
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

//    func testExportFailsWhenKeychainThrows() {
//        // Given
//        keychainUtils.shouldThrowError = true
//
//        // When
//        let migratorError = getExportDataMigratorError(migrator)
//
//        // Then
//        XCTAssertEqual(migratorError, .keychainError)
//    }

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

    override func copyKeychain(from sourceAccessGroup: String?, to destinationAccessGroup: String?, updateExisting: Bool = true) throws {
        if shouldThrowError {
            throw NSError(domain: "", code: 0)
        }

        self.sourceAccessGroup = sourceAccessGroup
        self.destinationAccessGroup = destinationAccessGroup
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
