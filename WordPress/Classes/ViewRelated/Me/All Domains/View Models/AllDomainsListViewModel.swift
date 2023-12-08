import Foundation
import Combine

class AllDomainsListViewModel {

    // MARK: - Types

    enum State {
        /// This state is set when domains data is loaded.
        case normal([AllDomainsListItemViewModel])

        /// This state is set when domains data is being fetched.
        case loading

        /// This state is set when the list is empty or an error occurs.
        case message(AllDomainsListMessageStateViewModel)
    }

    private enum ViewModelError: Error {
        case internalError(reason: String)
    }

    private typealias Domain = DomainsService.AllDomainsListItem

    // MARK: - Configuration

    var addDomainAction: (() -> Void)?

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
            self.domainsService = .init(coreDataStack: coreDataStack, wordPressComRestApi: account.wordPressComRestApi)
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
            return .message(noDomainsMessageViewModel())
        }

        var domains = domains

        if let searchQuery, !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            domains = domains.filter { $0.matches(searchQuery: searchQuery) }
        }

        let viewModels = domains.map { AllDomainsListItemViewModel(domain: $0) }

        if let searchQuery, viewModels.isEmpty {
            return .message(noSearchResultsMessageViewModel(searchQuery: searchQuery))
        } else if viewModels.isEmpty {
            return .message(noDomainsMessageViewModel())
        } else {
            return .normal(viewModels)
        }
    }

    /// Determines the state of the view based on an error.
    ///
    /// - Parameter error: An error that occurred during a data operation.
    /// - Returns: Always returns the `.empty` state.
    private func state(from error: Error) -> State {
        return .message(self.errorMessageViewModel(from: error))
    }

    // MARK: - Load Domains

    func loadData() {
        if domains.isEmpty {
            self.state = .loading
        }
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

    func search(_ query: String?) {
        // Keep track of the previous search query.
        self.lastSearchQuery = query

        // Search shouldn't be performed if the user doesn't have any domains.
        guard !domains.isEmpty else {
            return
        }

        // Perform search asynchrounously.
        switch state {
        case .normal, .message:
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

    // MARK: - Creating Message State View Models

    /// The message to display when the user doesn't have any domains.
    private func noDomainsMessageViewModel() -> AllDomainsListMessageStateViewModel {
        let action: () -> Void = { [weak self] in
            self?.addDomainAction?()
            WPAnalytics.track(.allDomainsFindDomainTapped)
        }
        return .init(
            title: Strings.emptyStateTitle,
            description: Strings.emptyStateDescription,
            button: .init(title: Strings.emptyStateButtonTitle, action: action)
        )
    }

    /// The  message to display when an error occurs.
    private func errorMessageViewModel(from error: Error) -> AllDomainsListMessageStateViewModel {
        let title: String
        let description: String
        let button: AllDomainsListMessageStateViewModel.Button = .init(title: Strings.errorStateButtonTitle) { [weak self] in
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

    /// The message to display when there are no domains matching the search query.
    private func noSearchResultsMessageViewModel(searchQuery: String) -> AllDomainsListMessageStateViewModel {
        return .init(
            title: Strings.searchEmptyStateTitle,
            description: Strings.searchEmptyStateDescription(searchQuery),
            button: nil
        )
    }
}
