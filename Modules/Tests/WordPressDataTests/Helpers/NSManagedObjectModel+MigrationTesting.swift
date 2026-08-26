import CoreData

extension NSManagedObjectModel {
    /// Resets every entity's managed object class to the generic `NSManagedObject`.
    ///
    /// Historical schema versions all define the same `NSManagedObject` subclasses (`Blog`,
    /// `Post`, ...). Core Data registers each loaded model's entities in a single process-global
    /// class-to-entity table, and the unit tests all run in one process. Loading more than one
    /// model that claims the same subclass leaves `+[NSManagedObject entity]` unable to resolve a
    /// unique match, which crashes unrelated Core Data tests depending on execution order.
    ///
    /// Migration tests only reach their data by entity name and key-value coding, so dropping the
    /// concrete class association keeps them working while preventing the duplicate registration.
    /// Call this right after loading a historical (non-current) model, before attaching it to a
    /// coordinator.
    func neutralizingEntityClasses() -> NSManagedObjectModel {
        for entity in entities {
            entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        }
        return self
    }
}
