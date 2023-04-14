import Foundation
import CoreData

/// A constant representing the current version of the data model.
///
/// - SeeAlso: ContextManager.init(modelName:store:)
let ContextManagerModelNameCurrent = "$CURRENT"

public protocol CoreDataStackSwift: CoreDataStack {

    /// Execute the given block with a background context and save the changes.
    ///
    /// This function _does not block_ its running thread. The block is executed in background and its return value
    /// is passed onto the `completion` block which is executed on the given `queue`.
    ///
    /// - Parameters:
    ///   - block: A closure which uses the given `NSManagedObjectContext` to make Core Data model changes.
    ///   - completion: A closure which is called with the return value of the `block`, after the changed made
    ///         by the `block` is saved.
    ///   - queue: A queue on which to execute the completion block.
    func performAndSave<T>(_ block: @escaping (NSManagedObjectContext) -> T, completion: ((T) -> Void)?, on queue: DispatchQueue)

    /// Execute the given block with a background context and save the changes _if the block does not throw an error_.
    ///
    /// This function _does not block_ its running thread. The block is executed in background and the return value
    /// (or an error) is passed onto the `completion` block which is executed on the given `queue`.
    ///
    /// - Parameters:
    ///   - block: A closure that uses the given `NSManagedObjectContext` to make Core Data model changes. The changes
    ///         are only saved if the block does not throw an error.
    ///   - completion: A closure which is called with the `block`'s execution result, which is either an error thrown
    ///         by the `block` or the return value of the `block`.
    ///   - queue: A queue on which to execute the completion block.
    func performAndSave<T>(_ block: @escaping (NSManagedObjectContext) throws -> T, completion: ((Result<T, Error>) -> Void)?, on queue: DispatchQueue)

    /// Execute the given block with a background context and save the changes _if the block does not throw an error_.
    ///
    /// - Parameter block: A closure that uses the given `NSManagedObjectContext` to make Core Data model changes.
    ///     The changes are only saved if the block does not throw an error.
    /// - Returns: The value returned by the `block`
    /// - Throws: The error thrown by the `block`, in which case the Core Data changes made by the `block` is discarded.
    func performAndSave<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T

}

@objc
public class ContextManager: NSObject, CoreDataStack, CoreDataStackSwift {
    static var inMemoryStoreURL: URL {
        URL(fileURLWithPath: "/dev/null")
    }

    private let modelName: String
    private let storeURL: URL
    private let persistentContainer: NSPersistentContainer

    /// A serial queue used to ensure there is only one writing operation at a time.
    ///
    /// - Note: This queue currently is not used in `performAndSave(_:)` the "save synchronously" function, since it's
    ///   not safe to block current thread. Considering the aforementioned `performAndSave(_:)` function is going to be
    ///   removed soon, I think it's okay to make this compromise.
    private let writerQueue: OperationQueue

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
        self.writerQueue = OperationQueue()
        self.writerQueue.name = "org.wordpress.CoreDataStack.writer"
        self.writerQueue.maxConcurrentOperationCount = 1

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

            self.save(context, .alreadyInContextQueue)
        }
    }

    @objc(performAndSaveUsingBlock:completion:onQueue:)
    public func performAndSave(_ block: @escaping (NSManagedObjectContext) -> Void, completion: (() -> Void)?, on queue: DispatchQueue) {
        let context = newDerivedContext()
        self.writerQueue.addOperation(AsyncBlockOperation { done in
            context.perform {
                block(context)

                self.save(context, .alreadyInContextQueue)
                queue.async { completion?() }
                done()
            }
        })
    }

    public func performAndSave<T>(_ block: @escaping (NSManagedObjectContext) throws -> T, completion: ((Result<T, Error>) -> Void)?, on queue: DispatchQueue) {
        let context = newDerivedContext()
        self.writerQueue.addOperation(AsyncBlockOperation { done in
            context.perform {
                let result = Result(catching: { try block(context) })
                if case .success = result {
                    self.save(context, .alreadyInContextQueue)
                }
                queue.async { completion?(result) }
                done()
            }
        })
    }

    public func performAndSave<T>(_ block: @escaping (NSManagedObjectContext) -> T, completion: ((T) -> Void)?, on queue: DispatchQueue) {
        performAndSave(
            block,
            completion: { (result: Result<T, Error>) in
                // It's safe to force-unwrap here, since the `block` does not throw an error.
                completion?(try! result.get())
            },
            on: queue
        )
    }

    public func performAndSave<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            performAndSave(block, completion: continuation.resume(with:), on: DispatchQueue.global())
        }
    }

    @objc
    public func saveContextAndWait(_ context: NSManagedObjectContext) {
        save(context, .synchronously)
    }

    @objc(saveContext:)
    public func save(_ context: NSManagedObjectContext) {
        save(context, .asynchronously)
    }

    @objc(saveContext:withCompletionBlock:onQueue:)
    public func save(_ context: NSManagedObjectContext, completion: (() -> Void)?, on queue: DispatchQueue) {
        if let completion {
            save(context, .asynchronouslyWithCallback(completion: completion, queue: queue))
        } else {
            save(context, .asynchronously)
        }
    }

    static func migrateDataModelsIfNecessary(storeURL: URL, objectModel: NSManagedObjectModel) throws {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            DDLogInfo("No store exists at \(storeURL).  Skipping migration.")
            return
        }

        guard let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL),
            !objectModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
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

// MARK: - Private methods

private extension ContextManager {
    static var localDatabasePath: URL {
        guard let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
            fatalError("Failed to find the document directory")
        }

        return url.appendingPathComponent("WordPress.sqlite")
    }

    func save(_ context: NSManagedObjectContext, _ option: SaveContextOption) {
        let block: () -> Void = {
            self.internalSave(context)

            switch option {
            case let .asynchronouslyWithCallback(completion, queue):
                queue.async(execute: completion)
            case .synchronously, .asynchronously, .alreadyInContextQueue:
                // Do nothing
                break
            }
        }

        // Ensure that the `context`'s concurrency type is not `confinementConcurrencyType`, since it will crash if `perform` or `performAndWait` is called.
        guard context.concurrencyType == .mainQueueConcurrencyType || context.concurrencyType == .privateQueueConcurrencyType else {
            block()
            return
        }

        switch option {
        case .synchronously:
            context.performAndWait(block)
        case .asynchronously, .asynchronouslyWithCallback:
            context.perform(block)
        case .alreadyInContextQueue:
            block()
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

}

extension ContextManager {
    private static let internalSharedInstance = ContextManager()
    /// Tests purpose only
    static var overrideInstance: ContextManager?

    @objc class func sharedInstance() -> ContextManager {
        if let overrideInstance = overrideInstance {
            return overrideInstance
        }

        return ContextManager.internalSharedInstance
    }

    static var shared: ContextManager {
        return sharedInstance()
    }
}

private enum SaveContextOption {
    case synchronously
    case asynchronously
    case asynchronouslyWithCallback(completion: () -> Void, queue: DispatchQueue)
    case alreadyInContextQueue
}

/// Use this temporary workaround to mitigate Core Data concurrency issues when accessing the given `object`.
///
/// When the app is launched from Xcode, some code may crash due to the effect of the "com.apple.CoreData.ConcurrencyDebug"
/// launch argument. The crash indicates the crash site violates [the following rule](https://developer.apple.com/documentation/coredata/using_core_data_in_the_background#overview)
///
/// > To use Core Data in a multithreaded environment, ensure that:
/// > - Managed objects retrieved from a context are bound to the same queue that the context is bound to.
///
/// This function can be used as a temporary workaround to mitigate aforementioned crashes during development.
///
/// - Warning: The workaround does not apply to release builds. In a release build, calling this function is exactly
///     the same as calling the given `closure` directly.
///
/// - Warning: This function is _not_ a solution for Core Data concurrency issues, and should only be used as a
///     temporary solution, to avoid the Core Data concurrency issue becoming a blocker to feature developlement.
@available(*, deprecated, message: "This workaround is meant as a temporary solution to mitigate Core Data concurrency issues when accessing the `object`. Please see this function's API doc for details.")
@inlinable
public func workaroundCoreDataConcurrencyIssue<Value>(accessing object: NSManagedObject, _ closure: () -> Value) -> Value {
#if DEBUG
    guard let context = object.managedObjectContext else {
        fatalError("The object must be bound to a context: \(object)")
    }

    var value: Value!
    context.performAndWait {
        value = closure()
    }
    return value
#else
    return closure()
#endif /* DEBUG */
}
