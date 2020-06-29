import Foundation
import CoreData

/// CoreDataIterativeMigrator: Migrates through a series of models to allow for users to skip app versions without risk.
///
class CoreDataIterativeMigrator: NSObject {

    private static func error(with code: IterativeMigratorErrorCodes, description: String) -> NSError {
        return NSError(domain: "IterativeMigrator", code: code.rawValue, userInfo: [NSLocalizedDescriptionKey: description])
    }

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
        // If metadataForPersistentStore throws an error that error is propagated, not replaced by the throw
        // in the guard's else clause.  If metadataForPersistentStore returns nil then an error is thrown.
        guard let sourceMetadata = try metadataForPersistentStore(storeType: storeType, at: sourceStore) else {
            throw error(with: .failedRetrievingMetadata, description: "The source metadata was nil.")
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

        // Nested function for retrieving a model's version name.
        // Used to give more context to errors.
        func versionNameForModel(model: NSManagedObjectModel) -> String {
            guard let index = objectModels.firstIndex(of: model) else {
                return "Unknown"
            }
            return modelNames[index]
        }

        // Migrate between each model. Count - 2 because of zero-based index and we want
        // to stop at the last pair (you can't migrate the last model to nothingness).
        let upperBound = modelsToMigrate.count - 2
        for index in 0...upperBound {
            let modelFrom = modelsToMigrate[index]
            let modelTo = modelsToMigrate[index + 1]

            let migrateWithModel: NSMappingModel
            // Check whether a custom mapping model exists.
            if let customModel = NSMappingModel(from: nil, forSourceModel: modelFrom, destinationModel: modelTo) {
                migrateWithModel = customModel
            } else {
                // No custom model, so use an inferred model.
                do {
                    let inferredModel = try NSMappingModel.inferredMappingModel(forSourceModel: modelFrom, destinationModel: modelTo)
                    migrateWithModel = inferredModel
                } catch {
                    let versionFrom = versionNameForModel(model: modelFrom)
                    let versionTo = versionNameForModel(model: modelTo)
                    var description = "Mapping model could not be inferred, and no custom mapping model found."
                    description = description + "Version From \(versionFrom), To \(versionTo)."
                    description = description + " Original Error: \(error)"
                    throw CoreDataIterativeMigrator.error(with: IterativeMigratorErrorCodes.failedOnCustomMappingModel, description: description)
                }

            }

            // Migrate the model to the next step
            DDLogWarn("⚠️ Attempting migration from \(modelNames[index]) to \(modelNames[index + 1])")

            do {
                try migrateStore(at: sourceStore, storeType: storeType, fromModel: modelFrom, toModel: modelTo, with: migrateWithModel)
            } catch {
                let versionFrom = versionNameForModel(model: modelFrom)
                let versionTo = versionNameForModel(model: modelTo)
                var description = "Failed migrating store from version \(versionFrom) to version \(versionTo)."
                description = description + " Original Error: \(error)"
                throw CoreDataIterativeMigrator.error(with: IterativeMigratorErrorCodes.failedMigratingStore, description: description)
            }
        }
    }

    @objc static func backupDatabase(at storeURL: URL) throws {
        _ = try CoreDataIterativeMigrator.makeBackup(at: storeURL)
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
                             with mappingModel: NSMappingModel) throws {
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
            throw error
        }

        do {
            let backupURL = try makeBackup(at: url)
            try copyMigratedOverOriginal(from: tempDestinationURL, to: url)
            try deleteBackupCopies(at: backupURL)
        } catch {
            throw error
        }
    }

    static func metadataForPersistentStore(storeType: String, at url: URL) throws -> [String: Any]? {
        do {
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: storeType, at: url, options: nil)
            return metadata
        } catch {
            let originalDescription: String = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String ?? ""
            let description = "Failed to find source metadata for store: \(url). Original Description: \(originalDescription)"
            throw CoreDataIterativeMigrator.error(with: IterativeMigratorErrorCodes.noMetadataForStore, description: description)
        }
    }

    static func model(for metadata: [String: Any]) throws -> NSManagedObjectModel? {
        let bundle = Bundle(for: ContextManager.self)
        guard let sourceModel = NSManagedObjectModel.mergedModel(from: [bundle], forStoreMetadata: metadata) else {
            let description = "Failed to find source model for metadata: \(metadata)"
            throw error(with: .noSourceModelForMetadata, description: description)
        }

        return sourceModel
    }

    static func models(for names: [String]) throws -> [NSManagedObjectModel] {
        let models = try names.map { (name) -> NSManagedObjectModel in
            guard let url = urlForModel(name: name, in: nil),
                let model = NSManagedObjectModel(contentsOf: url) else {
                    let description = "No model found for \(name)"
                    throw error(with: .noModelFound, description: description)
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

enum IterativeMigratorErrorCodes: Int {
    case noSourceModelForMetadata = 100
    case noMetadataForStore = 102
    case noModelFound = 110

    case failedRetrievingMetadata = 120
    case failedOnCustomMappingModel = 130
    case failedMigratingStore = 140
}
