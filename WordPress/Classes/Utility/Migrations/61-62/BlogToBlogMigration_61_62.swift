import CoreData

class BlogToBlogMigration_61_62: NSEntityMigrationPolicy {
    override func createRelationships(forDestination dInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        try super.createRelationships(forDestination: dInstance, in: mapping, manager: manager)
        guard dInstance.value(forKey: "account") == nil else {
            return
        }
        guard let sourceBlog = manager.sourceInstances(forEntityMappingName: "BlogToBlog", destinationInstances: [dInstance]).first,
            let sourceAccount = sourceBlog.value(forKey: "jetpackAccount") as? NSManagedObject,
            let destinationAccount = manager.destinationInstances(forEntityMappingName: "AccountToAccount", sourceInstances: [sourceAccount]).first else {
                return
        }
        dInstance.setValue(destinationAccount, forKey: "account")
    }
}
