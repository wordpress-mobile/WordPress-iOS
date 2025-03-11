import CoreData
import CocoaLumberjackSwift

// TODO: How to we test this?
public extension NSManagedObject {

    /// Lookup an object by its NSManagedObjectID
    ///
    /// - Parameters:
    ///   - objectID: The `NSManagedObject` subclass' objectID as defined by Core Data.
    ///   - context:  An NSManagedObjectContext that contains the associated object.
    /// - Returns: The `NSManagedObject` subclass associated with the given `objectID`, if it exists.
    static func lookup(withObjectID objectID: NSManagedObjectID, in context: NSManagedObjectContext) -> Self? {
        DDLogInfo("Dummy log to test CocoaLumberjack import") // FIXME: Remove once we have a legit usage
        return try? context.existingObject(with: objectID) as? Self
    }
}
