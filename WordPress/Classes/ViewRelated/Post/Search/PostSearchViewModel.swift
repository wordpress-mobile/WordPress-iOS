import Foundation
import Combine

final class PostSearchViewModel: NSObject, PostSearchServiceDelegate {
    @Published var searchTerm = ""
    @Published var selectedTokens: [any PostSearchToken] = []
    @Published private(set) var footerState: PagingFooterView.State?

    private(set) var suggestedTokens: [any PostSearchToken] = [] {
        didSet { didUpdateData?() }
    }

    private(set) var results: [PostSearchResultItem] = [] {
        didSet { didUpdateData?() }
    }

    var didUpdateData: (() -> Void)? // Send updates on `didSet` (unlike @Published)

    private let blog: Blog
    private let settings: PostListFilterSettings
    private let coreData: CoreDataStack
    private let entityName: String

    private var postViewModels: [NSManagedObjectID: PostListItemViewModel] = [:]
    private var pageViewModels: [NSManagedObjectID: PageListItemViewModel] = [:]
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
        results = []
        selectedTokens.append(token)
        searchTerm = ""
    }

    // MARK: - Search (Remote)

    private func performRemoteSearch() {
        cancelCurrentRemoteSearch()

        guard searchTerm.count > 1 || !selectedTokens.isEmpty else {
            if !results.isEmpty {
                results = []
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

        let items = posts.map(getSearchResultItem)
        if isRefreshing {
            self.results = items
            isRefreshing = false
        } else {
            self.results += items
        }

        // Updating for current searchTerm, not the one that the service searched for
        updateHighlightForSearchResults(for: searchTerm)
    }

    func serviceDidUpdateState(_ service: PostSearchService) {
        assert(Thread.isMainThread)

        if isRefreshing && service.error != nil {
            results = []
        }
        if service.isLoading && (!isRefreshing || results.isEmpty) {
            footerState = .loading
        } else if service.error != nil {
            footerState = .error
        } else {
            footerState = nil
        }
    }

    // MARK: - Results

    private func getSearchResultItem(for item: AbstractPost) -> PostSearchResultItem {
        switch item {
        case let post as Post:
            return .post(getViewModel(for: post))
        case let page as Page:
            return .page(getViewModel(for: page))
        default:
            fatalError("Unsupported item: \(type(of: item))")
        }
    }

    private func getViewModel(for post: Post) -> PostListItemViewModel {
        if let viewModel = postViewModels[post.objectID] {
            return viewModel
        }
        let viewModel = PostListItemViewModel(post: post)
        postViewModels[post.objectID] = viewModel
        return viewModel
    }

    private func getViewModel(for page: Page) -> PageListItemViewModel {
        if let viewModel = pageViewModels[page.objectID] {
            return viewModel
        }
        let viewModel = PageListItemViewModel(page: page)
        pageViewModels[page.objectID] = viewModel
        return viewModel
    }

    // MARK: - Highlighter

    private func updateHighlightForSearchResults(for searchTerm: String) {
        let terms = searchTerm
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        for item in results {
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

    var objectID: NSManagedObjectID {
        switch self {
        case .post(let viewModel):
            return viewModel.post.objectID
        case .page(let viewModel):
            return viewModel.page.objectID
        }
    }
}
