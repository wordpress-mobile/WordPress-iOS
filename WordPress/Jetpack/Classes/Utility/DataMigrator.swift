protocol ContentDataMigrating {
    func exportData(completion: ((Result<Void, DataMigrationError>) -> Void)?)
    func importData(completion: ((Result<Void, DataMigrationError>) -> Void)?)
}

enum DataMigrationError: Error {
    case databaseCopyError
    case sharedUserDefaultsNil
}

final class DataMigrator {
    private let coreDataStack: CoreDataStack
    private let backupLocation: URL?
    private let keychainUtils: KeychainUtils
    private let localDefaults: UserPersistentRepository
    private let sharedDefaults: UserPersistentRepository?

    init(coreDataStack: CoreDataStack = ContextManager.sharedInstance(),
         backupLocation: URL? = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.wordpress")?.appendingPathComponent("WordPress.sqlite"),
         keychainUtils: KeychainUtils = KeychainUtils(),
         localDefaults: UserPersistentRepository = UserDefaults.standard,
         sharedDefaults: UserPersistentRepository? = UserDefaults(suiteName: WPAppGroupName)) {
        self.coreDataStack = coreDataStack
        self.backupLocation = backupLocation
        self.keychainUtils = keychainUtils
        self.localDefaults = localDefaults
        self.sharedDefaults = sharedDefaults
    }

    /// Convenience variable to check whether the export data is ready to be imported.
    private(set) var isDataReadyToMigrate: Bool {
        get {
            sharedDefaults?.bool(forKey: .dataReadyToMigrateKey) ?? false
        }
        set {
            sharedDefaults?.set(newValue, forKey: .dataReadyToMigrateKey)
        }
    }
}

// MARK: - Content Data Migrating

extension DataMigrator: ContentDataMigrating {

    func exportData(completion: ((Result<Void, DataMigrationError>) -> Void)? = nil) {
        guard let backupLocation, copyDatabase(to: backupLocation) else {
            completion?(.failure(.databaseCopyError))
            return
        }
        guard populateSharedDefaults() else {
            completion?(.failure(.sharedUserDefaultsNil))
            return
        }
        BloggingRemindersScheduler.handleRemindersMigration()

        isDataReadyToMigrate = true

        completion?(.success(()))
    }

    func importData(completion: ((Result<Void, DataMigrationError>) -> Void)? = nil) {
        guard let backupLocation, restoreDatabase(from: backupLocation) else {
            completion?(.failure(.databaseCopyError))
            return
        }

        /// Upon successful database restoration, the backup files in the App Group will be deleted.
        /// This means that the exported data is no longer complete when the user attempts another migration.
        ///
        /// After the database is copied, let's mark the data as no longer ready to migrate
        /// to prevent the user from entering a faulty migration.
        isDataReadyToMigrate = false

        guard populateFromSharedDefaults() else {
            completion?(.failure(.sharedUserDefaultsNil))
            return
        }

        let sharedDataIssueSolver = SharedDataIssueSolver()
        sharedDataIssueSolver.migrateAuthKey()
        sharedDataIssueSolver.migrateExtensionsData()
        BloggingRemindersScheduler.handleRemindersMigration()
        completion?(.success(()))
    }
}

// MARK: - Private Functions

private extension DataMigrator {
    /// `DefaultsWrapper` is used to single out a dictionary for the migration process.
    /// This way we can delete just the value for its key and leave the rest of shared defaults untouched.
    struct DefaultsWrapper {
        static let dictKey = "defaults_staging_dictionary"
        let defaultsDict: [String: Any]
    }

    func copyDatabase(to destination: URL) -> Bool {
        do {
            try coreDataStack.createStoreCopy(to: destination)
        } catch {
            DDLogError("Error copying database: \(error)")
            return false
        }
        return true
    }

    func restoreDatabase(from source: URL) -> Bool {
        do {
            try coreDataStack.restoreStoreCopy(from: source)
        } catch {
            DDLogError("Error restoring database: \(error)")
            return false
        }
        return true
    }

    func populateSharedDefaults() -> Bool {
        guard let sharedDefaults = sharedDefaults else {
            return false
        }

        let data = localDefaults.dictionaryRepresentation()
        var temporaryDictionary: [String: Any] = [:]
        for (key, value) in data {
            temporaryDictionary[key] = value
        }
        sharedDefaults.set(temporaryDictionary, forKey: DefaultsWrapper.dictKey)
        return true
    }

    func populateFromSharedDefaults() -> Bool {
        guard let sharedDefaults = sharedDefaults,
              let temporaryDictionary = sharedDefaults.dictionary(forKey: DefaultsWrapper.dictKey) else {
            return false
        }

        for (key, value) in temporaryDictionary {
            localDefaults.set(value, forKey: key)
        }
        sharedDefaults.removeObject(forKey: DefaultsWrapper.dictKey)
        return true
    }
}

private extension String {
    static let dataReadyToMigrateKey = "wp_data_migration_ready"
}
