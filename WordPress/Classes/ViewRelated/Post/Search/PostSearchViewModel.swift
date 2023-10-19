import Foundation
import Combine

final class PostSearchViewModel: NSObject, PostSearchServiceDelegate {
    @Published var searchTerm = ""
    @Published var selectedTokens: [any PostSearchToken] = []
    @Published private(set) var footerState: PagingFooterView.State?

    private(set) var suggestedTokens: [any PostSearchToken] = [] {
        didSet { didUpdateData?() }
    }

    private(set) var posts: [AbstractPost] = [] {
        didSet { didUpdateData?() }
    }

    var didUpdateData: (() -> Void)? // Send updates on `didSet` (unlike @Published)

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
        }
    }
}
