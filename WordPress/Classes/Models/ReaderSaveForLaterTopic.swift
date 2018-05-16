/// Plese do not review this class. This is basically a mock at the moment. It models a mock topic, so that I can test that the topic gets rendered in the UI
final class ReaderSaveForLaterTopic: ReaderAbstractTopic {
    init() {
        let managedObjectContext = ReaderSaveForLaterTopic.setUpInMemoryManagedObjectContext()
        let entity = NSEntityDescription.entity(forEntityName: "ReaderDefaultTopic", in: managedObjectContext)
        super.init(entity: entity!, insertInto: managedObjectContext)
    }

    override open class var TopicType: String {
        return "saveForLater"
    }

    /// TODO. This function will have to go away
    static func setUpInMemoryManagedObjectContext() -> NSManagedObjectContext {
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!

        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        } catch {
            print("Adding in-memory persistent store failed")
        }

        let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator

        return managedObjectContext
    }
}
