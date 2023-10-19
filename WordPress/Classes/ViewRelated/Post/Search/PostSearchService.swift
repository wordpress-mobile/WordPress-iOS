import Foundation
import CoreData

protocol PostSearchServiceDelegate: AnyObject {
    func service(_ service: PostSearchService, didAppendPosts page: [AbstractPost])
    func serviceDidUpdateState(_ service: PostSearchService)
}

/// Loads post search results with pagination.
final class PostSearchService {
    private(set) var isLoading = false
    private(set) var error: Error?

    weak var delegate: PostSearchServiceDelegate?

    private let blog: Blog
    private let settings: PostListFilterSettings
    private let criteria: PostSearchCriteria
    private let coreDataStack: CoreDataStack

    private var postIDs: Set<NSManagedObjectID> = []
    private var offset = 0
    private var hasMore = true

    init(blog: Blog,
         settings: PostListFilterSettings,
         criteria: PostSearchCriteria,
         coreDataStack: CoreDataStack = ContextManager.shared
    ) {
        self.blog = blog
        self.settings = settings
        self.criteria = criteria
        self.coreDataStack = coreDataStack
    }

    func loadMore() {
        guard !isLoading && hasMore else {
            return
        }
        isLoading = true
        error = nil
        delegate?.serviceDidUpdateState(self)

        _loadMore()
    }

    private func _loadMore() {
        let options = PostServiceSyncOptions()
        options.number = 20
        options.offset = NSNumber(value: offset)
        options.purgesLocalSync = false
        options.search = criteria.searchTerm
        options.authorID = criteria.authorID
        options.tag = criteria.tag

        let postService = PostService(managedObjectContext: coreDataStack.mainContext)
        postService.syncPosts(
            ofType: settings.postType,
            with: options,
            for: blog,
            success: { [weak self] in
                self?.didLoad(with: .success($0 ?? []))
            },
            failure: { [weak self] in
                self?.didLoad(with: .failure($0 ?? URLError(.unknown)))
            }
        )
    }

    private func didLoad(with result: Result<[AbstractPost], Error>) {
        assert(Thread.isMainThread)

        switch result {
        case .success(let posts):
            offset += posts.count
            hasMore = !posts.isEmpty

            let newPosts = posts.filter { !postIDs.contains($0.objectID) }
            postIDs.formUnion(newPosts.map(\.objectID))
            self.delegate?.service(self, didAppendPosts: newPosts)
        case .failure(let error):
            self.error = error
        }
        isLoading = false
        delegate?.serviceDidUpdateState(self)
    }
}

struct PostSearchCriteria: Hashable {
    let searchTerm: String
    let authorID: NSNumber?
    let tag: String?
}
