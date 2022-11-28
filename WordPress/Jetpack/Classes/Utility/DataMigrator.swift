protocol ContentDataMigrating {
    func exportData(completion: ((Result<Void, DataMigrationError>) -> Void)?)
    func importData(completion: ((Result<Void, DataMigrationError>) -> Void)?)
}

enum DataMigrationError: Error {
    case databaseCopyError
    case sharedUserDefaultsNil
}

final class DataMigrator {

    /// `DefaultsWrapper` is used to single out a dictionary for the migration process.
    /// This way we can delete just the value for its key and leave the rest of shared defaults untouched.
    private struct DefaultsWrapper {
        static let dictKey = "defaults_staging_dictionary"
        let defaultsDict: [String: Any]
    }

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
        completion?(.success(()))
    }

    func importData(completion: ((Result<Void, DataMigrationError>) -> Void)? = nil) {
        guard let backupLocation, restoreDatabase(from: backupLocation) else {
            completion?(.failure(.databaseCopyError))
            return
        }
        guard populateFromSharedDefaults() else {
            completion?(.failure(.sharedUserDefaultsNil))
            return
        }

        BloggingRemindersScheduler.handleRemindersMigration()
        completion?(.success(()))
    }
}

// MARK: - Private Functions

private extension DataMigrator {

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
