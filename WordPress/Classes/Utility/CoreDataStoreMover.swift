import Foundation

class CoreDataStoreMover {
    enum MoveError: Error {
        case destinationFileExists(url: URL)
        case sourceFileDoesNotExist(url: URL)
        case couldNotLoadMetadataForStore(url: URL, error: Error)
        case couldNotLoadModel
        case couldNotLoadSourceStore(url: URL, error: Error)
        case sourceStoreLoadedButNotAvailable(url: URL)
        case couldNotBackupDatabase(error: Error)
        case couldNotMigrateStore(error: Error)
    }

    /// Moves the Store from `sourceLocation` to `targetLocation`.
    ///
    /// - Returns: on success this method returns the URL where the store was moved to.  On failure, returns a `MoveError`.
    ///
    func moveStore(ofType type: String, from sourceLocation: URL, to targetLocation: URL) -> Result<URL, MoveError> {
        // It's important that this is checked first, since the absence of the source file could
        // imply that the DB has not been created yet (first launch).  So we want the caller
        // to be able to handle this scenario.
        guard FileManager.default.fileExists(atPath: sourceLocation.path) else {
            return .failure(.sourceFileDoesNotExist(url: sourceLocation))
        }

        guard !FileManager.default.fileExists(atPath: targetLocation.path) else {
            return .failure(.destinationFileExists(url: targetLocation))
        }

        let metadata: [String: Any]

        do {
            metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: type, at: sourceLocation, options: nil)
        } catch {
            return .failure(.couldNotLoadMetadataForStore(url: sourceLocation, error: error))
        }

        guard let model = NSManagedObjectModel.mergedModel(from: nil, forStoreMetadata: metadata) else {
            return .failure(.couldNotLoadModel)
        }

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)

        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: sourceLocation, options: nil)
        } catch {
            return .failure(.couldNotLoadSourceStore(url: sourceLocation, error: error))
        }

        guard let store = coordinator.persistentStore(for: sourceLocation) else {
            return .failure(.sourceStoreLoadedButNotAvailable(url: sourceLocation))
        }

        do {
            try coordinator.migratePersistentStore(store, to: targetLocation, options: [NSReadOnlyPersistentStoreOption: true], withType: NSSQLiteStoreType)
        } catch {
            return .failure(.couldNotMigrateStore(error: error))
        }

        return .success(targetLocation)
    }
}
