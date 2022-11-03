import Foundation
import CocoaLumberjack
import CoreData

// MARK: - NSManagedObject Default entityName Helper
//
extension NSManagedObject {

    /// Returns the Entity Name, if available, as specified in the NSEntityDescription. Otherwise, will return
    /// the subclass name.
    ///
    /// Note: entity().name returns nil as per iOS 10, in Unit Testing Targets. Awesome.
    ///
    @objc class func entityName() -> String {
        return entity().name ?? classNameWithoutNamespaces()
    }

    /// Returns a NSFetchRequest instance with it's *Entity Name* always set.
    ///
    /// Note: entity().name returns nil as per iOS 10, in Unit Testing Targets. Awesome.
    ///
    @objc class func safeFetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        guard entity().name == nil else {
            return fetchRequest()
        }

        return NSFetchRequest(entityName: entityName())
    }
}


// MARK: - NSManagedObjectContext Helpers!
//
extension NSManagedObjectContext {

    /// Returns all of the entities that match with a given predicate.
    ///
    /// - Parameter predicate: Defines the conditions that any given object should meet. Optional.
    ///
    func allObjects<T: NSManagedObject>(ofType type: T.Type, matching predicate: NSPredicate? = nil, sortedBy descriptors: [NSSortDescriptor]? = nil) -> [T] {
        let request = T.safeFetchRequest()
        request.predicate = predicate
        request.sortDescriptors = descriptors

        return loadObjects(ofType: type, with: request)
    }


    /// Returns the number of entities found that match with a given predicate.
    ///
    /// - Parameter predicate: Defines the conditions that any given object should meet. Optional.
    ///
    func countObjects<T: NSManagedObject>(ofType type: T.Type, matching predicate: NSPredicate? = nil) -> Int {
        let request = T.safeFetchRequest()
        request.includesSubentities = false
        request.predicate = predicate
        request.resultType = .countResultType

        var result = 0

        do {
            result = try count(for: request)
        } catch {
            DDLogError("Error counting objects [\(String(describing: T.entityName))]: \(error)")
            assertionFailure()
        }

        return result
    }

    /// Deletes the specified Object Instance
    ///
    func deleteObject<T: NSManagedObject>(_ object: T) {
        delete(object)
    }

    /// Deletes all of the NSMO instances associated to the current kind
    ///
    func deleteAllObjects<T: NSManagedObject>(ofType type: T.Type) {
        let request = T.safeFetchRequest()
        request.includesPropertyValues = false
        request.includesSubentities = false

        for object in loadObjects(ofType: type, with: request) {
            delete(object)
        }
    }

    /// Retrieves the first entity that matches with a given predicate
    ///
    /// - Parameter predicate: Defines the conditions that any given object should meet.
    ///
    func firstObject<T: NSManagedObject>(ofType type: T.Type, matching predicate: NSPredicate) -> T? {
        let request = T.safeFetchRequest()
        request.predicate = predicate
        request.fetchLimit = 1

        return loadObjects(ofType: type, with: request).first
    }

    /// Inserts a new Entity. For performance reasons, this helper *DOES NOT* persists the context.
    ///
    func insertNewObject<T: NSManagedObject>(ofType type: T.Type) -> T {
        return NSEntityDescription.insertNewObject(forEntityName: T.entityName(), into: self) as! T
    }

    /// Loads a single NSManagedObject instance, given its ObjectID, if available.
    ///
    /// - Parameter objectID: Unique Identifier of the entity to retrieve, if available.
    ///
    func loadObject<T: NSManagedObject>(ofType type: T.Type, with objectID: NSManagedObjectID) -> T? {
        var result: T?

        do {
            result = try existingObject(with: objectID) as? T
        } catch {
            DDLogError("Error loading Object [\(String(describing: T.entityName))]")
        }

        return result
    }

    /// Returns an entity already stored or it creates a new one of a specific type
    ///
    /// - Parameters:
    ///   - type: Type of the Entity
    ///   - predicate: A predicate used to fetch a stored Entity
    /// - Returns: A valid Entity
    func entity<Entity: NSManagedObject>(of type: Entity.Type, with predicate: NSPredicate) -> Entity {
        guard let entity = firstObject(ofType: type, matching: predicate) else {
            return insertNewObject(ofType: type)
        }
        return entity
    }

    /// Loads the collection of entities that match with a given Fetch Request
    ///
    private func loadObjects<T: NSManagedObject>(ofType type: T.Type, with request: NSFetchRequest<NSFetchRequestResult>) -> [T] {
        var objects: [T]?

        do {
            objects = try fetch(request) as? [T]
        } catch {
            DDLogError("Error loading Objects [\(String(describing: T.entityName))")
            assertionFailure()
        }

        return objects ?? []
    }
}

extension NSPersistentStoreCoordinator {

    /// Retrieves an NSManagedObjectID in a safe way, so even if the URL is not in a valid CoreData format no exceptions will be throw.
    ///
    /// - Parameter uri: the core-data object uri representation
    /// - Returns: a NSManagedObjectID if the uri is valid or nil if not.
    ///
    public func safeManagedObjectID(forURIRepresentation uri: URL) -> NSManagedObjectID? {
        guard let scheme = uri.scheme, scheme == "x-coredata" else {
            return nil
        }
        var result: NSManagedObjectID? = nil
        do {
            try WPException.objcTry {
                result = self.managedObjectID(forURIRepresentation: uri)
            }
        } catch {
            return nil
        }
        return result
    }
}


// MARK: - ContextManager Helpers
extension ContextManager {
    static var overrideInstance: CoreDataStack?

    @objc class func sharedInstance() -> CoreDataStack {
        if let overrideInstance = overrideInstance {
            return overrideInstance
        }

        return ContextManager.internalSharedInstance()
    }

    static var shared: CoreDataStack {
        return sharedInstance()
    }

    /// Tests purpose only
    @objc public class func overrideSharedInstance(_ instance: CoreDataStack?) {
        ContextManager.overrideInstance = instance
    }

    enum ContextManagerError: Error {
        case missingCoordinatorOrStore
        case missingDatabase
    }
}

extension CoreDataStack {
    func performAndSave<T>(_ block: @escaping (NSManagedObjectContext) throws -> T, completion: ((Result<T, Error>) -> Void)?) {
        let context = newDerivedContext()
        context.perform {
            let result = Result(catching: { try block(context) })
            if case .success = result {
                self.saveContextAndWait(context)
            }
            completion?(result)
        }
    }

    func performAndSave<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            performAndSave(block) {
                continuation.resume(with: $0)
            }
        }
    }

    /// Creates a copy of the current open store and saves it to the specified destination
    /// - Parameter backupLocation: Location to save the store copy to
    func createStoreCopy(to backupLocation: URL) throws {
        guard let storeCoordinator = mainContext.persistentStoreCoordinator,
              let store = storeCoordinator.persistentStores.first else {
            throw ContextManager.ContextManagerError.missingCoordinatorOrStore
        }

        let model = storeCoordinator.managedObjectModel
        let storeCoordinatorCopy = NSPersistentStoreCoordinator(managedObjectModel: model)
        var storeOptions = store.options
        storeOptions?[NSReadOnlyPersistentStoreOption] = true
        let storeCopy = try storeCoordinatorCopy.addPersistentStore(ofType: store.type,
                                                                    configurationName: store.configurationName,
                                                                    at: store.url,
                                                                    options: storeOptions)
        try storeCoordinatorCopy.migratePersistentStore(storeCopy,
                                                        to: backupLocation,
                                                        withType: storeCopy.type)
    }

    /// Replaces the current active store with the database at the specified location.
    ///
    /// The following steps are performed:
    ///   - Remove the current store from the store coordinator.
    ///   - Create a backup of the current database.
    ///   - Copy the source database over the current database. If this fails, restore the backup files.
    ///   - Attempt to re-add the store with the new database or original database if the copy failed. If adding the new store fails, restore the backup and try to re-add the old store.
    ///   - Finally, remove all the backup files and source database if everything was successful.
    ///
    /// **Warning: This is destructive towards the active database. It will be overwritten on success.**
    /// - Parameter databaseLocation: Database to overwrite the current one with
    func restoreStoreCopy(from databaseLocation: URL) throws {
        guard let storeCoordinator = mainContext.persistentStoreCoordinator,
              let store = storeCoordinator.persistentStores.first else {
            throw ContextManager.ContextManagerError.missingCoordinatorOrStore
        }

        let (databaseLocation, shmLocation, walLocation) = databaseFiles(for: databaseLocation)

        guard let currentDatabaseLocation = store.url,
              FileManager.default.fileExists(atPath: databaseLocation.path),
              FileManager.default.fileExists(atPath: shmLocation.path),
              FileManager.default.fileExists(atPath: walLocation.path)  else {
            throw ContextManager.ContextManagerError.missingDatabase
        }

        try storeCoordinator.remove(store)
        let databaseReplaced = replaceDatabase(from: databaseLocation, to: currentDatabaseLocation)

        do {
            try storeCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                    configurationName: nil,
                                                    at: currentDatabaseLocation)

            if databaseReplaced {
                // The database was replaced successfully and the store added with no errors so we
                // can remove the source database & backup files
                let (databaseBackup, shmBackup, walBackup) = backupFiles(for: currentDatabaseLocation)
                try? FileManager.default.removeItem(at: databaseLocation)
                try? FileManager.default.removeItem(at: shmLocation)
                try? FileManager.default.removeItem(at: walLocation)
                try? FileManager.default.removeItem(at: databaseBackup)
                try? FileManager.default.removeItem(at: shmBackup)
                try? FileManager.default.removeItem(at: walBackup)
            }
        } catch {
            // Re-adding the store failed for some reason, attempt to restore the backup
            // and use that store instead. We re-throw the error so that the caller can
            // attempt to handle the error
            restoreDatabaseBackup(at: currentDatabaseLocation)
            _ = try? storeCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                         configurationName: nil,
                                                         at: currentDatabaseLocation)
            throw error
        }
    }

    private func databaseFiles(for database: URL) -> (database: URL, shm: URL, wal: URL) {
        let shmFile = URL(string: database.absoluteString.appending("-shm"))!
        let walFile = URL(string: database.absoluteString.appending("-wal"))!
        return (database, shmFile, walFile)
    }

    private func backupFiles(for database: URL) -> (database: URL, shm: URL, wal: URL) {
        let (database, shmFile, walFile) = databaseFiles(for: database)
        let databaseBackup = database.appendingPathExtension("backup")
        let shmBackup = shmFile.appendingPathExtension("backup")
        let walBackup = walFile.appendingPathExtension("backup")
        return (databaseBackup, shmBackup, walBackup)
    }

    private func replaceDatabase(from source: URL, to destination: URL) -> Bool {
        let (source, sourceShm, sourceWal) = databaseFiles(for: source)
        let (destination, destinationShm, destinationWal) = databaseFiles(for: destination)
        let (databaseBackup, shmBackup, walBackup) = backupFiles(for: destination)

        do {
            try FileManager.default.copyItem(at: destination, to: databaseBackup)
            try FileManager.default.copyItem(at: destinationShm, to: shmBackup)
            try FileManager.default.copyItem(at: destinationWal, to: walBackup)
            try FileManager.default.removeItem(at: destination)
            try FileManager.default.removeItem(at: destinationShm)
            try FileManager.default.removeItem(at: destinationWal)
            try FileManager.default.copyItem(at: source, to: destination)
            try FileManager.default.copyItem(at: sourceShm, to: destinationShm)
            try FileManager.default.copyItem(at: sourceWal, to: destinationWal)
            return true
        } catch {
            // Attempt to restore backup files. Some might not exist depending on where the process failed
            DDLogError("Error when replacing database: \(error)")
            restoreDatabaseBackup(at: destination)
            return false
        }
    }

    private func restoreDatabaseBackup(at location: URL) {
        let (location, locationShm, locationWal) = databaseFiles(for: location)
        let (databaseBackup, shmBackup, walBackup) = backupFiles(for: location)
        _ = try? FileManager.default.replaceItemAt(location, withItemAt: databaseBackup)
        _ = try? FileManager.default.replaceItemAt(locationShm, withItemAt: shmBackup)
        _ = try? FileManager.default.replaceItemAt(locationWal, withItemAt: walBackup)
    }
}
