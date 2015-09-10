import Foundation

class ReaderTopicToReaderSiteTopic37to38: NSEntityMigrationPolicy {

    override func createDestinationInstancesForSourceInstance(sourceTopic: NSManagedObject, entityMapping mapping: NSEntityMapping, manager: NSMigrationManager, error: NSErrorPointer) -> Bool {
        // Preserve no site topics
        return true
    }

    override func createRelationshipsForDestinationInstance(newTopic: NSManagedObject, entityMapping mapping: NSEntityMapping, manager: NSMigrationManager, error: NSErrorPointer) -> Bool {
        // Preserve no posts.
        return true
    }
}
