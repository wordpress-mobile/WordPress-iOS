import Foundation
import Combine

final class PostSearchViewModel: NSObject, PostSearchServiceDelegate {
    @Published var searchTerm = ""
    @Published var selectedTokens: [any PostSearchToken] = []
    @Published private(set) var footerState: PagingFooterView.State?

    @Published private(set) var snapshot = NSDiffableDataSourceSnapshot<SectionID, ItemID>()

    enum SectionID: Int, CaseIterable {
        case tokens = 0
        case posts
    }

    enum ItemID: Hashable {
        case token(AnyHashable)
        case post(NSManagedObjectID)
    }

    private(set) var suggestedTokens: [any PostSearchToken] = []
    private(set) var posts: [AbstractPost] = []

    private let blog: Blog
    private let settings: PostListFilterSettings
    private let coreData: CoreDataStack
    private let entityName: String

    private var searchService: PostSearchService?
    private var localSearchTask: Task<Void, Never>?
    private let suggestionsService: PostSearchSuggestionsService
    private var suggestionsTask: Task<Void, Never>?
    private var isRefreshing = false
    private var cancellables: [AnyCancellable] = []

    init(blog: Blog,
        filters: PostListFilterSettings,
        coreData: CoreDataStack = ContextManager.shared
    ) {
        self.blog = blog
        self.settings = filters
        self.coreData = coreData
        self.suggestionsService = PostSearchSuggestionsService(blog: blog, coreData: coreData)

        switch settings.postType {
        case .post: self.entityName = String(describing: Post.self)
        case .page: self.entityName = String(describing: Page.self)
        default: fatalError("Unsupported post type: \(settings.postType)")
        }

        super.init()

        $searchTerm
            .dropFirst()
            .first()
            .sink { [weak self] _ in self?.syncTags() }
            .store(in: &cancellables)

        $searchTerm
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] in self?.updateSuggestedTokens(for: $0) }
            .store(in: &cancellables)

        $searchTerm.map { $0.trimmingCharacters(in: .whitespaces) }
            .combineLatest($selectedTokens)
            .dropFirst()
            .throttle(for: 1.0, scheduler: DispatchQueue.main, latest: true)
            .removeDuplicates { $0.0 == $1.0 && $0.1.map(\.id) == $1.1.map(\.id) }
            .sink { [weak self] _ in self?.performRemoteSearch() }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: NSManagedObjectContext.didChangeObjectsNotification, object: coreData.mainContext)
            .sink { [weak self] in self?.reload(with: $0) }
            .store(in: &cancellables)

        reload()
    }

    // MARK: - Snapshot

    private func reload() {
        snapshot = makeSnapshot()
    }

    private func reload(with notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo else { return }

        let existingObjects = Set(posts)
        var updated = (userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>) ?? []
        var deleted = (userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>) ?? []

        updated.formIntersection(existingObjects)
        deleted.formIntersection(existingObjects)

        guard !updated.isEmpty || !deleted.isEmpty else {
            return
        }

        var snapshot = makeSnapshot()
        snapshot.reloadItems(updated.map({ ItemID.post($0.objectID) }))

        for object in deleted {
            if let post = object as? AbstractPost,
               let index = posts.firstIndex(of: post) {
                posts.remove(at: index)
            }
            snapshot.deleteItems(deleted.map({ ItemID.post($0.objectID) }))
        }

        self.snapshot = snapshot
    }

    private func makeSnapshot() -> NSDiffableDataSourceSnapshot<SectionID, ItemID> {
        var snapshot = NSDiffableDataSourceSnapshot<SectionID, ItemID>()

        snapshot.appendSections([SectionID.tokens])
        let tokenIDs = suggestedTokens.map { ItemID.token($0.id) }
        snapshot.appendItems(tokenIDs, toSection: SectionID.tokens)

        snapshot.appendSections([SectionID.posts])
        let postIDs = posts.map { ItemID.post($0.objectID) }
        snapshot.appendItems(postIDs, toSection: SectionID.posts)

        return snapshot
    }

    // MARK: - Events

    func didReachBottom() {
        guard let searchService, searchService.error == nil else { return }
        searchService.loadMore()
    }

    func didTapRefreshButton() {
        searchService?.loadMore()
    }

    func didSelectToken(at index: Int) {
        let token = suggestedTokens[index]
        cancelCurrentRemoteSearch()
        suggestedTokens = []
        posts = []
        selectedTokens.append(token)
        searchTerm = ""
        reload()
    }

    // MARK: - Search (Remote)

    private func performRemoteSearch() {
        cancelCurrentRemoteSearch()

        guard searchTerm.count > 1 || !selectedTokens.isEmpty else {
            if !posts.isEmpty {
                posts = []
                reload()
            }
            return
        }

        self.isRefreshing = true // Order is important

        let criteria = PostSearchCriteria(
            searchTerm: searchTerm,
            authorID: getSelectedAuthorID(),
            tag: selectedTokens.lazy.compactMap({ $0 as? PostSearchTagToken }).first?.tag
        )
        let service = PostSearchService(blog: blog, settings: settings, criteria: criteria)
        service.delegate = self
        service.loadMore()
        self.searchService = service
    }

    private func cancelCurrentRemoteSearch() {
        // Stop receiving updates from the previous service
        self.searchService?.delegate = nil
    }

    private func getSelectedAuthorID() -> NSNumber? {
        if let token = selectedTokens.lazy.compactMap({ $0 as? PostSearchAuthorToken }).first {
            return token.authorID
        }
        if settings.shouldShowOnlyMyPosts(), let userID = blog.userID {
            return userID
        }
        return nil
    }

    // MARK: - PostSearchServiceDelegate

    func service(_ service: PostSearchService, didAppendPosts posts: [AbstractPost]) {
        assert(Thread.isMainThread)

        if isRefreshing {
            self.posts = posts
            isRefreshing = false
        } else {
            self.posts += posts
        }
        reload()
    }

    func serviceDidUpdateState(_ service: PostSearchService) {
        assert(Thread.isMainThread)

        if isRefreshing && service.error != nil {
            posts = []
        }
        if service.isLoading && (!isRefreshing || posts.isEmpty) {
            footerState = .loading
        } else if service.error != nil {
            footerState = .error
        } else {
            footerState = nil
        }
    }

    // MARK: - Search Tokens

    private func updateSuggestedTokens(for searchTerm: String) {
        let selectedTokens = self.selectedTokens
        suggestionsTask?.cancel()
        suggestionsTask = Task { @MainActor in
            let tokens = await suggestionsService.getSuggestion(for: searchTerm, selectedTokens: selectedTokens)
            guard !Task.isCancelled else { return }
            self.suggestedTokens = tokens
            self.reload()
        }
    }

    private func syncTags() {
        let tagsService = PostTagService(managedObjectContext: coreData.mainContext)
        tagsService.syncTags(for: blog, success: { _ in }, failure: { _ in })
    }
}
