import Foundation
import CoreData

/// NSPersistentContainer subclass that defaults to the shared container directory
///
final class SharedPersistentContainer: NSPersistentContainer {
    internal override class func defaultDirectoryURL() -> URL {
        var url = super.defaultDirectoryURL()
        if let newURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WPAppGroupName) {
            url = newURL
        }
        return url
    }
}

class SharedCoreDataStack {

    // MARK: - Private Properties

    fileprivate let modelName: String

    fileprivate lazy var storeContainer: SharedPersistentContainer = {
        let container = SharedPersistentContainer(name: self.modelName)
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                DDLogError("Error loading persistent stores: \(error), \(error.userInfo)")
            }
        }
        return container
    }()

    // MARK: - Public Properties

    /// Returns the managed context associated with the main queue
    ///
    lazy var managedContext: NSManagedObjectContext = {
        return self.storeContainer.viewContext
    }()

    // MARK: - Initializers

    /// Initialize the SharedPersistentContainer using the standard Extensions model.
    ///
    convenience init() {
        self.init(modelName: Constants.sharedModelName)
    }

    /// Initialize the core data stack with the given model name.
    ///
    /// This initializer is meant for testing. You probably want to use the convenience `init()` that uses the standard Extensions model
    ///
    /// - Parameters:
    ///     - modelName: Name of the model to initialize the SharedPersistentContainer with.
    ///
    init(modelName: String) {
        self.modelName = modelName
    }

    // MARK: - Public Funcntions

    /// Commit unsaved changes (if any exist) using the main queue's managed context
    ///
    func saveContext() {
        guard managedContext.hasChanges else {
            return
        }

        do {
            try managedContext.save()
        } catch let error as NSError {
            DDLogError("Error saving context: \(error), \(error.userInfo)")
        }
    }
}

// MARK: - Constants
//
extension SharedCoreDataStack {
    struct Constants {
        static let sharedModelName = "Extensions"
    }
}
