import Foundation

class ReaderTopicToReaderTagTopic37to38: NSEntityMigrationPolicy {

    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        // Only handle ReaderTopic entites that are tags
        let path = sInstance.value(forKey: "path") as! NSString
        if path.range(of: "/tags/").location == NSNotFound {
            return
        }

        // Create the destination ReaderTagTopic
        let newTopic = NSEntityDescription.insertNewObject(forEntityName: ReaderTagTopic.classNameWithoutNamespaces(),
            into: manager.destinationContext)

        // Update the destination topic's properties
        // Abstract
        newTopic.setValue(sInstance.value(forKey: "isSubscribed"), forKey: "following")
        newTopic.setValue(sInstance.value(forKey: "path"), forKey: "path")
        newTopic.setValue(sInstance.value(forKey: "isMenuItem"), forKey: "showInMenu")
        newTopic.setValue(sInstance.value(forKey: "title"), forKey: "title")
        newTopic.setValue(ReaderTagTopic.TopicType, forKey: "type")

        // Entity Specific
        newTopic.setValue(sInstance.value(forKey: "isRecommended"), forKey: "isRecommended")
        newTopic.setValue(sInstance.value(forKey: "slug"), forKey: "slug")
        newTopic.setValue(sInstance.value(forKey: "topicID"), forKey: "tagID")

        // Associate the source and destination instances
        manager.associate(sourceInstance: sInstance, withDestinationInstance: newTopic, for: mapping)

        return
    }

    override func createRelationships(forDestination dInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        // Preserve no posts
        return
    }
}
