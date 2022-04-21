import Foundation

protocol DashboardPostsSyncManagerListener: AnyObject {
    func postsSynced(success: Bool, blog: Blog, posts: [AbstractPost]?, for statuses: [String])
}

class DashboardPostsSyncManager {

    // MARK: Type Aliases

    typealias SyncSuccessBlock = () -> Void
    typealias SyncFailureBlock = (Error?) -> Void

    // MARK: Private Variables

    private let postService: PostService
    private let blogService: BlogService
    @Atomic private var listeners: [DashboardPostsSyncManagerListener] = []

    // MARK: Shared Instance

    static let shared = DashboardPostsSyncManager()

    // MARK: Initializer

    init(postService: PostService = PostService(managedObjectContext: ContextManager.shared.mainContext),
         blogService: BlogService = BlogService(managedObjectContext: ContextManager.shared.mainContext)) {
        self.postService = postService
        self.blogService = blogService
    }

    // MARK: Public Functions

    func addListener(_ listener: DashboardPostsSyncManagerListener) {
        listeners.append(listener)
    }

    func removeListener(_ listener: DashboardPostsSyncManagerListener) {
        if let index = listeners.firstIndex(where: {$0 === listener}) {
            listeners.remove(at: index)
        }
    }

    func syncPosts(blog: Blog, statuses: [String]) {
        let toBeSynced = statusesNotBeingSynced(statuses, for: blog)
        guard toBeSynced.isEmpty == false else {
            return
        }

        blog.dashboardState.syncingStatuses.append(contentsOf: toBeSynced)

        let options = PostServiceSyncOptions()
        options.statuses = toBeSynced
        options.authorID = blog.userID
        options.number = Constants.numberOfPostsToSync
        options.order = .descending
        options.orderBy = .byModified
        options.purgesLocalSync = true

        // If the userID is nil we need to sync authors
        // But only if the user is an admin
        if blog.userID == nil && blog.isAdmin {
            syncAuthors(blog: blog, success: { [weak self] in
                self?.stopSyncingStatuses(toBeSynced, for: blog)
                self?.syncPosts(blog: blog, statuses: toBeSynced)
            }, failure: { [weak self] error in
                self?.stopSyncingStatuses(toBeSynced, for: blog)
                self?.notifyListenersOfPostsSync(success: false, blog: blog, posts: nil, for: toBeSynced)
            })
            return
        }

        postService.syncPosts(ofType: .post, with: options, for: blog) { [weak self] posts in
            self?.stopSyncingStatuses(toBeSynced, for: blog)
            self?.notifyListenersOfPostsSync(success: true, blog: blog, posts: posts, for: toBeSynced)
        } failure: { [weak self] error in
            self?.stopSyncingStatuses(toBeSynced, for: blog)
            self?.notifyListenersOfPostsSync(success: false, blog: blog, posts: nil, for: toBeSynced)
        }
    }

    func syncAuthors(blog: Blog, success: @escaping SyncSuccessBlock, failure: @escaping SyncFailureBlock) {
        blogService.syncAuthors(for: blog, success: success, failure: failure)
    }

    // MARK: Private Helpers

    private func notifyListenersOfPostsSync(success: Bool, blog: Blog, posts: [AbstractPost]?, for statuses: [String]) {
        for aListener in listeners {
            aListener.postsSynced(success: success, blog: blog, posts: posts, for: statuses)
        }
    }

    private func statusesNotBeingSynced(_ statuses: [String], for blog: Blog) -> [String] {
        let currentlySyncing = blog.dashboardState.syncingStatuses
        let notCurrentlySyncing = statuses.filter({ !currentlySyncing.contains($0) })
        return notCurrentlySyncing
    }

    private func stopSyncingStatuses(_ statuses: [String], for blog: Blog) {
        blog.dashboardState.syncingStatuses = blog.dashboardState.syncingStatuses.filter({ !statuses.contains($0) })
    }

    enum Constants {
        static let numberOfPostsToSync: NSNumber = 3
    }
}
