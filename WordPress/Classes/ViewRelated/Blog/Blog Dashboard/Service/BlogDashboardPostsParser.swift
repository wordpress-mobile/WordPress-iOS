import Foundation
import CoreData

class BlogDashboardPostsParser {
    private let managedObjectContext: NSManagedObjectContext

    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    func parse(_ postsDictionary: NSDictionary, for blog: Blog) -> NSDictionary {
        guard let posts = postsDictionary.mutableCopy() as? NSMutableDictionary else {
            return postsDictionary
        }

        if !posts.hasDrafts {
            // Check for local drafts
            let fetchRequest = NSFetchRequest<Post>(entityName: String(describing: Post.self))
            fetchRequest.predicate = PostListFilter.draftFilter().predicate(for: blog)
            fetchRequest.sortDescriptors = PostListFilter.draftFilter().sortDescriptors
            fetchRequest.fetchBatchSize = 1
            fetchRequest.fetchLimit = 1
            if let localDraftsCount = try? managedObjectContext.count(for: fetchRequest),
               localDraftsCount > 0 {
                posts["draft"] = [0...localDraftsCount].map { _ in [:] }
                print("$$ adding \(localDraftsCount) drafts")
            }
        }

        if !posts.hasScheduled {
            // Check for local scheduled
            let fetchRequest = NSFetchRequest<Post>(entityName: String(describing: Post.self))
            fetchRequest.predicate = PostListFilter.scheduledFilter().predicate(for: blog)
            fetchRequest.sortDescriptors = PostListFilter.scheduledFilter().sortDescriptors
            fetchRequest.fetchBatchSize = 1
            fetchRequest.fetchLimit = 1
            if let localScheduledCount = try? managedObjectContext.count(for: fetchRequest),
               localScheduledCount > 0 {
                posts["scheduled"] = [0...localScheduledCount].map { _ in [:] }
                print("$$ adding \(localScheduledCount) scheduled")
            }
        }

        return posts
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
