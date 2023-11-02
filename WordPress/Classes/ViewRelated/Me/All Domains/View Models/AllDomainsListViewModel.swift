import Foundation
import Combine

class AllDomainsListViewModel {

    // MARK: - Types

    enum State {
        /// This state is set when domains data is loaded.
        case normal

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
                self.state = domains.isEmpty ? .message(self.noDomainsMessageViewModel()) : .normal
            case .failure(let error):
                self.state = .message(self.errorMessageViewModel(from: error))
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

    // MARK: - Creating Message State View Models

    /// The  message to display when the user doesn't have any domains.
    private func noDomainsMessageViewModel() -> AllDomainsListMessageStateViewModel {
        let action: () -> Void = { [weak self] in
            self?.addDomainAction?()
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
        fatalError("Not implemented yet")
    }
}
