import Foundation

class CoreDataStoreMover {
    private let modelLocation: URL
    
    enum MoveError: Error {
        case destinationFileExists(url: URL)
        case sourceFileDoesNotExist(url: URL)
        case couldNotLoadModel(url: URL)
        case couldNotLoadSourceStore(url: URL)
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
        guard !FileManager.default.fileExists(atPath: targetLocation.absoluteString) else {
            return .failure(.destinationFileExists(url: targetLocation))
        }
        
        guard FileManager.default.fileExists(atPath: sourceLocation.absoluteString) else {
            return .failure(.sourceFileDoesNotExist(url: sourceLocation))
        }

        guard let model = NSManagedObjectModel(contentsOf: modelLocation) else {
            return .failure(.couldNotLoadModel(url: modelLocation))
        }

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        guard let oldStore = coordinator.persistentStore(for: sourceLocation) else {
            return .failure(.couldNotLoadSourceStore(url: sourceLocation))
        }
        
        do {
            try CoreDataIterativeMigrator.backupDatabase(at: sourceLocation)
        } catch {
            return .failure(.couldNotBackupDatabase(error: error))
        }
        
        do {
            try coordinator.migratePersistentStore(oldStore, to: sourceLocation, options: nil, withType: NSSQLiteStoreType)
        } catch {
            return .failure(.couldNotMigrateStore(error: error))
        }
        
        // I don't love what I did here.  Normally I'd prefer to avoid writing code in a way that the
        // unit tests behave differently... but since our unit tests can run any code from the App, I believe
        // we need to make sure that the unit tests don't delete our stores when running.  Please feel free
        // to suggest improvements to this approach.
        if !CommandLine.arguments.contains("isTesting") {
            do {
                try coordinator.remove(oldStore)
            } catch {
                return .failure(.couldNotRemoveOldStore(error: error))
            }
        }
        
        return .success(targetLocation)
    }
}
