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

        if let localDraftsCount = numberOfPosts(for: blog, filter: PostListFilter.draftFilter()) {
            if blog.dashboardState.draftsSynced { // If drafts are synced, depend on local data
                posts["draft"] = Array(repeatElement([:], count: localDraftsCount))
            }
            else { // If drafts are not synced, only depend on local data if the cards API returns zero posts
                if !posts.hasDrafts, localDraftsCount > 0 {
                    posts["draft"] = Array(repeatElement([:], count: localDraftsCount))
                }
            }
        }

        if let localScheduledCount = numberOfPosts(for: blog, filter: PostListFilter.scheduledFilter()) {
            if blog.dashboardState.scheduledSynced { // If scheduled posts are synced, depend on local data
                posts["scheduled"] = Array(repeatElement([:], count: localScheduledCount))
            }
            else { // If scheduled posts are not synced, only depend on local data if the cards API returns zero posts
                if !posts.hasScheduled, localScheduledCount > 0 {
                    posts["scheduled"] = Array(repeatElement([:], count: localScheduledCount))
                }
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
