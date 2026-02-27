import XCTest
@testable import WordPress
@testable import WordPressData

class DataMigratorTests: XCTestCase {

    private var migrator: DataMigrator!
    private var coreDataStack: ContextManager!
    private var keychainUtils: KeychainUtilsMock!
    private var sharedUserDefaults: InMemoryUserDefaults!
    private var localUserDefaults: InMemoryUserDefaults!
    private let appGroupName = "xctest_app_group_name"

    override func setUp() {
        super.setUp()

        coreDataStack = ContextManager.forTesting()
        keychainUtils = KeychainUtilsMock()
        sharedUserDefaults = InMemoryUserDefaults()
        localUserDefaults = InMemoryUserDefaults()
        migrator = DataMigrator(
            coreDataStack: coreDataStack,
            backupLocation: URL(string: "/dev/null"),
            keychainUtils: keychainUtils,
            localDefaults: localUserDefaults,
            sharedDefaults: sharedUserDefaults,
            crashLogger: nil,
            appGroupName: appGroupName
        )
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
        migrator = DataMigrator(
            coreDataStack: coreDataStack,
            backupLocation: URL(string: "/dev/null"),
            keychainUtils: keychainUtils,
            sharedDefaults: nil,
            crashLogger: nil,
            appGroupName: appGroupName
        )

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
        seedDatabase(model: currentModel, at: currentDatabaseFile)
        coreDataStack = ContextManager(modelName: ContextManagerModelNameCurrent, store: currentDatabaseFile)

        // Create a previous database model at the backup location
        let backupLocation = temporaryDatabaseFileURL()
        seedDatabase(model: previousModel, at: backupLocation)

        migrator = DataMigrator(
            coreDataStack: coreDataStack,
            backupLocation: backupLocation,
            keychainUtils: keychainUtils,
            localDefaults: localUserDefaults,
            sharedDefaults: sharedUserDefaults,
            crashLogger: nil,
            appGroupName: appGroupName
        )

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
        seedDatabase(model: previousModel, at: currentDatabaseFile)
        coreDataStack = ContextManager(modelName: ContextManagerModelNameCurrent, store: currentDatabaseFile)

        // Create the current database model at the backup location
        let backupLocation = temporaryDatabaseFileURL()
        seedDatabase(model: currentModel, at: backupLocation)

        migrator = DataMigrator(
            coreDataStack: coreDataStack,
            backupLocation: backupLocation,
            keychainUtils: keychainUtils,
            localDefaults: localUserDefaults,
            sharedDefaults: sharedUserDefaults,
            crashLogger: nil,
            appGroupName: appGroupName
        )

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
    }
}

// MARK: - Helpers

private extension DataMigratorTests {

    enum Constants {
        static let readyToMigrateKey = "wp_data_migration_ready"
        static let defaultsWrapperKey = "defaults_staging_dictionary"
    }

    /// Seeds a SQLite database file at the given location using the specified model.
    func seedDatabase(model: NSManagedObjectModel, at location: URL) {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let store = try! coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: location, options: nil)
        try! coordinator.remove(store)
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
        guard let modelFileURL = Bundle.wordPressData.url(forResource: "WordPress", withExtension: "momd"),
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
        if let url = Bundle.wordPressData.url(forResource: name, withExtension: "mom") {
            return url
        }

        let momdPaths = Bundle.wordPressData.paths(forResourcesOfType: "momd", inDirectory: nil)
        for path in momdPaths {
            if let url = Bundle.wordPressData.url(forResource: name, withExtension: "mom", subdirectory: URL(fileURLWithPath: path).lastPathComponent) {
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
        let fileURL = URL.Helpers.temporaryFile(named: "\(UUID().uuidString).sqlite")

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
