import Foundation

class ReaderTopicToReaderDefaultTopic37to38: NSEntityMigrationPolicy {

    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        // Only handle ReaderTopic entites that are defaults
        let path = sInstance.value(forKey: "path") as! NSString
        if path.range(of: "/list/").location != NSNotFound ||
            path.range(of: "/tags/").location != NSNotFound ||
            path.range(of: "/site/").location != NSNotFound {
            return
        }

        // Create the destination ReaderTagTopic
        let newTopic = NSEntityDescription.insertNewObject(forEntityName: ReaderDefaultTopic.classNameWithoutNamespaces(),
            into: manager.destinationContext)

        // Update the destination topic's properties
        // Abstract
        newTopic.setValue(sInstance.value(forKey: "isSubscribed"), forKey: "following")
        newTopic.setValue(sInstance.value(forKey: "path"), forKey: "path")
        newTopic.setValue(sInstance.value(forKey: "isMenuItem"), forKey: "showInMenu")
        newTopic.setValue(sInstance.value(forKey: "title"), forKey: "title")
        newTopic.setValue(ReaderDefaultTopic.TopicType, forKey: "type")

        // Associate the source and destination instances
        manager.associate(sourceInstance: sInstance, withDestinationInstance: newTopic, for: mapping)
    }

    override func createRelationships(forDestination dInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        // preserve no posts
        return
    }
}
