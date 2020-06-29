import WordPressFlux

protocol ItemsStore: Observable {
    var items: [ReaderTabItem] { get }
    func getItems()
}

class ReaderTabItemsStore: ItemsStore {

    let changeDispatcher = Dispatcher<Void>()

    let context: NSManagedObjectContext
    let service: ReaderTopicService

    init(context: NSManagedObjectContext = ContextManager.sharedInstance().mainContext,
         service: ReaderTopicService? = nil) {
        self.context = context
        self.service = service ?? ReaderTopicService(managedObjectContext: context)
    }

    enum State {
        case loading
        case ready([ReaderTabItem])
        case error(Error)

        var isLoading: Bool {
            switch self {
            case .loading:
                return true
            case .error, .ready:
                return false
            }
        }
    }

    var state: State = .ready([]) {
        didSet {
            guard !state.isLoading else {
                return
            }
            emitChange()
        }
    }

    var items: [ReaderTabItem] {
        switch state {
        case .loading, .error:
            return []
        case .ready(let items):
            return items
        }
    }
}

// MARK: - Data fetching
extension ReaderTabItemsStore {

    /// Fetch request to extract reader menu topics from Core Data
    private var topicsFetchRequest: NSFetchRequest<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderTopicsConstants.entityName)
        fetchRequest.predicate = NSPredicate(format: ReaderTopicsConstants.predicateFormat, NSNumber(value: ReaderHelpers.isLoggedIn()))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: ReaderTopicsConstants.sortByKey, ascending: true)]
        return fetchRequest
    }

    /// Fetches items from the Core Data cache, if they exist, and updates the state accordingly
    private func fetchTabBarItems() {
        do {
            guard let topics = try context.fetch(topicsFetchRequest) as? [ReaderAbstractTopic] else {
                self.state = .error(ReaderTopicsConstants.objectTypeError)
                DDLogError(ReaderTopicsConstants.fetchRequestError + ReaderTopicsConstants.objectTypeError.localizedDescription)
                return
            }
            let items = ReaderHelpers.rearrange(items: topics.map { ReaderTabItem(ReaderContent(topic: $0)) })
            self.state = .ready(items)

        } catch {
            DDLogError(ReaderTopicsConstants.fetchRequestError + error.localizedDescription)
            self.state = .error(error)
        }
    }

    /// Updates the items from the underlying service
    func getItems() {
        guard !state.isLoading else {
            return
        }
        state = .loading

        let dispatchGroup = DispatchGroup()

        // Sync the reader menu
        dispatchGroup.enter()
        service.fetchReaderMenu(success: {
            dispatchGroup.leave()
        }, failure: { (error) in
            let actualError = error ?? ReaderTopicsConstants.remoteServiceError
            DDLogError("Error syncing menu: \(String(describing: actualError))")

            dispatchGroup.leave()
        })

        // Sync the followed sites
        dispatchGroup.enter()
        service.fetchFollowedSites(success: {
            dispatchGroup.leave()
        }, failure: { (error) in
            let actualError = error ?? ReaderTopicsConstants.remoteServiceError
            DDLogError("Could not sync sites: \(String(describing: actualError))")

            dispatchGroup.leave()
        })

        // Wait for both the requests to finish
        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.fetchTabBarItems()
        }
    }

    private enum ReaderTopicsConstants {
        static let predicateFormat = "type == 'default' OR type == 'team' OR (type == 'list' AND following == %@ AND showInMenu == YES)"
        static let entityName = "ReaderAbstractTopic"
        static let sortByKey = "type"
        static let fetchRequestError = "There was a problem fetching topics for the menu. "
        static let objectTypeError = NSError(domain: "ReaderTabItemsStoreDomain", code: -1, userInfo: nil)
        static let remoteServiceError = NSError(domain: WordPressComRestApiErrorDomain, code: -1, userInfo: nil)
    }
}
