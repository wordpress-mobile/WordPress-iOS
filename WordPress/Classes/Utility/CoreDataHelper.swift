import Foundation


// MARK: - NSManagedObject Default entityName Helper
//
extension NSManagedObject {

    /// Returns the Entity Name, if available, as specified in the NSEntityDescription. Otherwise, will return
    /// the subclass name.
    ///
    /// Note: entity().name returns nil as per iOS 10, in Unit Testing Targets. Awesome.
    ///
    class var entityName: String {
        return entity().name ?? classNameWithoutNamespaces()
    }

    /// Returns a NSFetchRequest instance with it's *Entity Name* always set.
    ///
    /// Note: entity().name returns nil as per iOS 10, in Unit Testing Targets. Awesome.
    ///
    class func safeFetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        guard entity().name == nil else {
            return fetchRequest()
        }

        return NSFetchRequest(entityName: entityName)
    }
}


// MARK: - NSManagedObjectContext Helpers!
//
extension NSManagedObjectContext {

    /// Returns all of the entities that match with a given predicate.
    ///
    /// - Parameter predicate: Defines the conditions that any given object should meet. Optional.
    ///
    func allObjects<T: NSManagedObject>(ofType type: T.Type, matching predicate: NSPredicate? = nil, sortedBy descriptors: [NSSortDescriptor]? = nil) -> [T] {
        let request = T.safeFetchRequest()
        request.predicate = predicate
        request.sortDescriptors = descriptors

        return loadObjects(ofType: type, with: request)
    }


    /// Returns the number of entities found that match with a given predicate.
    ///
    /// - Parameter predicate: Defines the conditions that any given object should meet. Optional.
    ///
    func countObjects<T: NSManagedObject>(ofType type: T.Type, matching predicate: NSPredicate? = nil) -> Int {
        let request = T.safeFetchRequest()
        request.includesSubentities = false
        request.predicate = predicate
        request.resultType = .countResultType

        var result = 0

        do {
            result = try count(for: request)
        } catch {
            DDLogSwift.logError("Error counting objects [\(T.entityName)]: \(error)")
            assertionFailure()
        }

        return result
    }

    /// Deletes the specified Object Instance
    ///
    func deleteObject<T: NSManagedObject>(_ object: T) {
        delete(object)
    }

    /// Deletes all of the NSMO instances associated to the current kind
    ///
    func deleteAllObjects<T: NSManagedObject>(ofType type: T.Type) {
        let request = T.safeFetchRequest()
        request.includesPropertyValues = false
        request.includesSubentities = false

        for object in loadObjects(ofType: type, with: request) {
            delete(object)
        }
    }

    /// Retrieves the first entity that matches with a given predicate
    ///
    /// - Parameter predicate: Defines the conditions that any given object should meet.
    ///
    func firstObject<T: NSManagedObject>(ofType type: T.Type, matching predicate: NSPredicate) -> T? {
        let request = T.safeFetchRequest()
        request.predicate = predicate
        request.fetchLimit = 1

        return loadObjects(ofType: type, with: request).first
    }

    /// Inserts a new Entity. For performance reasons, this helper *DOES NOT* persists the context.
    ///
    func insertNewObject<T: NSManagedObject>(ofType type: T.Type) -> T {
        return NSEntityDescription.insertNewObject(forEntityName: T.entityName, into: self) as! T
    }

    /// Loads a single NSManagedObject instance, given its ObjectID, if available.
    ///
    /// - Parameter objectID: Unique Identifier of the entity to retrieve, if available.
    ///
    func loadObject<T: NSManagedObject>(ofType type: T.Type, with objectID: NSManagedObjectID) -> T? {
        var result: T?

        do {
            result = try existingObject(with: objectID) as? T
        } catch {
            DDLogSwift.logError("Error loading Object [\(T.entityName)]")
        }

        return result
    }

    /// Loads the collection of entities that match with a given Fetch Request
    ///
    private func loadObjects<T: NSManagedObject>(ofType type: T.Type, with request: NSFetchRequest<NSFetchRequestResult>) -> [T] {
        var objects: [T]?

        do {
            objects = try fetch(request) as? [T]
        } catch {
            DDLogSwift.logError("Error loading Objects [\(T.entityName)")
            assertionFailure()
        }

        return objects ?? []
    }
}
