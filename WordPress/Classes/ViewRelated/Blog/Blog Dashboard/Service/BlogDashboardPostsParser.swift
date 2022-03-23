import Foundation
import CoreData

class BlogDashboardPostsParser {
    private let managedObjectContext: NSManagedObjectContext

    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    func parse(postsDictionary: NSDictionary, for blog: Blog) -> NSDictionary {
        guard let posts = postsDictionary.mutableCopy() as? NSMutableDictionary else {
            return postsDictionary
        }

        if !posts.hasDrafts {
            // Check for local drafts
            let fetchRequest = NSFetchRequest<Post>(entityName: String(describing: Post.self))
            fetchRequest.predicate = predicateForFetchRequest(PostListFilter.draftFilter().predicateForFetchRequest, blog: blog)
            fetchRequest.sortDescriptors = PostListFilter.draftFilter().sortDescriptors
            fetchRequest.fetchBatchSize = 3
            fetchRequest.fetchLimit = 3
            if let localDraftsCount = try? managedObjectContext.count(for: fetchRequest),
               localDraftsCount > 0 {
                posts["draft"] = [0...localDraftsCount].map { _ in [:] }
                print("$$ adding \(localDraftsCount) drafts")
            }
        }

        if !posts.hasScheduled {
            // Check for local scheduled
            let fetchRequest = NSFetchRequest<Post>(entityName: String(describing: Post.self))
            fetchRequest.predicate = predicateForFetchRequest(PostListFilter.scheduledFilter().predicateForFetchRequest, blog: blog)
            fetchRequest.sortDescriptors = PostListFilter.scheduledFilter().sortDescriptors
            fetchRequest.fetchBatchSize = 3
            fetchRequest.fetchLimit = 3
            if let localScheduledCount = try? managedObjectContext.count(for: fetchRequest),
               localScheduledCount > 0 {
                posts["scheduled"] = [0...localScheduledCount].map { _ in [:] }
                print("$$ adding \(localScheduledCount) scheduled")
            }
        }

        return posts
    }

    func predicateForFetchRequest(_ filterPredicate: NSPredicate, blog: Blog) -> NSPredicate {
        var predicates = [NSPredicate]()

        // Show all original posts without a revision & revision posts.
        let basePredicate = NSPredicate(format: "blog = %@ && revision = nil", blog)
        predicates.append(basePredicate)

        predicates.append(filterPredicate)

        if let myAuthorID = blog.userID {
            // Brand new local drafts have an authorID of 0.
            let authorPredicate = NSPredicate(format: "authorID = %@ || authorID = 0", myAuthorID)
            predicates.append(authorPredicate)
        }

       let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
       return predicate
    }
}

private extension NSDictionary {
    var hasDrafts: Bool {
        let draftsCount = (self["draft"] as? Array<Any>)?.count ?? 0
        return draftsCount > 0
    }

    var hasScheduled: Bool {
        let scheduledCount = (self["scheduled"] as? Array<Any>)?.count ?? 0
        return scheduledCount > 0
    }
}
