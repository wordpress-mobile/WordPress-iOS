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

        context = try! createContext()
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
        XCTAssertEqual(migratorError, DataMigrationError.databaseExportError(underlyingError: DataMigrationError.sharedUserDefaultsNil))
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

    func test_importData_databaseUpgradeFromOlderModel_shouldSucceed() {
        // Given
        sharedUserDefaults.set(true, forKey: Constants.readyToMigrateKey)
        sharedUserDefaults.set(["test": 1], forKey: Constants.defaultsWrapperKey)

        let (currentModel, previousModel) = getRecentObjectModels()
        guard let currentModel, let previousModel else {
            XCTFail("Invalid core data models")
            return
        }

        // Set the active database to the current database model
        let currentDatabaseFile = temporaryDatabaseFileURL()
        context = try! createFileContext(for: currentModel, at: currentDatabaseFile)
        coreDataStack = CoreDataStackMock(mainContext: context)

        // Create a previous database model at the backup location
        let backupLocation = temporaryDatabaseFileURL()
        _ = try! createFileContext(for: previousModel, at: backupLocation)

        migrator = DataMigrator(coreDataStack: coreDataStack,
                                backupLocation: backupLocation,
                                keychainUtils: keychainUtils,
                                localDefaults: localUserDefaults,
                                sharedDefaults: sharedUserDefaults)

        // When
        let expect = expectation(description: "Import data should succeed")
        migrator.importData { result in
            // Then
            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("Import data failed: \(error)")
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1)

        // Prevents a warning about deleting an open file descriptor
        migrator = nil
        coreDataStack = nil
        context = nil
    }

    func test_importData_databaseDowngradeFromNewerModel_shouldSucceed() {
        // Given
        sharedUserDefaults.set(true, forKey: Constants.readyToMigrateKey)
        sharedUserDefaults.set(["test": 1], forKey: Constants.defaultsWrapperKey)

        let (currentModel, previousModel) = getRecentObjectModels()
        guard let currentModel, let previousModel else {
            XCTFail("Invalid core data models")
            return
        }

        // Set the active database to the previous database model
        let currentDatabaseFile = temporaryDatabaseFileURL()
        context = try! createFileContext(for: previousModel, at: currentDatabaseFile)
        coreDataStack = CoreDataStackMock(mainContext: context)

        // Create the current database model at the backup location
        let backupLocation = temporaryDatabaseFileURL()
        _ = try! createFileContext(for: currentModel, at: backupLocation)

        migrator = DataMigrator(coreDataStack: coreDataStack,
                                backupLocation: backupLocation,
                                keychainUtils: keychainUtils,
                                localDefaults: localUserDefaults,
                                sharedDefaults: sharedUserDefaults)

        // When
        let expect = expectation(description: "Import data should succeed")
        migrator.importData { result in
            // Then
            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("Import data failed: \(error)")
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1)

        // Prevents a warning about deleting an open file descriptor
        migrator = nil
        coreDataStack = nil
        context = nil
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

    func createContext(for model: NSManagedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!,
                       type: String = NSInMemoryStoreType,
                       at location: URL? = nil) throws -> NSManagedObjectContext {
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try persistentStoreCoordinator.addPersistentStore(ofType: type, configurationName: nil, at: location, options: nil)
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator

        return managedObjectContext
    }

    func createFileContext(for model: NSManagedObjectModel, at location: URL) throws -> NSManagedObjectContext {
        return try createContext(for: model, type: NSSQLiteStoreType, at: location)
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

    func getModelNames() -> [String] {
        guard let modelFileURL = Bundle.main.url(forResource: "WordPress", withExtension: "momd"),
              let versionInfo = NSDictionary(contentsOf: modelFileURL.appendingPathComponent("VersionInfo.plist")),
              let modelNames = (versionInfo["NSManagedObjectModel_VersionHashes"] as? [String: AnyObject])?.keys else {
            return []
        }
        let sortedModelNames = modelNames.sorted { $0.compare($1, options: .numeric) == .orderedAscending }
        return sortedModelNames
    }

    func getModelObject(for modelName: String) -> NSManagedObjectModel? {
        guard let url = urlForModel(name: modelName) else {
            return nil
        }
        return NSManagedObjectModel(contentsOf: url)
    }

    func urlForModel(name: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: "mom") {
            return url
        }

        let momdPaths = Bundle.main.paths(forResourcesOfType: "momd", inDirectory: nil)
        for path in momdPaths {
            if let url = Bundle.main.url(forResource: name, withExtension: "mom", subdirectory: URL(fileURLWithPath: path).lastPathComponent) {
                return url
            }
        }

        return nil
    }

    func getRecentObjectModels() -> (current: NSManagedObjectModel?, previous: NSManagedObjectModel?) {
        let models = getModelNames()
        guard models.count > 1,
              let currentModel = getModelObject(for: models[models.count - 1]),
              let previousModel = getModelObject(for: models[models.count - 2]) else {
            return (current: nil, previous: nil)
        }
        return (current: currentModel, previous: previousModel)
    }

    // Slightly modified from: https://developer.apple.com/documentation/xctest/xctestcase/2887226-addteardownblock
    func temporaryDatabaseFileURL() -> URL {
        // Create a URL for an unique file in the system's temporary directory.
        let directory = NSTemporaryDirectory()
        let filename = "\(UUID().uuidString).sqlite"
        let fileURL = URL(fileURLWithPath: directory).appendingPathComponent(filename)

        // Add a teardown block to delete any file at `fileURL`.
        addTeardownBlock {
            do {
                let fileManager = FileManager.default
                let shmFileURL = URL(string: fileURL.absoluteString.appending("-shm"))
                let walFileURL = URL(string: fileURL.absoluteString.appending("-wal"))
                let files = [fileURL, shmFileURL, walFileURL]

                try files.forEach { file in
                    guard let file else {
                        return
                    }
                    // Check that the file exists before trying to delete it.
                    if fileManager.fileExistsAtURL(file) {
                        // Perform the deletion.
                        try fileManager.removeItem(at: file)
                        // Verify that the file no longer exists after the deletion.
                        XCTAssertFalse(fileManager.fileExistsAtURL(file))
                    }
                }
            } catch {
                // Treat any errors during file deletion as a test failure.
                XCTFail("Error while deleting temporary file: \(error)")
            }
        }

        // Return the temporary file URL for use in a test method.
        return fileURL
    }
}
