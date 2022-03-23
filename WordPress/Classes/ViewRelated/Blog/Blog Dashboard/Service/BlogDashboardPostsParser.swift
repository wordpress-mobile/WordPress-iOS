import Foundation
import CoreData

class BlogDashboardPostsParser {
    private let managedObjectContext: NSManagedObjectContext

    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    /// Parse the posts data that comes from the API
    /// We might run into cases where the API returns that there are no
    /// drafts and/or scheduled posts, however the user might have
    /// they locally.
    /// This parser basically looks in the local content and fixes the data
    /// if needed.
    func parse(_ postsDictionary: NSDictionary, for blog: Blog) -> NSDictionary {
        guard let posts = postsDictionary.mutableCopy() as? NSMutableDictionary else {
            return postsDictionary
        }

        if !posts.hasDrafts {
            // Check for local drafts
            if let localDraftsCount = numberOfPosts(for: blog, filter: PostListFilter.draftFilter()),
               localDraftsCount > 0 {
                posts["draft"] = [0...localDraftsCount].map { _ in [:] }
            }
        }

        if !posts.hasScheduled {
            // Check for local scheduled
            if let localScheduledCount = numberOfPosts(for: blog, filter: PostListFilter.scheduledFilter()),
               localScheduledCount > 0 {
                posts["scheduled"] = [0...localScheduledCount].map { _ in [:] }
            }
        }

        return posts
    }

    private func numberOfPosts(for blog: Blog, filter: PostListFilter) -> Int? {
        let fetchRequest = NSFetchRequest<Post>(entityName: String(describing: Post.self))
        fetchRequest.predicate = filter.predicate(for: blog)
        fetchRequest.sortDescriptors = filter.sortDescriptors
        fetchRequest.fetchBatchSize = 1
        fetchRequest.fetchLimit = 1
        return try? managedObjectContext.count(for: fetchRequest)
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
