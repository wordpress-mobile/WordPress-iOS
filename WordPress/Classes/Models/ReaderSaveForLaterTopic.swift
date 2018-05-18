@objc class ReaderSaveForLaterTopic: ReaderAbstractTopic {
    override open class var TopicType: String {
        return "saveForLater"
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
