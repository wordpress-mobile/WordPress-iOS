import Foundation
import Combine

class AllDomainsListViewModel {

    // MARK: - Types

    enum State {
        case normal([AllDomainsListItemViewModel])
        case loading
        case empty(AllDomainsListEmptyStateViewModel)
    }

    private enum ViewModelError: Error {
        case internalError(reason: String)
    }

    private typealias Domain = DomainsService.AllDomainsListItem

    // MARK: - Dependencies

    private var domainsService: DomainsService?

    // MARK: - Properties

    @Published
    private(set) var state: State = .normal([])

    private var domains = [Domain]()

    private var lastSearchQuery: String?

    private let searchQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    // MARK: - Init

    init(coreDataStack: CoreDataStackSwift = ContextManager.shared) {
        if let account = defaultAccount(with: coreDataStack) {
            self.domainsService = .init(coreDataStack: coreDataStack, account: account)
        }
    }

    private func defaultAccount(with contextManager: CoreDataStackSwift) -> WPAccount? {
        try? WPAccount.lookupDefaultWordPressComAccount(in: contextManager.mainContext)
    }

    // MARK: - Resolving State

    /// Determines the state of the view based on the domains and an optional search query.
    ///
    /// - Parameters:
    ///   - domains: An array of domain objects to be filtered.
    ///   - searchQuery: An optional search query to filter the domains. Pass `nil` or an empty string to skip filtering.
    /// - Returns: The `.normal` or `.empty` state.
    private func state(from domains: [Domain], searchQuery: String?) -> State {
        if domains.isEmpty {
            return .empty(emptyStateViewModel())
        }

        var domains = domains

        if let searchQuery, !searchQuery.isEmpty {
            let searchQuery = searchQuery.lowercased()
            domains = domains.filter { domain in
                return domain.domain.localizedStandardContains(searchQuery)
                || domain.siteSlug.localizedStandardContains(searchQuery)
                || domain.blogName.localizedStandardContains(searchQuery)
                || (domain.status?.value.localizedStandardContains(searchQuery) ?? false)
            }
        }

        let viewModels = domains.map { AllDomainsListItemViewModel(domain: $0) }

        return viewModels.isEmpty ? .empty(emptyStateViewModel(searchQuery: searchQuery)) : .normal(viewModels)
    }

    /// Determines the state of the view based on an error.
    ///
    /// - Parameter error: An error that occurred during a data operation.
    /// - Returns: Always returns the `.empty` state.
    private func state(from error: Error) -> State {
        return .empty(self.emptyStateViewModel(from: error))
    }

    // MARK: - Load Domains

    func loadData() {
        self.state = .loading
        self.fetchAllDomains { [weak self] result in
            guard let self else {
                return
            }
            switch result {
            case .success(let domains):
                self.domains = domains
                self.state = self.state(from: domains, searchQuery: lastSearchQuery)
            case .failure(let error):
                self.state = self.state(from: error)
            }
        }
    }

    private func fetchAllDomains(completion: @escaping (DomainsService.AllDomainsEndpointResult) -> Void) {
        guard let service = domainsService else {
            completion(.failure(ViewModelError.internalError(reason: "The `domainsService` property is nil")))
            return
        }
        service.fetchAllDomains(resolveStatus: true, noWPCOM: true, completion: completion)
    }

    // MARK: - Search

    func search(_ query: String) {
        self.lastSearchQuery = query
        switch state {
        case .normal, .empty:
            self.searchQueue.cancelAllOperations()
            self.searchQueue.addOperation { [weak self] in
                guard let self else {
                    return
                }
                let state: State = self.state(from: domains, searchQuery: query)
                DispatchQueue.main.async {
                    self.state = state
                }
            }
        default:
            break
        }
    }

    // MARK: - Creating Empty State View Models

    /// The empty state to display when the user doesn't have any domains or there are no domains matching the search queury.jjj
    private func emptyStateViewModel(searchQuery: String? = nil) -> AllDomainsListEmptyStateViewModel {
        if let searchQuery {
            return .init(
                title: Strings.searchEmptyStateTitle,
                description: Strings.searchEmptyStateDescription(searchQuery),
                button: nil
            )
        } else {
            return .init(
                title: Strings.emptyStateTitle,
                description: Strings.emptyStateDescription,
                button: .init(title: Strings.emptyStateButtonTitle, action: {})
            )
        }
    }

    /// The empty state to display when an error occurs.
    private func emptyStateViewModel(from error: Error) -> AllDomainsListEmptyStateViewModel {
        let title: String
        let description: String
        let button: AllDomainsListEmptyStateViewModel.Button = .init(title: Strings.errorStateButtonTitle) { [weak self] in
            self?.loadData()
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorNotConnectedToInternet {
            title = Strings.offlineEmptyStateTitle
            description = Strings.offlineEmptyStateDescription
        } else {
            title = Strings.errorEmptyStateTitle
            description = Strings.errorEmptyStateDescription
        }

        return .init(title: title, description: description, button: button)
    }
}
