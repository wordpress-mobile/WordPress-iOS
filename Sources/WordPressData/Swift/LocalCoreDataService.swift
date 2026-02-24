import CoreData

@objc open class LocalCoreDataService: NSObject {
    @objc public let managedObjectContext: NSManagedObjectContext

    @objc public init(managedObjectContext context: NSManagedObjectContext) {
        self.managedObjectContext = context
        super.init()
    }
}
