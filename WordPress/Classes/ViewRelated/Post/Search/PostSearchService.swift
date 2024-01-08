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

    let criteria: PostSearchCriteria
    private let blog: Blog
    private let settings: PostListFilterSettings
    private let coreDataStack: CoreDataStack
    private let repository: PostRepository

    private var postIDs: Set<NSManagedObjectID> = []
    private var offset = 0
    private var hasMore = true

    init(blog: Blog,
         settings: PostListFilterSettings,
         criteria: PostSearchCriteria,
         coreDataStack: CoreDataStackSwift = ContextManager.shared
    ) {
        self.blog = blog
        self.settings = settings
        self.criteria = criteria
        self.coreDataStack = coreDataStack
        self.repository = PostRepository(coreDataStack: coreDataStack)
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
        let postType = settings.postType == .post ? Post.self : Page.self
        let blogID = TaggedManagedObjectID(blog)

        Task { @MainActor [weak self, offset, criteria, repository, coreDataStack] in
            let result: Result<[AbstractPost], Error>
            do {
                let postIDs: [TaggedManagedObjectID<AbstractPost>] = try await repository.search(
                    type: postType,
                    input: criteria.searchTerm,
                    statuses: [],
                    tag: criteria.tag,
                    authorUserID: criteria.authorID,
                    offset: offset,
                    limit: 20,
                    orderBy: .byDate,
                    descending: true,
                    in: blogID
                )
                result = try .success(postIDs.map { try coreDataStack.mainContext.existingObject(with: $0) })
            } catch {
                result = .failure(error)
            }
            self?.didLoad(with: result)
        }
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
