import WordPressFlux


class ReaderTabItemsStore: Observable {

    let changeDispatcher = Dispatcher<Void>()

    enum State {
        case loading
        case ready([ReaderTabItem])
        case error(Error)

        var isReady: Bool {
            switch self {
            case .ready:
                return true
            case .error, .loading:
                return false
            }
        }
    }

    var state: State = .loading {
        didSet {
            emitChange()
        }
    }

    var tabItems: [ReaderTabItem] {
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
            guard let topics = try ContextManager.sharedInstance().mainContext.fetch(topicsFetchRequest) as? [ReaderAbstractTopic] else {
                return
            }
            let items = ReaderHelpers.rearrange(items: topics.map { ReaderTabItem(topic: $0) })
            self.state = .ready(items)

        } catch {
            DDLogError(ReaderTopicsConstants.fetchRequestError + error.localizedDescription)
            self.state = .error(error)
        }
    }

    /// Updates the items from the underlying service
    func getItems() {
        let service = ReaderTopicService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.fetchReaderMenu(success: { [weak self] in
            self?.fetchTabBarItems()
            }, failure: { error in
                DDLogError(ReaderTopicsConstants.remoteFetchError + String(describing: error))
        })
    }

    private enum ReaderTopicsConstants {
        static let predicateFormat = "following == %@ AND showInMenu == YES AND type == 'default' OR type == 'list' OR type == 'team'"
        static let entityName = "ReaderAbstractTopic"
        static let sortByKey = "type"
        static let fetchRequestError = "There was a problem fetching topics for the menu. "
        static let remoteFetchError = "Error syncing menu: "
    }
}
