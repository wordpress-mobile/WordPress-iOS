import Foundation

@objc class ReaderPostCacheProvider: NSObject {

    let context: NSManagedObjectContext
    init(context: NSManagedObjectContext) {
        self.context = context
    }

    /**
     Gets an stored ReaderPost from the local database, it searches for an Original Post,
     a SourceAttribution Post or a Cross Post.

     - Parameters:
        - postID: the postID of the post to fetch
        - siteID: the siteID of the post to fetch, can be a blogID if it has source attribution information

     - Returns: A ReaderPost object if it is cached localy or nil if not found
     */
    func getPostByID(postID: Int, siteID: Int) -> ReaderPost? {

        let fetchRequest = searchPostRequestForID(postID, siteID: siteID)
        var post: ReaderPost? = nil

        do {

            let results = try context.executeFetchRequest(fetchRequest)
            post = suitablePostFromPosts(results)

        } catch {
            DDLogSwift.logError("Error fetching post from database")
        }

        return post
    }

    // This functions checks from a multiple cachedPosts the original one and returns it
    // If it can't find one, then returns the first one.
    private func suitablePostFromPosts(posts: [AnyObject]?) -> ReaderPost? {

        guard let cachedPosts = posts as? [ReaderPost] else {
            return nil
        }

        let originalPosts = cachedPosts.filter { $0.sourceAttribution == nil }
        return originalPosts.first ?? cachedPosts.first
    }

    private func searchPostRequestForID(postID: Int, siteID: Int) -> NSFetchRequest {
        let fetchRequest = NSFetchRequest(entityName: "ReaderPost")
        fetchRequest.predicate = searchPostPredicateForID(postID, siteID: siteID)
        return fetchRequest
    }

    private func searchPostPredicateForID(postID: Int, siteID: Int) -> NSPredicate {

        let subPredicates = [originalPredicateWithPostID(postID, siteID: siteID),
                             crossPredicateWithPostID(postID, siteID: siteID),
                             attributionPredicateWithPostID(postID, blogID: siteID)]
        return NSCompoundPredicate(orPredicateWithSubpredicates: subPredicates)
    }

    private func originalPredicateWithPostID(postID: Int, siteID: Int) -> NSPredicate {
        return NSPredicate(format: "postID = %d AND siteID = %d AND sourceAttribution = NULL", postID, siteID)
    }

    private func attributionPredicateWithPostID(postID: Int, blogID: Int) -> NSPredicate {
        return NSPredicate(format: "sourceAttribution.postID = %d AND sourceAttribution.blogID = %d", postID, blogID)
    }

    private func crossPredicateWithPostID(postID: Int, siteID: Int) -> NSPredicate {
        return NSPredicate(format: "crossPostMeta.postID = %d AND crossPostMeta.siteID = %d", postID, siteID)
    }
}
