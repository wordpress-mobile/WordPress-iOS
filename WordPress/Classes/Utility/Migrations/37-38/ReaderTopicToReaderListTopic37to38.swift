import Foundation

class ReaderTopicToReaderListTopic37to38: NSEntityMigrationPolicy {
    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        // Only handle ReaderTopic entites that are lists
        let path = sInstance.value(forKey: "path") as! NSString
        if path.range(of: "/list/").location == NSNotFound {
            return
        }

        // Create the destination ReaderTagTopic
        let newTopic = NSEntityDescription.insertNewObject(forEntityName: ReaderListTopic.classNameWithoutNamespaces(),
            into: manager.destinationContext)

        // Update the destination topic's properties
        // Abstract
        newTopic.setValue(sInstance.value(forKey: "isSubscribed"), forKey: "following")
        newTopic.setValue(sInstance.value(forKey: "path"), forKey: "path")
        newTopic.setValue(sInstance.value(forKey: "isMenuItem"), forKey: "showInMenu")
        newTopic.setValue(sInstance.value(forKey: "title"), forKey: "title")
        newTopic.setValue(ReaderListTopic.TopicType, forKey: "type")

        // Entity Specific
        newTopic.setValue(sInstance.value(forKey: "slug"), forKey: "slug")
        newTopic.setValue(sInstance.value(forKey: "topicID"), forKey: "listID")

        // Associate the source and destination instances
        manager.associate(sourceInstance: sInstance, withDestinationInstance: newTopic, for: mapping)
    }

    override func createRelationships(forDestination dInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        // preserve no posts
        return
    }
}
