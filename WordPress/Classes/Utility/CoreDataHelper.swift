import Foundation




// MARK: - Core Data Helpers
//
struct CoreDataHelper<T> where T: NSManagedObject, T: ManagedObject {
    /// CoreData ManagedObjectContext
    ///
    let context: NSManagedObjectContext


    /// Returns a new FetchRequest for the associated Entity
    ///
    func newFetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest(entityName: T.entityName)
    }


    /// Returns all of the entities that match with a given predicate.
    ///
    /// - Parameter predicate: Defines the conditions that any given object should meet. Optional.
    ///
    func allObjects(matchingPredicate predicate: NSPredicate? = nil, sortedBy descriptors: [NSSortDescriptor]? = nil)  -> [T] {
        let request = newFetchRequest()
        request.predicate = predicate
        request.sortDescriptors = descriptors

        return loadObjects(withFetchRequest: request)
    }

    /// Returns the number of entities found that match with a given predicate.
    ///
    /// - Parameter predicate: Defines the conditions that any given object should meet. Optional.
    ///
    func countObjects(matchingPredicate predicate: NSPredicate? = nil) -> Int {
        let request = newFetchRequest()
        request.predicate = predicate
        request.includesSubentities = false
        request.predicate = predicate
        request.resultType = .countResultType

        var result = 0

        do {
            result = try context.count(for: request)
        } catch {
            DDLogSwift.logError("Error counting objects [\(T.entityName)]: \(error)")
            assert(false)
        }

        return result
    }

    /// Deletes the specified Object Instance
    ///
    func deleteObject(_ object: T) {
        context.delete(object)
    }

    /// Deletes all of the NSMO instances associated to the current kind
    ///
    func deleteAllObjects() {
        let request = newFetchRequest()
        request.includesPropertyValues = false
        request.includesSubentities = false

        let objects = loadObjects(withFetchRequest: request)
        for object in objects {
            context.delete(object)
        }
    }

    /// Retrieves the first entity that matches with a given predicate
    ///
    /// - Parameter predicate: Defines the conditions that any given object should meet.
    ///
    func firstObject(matchingPredicate predicate: NSPredicate) -> T? {
        let request = newFetchRequest()
        request.predicate = predicate
        request.fetchLimit = 1

        let objects = loadObjects(withFetchRequest: request)
        return objects.first
    }

    /// Inserts a new Entity. For performance reasons, this helper *DOES NOT* persists the context.
    ///
    func insertNewObject() -> T {
        let name = T.entityName
        let entity = NSEntityDescription.insertNewObject(forEntityName: name, into: context)

        return entity as! T
    }

    /// Loads a single NSManagedObject instance, given its ObjectID, if available.
    ///
    /// - Parameter objectID: Unique Identifier of the entity to retrieve, if available.
    ///
    func loadObject(withObjectID objectID: NSManagedObjectID) -> T? {
        var result: T?

        do {
            result = try context.existingObject(with: objectID) as? T
        } catch {
            DDLogSwift.logError("Error loading Object [\(T.entityName)]")
        }

        return result
    }
}


// MARK: - Private Helpers
//
private extension CoreDataHelper {
    /// Loads the collection of entities that match with a given Fetch Request
    ///
    func loadObjects(withFetchRequest request: NSFetchRequest<NSFetchRequestResult>) -> [T] {
        var objects: [T]?

        do {
            objects = try context.fetch(request) as? [T]
        } catch {
            DDLogSwift.logError("Error loading Objects [\(T.entityName)")
            assert(false)
        }

        return objects ?? []
    }
}
