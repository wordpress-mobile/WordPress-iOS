import Foundation

@testable import WordPress

class PostBuilder {
    private let inMemoryManagedObjectContext: NSManagedObjectContext = {
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!

        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        } catch {
            print("Adding in-memory persistent store failed")
        }

        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator

        return managedObjectContext
    }()

    lazy var post = {
        return NSEntityDescription.insertNewObject(forEntityName: "Post", into: inMemoryManagedObjectContext) as! Post
    }()

    func published() -> PostBuilder {
        post.status = .publish
        return self
    }

    func drafted() -> PostBuilder {
        post.status = .draft
        return self
    }

    func build() -> Post {
        return NSEntityDescription.insertNewObject(forEntityName: "Post", into: inMemoryManagedObjectContext) as! Post
    }
}
