import Foundation

class ReaderTopicToReaderSiteTopic37to38: NSEntityMigrationPolicy {

    override func createDestinationInstancesForSourceInstance(sInstance: NSManagedObject, entityMapping mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        // Preserve no site topics
        return
    }

    override func createRelationshipsForDestinationInstance(dInstance: NSManagedObject, entityMapping mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        // Preserve no posts.
        return
    }
}
