import Foundation
import CoreData

/// CoreDataIterativeMigrator: Migrates through a series of models to allow for users to skip app versions without risk.
///
class CoreDataIterativeMigrator: NSObject {

    /// Migrates a store to a particular model using the list of models to do it iteratively, if required.
    ///
    /// - Parameters:
    ///     - sourceStore: URL of the store on disk.
    ///     - storeType: Type of store (usually NSSQLiteStoreType).
    ///     - to: The target/most current model the migrator should migrate to.
    ///     - using: List of models on disk, sorted in migration order, that should include the to: model.
    ///
    /// - Returns: True if the process succeeded and didn't run into any errors. False if there was any problem and the store was left untouched.
    ///
    /// - Throws: A whole bunch of crap is possible to be thrown between Core Data and FileManager.
    ///
    @objc static func iterativeMigrate(sourceStore: URL, storeType: String, to targetModel: NSManagedObjectModel, using modelNames: [String]) throws {
        // If the persistent store does not exist at the given URL,
        // assume that it hasn't yet been created and return success immediately.
        guard FileManager.default.fileExists(atPath: sourceStore.path) == true else {
            return
        }

        // Get the persistent store's metadata.  The metadata is used to
        // get information about the store's managed object model.
        guard let sourceMetadata = try metadataForPersistentStore(storeType: storeType, at: sourceStore) else {
            throw MigrationError.migrationFailed
        }

        // Check whether the final model is already compatible with the store.
        // If it is, no migration is necessary.
        guard targetModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: sourceMetadata) == false else {
            return
        }

        // Find the current model used by the store.
        guard let sourceModel = try model(for: sourceMetadata) else {
            return
        }

        // Get NSManagedObjectModels for each of the model names given.
        let objectModels = try models(for: modelNames)

        // Build an inclusive list of models between the source and final models.
        var modelsToMigrate = [NSManagedObjectModel]()
        var firstFound = false, lastFound = false, reverse = false

        for model in objectModels {
            if model.isEqual(sourceModel) || model.isEqual(targetModel) {
                if firstFound {
                    lastFound = true
                    // In case a reverse migration is being performed (descending through the
                    // ordered array of models), check whether the source model is found
                    // after the final model.
                    reverse = model.isEqual(sourceModel)
                } else {
                    firstFound = true
                }
            }

            if firstFound {
                modelsToMigrate.append(model)
            }

            if lastFound {
                break
            }
        }

        // Ensure that the source model is at the start of the list.
        if reverse {
            modelsToMigrate = modelsToMigrate.reversed()
        }

        // Migrate between each model. Count - 2 because of zero-based index and we want
        // to stop at the last pair (you can't migrate the last model to nothingness).
        let upperBound = modelsToMigrate.count - 2
        for index in 0...upperBound {
            let modelFrom = modelsToMigrate[index]
            let modelTo = modelsToMigrate[index + 1]

            // Check whether a custom mapping model exists.
            guard let migrateWithModel = NSMappingModel(from: nil, forSourceModel: modelFrom, destinationModel: modelTo) ??
                (try? NSMappingModel.inferredMappingModel(forSourceModel: modelFrom, destinationModel: modelTo)) else {
                    throw MigrationError.migrationFailed
            }

            // Migrate the model to the next step
            DDLogWarn("⚠️ Attempting migration from \(modelNames[index]) to \(modelNames[index + 1])")

            guard migrateStore(at: sourceStore, storeType: storeType, fromModel: modelFrom, toModel: modelTo, with: migrateWithModel) == true else {
                throw MigrationError.migrationFailed
            }
        }
    }
}


// MARK: - File helpers
//
private extension CoreDataIterativeMigrator {

    /// Build a temporary path to write the migrated store.
    ///
    static func createTemporaryFolder(at storeURL: URL) -> URL {
        let fileManager = FileManager.default
        let tempDestinationURL = storeURL.deletingLastPathComponent().appendingPathComponent("migration").appendingPathComponent(storeURL.lastPathComponent)
        try? fileManager.removeItem(at: tempDestinationURL.deletingLastPathComponent())
        try? fileManager.createDirectory(at: tempDestinationURL.deletingLastPathComponent(), withIntermediateDirectories: false, attributes: nil)

        return tempDestinationURL
    }

    /// Move the original source store to a backup location.
    ///
    static func makeBackup(at storeURL: URL) throws -> URL {
        let fileManager = FileManager.default
        let backupURL = storeURL.deletingLastPathComponent().appendingPathComponent("backup")
        try? fileManager.removeItem(at: backupURL)
        try? fileManager.createDirectory(atPath: backupURL.path, withIntermediateDirectories: false, attributes: nil)
        do {
            let files = try fileManager.contentsOfDirectory(atPath: storeURL.deletingLastPathComponent().path)
            try files.forEach { (file) in
                if file.hasPrefix(storeURL.lastPathComponent) {
                    let fullPath = storeURL.deletingLastPathComponent().appendingPathComponent(file).path
                    let toPath = URL(fileURLWithPath: backupURL.path).appendingPathComponent(file).path
                    try fileManager.moveItem(atPath: fullPath, toPath: toPath)
                }
            }
        } catch {
            DDLogError("⛔️ Error while moving original source store to a backup location: \(error)")
            throw error
        }

        return backupURL
    }

    /// Copy migrated over the original files
    ///
    static func copyMigratedOverOriginal(from tempDestinationURL: URL, to storeURL: URL) throws {
        do {
            let fileManager = FileManager.default
            let files = try fileManager.contentsOfDirectory(atPath: tempDestinationURL.deletingLastPathComponent().path)
            try files.forEach { (file) in
                if file.hasPrefix(tempDestinationURL.lastPathComponent) {
                    let fullPath = tempDestinationURL.deletingLastPathComponent().appendingPathComponent(file).path
                    let toPath = storeURL.deletingLastPathComponent().appendingPathComponent(file).path
                    try? fileManager.removeItem(atPath: toPath)
                    try fileManager.moveItem(atPath: fullPath, toPath: toPath)
                }
            }
        } catch {
            DDLogError("⛔️ Error while copying migrated over the original files: \(error)")
            throw error
        }
    }

    /// Delete backup copies of the original file before migration
    ///
    static func deleteBackupCopies(at backupURL: URL) throws {
        do {
            let fileManager = FileManager.default
            let files = try fileManager.contentsOfDirectory(atPath: backupURL.path)
            try files.forEach { (file) in
                let fullPath = URL(fileURLWithPath: backupURL.path).appendingPathComponent(file).path
                try fileManager.removeItem(atPath: fullPath)
            }
        } catch {
            DDLogError("⛔️ Error while deleting backup copies of the original file before migration: \(error)")
            throw error
        }
    }
}


// MARK: - Private helper functions
//
private extension CoreDataIterativeMigrator {

    static func migrateStore(at url: URL,
                             storeType: String,
                             fromModel: NSManagedObjectModel,
                             toModel: NSManagedObjectModel,
                             with mappingModel: NSMappingModel) -> Bool {
        let tempDestinationURL = createTemporaryFolder(at: url)

        // Migrate from the source model to the target model using the mapping,
        // and store the resulting data at the temporary path.
        let migrator = NSMigrationManager(sourceModel: fromModel, destinationModel: toModel)
        do {
            try migrator.migrateStore(from: url,
                                      sourceType: storeType,
                                      options: nil,
                                      with: mappingModel,
                                      toDestinationURL: tempDestinationURL,
                                      destinationType: storeType,
                                      destinationOptions: nil)
        } catch {
            return false
        }

        do {
            let backupURL = try makeBackup(at: url)
            try copyMigratedOverOriginal(from: tempDestinationURL, to: url)
            try deleteBackupCopies(at: backupURL)
        } catch {
            return false
        }

        return true
    }

    static func metadataForPersistentStore(storeType: String, at url: URL) throws -> [String: Any]? {

        guard let sourceMetadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: storeType, at: url, options: nil) else {
            let description = "Failed to find source metadata for store: \(url)"
            throw NSError(domain: "IterativeMigrator", code: 102, userInfo: [NSLocalizedDescriptionKey: description])
        }

        return sourceMetadata
    }

    static func model(for metadata: [String: Any]) throws -> NSManagedObjectModel? {
        let bundle = Bundle(for: ContextManager.self)
        guard let sourceModel = NSManagedObjectModel.mergedModel(from: [bundle], forStoreMetadata: metadata) else {
            let description = "Failed to find source model for metadata: \(metadata)"
            throw NSError(domain: "IterativeMigrator", code: 100, userInfo: [NSLocalizedDescriptionKey: description])
        }

        return sourceModel
    }

    static func models(for names: [String]) throws -> [NSManagedObjectModel] {
        let models = try names.map { (name) -> NSManagedObjectModel in
            guard let url = urlForModel(name: name, in: nil),
                let model = NSManagedObjectModel(contentsOf: url) else {
                    let description = "No model found for \(name)"
                    throw NSError(domain: "IterativeMigrator", code: 110, userInfo: [NSLocalizedDescriptionKey: description])
            }

            return model
        }

        return models
    }

    static func urlForModel(name: String, in directory: String?) -> URL? {
        let bundle = Bundle(for: ContextManager.self)
        var url = bundle.url(forResource: name, withExtension: "mom", subdirectory: directory)

        if url != nil {
            return url
        }

        let momdPaths = bundle.paths(forResourcesOfType: "momd", inDirectory: directory)
        momdPaths.forEach { (path) in
            if url != nil {
                return
            }
            url = bundle.url(forResource: name, withExtension: "mom", subdirectory: URL(fileURLWithPath: path).lastPathComponent)
        }

        return url
    }
}

enum MigrationError: Error {
    case migrationFailed
}
