import Foundation

class BlogDashboardPostsInfo {
    var hasDrafts: Bool
    var hasScheduled: Bool
    var hasPublished: Bool

    var hasNoDraftsOrScheduled: Bool {
        return !hasDrafts && !hasScheduled
    }

    init(draftsCount: Int, scheduledCount: Int, hasPublished: Bool) {
        self.hasDrafts = draftsCount > 0
        self.hasScheduled = scheduledCount > 0
        self.hasPublished = hasPublished
    }

    static func create(from entity: BlogDashboardRemoteEntity?) -> BlogDashboardPostsInfo? {
        guard let entity = entity else {
            return nil
        }
        let draftsCount = entity.posts?.draft?.count ?? 0
        let scheduledCount = entity.posts?.scheduled?.count ?? 0
        let hasPublished = entity.posts?.hasPublished ?? true
        return BlogDashboardPostsInfo(draftsCount: draftsCount, scheduledCount: scheduledCount, hasPublished: hasPublished)
    }
}
