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
        case result(NSManagedObjectID)
    }

    private(set) var suggestedTokens: [any PostSearchToken] = [] {
        didSet { reload() }
    }

    private(set) var posts: [AbstractPost] = [] {
        didSet { reload() }
    }

    private let blog: Blog
    private let settings: PostListFilterSettings
    private let coreData: CoreDataStack
    private let entityName: String

    private var cachedItems: [NSManagedObjectID: PostSearchResultItem] = [:]
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
            .removeDuplicates()
            .sink { [weak self] in self?.didUpdateSearchTerm($0) }
            .store(in: &cancellables)

        $searchTerm.map { $0.trimmingCharacters(in: .whitespaces) }
            .combineLatest($selectedTokens)
            .dropFirst()
            .throttle(for: 1.0, scheduler: DispatchQueue.main, latest: true)
            .removeDuplicates { $0.0 == $1.0 && $0.1.map(\.id) == $1.1.map(\.id) }
            .sink { [weak self] _ in self?.performRemoteSearch() }
            .store(in: &cancellables)

        // TODO:
//        NotificationCenter.default.addObserver(self, selector: #selector(reloadData(with:)), name: NSManagedObjectContext.didChangeObjectsNotification, object: ContextManager.shared.mainContext)

        reload()
    }

    // MARK: - Snapshot

    private func reload() {
        snapshot = makeSnapshot()
    }

    private func makeSnapshot() -> NSDiffableDataSourceSnapshot<SectionID, ItemID> {
        var snapshot = NSDiffableDataSourceSnapshot<SectionID, ItemID>()

        snapshot.appendSections([SectionID.tokens])
        let tokenIDs = suggestedTokens.map { ItemID.token($0.id) }
        snapshot.appendItems(tokenIDs, toSection: SectionID.tokens)

        snapshot.appendSections([SectionID.posts])
        let postIDs = posts.map { ItemID.result($0.objectID) }
        snapshot.appendItems(postIDs, toSection: SectionID.posts)

        return snapshot
    }

    // MARK: - Events

    private func didUpdateSearchTerm(_ searchTerm: String) {
        updateHighlightForSearchResults(for: searchTerm)
        updateSuggestedTokens(for: searchTerm)
    }

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
    }

    func apply( notification: NSNotification) {
        // TODO: Reload all the needed ViewModels and the respective search term highlughts
        // TODO: Create a snapshot and send to the screen (this will support cancellation)
    }

    // MARK: - Search (Remote)

    private func performRemoteSearch() {
        cancelCurrentRemoteSearch()

        guard searchTerm.count > 1 || !selectedTokens.isEmpty else {
            if !posts.isEmpty {
                posts = []
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

        // Updating for current searchTerm, not the one that the service searched for
        updateHighlightForSearchResults(for: searchTerm)
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

    // MARK: - Search Results

    func getSearchResultItem(for post: AbstractPost) -> PostSearchResultItem {
        if let item = cachedItems[post.objectID] {
            return item
        }
        let item: PostSearchResultItem
        switch post {
        case let post as Post:
            item = .post(PostListItemViewModel(post: post))
        case let page as Page:
            item = .page(PageListItemViewModel(page: page))
        default:
            fatalError("Unsupported item: \(type(of: post))")
        }
        cachedItems[post.objectID] = item
        return item
    }

    // MARK: - Highlighter

    private func updateHighlightForSearchResults(for searchTerm: String) {
        let terms = searchTerm
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        for post in posts {
            guard let item = cachedItems[post.objectID] else {
                continue
            }
            switch item {
            case .post(let viewModel):
                let string = NSMutableAttributedString(attributedString: viewModel.content)
                PostSearchViewModel.highlight(terms: terms, in: string)
                viewModel.content = string
            case .page(let viewModel):
                let string = NSMutableAttributedString(attributedString: viewModel.title)
                PostSearchViewModel.highlight(terms: terms, in: string)
                viewModel.title = string
            }
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
        }
    }
}

enum PostSearchResultItem {
    case post(PostListItemViewModel)
    case page(PageListItemViewModel)
}
