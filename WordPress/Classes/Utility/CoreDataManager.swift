/// Handles the core data stack for the whole app
class CoreDataManager: CoreDataStack {

    static let shared = CoreDataManager()

    /// Only for tests, do not use this method directly
    init() {
        observe()
    }

    private lazy var writerContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.persistentStoreCoordinator
        return context
    }()

    lazy var mainContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = self.writerContext
        return context
    }()

    var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        persistentContainer.persistentStoreCoordinator
    }

    var managedObjectModel: NSManagedObjectModel {
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Could not load model")
        }
        return mom
    }

    // Error handling
    private lazy var sentryStartupError: SentryStartupEvent = {
        return SentryStartupEvent()
    }()

    lazy var persistentContainer: NSPersistentContainer = {
        migrateDataModelIfNecessary()

        let container = NSPersistentContainer(name: Constants.name, managedObjectModel: managedObjectModel)
        container.persistentStoreDescriptions = [storeDescription]

        container.loadPersistentStores { [weak self] (storeDescription, error) in
            guard let `self` = self, let error = error else {
                return
            }
            DDLogError("⛔️ [CoreDataManager] loadPersistentStore failed. Attempting to recover... \(error)")
            self.sentryStartupError.add(error: error)

            /// Backup the old Store
            ///
            do {
                try CoreDataIterativeMigrator.backupDatabase(at: self.storeURL)
            } catch {
                self.sentryStartupError.add(error: error)
                self.sentryStartupError.send(title: "Can't initialize Core Data stack")
                fatalError("☠️ [CoreDataManager] Cannot backup Store: \(error)")
            }

            /// Retry!
            ///
            container.loadPersistentStores { [weak self] (storeDescription, error) in
                guard let error = error as NSError? else {
                    return
                }

                self?.sentryStartupError.add(error: error)
                self?.sentryStartupError.send(title: "Can't initialize Core Data stack")
                fatalError("☠️ [CoreDataManager] Recovery Failed! \(error) [\(error.userInfo)]")
            }
        }
        return container
    }()

    var storeURL: URL {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Missing Documents Folder")
        }
        return url.appendingPathComponent(Constants.name + ".sqlite")
    }

    private func childContext(with concurrencyType: NSManagedObjectContextConcurrencyType) -> NSManagedObjectContext {
        let childManagedObjectContext = NSManagedObjectContext(concurrencyType: concurrencyType)
        childManagedObjectContext.parent = self.mainContext
        childManagedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return childManagedObjectContext
    }

    func newDerivedContext() -> NSManagedObjectContext {
        childContext(with: .privateQueueConcurrencyType)
    }

    func newMainContextChildContext() -> NSManagedObjectContext {
        childContext(with: .mainQueueConcurrencyType)
    }

    func saveContextAndWait(_ context: NSManagedObjectContext) {
        save(context, wait: true)
    }

    func save(_ context: NSManagedObjectContext) {
        save(context, wait: false)
    }

    func save(_ context: NSManagedObjectContext, withCompletionBlock completionBlock: @escaping () -> Void) {
        save(context, wait: false, completion: completionBlock)
    }

    private func save(_ context: NSManagedObjectContext, wait: Bool, completion: (() -> Void)? = nil) {

        guard context.parent != self.mainContext else {
            saveDerivedContext(context, wait: wait, completion: completion)
            return
        }

        guard wait else {
            context.perform {
                self.performSave(context: context, completion: completion)
            }
            return
        }
        context.performAndWait {
            self.performSave(context: context, completion: completion)
        }
    }

    private func performSave(context: NSManagedObjectContext, completion: (() -> Void)? = nil) {

        guard context.hasChanges else {
            DispatchQueue.main.async {
                completion?()
            }
            return
        }

        let objects = Array(context.insertedObjects)
        do {
            try context.obtainPermanentIDs(for: objects)

            try context.save()
            DispatchQueue.main.async {
                completion?()
            }

        } catch {
            DDLogError("Error obtaining permanent object IDs for \(objects), \(error)")
            handleSaveError(error as NSError, in: context)
            DispatchQueue.main.async {
                completion?()
            }
        }
    }

    private func saveDerivedContext(_ context: NSManagedObjectContext, wait: Bool, completion: (() -> Void)? = nil) {
        guard wait else {
            context.perform {
                self.performSave(context: context)
                self.save(self.mainContext, wait: wait, completion: completion)
            }
            return
        }
        context.performAndWait {
            self.performSave(context: context)
            self.save(self.mainContext, wait: wait, completion: completion)
        }
    }

    func obtainPermanentID(for managedObject: NSManagedObject) -> Bool {
        guard !managedObject.objectID.isTemporaryID else {
            return false
        }
        do {
            guard let context = managedObject.managedObjectContext else {
                return false
            }
            try context.obtainPermanentIDs(for: [managedObject])
            return true
        } catch {
            DDLogError("Error obtaining permanent object ID for \(managedObject), \(error)")
            return false
        }
    }

    func mergeChanges(_ context: NSManagedObjectContext, fromContextDidSave notification: Foundation.Notification) {
        context.perform {
            guard let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? [NSManagedObject] else {
                return
            }

            updatedObjects.forEach {
                do {
                    let object = try context.existingObject(with: $0.objectID)
                    if object.isFault {
                        object.willAccessValue(forKey: nil)
                    }
                } catch {
                    DDLogError("Error merging object \($0), \(error)")
                }
            }
            context.mergeChanges(fromContextDidSave: notification)
        }
    }
}


// MARK: - Migration
extension CoreDataManager {

    private func migrateDataModelIfNecessary() {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            DDLogInfo("No store exists at URL \(storeURL).  Skipping migration.")
            return
        }

        guard let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL, options: nil) else {
            return
        }

        guard managedObjectModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) == false else {
            // Configuration is compatible, no migration necessary.
            return
        }

        DDLogWarn("⚠️ [CoreDataManager] Migration required for persistent store")

        // Extract model names
        let versionPath = modelURL.appendingPathComponent(Constants.versionInfoPlist).path
        guard let versionInfo = NSDictionary(contentsOfFile: versionPath),
            let modelNames = versionInfo[Constants.versionHashesKey] as? NSDictionary,
            let allKeys = modelNames.allKeys as? [String] else {
                return
        }

        let sortedKeys = allKeys.sorted { (string1, string2) -> Bool in
            return string1.compare(string2, options: [.numeric], range: nil, locale: nil) == .orderedAscending
        }

        do {
            try CoreDataIterativeMigrator.iterativeMigrate(sourceStore: storeURL,
                                                           storeType: NSSQLiteStoreType,
                                                           to: managedObjectModel,
                                                           using: sortedKeys)
        } catch {
            DDLogError("☠️ [CoreDataManager] Unable to migrate store with error: \(error)")
            sentryStartupError.add(error: error)
        }
    }
}


// MARK: - Notifications
extension CoreDataManager {

    private func observe() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSManagedObjectContextDidSave,
                                               object: self.mainContext,
                                               queue: nil) { [weak self] notification in
            guard let self = self else {
                return
            }
            self.writerContext.perform {
                self.performSave(context: self.writerContext)
            }
        }
    }
}


// MARK: - Private properties
extension CoreDataManager {

    private var storeDescription: NSPersistentStoreDescription {
        let description = NSPersistentStoreDescription(url: storeURL)
        description.shouldAddStoreAsynchronously = false
        description.shouldMigrateStoreAutomatically = false
        return description
    }

    private var modelURL: URL {
        guard let url = Bundle.main.url(forResource: Constants.name, withExtension: "momd") else {
            fatalError("Missing Model Resource")
        }
        return url
    }
}

// MARK: - Constants
extension CoreDataManager {

    private enum Constants {
        static let name = "WordPress"
        static let versionInfoPlist = "VersionInfo.plist"
        static let versionHashesKey = "NSManagedObjectModel_VersionHashes"

    }
}


// MARK: - Error handling
private extension CoreDataManager {

    func handleSaveError(_ error: NSError, in context: NSManagedObjectContext) {
        let isMainContext = context == mainContext
        let exceptionName: NSExceptionName = isMainContext ? .coreDataSaveMainException : .coreDataSaveDerivedException
        let reason = reasonForError(error)
        DDLogError("Unresolved Core Data save error: \(error)")
        DDLogError("Generating exception with reason:\n\(reason)")
        // Sentry is choking when userInfo is too big and not sending crash reports
        // For debugging we can still see the userInfo details since we're logging the full error above
        let exception = NSException(name: exceptionName, reason: reason, userInfo: nil)
        exception.raise()
    }

    func reasonForError(_ error: NSError) -> String {
        if error.code == NSValidationMultipleErrorsError {
            guard let errors = error.userInfo[NSDetailedErrorsKey] as? [NSError] else {
                return "Multiple errors without details"
            }
            return reasonForMultipleErrors(errors)
        } else {
            return reasonForIndividualError(error)
        }
    }

    func reasonForMultipleErrors(_ errors: [NSError]) -> String {
        return "Multiple errors:\n" + errors.enumerated().map({ (index, error) in
            return "  \(index + 1): " + reasonForIndividualError(error)
        }).joined(separator: "\n")
    }

    func reasonForIndividualError(_ error: NSError) -> String {
        let entity = entityName(for: error) ?? "null"
        let property = propertyName(for: error) ?? "null"
        let message = coreDataKnownErrorCodes[error.code] ?? "Unknown error (domain: \(error.domain) code: \(error.code), \(error.localizedDescription)"
        return "\(message) on \(entity).\(property)"
    }

    func entityName(for error: NSError) -> String? {
        guard let managedObject = error.userInfo[NSValidationObjectErrorKey] as? NSManagedObject else {
            return nil
        }
        return managedObject.entity.name
    }

    func propertyName(for error: NSError) -> String? {
        return error.userInfo[NSValidationKeyErrorKey] as? String
    }

}


// Imported from CoreData.CoreDataErrors
private let coreDataKnownErrorCodes = [
    NSCoreDataError: "General Core Data error",
    NSEntityMigrationPolicyError: "Migration failed during processing of the entity migration policy ",
    NSExternalRecordImportError: "General error encountered while importing external records",
    NSInferredMappingModelError: "Inferred mapping model creation error",
    NSManagedObjectConstraintMergeError: "Merge policy failed - unable to complete merging due to multiple conflicting constraint violations",
    NSManagedObjectConstraintValidationError: "One or more uniqueness constraints were violated",
    NSManagedObjectContextLockingError: "Can't acquire a lock in a managed object context",
    NSManagedObjectExternalRelationshipError: "An object being saved has a relationship containing an object from another store",
    NSManagedObjectMergeError: "Merge policy failed - unable to complete merging",
    NSManagedObjectReferentialIntegrityError: "Attempt to fire a fault pointing to an object that does not exist (we can see the store, we can't see the object)",
    NSManagedObjectValidationError: "Generic validation error",
    NSMigrationCancelledError: "Migration failed due to manual cancellation",
    NSMigrationConstraintViolationError: "Migration failed due to a violated uniqueness constraint",
    NSMigrationError: "General migration error",
    NSMigrationManagerDestinationStoreError: "Migration failed due to a problem with the destination data store",
    NSMigrationManagerSourceStoreError: "Migration failed due to a problem with the source data store",
    NSMigrationMissingMappingModelError: "Migration failed due to missing mapping model",
    NSMigrationMissingSourceModelError: "Migration failed due to missing source data model",
    NSPersistentHistoryTokenExpiredError: "The history token passed to NSPersistentChangeRequest was invalid",
    NSPersistentStoreCoordinatorLockingError: "Can't acquire a lock in a persistent store coordinator",
    NSPersistentStoreIncompatibleSchemaError: "Store returned an error for save operation (database level errors ie missing table, no permissions)",
    NSPersistentStoreIncompatibleVersionHashError: "Entity version hashes incompatible with data model",
    NSPersistentStoreIncompleteSaveError: "One or more of the stores returned an error during save (stores/objects that failed will be in userInfo)",
    NSPersistentStoreInvalidTypeError: "Unknown persistent store type/format/version",
    NSPersistentStoreOpenError: "An error occurred while attempting to open the persistent store",
    NSPersistentStoreOperationError: "The persistent store operation failed",
    NSPersistentStoreSaveConflictsError: "An unresolved merge conflict was encountered during a save.  userInfo has NSPersistentStoreSaveConflictsErrorKey",
    NSPersistentStoreSaveError: "Unclassified save error - something we depend on returned an error",
    NSPersistentStoreTimeoutError: "Failed to connect to the persistent store within the specified timeout (see NSPersistentStoreTimeoutOption)",
    NSPersistentStoreTypeMismatchError: "Returned by persistent store coordinator if a store is accessed that does not match the specified type",
    NSPersistentStoreUnsupportedRequestTypeError: "An NSPersistentStore subclass was passed an NSPersistentStoreRequest that it did not understand",
    NSSQLiteError: "General SQLite error ",
    NSValidationDateTooLateError: "Some date value is too late",
    NSValidationDateTooSoonError: "Some date value is too soon",
    NSValidationInvalidDateError: "Some date value fails to match date pattern",
    NSValidationInvalidURIError: "Some URI value cannot be represented as a string",
    NSValidationMissingMandatoryPropertyError: "Non-optional property with a nil value",
    NSValidationMultipleErrorsError: "Generic message for error containing multiple validation errors",
    NSValidationNumberTooLargeError: "Some numerical value is too large",
    NSValidationNumberTooSmallError: "Some numerical value is too small",
    NSValidationRelationshipDeniedDeleteError: "Some relationship with NSDeleteRuleDeny is non-empty",
    NSValidationRelationshipExceedsMaximumCountError: "Bounded, to-many relationship with too many destination objects",
    NSValidationRelationshipLacksMinimumCountError: "To-many relationship with too few destination objects",
    NSValidationStringPatternMatchingError: "Some string value fails to match some pattern",
    NSValidationStringTooLongError: "Some string value is too long",
    NSValidationStringTooShortError: "Some string value is too short",
]

private extension NSExceptionName {
    static let coreDataSaveMainException = NSExceptionName("Unresolved Core Data save error (Main Context)")
    static let coreDataSaveDerivedException = NSExceptionName("Unresolved Core Data save error (Derived Context)")
}
