import Foundation
import Combine

class AllDomainsListViewModel {
    
    // MARK: - Types

    enum State {
        case normal
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
    private(set) var state: State = .normal

    private var domains = [Domain]()

    // MARK: - Init

    init(coreDataStack: CoreDataStackSwift = ContextManager.shared) {
        if let account = defaultAccount(with: coreDataStack) {
            self.domainsService = .init(coreDataStack: coreDataStack, account: account)
        }
    }

    private func defaultAccount(with contextManager: CoreDataStackSwift) -> WPAccount? {
        try? WPAccount.lookupDefaultWordPressComAccount(in: contextManager.mainContext)
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
                self.state = domains.isEmpty ? .empty(self.emptyStateViewModel()) : .normal
            case .failure(let error):
                self.state = .empty(self.emptyStateViewModel(from: error))
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

    // MARK: - Accessing Domains

    var numberOfDomains: Int {
        return domains.count
    }

    func domain(atIndex index: Int) -> AllDomainsListItemViewModel {
        return .init(domain: domains[index])
    }

    // MARK: - Creating Empty State View Models

    /// The empty state to display when the user doesn't have any domains.
    private func emptyStateViewModel() -> AllDomainsListEmptyStateViewModel {
        return .init(
            title: Strings.emptyStateTitle,
            description: Strings.emptyStateDescription,
            button: .init(title: Strings.emptyStateButtonTitle, action: {})
        )
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

    /// The empty state to display when there are no domains matching the search query.
    private func emptyStateViewModel(searchQuery: String) -> AllDomainsListEmptyStateViewModel {
        fatalError("Not implemented yet")
    }
}
