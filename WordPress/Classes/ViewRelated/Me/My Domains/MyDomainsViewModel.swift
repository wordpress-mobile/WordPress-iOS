import Foundation
import Combine

protocol MyDomainViewModel {

    init(domain: DomainsService.AllDomainsListItem)
}

class MyDomainsViewModel<T: MyDomainViewModel> {

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
        guard let service = domainsService else {
            return
        }
        self.state = .loading
        service.fetchAllDomains(resolveStatus: true, noWPCOM: true) { result in
            switch result {
            case .success(let domains):
                self.domains = .init(repeating: domains[0], count: 10)
            case .failure:
                break
            }
            self.state = .normal
        }
    }

    // MARK: - Accessing Domains

    var numberOfDomains: Int {
        return domains.count
    }

    func domain(atIndex index: Int) -> T {
        return .init(domain: domains[index])
    }

    // MARK: - Types

    enum State {
        case normal
        case loading
        case empty
        case error(MyDomainsErrorViewModel)
    }

    private typealias Domain = DomainsService.AllDomainsListItem

}

struct MyDomainsErrorViewModel {
    let title: String
    let description: String
}
