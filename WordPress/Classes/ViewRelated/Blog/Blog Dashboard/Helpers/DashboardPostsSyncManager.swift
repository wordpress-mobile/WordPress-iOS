import Foundation

protocol DashboardPostsSyncManagerListener: AnyObject {
    func postsSynced(success: Bool,
                     blog: Blog,
                     postType: DashboardPostsSyncManager.PostType,
                     posts: [AbstractPost]?,
                     for statuses: [String])
}

class DashboardPostsSyncManager {

    enum PostType {
        case post
        case page
    }

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
         blogService: BlogService = BlogService(coreDataStack: ContextManager.shared)) {
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

    func syncPosts(blog: Blog, postType: PostType, statuses: [String]) {
        let toBeSynced = postType.statusesNotBeingSynced(statuses, for: blog)
        guard toBeSynced.isEmpty == false else {
            return
        }

        postType.markStatusesAsBeingSynced(toBeSynced, for: blog)

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
                postType.stopSyncingStatuses(toBeSynced, for: blog)
                self?.syncPosts(blog: blog, postType: postType, statuses: toBeSynced)
            }, failure: { [weak self] error in
                postType.stopSyncingStatuses(toBeSynced, for: blog)
                self?.notifyListenersOfPostsSync(success: false, blog: blog, postType: postType, posts: nil, for: toBeSynced)
            })
            return
        }

        postService.syncPosts(ofType: postType.postServiceType, with: options, for: blog) { [weak self] posts in
            postType.stopSyncingStatuses(toBeSynced, for: blog)
            self?.notifyListenersOfPostsSync(success: true, blog: blog, postType: postType, posts: posts, for: toBeSynced)
        } failure: { [weak self] error in
            postType.stopSyncingStatuses(toBeSynced, for: blog)
            self?.notifyListenersOfPostsSync(success: false, blog: blog, postType: postType, posts: nil, for: toBeSynced)
        }
    }

    func syncAuthors(blog: Blog, success: @escaping SyncSuccessBlock, failure: @escaping SyncFailureBlock) {
        blogService.syncAuthors(for: blog, success: success, failure: failure)
    }

    // MARK: Private Helpers

    private func notifyListenersOfPostsSync(success: Bool,
                                            blog: Blog,
                                            postType: PostType,
                                            posts: [AbstractPost]?,
                                            for statuses: [String]) {
        for aListener in listeners {
            aListener.postsSynced(success: success, blog: blog, postType: postType, posts: posts, for: statuses)
        }
    }

    enum Constants {
        static let numberOfPostsToSync: NSNumber = 3
    }
}

private extension DashboardPostsSyncManager.PostType {
    var postServiceType: PostServiceType {
        switch self {
        case .post:
            return .post
        case .page:
            return .page
        }
    }

    func statusesNotBeingSynced(_ statuses: [String], for blog: Blog) -> [String] {
        var currentlySyncing: [String]
        switch self {
        case .post:
            currentlySyncing = blog.dashboardState.postsSyncingStatuses
        case .page:
            currentlySyncing = blog.dashboardState.pagesSyncingStatuses
        }
        let notCurrentlySyncing = statuses.filter({ !currentlySyncing.contains($0) })
        return notCurrentlySyncing
    }

    func markStatusesAsBeingSynced(_ toBeSynced: [String], for blog: Blog) {
        switch self {
        case .post:
            blog.dashboardState.postsSyncingStatuses.append(contentsOf: toBeSynced)
        case .page:
            blog.dashboardState.pagesSyncingStatuses.append(contentsOf: toBeSynced)
        }
    }

    func stopSyncingStatuses(_ statuses: [String], for blog: Blog) {
        switch self {
        case .post:
            blog.dashboardState.postsSyncingStatuses = blog.dashboardState.postsSyncingStatuses.filter({ !statuses.contains($0) })
        case .page:
            blog.dashboardState.pagesSyncingStatuses = blog.dashboardState.pagesSyncingStatuses.filter({ !statuses.contains($0) })
        }
    }
}
