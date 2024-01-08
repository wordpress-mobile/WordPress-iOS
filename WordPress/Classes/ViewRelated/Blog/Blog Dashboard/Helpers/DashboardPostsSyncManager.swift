import Foundation

protocol DashboardPostsSyncManagerListener: AnyObject {
    func postsSynced(success: Bool,
                     blog: Blog,
                     postType: DashboardPostsSyncManager.PostType,
                     for statuses: [BasePost.Status])
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

    private let postRepository: PostRepository
    private let blogService: BlogService
    @Atomic private var listeners: [DashboardPostsSyncManagerListener] = []

    // MARK: Shared Instance

    static let shared = DashboardPostsSyncManager()

    // MARK: Initializer

    init(postRepository: PostRepository = PostRepository(coreDataStack: ContextManager.shared),
         blogService: BlogService = BlogService(coreDataStack: ContextManager.shared)) {
        self.postRepository = postRepository
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

    func syncPosts(blog: Blog, postType: PostType, statuses: [BasePost.Status]) {
        let toBeSynced = postType.statusesNotBeingSynced(statuses, for: blog)
        guard toBeSynced.isEmpty == false else {
            return
        }

        postType.markStatusesAsBeingSynced(toBeSynced, for: blog)

        // If the userID is nil we need to sync authors
        // But only if the user is an admin
        if blog.userID == nil && blog.isAdmin {
            syncAuthors(blog: blog, success: { [weak self] in
                postType.stopSyncingStatuses(toBeSynced, for: blog)
                self?.syncPosts(blog: blog, postType: postType, statuses: toBeSynced)
            }, failure: { [weak self] error in
                postType.stopSyncingStatuses(toBeSynced, for: blog)
                self?.notifyListenersOfPostsSync(success: false, blog: blog, postType: postType, for: toBeSynced)
            })
            return
        }

        Task { @MainActor [weak self, postRepository, authorID = blog.userID, blogID = TaggedManagedObjectID(blog)] in
            let success: Bool
            do {
                _ = try await postRepository.search(
                    type: postType == .post ? Post.self : Page.self,
                    input: nil,
                    statuses: toBeSynced,
                    tag: nil,
                    authorUserID: authorID,
                    offset: 0,
                    limit: Constants.numberOfPostsToSync,
                    orderBy: .byModified,
                    descending: true,
                    in: blogID
                )
                success = true
            } catch {
                success = false
            }

            postType.stopSyncingStatuses(toBeSynced, for: blog)
            self?.notifyListenersOfPostsSync(success: success, blog: blog, postType: postType, for: toBeSynced)
        }
    }

    func syncAuthors(blog: Blog, success: @escaping SyncSuccessBlock, failure: @escaping SyncFailureBlock) {
        blogService.syncAuthors(for: blog, success: success, failure: failure)
    }

    // MARK: Private Helpers

    private func notifyListenersOfPostsSync(success: Bool,
                                            blog: Blog,
                                            postType: PostType,
                                            for statuses: [BasePost.Status]) {
        for aListener in listeners {
            aListener.postsSynced(success: success, blog: blog, postType: postType, for: statuses)
        }
    }

    enum Constants {
        static let numberOfPostsToSync: Int = 3
    }
}

private extension DashboardPostsSyncManager.PostType {
    func statusesNotBeingSynced(_ statuses: [BasePost.Status], for blog: Blog) -> [BasePost.Status] {
        var currentlySyncing: [BasePost.Status]
        switch self {
        case .post:
            currentlySyncing = blog.dashboardState.postsSyncingStatuses
        case .page:
            currentlySyncing = blog.dashboardState.pagesSyncingStatuses
        }
        let notCurrentlySyncing = statuses.filter({ !currentlySyncing.contains($0) })
        return notCurrentlySyncing
    }

    func markStatusesAsBeingSynced(_ toBeSynced: [BasePost.Status], for blog: Blog) {
        switch self {
        case .post:
            blog.dashboardState.postsSyncingStatuses.append(contentsOf: toBeSynced)
        case .page:
            blog.dashboardState.pagesSyncingStatuses.append(contentsOf: toBeSynced)
        }
    }

    func stopSyncingStatuses(_ statuses: [BasePost.Status], for blog: Blog) {
        switch self {
        case .post:
            blog.dashboardState.postsSyncingStatuses = blog.dashboardState.postsSyncingStatuses.filter({ !statuses.contains($0) })
        case .page:
            blog.dashboardState.pagesSyncingStatuses = blog.dashboardState.pagesSyncingStatuses.filter({ !statuses.contains($0) })
        }
    }
}
