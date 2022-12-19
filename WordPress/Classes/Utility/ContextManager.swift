import Foundation
import CoreData

/// A constant representing the current version of the data model.
///
/// - SeeAlso: ContextManager.init(modelName:store:)
let ContextManagerModelNameCurrent = "$CURRENT"

@objc
public class ContextManager: NSObject, CoreDataStack {
    static var inMemoryStoreURL: URL {
        URL(fileURLWithPath: "/dev/null")
    }

    private let modelName: String
    private let storeURL: URL
    private let persistentContainer: NSPersistentContainer

    @objc
    public var mainContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    convenience override init() {
        self.init(modelName: ContextManagerModelNameCurrent, store: Self.localDatabasePath)
    }

    /// Create a ContextManager instance with given model name and database location.
    ///
    /// Note: This initialiser is only used for testing purpose at the moment.
    ///
    /// - Parameters:
    ///   - modelName: Model name in Core Data data model file.
    ///         Use ContextManagerModelNameCurrent for current version, or
    ///         "WordPress <version>" for specific version.
    ///   - store: Database location. Use `ContextManager.inMemoryStoreURL` to create an in-memory database.
    init(modelName: String, store storeURL: URL) {
        assert(modelName == ContextManagerModelNameCurrent || modelName.hasPrefix("WordPress "))
        assert(storeURL.isFileURL)

        self.modelName = modelName
        self.storeURL = storeURL
        self.persistentContainer = Self.createPersistentContainer(storeURL: storeURL, modelName: modelName)

        super.init()

        mainContext.automaticallyMergesChangesFromParent = true
        mainContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        NullBlogPropertySanitizer(context: mainContext).sanitize()
    }

    public func newDerivedContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    @objc(performAndSaveUsingBlock:)
    public func performAndSave(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let context = newDerivedContext()
        context.performAndWait {
            block(context)

            self.save(context, andWait: true, withCompletionBlock: nil)
        }
    }

    @objc(performAndSaveUsingBlock:completion:)
    public func performAndSave(_ block: @escaping (NSManagedObjectContext) -> Void, completion: @escaping () -> Void) {
        let context = newDerivedContext()
        context.perform {
            block(context)

            self.save(context, andWait: false, withCompletionBlock: completion)
        }
    }

    @objc
    public func saveContextAndWait(_ context: NSManagedObjectContext) {
        save(context, andWait: true, withCompletionBlock: nil)
    }

    @objc(saveContext:)
    public func save(_ context: NSManagedObjectContext) {
        save(context, andWait: false, withCompletionBlock: nil)
    }

    @objc(saveContext:withCompletionBlock:)
    public func save(_ context: NSManagedObjectContext, withCompletionBlock completion: @escaping () -> Void) {
        save(context, andWait: false, withCompletionBlock: completion)
    }
}

// MARK: - Private methods

private extension ContextManager {
    static var localDatabasePath: URL {
        guard let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
            fatalError("Failed to find the document directory")
        }

        return url.appendingPathComponent("WordPress.sqlite")
    }

    func save(_ context: NSManagedObjectContext, andWait wait: Bool, withCompletionBlock completionBlock: (() -> Void)?) {
        let block: () -> Void = {
            self.internalSave(context)
            DispatchQueue.main.async {
                completionBlock?()
            }
        }

        // Ensure that the `context`'s concurrency type is not `confinementConcurrencyType`, since it will crash if `perform` or `performAndWait` is called.
        guard context.concurrencyType == .mainQueueConcurrencyType || context.concurrencyType == .privateQueueConcurrencyType else {
            block()
            return
        }

        if wait {
            context.performAndWait(block)
        } else {
            context.perform(block)
        }
    }
}

// MARK: - Initialise Core Data stack

private extension ContextManager {
    static func createPersistentContainer(storeURL: URL, modelName: String) -> NSPersistentContainer {
        guard var modelFileURL = Bundle.main.url(forResource: "WordPress", withExtension: "momd") else {
            fatalError("Can't find WordPress.momd")
        }

        if modelName != ContextManagerModelNameCurrent {
            modelFileURL = modelFileURL.appendingPathComponent(modelName).appendingPathExtension("mom")
        }

        guard let objectModel = NSManagedObjectModel(contentsOf: modelFileURL) else {
            fatalError("Can't create object model named \(modelName) at \(modelFileURL)")
        }

        let startupEvent = SentryStartupEvent()

        do {
            try migrateDataModelsIfNecessary(storeURL: storeURL, objectModel: objectModel)
        } catch {
            DDLogError("Unable to migrate store: \(error)")
            startupEvent.add(error: error as NSError)
        }

        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        storeDescription.shouldInferMappingModelAutomatically = true
        storeDescription.shouldMigrateStoreAutomatically = true
        let persistentContainer = NSPersistentContainer(name: "WordPress", managedObjectModel: objectModel)
        persistentContainer.persistentStoreDescriptions = [storeDescription]
        persistentContainer.loadPersistentStores { _, error in
            guard let error else {
                return
            }

            DDLogError("Error opening the database. \(error)\nDeleting the file and trying again")
            startupEvent.add(error: error)

            // make a backup of the old database
            do {
                try CoreDataIterativeMigrator.backupDatabase(at: storeURL)
            } catch {
                startupEvent.add(error: error)
            }

            // TODO: The original Objective C implement calls `loadPersistentStores` again here, but throws an exception regardless the result.

            startupEvent.send(title: "Can't initialize Core Data stack")
            objc_exception_throw(
                NSException(
                    name: NSExceptionName(rawValue: "Can't initialize Core Data stack"),
                    reason: error.localizedDescription,
                    userInfo: (error as NSError).userInfo
                )
            )
        }

        return persistentContainer
    }

    static func migrateDataModelsIfNecessary(storeURL: URL, objectModel: NSManagedObjectModel) throws {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            DDLogInfo("No store exists at \(storeURL).  Skipping migration.")
            return
        }

        guard let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL),
            objectModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        else {
            return
        }

        DDLogWarn("Migration required for persistent store.")

        guard let modelFileURL = Bundle.main.url(forResource: "WordPress", withExtension: "momd") else {
            fatalError("Can't find WordPress.momd")
        }

        guard let versionInfo = NSDictionary(contentsOf: modelFileURL.appendingPathComponent("VersionInfo.plist")) else {
            fatalError("Can't get the object model's version info")
        }

        guard let modelNames = (versionInfo["NSManagedObjectModel_VersionHashes"] as? [String: AnyObject])?.keys else {
            fatalError("Can't parse the model versions")
        }

        let sortedModelNames = modelNames.sorted { $0.compare($1, options: .numeric) == .orderedAscending }
        try CoreDataIterativeMigrator.iterativeMigrate(
            sourceStore: storeURL,
            storeType: NSSQLiteStoreType,
            to: objectModel,
            using: sortedModelNames
        )
    }
}

extension ContextManager {
    private static let internalSharedInstance = ContextManager()
    /// Tests purpose only
    static var overrideInstance: CoreDataStack?

    @objc class func sharedInstance() -> CoreDataStack {
        if let overrideInstance = overrideInstance {
            return overrideInstance
        }

        return ContextManager.internalSharedInstance
    }

    static var shared: CoreDataStack {
        return sharedInstance()
    }
}
