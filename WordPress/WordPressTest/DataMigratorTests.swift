import XCTest
@testable import WordPress

class DataMigratorTests: XCTestCase {

    private var context: NSManagedObjectContext!
    private var migrator: DataMigrator!
    private var coreDataStack: CoreDataStackMock!
    private var keychainUtils: KeychainUtilsMock!
    private var sharedUserDefaults: InMemoryUserDefaults!
    private var localUserDefaults: InMemoryUserDefaults!

    override func setUp() {
        super.setUp()

        context = try! createInMemoryContext()
        coreDataStack = CoreDataStackMock(mainContext: context)
        keychainUtils = KeychainUtilsMock()
        sharedUserDefaults = InMemoryUserDefaults()
        localUserDefaults = InMemoryUserDefaults()
        migrator = DataMigrator(coreDataStack: coreDataStack,
                                backupLocation: URL(string: "/dev/null"),
                                keychainUtils: keychainUtils,
                                localDefaults: localUserDefaults,
                                sharedDefaults: sharedUserDefaults)
    }

    func testExportSucceeds() {
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
        XCTAssertTrue(sharedUserDefaults.bool(forKey: Constants.readyToMigrateKey))
    }

    func testUserDefaultsCopiesToSharedOnExport() {
        // Given
        let value = "Test"
        let keys = [UUID().uuidString, UUID().uuidString, UUID().uuidString]
        keys.forEach { key in localUserDefaults.set(value, forKey: key) }

        // When
        migrator.exportData()

        let stagingDict = sharedUserDefaults.dictionary(forKey: "defaults_staging_dictionary")
        keys.forEach { key in
            // Then
            let sharedValue = stagingDict?[key] as? String
            XCTAssertEqual(value, sharedValue)

            localUserDefaults.removeObject(forKey: key)
            sharedUserDefaults.removeObject(forKey: key)
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

    func test_importData_givenDataIsNotExported_shouldFail() {
        // wp_data_migration_ready should be false by default, which should cause `importData` to exit early.

        // When
        let expect = expectation(description: "Import Data should fail")
        migrator.importData { result in
            guard case .failure(let error) = result else {
                XCTFail()
                return
            }

            // Then
            XCTAssertEqual(error, DataMigrationError.dataNotReadyToImport)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1)
    }

    // MARK: Exported data deletion tests

    func test_deleteExportedData_shouldMarkDataNotReadyToMigrate() {
        // Given
        sharedUserDefaults.set(true, forKey: Constants.readyToMigrateKey)

        // When
        migrator.deleteExportedData()

        // Then
        XCTAssertFalse(sharedUserDefaults.bool(forKey: Constants.readyToMigrateKey))
    }

    func test_deleteExportedData_shouldRemoveExportedDefaults() {
        // Given
        sharedUserDefaults.set(["test": 1], forKey: Constants.defaultsWrapperKey)

        // When
        migrator.deleteExportedData()

        // Then
        XCTAssertNil(sharedUserDefaults.object(forKey: Constants.defaultsWrapperKey))
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
    func save(_ context: NSManagedObjectContext, completion completionBlock: (() -> Void)?, on queue: DispatchQueue) {}

    func performAndSave(_ aBlock: @escaping (NSManagedObjectContext) -> Void) {}
    func performAndSave(_ aBlock: @escaping (NSManagedObjectContext) -> Void, completion: (() -> Void)?, on queue: DispatchQueue) {}
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

    enum Constants {
        static let readyToMigrateKey = "wp_data_migration_ready"
        static let defaultsWrapperKey = "defaults_staging_dictionary"
    }

    func createInMemoryContext() throws -> NSManagedObjectContext {
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        try persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator

        return managedObjectContext
    }

    func getExportDataMigratorError(_ migrator: DataMigrator) -> DataMigrationError? {
        var migratorError: DataMigrationError?
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
