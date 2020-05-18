
/// Handles the core data stack for the whole app
class CoreDataManager: CoreDataStack {

    static let shared = CoreDataManager()

    private init() {}

    var mainContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        persistentContainer.persistentStoreCoordinator
    }

    var modelURL: URL {
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: Constants.name, withExtension: "momd") else {
            fatalError("Missing Model Resource")
        }
        return url
    }

    var managedObjectModel: NSManagedObjectModel {
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Could not load model")
        }
        return mom
    }

    var storeURL: URL {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Okay: Missing Documents Folder?")
        }

        return url.appendingPathComponent(Constants.name + ".sqlite")
    }

    var storeDescription: NSPersistentStoreDescription {
        let description = NSPersistentStoreDescription(url: storeURL)
        description.shouldAddStoreAsynchronously = false
        description.shouldMigrateStoreAutomatically = false
        return description
    }

    lazy var persistentContainer: NSPersistentContainer = {
        migrateDataModelIfNecessary()

        let container = NSPersistentContainer(name: Constants.name, managedObjectModel: managedObjectModel)
        container.persistentStoreDescriptions = [storeDescription]

        container.loadPersistentStores { [weak self] (storeDescription, error) in
            guard let `self` = self, let error = error else {
                return
            }

            DDLogError("⛔️ [CoreDataManager] loadPersistentStore failed. Attempting to recover... \(error)")

            /// Backup the old Store
            ///
            do {
                let sourceURL = self.storeURL
                let backupURL = sourceURL.appendingPathExtension("~")
                try FileManager.default.copyItem(at: sourceURL, to: backupURL)
                try FileManager.default.removeItem(at: sourceURL)
            } catch {
                fatalError("☠️ [CoreDataManager] Cannot backup Store: \(error)")
            }

            /// Retry!
            ///
            container.loadPersistentStores { [weak self] (storeDescription, error) in
                guard let error = error as NSError? else {
                    return
                }

                fatalError("☠️ [CoreDataManager] Recovery Failed! \(error) [\(error.userInfo)]")
            }
        }

        return container
    }()

    private func childContext(with concurrencyType: NSManagedObjectContextConcurrencyType) -> NSManagedObjectContext {
        let childManagedObjectContext = NSManagedObjectContext(concurrencyType: concurrencyType)
        childManagedObjectContext.parent = persistentContainer.viewContext
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

    }

    func save(_ context: NSManagedObjectContext) {

    }

    func save(_ context: NSManagedObjectContext, withCompletionBlock completionBlock: @escaping () -> Void) {

    }

    func obtainPermanentID(for managedObject: NSManagedObject) -> Bool {
        return true
    }

    func mergeChanges(_ context: NSManagedObjectContext, fromContextDidSave notification: Foundation.Notification) {
        
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
            let allKeys = modelNames.allKeys as? [String],
            let objectModel = NSManagedObjectModel(contentsOf: modelURL) else {
                return
        }

        let sortedKeys = allKeys.sorted { (string1, string2) -> Bool in
            return string1.compare(string2, options: [.numeric], range: nil, locale: nil) == .orderedAscending
        }

        do {
            try CoreDataIterativeMigrator.iterativeMigrate(sourceStore: storeURL,
                                                           storeType: NSSQLiteStoreType,
                                                           to: objectModel,
                                                           using: sortedKeys)
        } catch {
            DDLogError("☠️ [CoreDataManager] Unable to migrate store with error: \(error)")
        }
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
