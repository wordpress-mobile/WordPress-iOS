import Foundation

@objc open class ReaderSearchTopic: ReaderAbstractTopic {
    override open class var TopicType: String {
        return "search"
    }

    open override var posts: [ReaderPost] {
        set {}
        get {
            if let context = managedObjectContext {
                let savedPostsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderPost.classNameWithoutNamespaces())
                savedPostsRequest.predicate = NSPredicate(format: "isSavedForLater = %@", NSNumber(value: true))
                guard let results = (try? context.fetch(savedPostsRequest)) as? [ReaderPost] else {
                    return []
                }

                return results
            }

            return []
        }
    }
}
