/// Static helpers for Reader actions
struct ReaderActionHelpers {
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

    static func postInMainContext(_ post: ReaderPost) -> ReaderPost? {
        guard let post = (try? ContextManager.sharedInstance().mainContext.existingObject(with: post.objectID)) as? ReaderPost else {
            DDLogError("Error retrieving an exsting post from the main context by its object ID.")
            return nil
        }
        return post
    }
}
