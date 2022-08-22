import ObjectiveC

@objc
class ContainerContextFactory: NSObject, ManagedObjectContextFactory {

    private let container: NSPersistentContainer

    let mainContext: NSManagedObjectContext

    required init(persistentContainer container: NSPersistentContainer) {
        self.container = container
        self.mainContext = container.viewContext
        self.mainContext.automaticallyMergesChangesFromParent = true
        self.mainContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func newDerivedContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    func save(_ context: NSManagedObjectContext, andWait wait: Bool, withCompletionBlock completionBlock: (() -> Void)?) {
        let block: () -> Void = {
            self.internalSave(context)
            DispatchQueue.main.async {
                completionBlock?()
            }
        }
        if wait {
            context.performAndWait(block)
        } else {
            context.perform(block)
        }
    }

}
