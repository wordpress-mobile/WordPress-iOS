import Foundation

class ReaderPostToReaderPost37to38: NSEntityMigrationPolicy {

    override func createDestinationInstancesForSourceInstance(sourcePost: NSManagedObject, entityMapping mapping: NSEntityMapping, manager: NSMigrationManager, error: NSErrorPointer) -> Bool {
        // Preserve no reader posts.
        return true
    }

    override func createRelationshipsForDestinationInstance(newPost: NSManagedObject, entityMapping mapping: NSEntityMapping, manager: NSMigrationManager, error: NSErrorPointer) -> Bool {
        // Preserve no reader posts.
        return true
    }
}
