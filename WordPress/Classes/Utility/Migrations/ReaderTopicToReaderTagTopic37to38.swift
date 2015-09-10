import Foundation

class ReaderTopicToReaderTagTopic37to38: NSEntityMigrationPolicy {

    override func createDestinationInstancesForSourceInstance(sInstance: NSManagedObject, entityMapping mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        // Only handle ReaderTopic entites that are tags
        let path = sInstance.valueForKey("path") as! NSString
        if path.rangeOfString("/tags/").location == NSNotFound {
            return
        }

        // Create the destination ReaderTagTopic
        let newTopic = NSEntityDescription.insertNewObjectForEntityForName(ReaderTagTopic.classNameWithoutNamespaces(),
            inManagedObjectContext: manager.destinationContext)

        // Update the destination topic's properties
        // Abstract
        newTopic.setValue(sInstance.valueForKey("isSubscribed"), forKey: "following")
        newTopic.setValue(sInstance.valueForKey("path"), forKey: "path")
        newTopic.setValue(sInstance.valueForKey("isMenuItem"), forKey: "showInMenu")
        newTopic.setValue(sInstance.valueForKey("title"), forKey: "title")
        newTopic.setValue(ReaderTagTopic.TopicType, forKey: "type")

        // Entity Specific
        newTopic.setValue(sInstance.valueForKey("isRecommended"), forKey: "isRecommended")
        newTopic.setValue(sInstance.valueForKey("slug"), forKey: "slug")
        newTopic.setValue(sInstance.valueForKey("topicID"),forKey: "tagID")

        // Associate the source and destination instances
        manager.associateSourceInstance(sInstance, withDestinationInstance: newTopic, forEntityMapping: mapping)

        return
    }

    override func createRelationshipsForDestinationInstance(dInstance: NSManagedObject, entityMapping mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        // Preserve no posts
        return
    }
}
