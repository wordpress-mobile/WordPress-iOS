import Foundation

class ReaderTopicToReaderTagTopic37to38: NSEntityMigrationPolicy {

    override func createDestinationInstancesForSourceInstance(sourceTopic: NSManagedObject, entityMapping mapping: NSEntityMapping, manager: NSMigrationManager, error: NSErrorPointer) -> Bool {
        // Only handle ReaderTopic entites that are tags
        let path = sourceTopic.valueForKey("path") as! NSString
        if path.rangeOfString("/tags/").location == NSNotFound {
            return true
        }

        // Create the destination ReaderTagTopic
        let newTopic = NSEntityDescription.insertNewObjectForEntityForName(ReaderTagTopic.classNameWithoutNamespaces(),
            inManagedObjectContext: manager.destinationContext) as! NSManagedObject

        // Update the destination topic's properties
        // Abstract
        newTopic.setValue(sourceTopic.valueForKey("isSubscribed"), forKey: "following")
        newTopic.setValue(sourceTopic.valueForKey("path"), forKey: "path")
        newTopic.setValue(sourceTopic.valueForKey("isMenuItem"), forKey: "showInMenu")
        newTopic.setValue(sourceTopic.valueForKey("title"), forKey: "title")
        newTopic.setValue(ReaderTagTopic.TopicType, forKey: "type")

        // Entity Specific
        newTopic.setValue(sourceTopic.valueForKey("isRecommended"), forKey: "isRecommended")
        newTopic.setValue(sourceTopic.valueForKey("slug"), forKey: "slug")
        newTopic.setValue(sourceTopic.valueForKey("topicID"),forKey: "tagID")

        // Associate the source and destination instances
        manager.associateSourceInstance(sourceTopic, withDestinationInstance: newTopic, forEntityMapping: mapping)

        return true
    }

    override func createRelationshipsForDestinationInstance(newTopic: NSManagedObject, entityMapping mapping: NSEntityMapping, manager: NSMigrationManager, error: NSErrorPointer) -> Bool {
        // Preserve no posts
        return true
    }
}
