import Foundation

class ReaderTopicToReaderListTopic37to38: NSEntityMigrationPolicy {
    override func createDestinationInstancesForSourceInstance(sInstance: NSManagedObject, entityMapping mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        // Only handle ReaderTopic entites that are lists
        let path = sInstance.valueForKey("path") as! NSString
        if path.rangeOfString("/list/").location == NSNotFound {
            return
        }

        // Create the destination ReaderTagTopic
        let newTopic = NSEntityDescription.insertNewObjectForEntityForName(ReaderListTopic.classNameWithoutNamespaces(),
            inManagedObjectContext: manager.destinationContext)

        // Update the destination topic's properties
        // Abstract
        newTopic.setValue(sInstance.valueForKey("isSubscribed"), forKey: "following")
        newTopic.setValue(sInstance.valueForKey("path"), forKey: "path")
        newTopic.setValue(sInstance.valueForKey("isMenuItem"), forKey: "showInMenu")
        newTopic.setValue(sInstance.valueForKey("title"), forKey: "title")
        newTopic.setValue(ReaderListTopic.TopicType, forKey: "type")

        // Entity Specific
        newTopic.setValue(sInstance.valueForKey("slug"), forKey: "slug")
        newTopic.setValue(sInstance.valueForKey("topicID"),forKey: "listID")

        // Associate the source and destination instances
        manager.associateSourceInstance(sInstance, withDestinationInstance: newTopic, forEntityMapping: mapping)
    }
    
    override func createRelationshipsForDestinationInstance(dInstance: NSManagedObject, entityMapping mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        // preserve no posts
        return
    }
}
