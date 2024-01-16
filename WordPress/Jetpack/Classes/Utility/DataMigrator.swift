import Foundation
import AutomatticTracks

protocol ContentDataMigrating {
    /// Exports user content data to a shared location that's accessible by the Jetpack app.
    ///
    /// - Parameter completion: Closure called after the export process completes.
    func exportData(completion: ((Result<Void, DataMigrationError>) -> Void)?)

    /// Imports user's WordPress content data from the shared location.
    ///
    /// - Parameter completion: Closure called after the export process completes.
    func importData(completion: ((Result<Void, DataMigrationError>) -> Void)?)

    /// Deletes any exported user content at the shared location if it exists.
    func deleteExportedData()
}

final class DataMigrator {
    private let coreDataStack: CoreDataStack
    private let backupLocation: URL?
    private let keychainUtils: KeychainUtils
    private let localDefaults: UserPersistentRepository
    private let sharedDefaults: UserPersistentRepository?
    private let crashLogger: CrashLogging

    init(coreDataStack: CoreDataStack = ContextManager.sharedInstance(),
         backupLocation: URL? = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WPAppGroupName)?.appendingPathComponent("WordPress.sqlite"),
         keychainUtils: KeychainUtils = KeychainUtils(),
         localDefaults: UserPersistentRepository = UserDefaults.standard,
         sharedDefaults: UserPersistentRepository? = UserDefaults(suiteName: WPAppGroupName),
         crashLogger: CrashLogging = .main) {
        self.coreDataStack = coreDataStack
        self.backupLocation = backupLocation
        self.keychainUtils = keychainUtils
        self.localDefaults = localDefaults
        self.sharedDefaults = sharedDefaults
        self.crashLogger = crashLogger
    }
}

// MARK: - Content Data Migrating

extension DataMigrator: ContentDataMigrating {

    func exportData(completion: ((Result<Void, DataMigrationError>) -> Void)? = nil) {
        do {
            try copyDatabase(to: backupLocation)
            try populateSharedDefaults()
        } catch {
            let error = DataMigrationError.databaseExportError(underlyingError: error)
            log(error: error)
            completion?(.failure(error))
            return
        }
        BloggingRemindersScheduler.handleRemindersMigration()

        isDataReadyToMigrate = true

        completion?(.success(()))
    }

    func importData(completion: ((Result<Void, DataMigrationError>) -> Void)? = nil) {
        guard isDataReadyToMigrate else {
            completion?(.failure(.dataNotReadyToImport))
            return
        }

        do {
            try restoreDatabase(from: backupLocation)

            /// Upon successful database restoration, the backup files in the App Group will be deleted.
            /// This means that the exported data is no longer complete when the user attempts another migration.
            isDataReadyToMigrate = false

            try populateFromSharedDefaults()
        } catch {
            let error = DataMigrationError.databaseImportError(underlyingError: error)
            log(error: error)
            completion?(.failure(error))
            return
        }

        let sharedDataIssueSolver = SharedDataIssueSolver()
        sharedDataIssueSolver.migrateAuthKey()
        sharedDataIssueSolver.migrateExtensionsData()
        BloggingRemindersScheduler.handleRemindersMigration()
        completion?(.success(()))
    }

    func deleteExportedData() {
        guard let backupLocation,
              let sharedDefaults else {
            return
        }

        // mark this as false regardless if any of the steps below fails.
        // this serves as the first stopgap that prevents the migration process on the Jetpack side.
        isDataReadyToMigrate = false

        // remove database backup
        try? coreDataStack.removeBackupData(from: backupLocation)

        // remove user defaults backup
        sharedDefaults.removeObject(forKey: DefaultsWrapper.dictKey)

        // remove blogging reminders backup
        BloggingRemindersScheduler.deleteBackupReminders()
    }
}

// MARK: - Private Functions

private extension DataMigrator {
    /// `DefaultsWrapper` is used to single out a dictionary for the migration process.
    /// This way we can delete just the value for its key and leave the rest of shared defaults untouched.
    struct DefaultsWrapper {
        static let dictKey = "defaults_staging_dictionary"
    }

    /// Convenience wrapper to check whether the export data is ready to be imported.
    /// The value is stored in the App Group space so it is accessible from both apps.
    var isDataReadyToMigrate: Bool {
        get {
            sharedDefaults?.bool(forKey: .dataReadyToMigrateKey) ?? false
        }
        set {
            sharedDefaults?.set(newValue, forKey: .dataReadyToMigrateKey)
        }
    }

    func copyDatabase(to destination: URL?) throws {
        guard let destination else {
            throw DataMigrationError.backupLocationNil
        }
        try coreDataStack.createStoreCopy(to: destination)
    }

    func restoreDatabase(from source: URL?) throws {
        guard let source else {
            throw DataMigrationError.backupLocationNil
        }
        try coreDataStack.restoreStoreCopy(from: source)
    }

    func populateSharedDefaults() throws {
        guard let sharedDefaults = sharedDefaults else {
            throw DataMigrationError.sharedUserDefaultsNil
        }
        let data = localDefaults.dictionaryRepresentation()
        var temporaryDictionary: [String: Any] = [:]
        for (key, value) in data {
            temporaryDictionary[key] = value
        }
        sharedDefaults.set(temporaryDictionary, forKey: DefaultsWrapper.dictKey)
    }

    func populateFromSharedDefaults() throws {
        guard let sharedDefaults = sharedDefaults,
              let temporaryDictionary = sharedDefaults.dictionary(forKey: DefaultsWrapper.dictKey) else {
            throw DataMigrationError.sharedUserDefaultsNil
        }
        for (key, value) in temporaryDictionary {
            localDefaults.set(value, forKey: key)
        }
        AppAppearance.overrideAppearance()
        sharedDefaults.removeObject(forKey: DefaultsWrapper.dictKey)
    }

    private func log(error: DataMigrationError, userInfo: [String: Any] = [:]) {
        let userInfo = userInfo.merging(self.userInfo(for: error)) { $1 }
        DDLogError(error)
        crashLogger.logError(error, userInfo: userInfo, level: .error)
    }

    private func userInfo(for error: DataMigrationError) -> [String: Any] {
        let defaultUserInfo = ["backup-location": backupLocation?.absoluteString as Any]
        return defaultUserInfo.merging(error.errorUserInfo) { $1 }
    }
}

private extension String {
    static let dataReadyToMigrateKey = "wp_data_migration_ready"
}
