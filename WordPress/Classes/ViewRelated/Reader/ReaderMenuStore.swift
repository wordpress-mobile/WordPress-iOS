import UIKit

protocol ReaderMenuStoreProtocol {
    func refreshMenu()
}

final class ReaderMenuStore: ReaderMenuStoreProtocol {
    let context: NSManagedObjectContext
    let service: ReaderTopicService

    private var isLoading = false

    init(context: NSManagedObjectContext = ContextManager.shared.mainContext,
         service: ReaderTopicService? = nil) {
        self.context = context
        self.service = service ?? ReaderTopicService(coreDataStack: ContextManager.shared)
    }

    /// Updates the items from the underlying service
    func refreshMenu() {
        guard !isLoading else {
            return
        }
        isLoading = true

        // Sync the reader menu
        service.fetchReaderMenu(success: { [weak self] in
            self?.fetchTabBarItemsAndFollowedSites()
        }, failure: { [weak self] error in
            self?.fetchTabBarItemsAndFollowedSites()
            DDLogError("Error syncing menu: \(String(describing: error))")
        })
    }

    private func fetchTabBarItemsAndFollowedSites() {
        DispatchQueue.main.async {
            self.fetchFollowedSites()
        }
    }

    private func fetchFollowedSites() {
        service.fetchAllFollowedSites(success: { [weak self] in
            self?.isLoading = false
        }, failure: { [weak self] error in
            DDLogError("Could not sync sites: \(String(describing: error))")
            self?.isLoading = false
        })
    }
}
