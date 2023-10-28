import Foundation
import Combine

class AllDomainsListViewModel {
<<<<<<<< HEAD:WordPress/Classes/ViewRelated/Me/All Domains/View Models/AllDomainsListViewModel.swift

    // MARK: - Types

    enum State {
        case normal
        case loading
        case empty
        case error
    }

    private typealias Domain = DomainsService.AllDomainsListItem

    private enum ViewModelError: Error {
        case internalError(reason: String)
    }
========
>>>>>>>> 91edbe6f29 (Replace all occurences of My Domains to All Domains):WordPress/Classes/ViewRelated/Me/All Domains/AllDomainsListViewModel.swift

    // MARK: - Dependencies

    private var domainsService: DomainsService?

    // MARK: - Properties

    @Published
    private(set) var state: State = .empty

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
        self.fetchAllDomains { result in
            switch result {
            case .success(let domains):
                self.domains = domains
                self.state = domains.isEmpty ? .empty : .normal
            case .failure:
                self.state = .error
            }
        }
    }

    private func fetchAllDomains(completion: @escaping (DomainsService.AllDomainsEndpointResult) -> Void) {
        completion(.success([]))
//        guard let service = domainsService else {
//            completion(.failure(ViewModelError.internalError(reason: "The `domainsService` property is nil")))
//            return
//        }
//        service.fetchAllDomains(resolveStatus: true, noWPCOM: true, completion: completion)
    }

    // MARK: - Accessing Domains

    var numberOfDomains: Int {
        return domains.count
    }

    func domain(atIndex index: Int) -> AllDomainsListItemViewModel {
        return .init(domain: domains[index])
    }
}
