import Foundation

class ReaderTopicToReaderDefaultTopic37to38: NSEntityMigrationPolicy {

    override func createDestinationInstancesForSourceInstance(sInstance: NSManagedObject, entityMapping mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        // Only handle ReaderTopic entites that are defaults
        let path = sInstance.valueForKey("path") as! NSString
        if path.rangeOfString("/list/").location != NSNotFound ||
            path.rangeOfString("/tags/").location != NSNotFound ||
            path.rangeOfString("/site/").location != NSNotFound {
            return
        }

        // Create the destination ReaderTagTopic
        let newTopic = NSEntityDescription.insertNewObjectForEntityForName(ReaderDefaultTopic.classNameWithoutNamespaces(),
            inManagedObjectContext: manager.destinationContext)

        // Update the destination topic's properties
        // Abstract
        newTopic.setValue(sInstance.valueForKey("isSubscribed"), forKey: "following")
        newTopic.setValue(sInstance.valueForKey("path"), forKey: "path")
        newTopic.setValue(sInstance.valueForKey("isMenuItem"), forKey: "showInMenu")
        newTopic.setValue(sInstance.valueForKey("title"), forKey: "title")
        newTopic.setValue(ReaderDefaultTopic.TopicType, forKey: "type")

        // Associate the source and destination instances
        manager.associateSourceInstance(sInstance, withDestinationInstance: newTopic, forEntityMapping: mapping)
    }

    override func createRelationshipsForDestinationInstance(dInstance: NSManagedObject, entityMapping mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        // preserve no posts
        return
    }
}
