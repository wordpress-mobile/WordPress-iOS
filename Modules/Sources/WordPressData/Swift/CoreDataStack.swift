import CoreData

@objc public protocol CoreDataStack {

    var mainContext: NSManagedObjectContext { get }

    @available(*, deprecated, message: "Use `performAndSave` instead")
    func newDerivedContext() -> NSManagedObjectContext

    func saveContextAndWait(_ context: NSManagedObjectContext)

    @objc(saveContext:)
    func save(_ context: NSManagedObjectContext)

    @objc(saveContext:withCompletionBlock:onQueue:)
    func save(_ context: NSManagedObjectContext, completion: (() -> Void)?, on queue: DispatchQueue)

    @objc(performAndSaveUsingBlock:)
    func performAndSave(_ block: @escaping (NSManagedObjectContext) -> Void)

    @objc(performAndSaveUsingBlock:completion:onQueue:)
    func performAndSave(_ block: @escaping (NSManagedObjectContext) -> Void, completion: (() -> Void)?, on queue: DispatchQueue)
}
