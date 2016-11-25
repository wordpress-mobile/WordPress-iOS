import Foundation

@objc class ReaderPostCacheProvider: NSObject {

    private enum ReaderPostType {

        case normal
        case cross
        case attribution

        static let allTypes = [normal, cross, attribution]
    }

    let context: NSManagedObjectContext
    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func getPostByID(postID: Int, siteID: Int) -> ReaderPost? {

        for type in ReaderPostType.allTypes {
            if let post = getPostByID(postID, siteID: siteID, type: type) {
                return post
            }
        }

        return nil
    }

    private func getPostByID(postID: Int, siteID: Int, type: ReaderPostType) -> ReaderPost? {

        let fetchRequest = searchPostRequestForID(postID, siteID: siteID, type: type)
        var post: ReaderPost? = nil

        do {

            let results = try context.executeFetchRequest(fetchRequest)
            post = results.first as? ReaderPost

        } catch {
            DDLogSwift.logError("Error fetching post from database")
        }

        return post
    }

    private func searchPostRequestForID(postID: Int, siteID: Int, type: ReaderPostType) -> NSFetchRequest {
        let fetchRequest = NSFetchRequest(entityName: "ReaderPost")
        fetchRequest.predicate = searchPostPredicateForID(postID, siteID: siteID, type: type)
        return fetchRequest
    }

    private func searchPostPredicateForID(postID: Int, siteID: Int, type: ReaderPostType) -> NSPredicate {

        var predicateFormat: String
        switch type {
        case .normal:
            predicateFormat = "postID = %d AND siteID = %d"
        case .cross:
            predicateFormat = "sourceAttribution.postID = %d AND sourceAttribution.blogID = %d"
        case .attribution:
            predicateFormat = "crossPostMeta.postID = %d AND crossPostMeta.siteID = %d"
        }

        let predicate = NSPredicate(format:predicateFormat, postID, siteID)
        return predicate
    }
}
