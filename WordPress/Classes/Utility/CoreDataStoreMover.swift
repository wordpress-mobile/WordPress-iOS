import Foundation

class CoreDataStoreMover {
    private let modelLocation: URL

    enum MoveError: Error {
        case destinationFileExists(url: URL)
        case sourceFileDoesNotExist(url: URL)
        case couldNotLoadMetadataForStore(url: URL, error: Error)
        case couldNotLoadModel(url: URL)
        case couldNotLoadSourceStore(url: URL, error: Error)
        case sourceStoreLoadedButNotAvailable(url: URL)
        case couldNotBackupDatabase(error: Error)
        case couldNotMigrateStore(error: Error)
        case couldNotRemoveOldStore(error: Error)
    }

    init(modelLocation: URL) {
        self.modelLocation = modelLocation
    }

    /// Moves the Store from `sourceLocation` to `targetLocation`.
    ///
    /// - Returns: on success this method returns a boolean holding `true` if the store was moved, or `false` if it wasn't
    ///         necessary to move any files.  An error is returned if there was a problem.
    ///
    func moveStore(from sourceLocation: URL, to targetLocation: URL) -> Result<URL, MoveError> {
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
            metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: sourceLocation, options: nil)
        } catch {
            return .failure(.couldNotLoadMetadataForStore(url: sourceLocation, error: error))
        }

        guard let model = NSManagedObjectModel.mergedModel(from: nil, forStoreMetadata: metadata) else {
            return .failure(.couldNotLoadModel(url: modelLocation))
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

        // I don't love what I did here.  Normally I'd prefer to avoid writing code in a way that the
        // unit tests behave differently... but since our unit tests can run any code from the App, I believe
        // we need to make sure that the unit tests don't delete our stores when running.  Please feel free
        // to suggest improvements to this approach.
        if !CommandLine.arguments.contains("isTesting") {
            do {
                try coordinator.destroyPersistentStore(at: sourceLocation, ofType: NSSQLiteStoreType, options: nil)
            } catch {
                return .failure(.couldNotRemoveOldStore(error: error))
            }
        }

        return .success(targetLocation)
    }
}
