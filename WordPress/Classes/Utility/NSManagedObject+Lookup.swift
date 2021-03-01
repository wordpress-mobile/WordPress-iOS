import CoreData

extension NSManagedObject {

    /// Lookup an object by its NSManagedObjectID
    ///
    /// - Parameters:
    ///   - objectID: The `NSManagedObject` subclass' objectID as defined by Core Data.
    ///   - context:  An NSManagedObjectContext that contains the associated object.
    /// - Returns: The `NSManagedObject` subclass associated with the given `objectID`, if it exists.
    static func lookup(withObjectID objectID: NSManagedObjectID, in context: NSManagedObjectContext) -> Self? {
        return try? context.existingObject(with: objectID) as? Self
    }
}
