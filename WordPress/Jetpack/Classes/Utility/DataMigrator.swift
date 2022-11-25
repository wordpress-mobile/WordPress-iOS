final class DataMigrator {

    private let coreDataStack: CoreDataStack
    private let backupLocation: URL?
    private let keychainUtils: KeychainUtils
    private let localDefaults: UserDefaults
    private let sharedDefaults: UserDefaults?

    init(coreDataStack: CoreDataStack = ContextManager.sharedInstance(),
         backupLocation: URL? = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.wordpress")?.appendingPathComponent("WordPress.sqlite"),
         keychainUtils: KeychainUtils = KeychainUtils(),
         localDefaults: UserDefaults = UserDefaults.standard,
         sharedDefaults: UserDefaults? = UserDefaults(suiteName: WPAppGroupName)) {
        self.coreDataStack = coreDataStack
        self.backupLocation = backupLocation
        self.keychainUtils = keychainUtils
        self.localDefaults = localDefaults
        self.sharedDefaults = sharedDefaults
    }

    enum DataMigratorError: Error {
        case localDraftsNotSynced
        case databaseCopyError
        case keychainError
        case sharedUserDefaultsNil
    }

    func exportData(completion: ((Result<Void, DataMigratorError>) -> Void)? = nil) {
        guard isLocalDraftsSynced() else {
            completion?(.failure(.localDraftsNotSynced))
            return
        }
        guard let backupLocation, copyDatabase(to: backupLocation) else {
            completion?(.failure(.databaseCopyError))
            return
        }
        guard copyUserDefaults(from: localDefaults, to: sharedDefaults) else {
            completion?(.failure(.sharedUserDefaultsNil))
            return
        }
        BloggingRemindersScheduler.handleRemindersMigration()
        completion?(.success(()))
    }

    func importData(completion: ((Result<Void, DataMigratorError>) -> Void)? = nil) {
        guard let backupLocation, restoreDatabase(from: backupLocation) else {
            completion?(.failure(.databaseCopyError))
            return
        }
        guard copyUserDefaults(from: sharedDefaults, to: localDefaults) else {
            completion?(.failure(.sharedUserDefaultsNil))
            return
        }
        BloggingRemindersScheduler.handleRemindersMigration()
        completion?(.success(()))
    }

}

// MARK: - Private Functions

private extension DataMigrator {

    func isLocalDraftsSynced() -> Bool {
        let fetchRequest = NSFetchRequest<Post>(entityName: String(describing: Post.self))
        fetchRequest.predicate = NSPredicate(format: "status = %@ && (remoteStatusNumber = %@ || remoteStatusNumber = %@ || remoteStatusNumber = %@ || remoteStatusNumber = %@)",
                                             BasePost.Status.draft.rawValue,
                                             NSNumber(value: AbstractPostRemoteStatus.pushing.rawValue),
                                             NSNumber(value: AbstractPostRemoteStatus.failed.rawValue),
                                             NSNumber(value: AbstractPostRemoteStatus.local.rawValue),
                                             NSNumber(value: AbstractPostRemoteStatus.pushingMedia.rawValue))
        guard let count = try? coreDataStack.mainContext.count(for: fetchRequest) else {
            return false
        }

        return count == 0
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

    func copyKeychain(from sourceAccessGroup: String?, to destinationAccessGroup: String?) -> Bool {
        do {
            try keychainUtils.copyKeychain(from: sourceAccessGroup, to: destinationAccessGroup)
        } catch {
            DDLogError("Error copying keychain: \(error)")
            return false
        }

        return true
    }

    func copyUserDefaults(from source: UserDefaults?, to destination: UserDefaults?) -> Bool {
        guard let source, let destination else {
            return false
        }
        let data = source.dictionaryRepresentation()
        for (key, value) in data {
            destination.set(value, forKey: key)
        }

        return true
    }
}
