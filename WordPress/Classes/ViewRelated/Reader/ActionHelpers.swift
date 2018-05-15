struct ActionHelpers {
    static func existingObject<T>(for objectID: NSManagedObjectID?, in context: NSManagedObjectContext) -> T? {
        guard let objectID = objectID else {
            return nil
        }

        do {
            return (try context.existingObject(with: objectID)) as? T
        } catch let error as NSError {
            DDLogError(error.localizedDescription)
            return nil
        }
    }
}
