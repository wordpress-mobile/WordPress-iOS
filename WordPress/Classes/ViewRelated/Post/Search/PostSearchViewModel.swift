import Foundation
import Combine

final class PostSearchViewModel {
    @Published var searchText = ""

    private let blog: Blog
    private let postType: PostServiceType
    private let coreDataStack: CoreDataStack
    private var cancellables: [AnyCancellable] = []

    private(set) var fetchResultsController: NSFetchedResultsController<BasePost>!

    init(blog: Blog,
         postType: PostServiceType,
         coreDataStack: CoreDataStack = ContextManager.shared
    ) {
        self.blog = blog
        self.postType = postType
        self.coreDataStack = coreDataStack

        fetchResultsController = NSFetchedResultsController(
            fetchRequest: makeFetchRequest(searchTerm: ""),
            managedObjectContext: coreDataStack.mainContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        $searchText.dropFirst().sink { [weak self] in
            self?.performLocalSearch(with: $0)
        }.store(in: &cancellables)

        $searchText
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
            .removeDuplicates()
            .filter { $0.count > 1 }
            .sink { [weak self] in
                self?.syncPostsMatchingSearchTerm($0)
        }.store(in: &cancellables)
    }

    // MARK: - Local Search

    private func performLocalSearch(with searchTerm: String) {
        fetchResultsController.fetchRequest.predicate = makePredicate(searchTerm: searchTerm)
        do {
            try fetchResultsController.performFetch()
        } catch {
            assertionFailure("Failed to perform search: \(error)")
        }
    }

    // TODO: Move search to the background
    private func makeFetchRequest(searchTerm: String) -> NSFetchRequest<BasePost> {
        let request = NSFetchRequest<BasePost>(entityName: makeEntityName())
        request.predicate = makePredicate(searchTerm: searchTerm)
        // TODO: Update sort descriptors
        request.sortDescriptors = [NSSortDescriptor(key: "date_created_gmt", ascending: true)]
        request.fetchBatchSize = 40
        return request
    }

    private func makeEntityName() -> String {
        switch postType {
        case .post: return String(describing: Post.self)
        case .page: return String(describing: Page.self)
        default: fatalError("Unsupported post type: \(postType)")
        }
    }

    private func makePredicate(searchTerm: String) -> NSPredicate {
        var predicates = [NSPredicate]()

        // Show all original posts without a revision & revision posts.
        predicates.append(NSPredicate(format: "blog = %@ && revision = nil", blog))
        predicates.append(NSPredicate(format: "postTitle CONTAINS[cd] %@", searchText))

        if postType == .page, let predicate = PostSearchViewModel.makeHomepagePredicate(for: blog) {
            predicates.append(predicate)
        }

        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    static func makeHomepagePredicate(for blog: Blog) -> NSPredicate? {
        guard RemoteFeatureFlag.siteEditorMVP.enabled(),
           blog.blockEditorSettings?.isFSETheme ?? false,
           let homepageID = blog.homepagePageID,
           let homepageType = blog.homepageType,
              homepageType == .page else {
            return nil
        }
        return NSPredicate(format: "postID != %i", homepageID)
    }

    // MARK: - Remote Search (Sync)

    // TODO: Implement remove search
    private func syncPostsMatchingSearchTerm(_ searchTerm: String) {
//        let filter = filterSettings.currentPostListFilter()
//        guard filter.hasMore else {
//            return
//        }

        let postService = PostService(managedObjectContext: coreDataStack.mainContext)

        let options = PostServiceSyncOptions()
        options.number = 20
        options.purgesLocalSync = false
        options.search = searchTerm

        postService.syncPosts(
            ofType: postType,
            with: options,
            for: blog,
            success: { _ in
                // TODO:
            }, failure: { _ in
                // TODO:
            }
        )
    }
}
