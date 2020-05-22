import Foundation

@testable import WordPress

class CoreDataManagerMock: CoreDataManager, ManagerMock {
    override init() {
        super.init()
        ContextManager.overrideSharedInstance(self)
    }

    var _managedObjectModel: NSManagedObjectModel?
    override var managedObjectModel: NSManagedObjectModel {
        set {
            _managedObjectModel = newValue
        }

        get {
            return _managedObjectModel ?? super.managedObjectModel
        }
    }

    var _persistentStoreCoordinator: NSPersistentStoreCoordinator?
    override var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        set {
            _persistentStoreCoordinator = newValue
        }

        get {
            return _persistentStoreCoordinator ?? _persistentContainer.persistentStoreCoordinator
        }
    }

    override func save(_ context: NSManagedObjectContext) {
        save(context) {
            if let testExpectation = self.testExpectation {
                testExpectation.fulfill()
                self.testExpectation = nil
            } else if self.requiresTestExpectation {
                NSLog("No test expectation present for context save")
            }
        }
    }

    override func saveContextAndWait(_ context: NSManagedObjectContext) {
        super.saveContextAndWait(context)
        if let testExpectation = testExpectation {
            testExpectation.fulfill()
            self.testExpectation = nil
        } else if requiresTestExpectation {
            NSLog("No test expectation present for context save")
        }
    }

    override func save(_ context: NSManagedObjectContext, withCompletionBlock completionBlock: @escaping () -> Void) {
        super.save(context) {
            if let testExpectation = self.testExpectation {
                testExpectation.fulfill()
                self.testExpectation = nil
            } else if self.requiresTestExpectation {
                NSLog("No test expectation present for context save")
            }
            completionBlock()
        }
    }

    lazy var _persistentContainer: NSPersistentContainer = {
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        description.shouldMigrateStoreAutomatically = false

        let container = NSPersistentContainer(name: "WordPress", managedObjectModel: managedObjectModel)
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { [weak self] (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("CoreData Fatal Error: \(error) [\(error.userInfo)]")
            }
        }
        return container
    }()

    override var persistentContainer: NSPersistentContainer {
        set {
            // Noop
        }

        get {
            return _persistentContainer
        }
    }

    var standardPSC: NSPersistentStoreCoordinator {
        return super.persistentStoreCoordinator
    }

    var requiresTestExpectation = true

    var storeURL: URL {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Missing Documents Folder")
        }
        return url.appendingPathComponent("WordPress.sqlite")
    }

    var testExpectation: XCTestExpectation?
}

// Expose CoreDataManagerMock
@objc class SwiftManagerMock: NSObject {
    @objc static func instance() -> CoreDataStack & ManagerMock {
        return CoreDataManagerMock()
    }
}
