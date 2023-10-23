import Foundation
import Combine

class MyDomainsViewModel {

    // MARK: - Dependencies

    private var domainsService: DomainsService?

    // MARK: - Properties

    @Published
    private var state: State = .empty

    // MARK: - Init

    init(coreDataStack: CoreDataStackSwift = ContextManager.shared) {
        if let account = defaultAccount(with: coreDataStack) {
            self.domainsService = .init(coreDataStack: coreDataStack, account: account)
        }
    }

    private func defaultAccount(with contextManager: CoreDataStackSwift) -> WPAccount? {
        try? WPAccount.lookupDefaultWordPressComAccount(in: contextManager.mainContext)
    }

    // MARK: - Load Data

    func loadData() {
        guard let service = domainsService else {
            return
        }
        service.fetchAllDomains(resolveStatus: true, noWPCOM: true) { result in

        }
    }

    // MARK: - Types

    enum State {
        case loading
        case empty
        case error(MyDomainsErrorViewModel)
    }

}

struct MyDomainsErrorViewModel {
    let title: String
    let description: String
}
