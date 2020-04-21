
@objc class ReaderTabViewModel: NSObject {
    // MARK: - Properties
    /// tab selection
    var indexSelectionCallback: ((Int) -> Void)?
    var topicSelectionCallback: ((ReaderAbstractTopic?) -> Void)?
    var selectedIndex = 0
    private var tabItems: [ReaderTabItem] = []
    /// Reader content
    var makeReaderContentViewController: (ReaderAbstractTopic?) -> ReaderContentViewController
    /// filter sheet
    var filterTapped: ((UIView, @escaping (ReaderAbstractTopic?) -> Void) -> Void)?
    var selectedFilter: ReaderAbstractTopic?
    /// search
    var navigateToSearch: () -> Void


    init(readerContentFactory: @escaping (ReaderAbstractTopic?) -> ReaderContentViewController,
         searchNavigationFactory: @escaping () -> Void) {
        self.makeReaderContentViewController = readerContentFactory
        self.navigateToSearch = searchNavigationFactory
        super.init()
        addNotificationsObservers()
    }
}


// MARK: - Tab selection
extension ReaderTabViewModel {

    func showTab(at index: Int) {
        guard index < tabItems.count else {
            return
        }
        selectedIndex = index
        let topic = tabItems[index].topic

        let selectedTopic: ReaderAbstractTopic?
        if !tabItems[index].shouldHideButtonsView {
            selectedTopic = selectedFilter ?? topic
        } else {
            selectedTopic = topic
        }
        topicSelectionCallback?(selectedTopic)
    }

    /// switch to the tab whose topic matches the given predicate
    func switchToTab(where predicate: (ReaderAbstractTopic) -> Bool) {
        guard let index = tabItems.firstIndex(where: { item in
            guard let topic = item.topic else {
                return false
            }
            return predicate(topic)
        }) else {
            return
        }
        showTab(at: index)
        indexSelectionCallback?(index)
    }

    /// switch to the tab  whose title matches the given predicate
    func switchToTab(where predicate: (String) -> Bool) {
        guard let index = tabItems.firstIndex(where: {
            predicate($0.title)
        }) else {
            return
        }
        showTab(at: index)
        indexSelectionCallback?(index)
    }
}


// MARK: - Filter
extension ReaderTabViewModel {

    func presentFilter(from: UIViewController, sourceView: UIView, completion: @escaping (ReaderAbstractTopic?) -> Void) {
        let viewController = makeFilterSheetViewController(completion: completion)
        let bottomSheet = BottomSheetViewController(childViewController: viewController)
        bottomSheet.additionalSafeAreaInsetsRegular = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        bottomSheet.show(from: from, sourceView: sourceView, arrowDirections: .up)
    }

    func presentFilter(from: UIView, completion: @escaping (String?) -> Void) {
        filterTapped?(from, { [weak self] topic in
            self?.selectedFilter = topic
            if let topic = topic {
                self?.topicSelectionCallback?(topic)
            }
            completion(topic?.title)
        })
    }

    func resetFilter(selectedItem: FilterTabBarItem) {
        selectedFilter = nil
        if let topic = (selectedItem as? ReaderTabItem)?.topic {
            topicSelectionCallback?(topic)
        }
    }
}


// MARK: - Settings
extension ReaderTabViewModel {
    // TODO: - READERNAV - Methods to be implemented. Signature will likely change
    func presentSettings() { }
}


// MARK: - Bottom Sheet
extension ReaderTabViewModel {
    private func makeFilterSheetViewController(completion: @escaping (ReaderAbstractTopic) -> Void) -> FilterSheetViewController {
        return FilterSheetViewController(filters:
            [ReaderSiteTopic.filterProvider(),
             ReaderTagTopic.filterProvider()],
            changedFilter: completion)
    }
}


// MARK: - Tab menu items
extension ReaderTabViewModel {

    /// Fetch request to extract reader menu topics from Core Data
    private var topicsFetchRequest: NSFetchRequest<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderTopicsConstants.entityName)
        fetchRequest.predicate = NSPredicate(format: ReaderTopicsConstants.predicateFormat, NSNumber(value: ReaderHelpers.isLoggedIn()))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: ReaderTopicsConstants.sortByKey, ascending: true)]
        return fetchRequest
    }

    /// Fetches topics from Core Data populates tab bar items accordingly and passes them to the completion closure
    /// - Parameter completion: completion closure: will be passed an array of ReaderTabItem or nil, if the request fails
    private func fetchTabBarItems(completion: @escaping ([ReaderTabItem]?) -> Void) {
        do {
            guard let topics = try ContextManager.sharedInstance().mainContext.fetch(topicsFetchRequest) as? [ReaderAbstractTopic] else {
                return
            }
            let items = ReaderHelpers.rearrange(items: topics.map { ReaderTabItem(topic: $0) })
            tabItems = items
            completion(items)

        } catch {
            DDLogError(ReaderTopicsConstants.fetchRequestError + error.localizedDescription)
            completion(nil)
        }
    }

    /// Fetches the menu from the designated service and passes it to the completion closure
    /// - Parameter completion: completion closure: will be passed an array of ReaderTabItem or nil, if the request fails
    func fetchReaderMenu(completion: @escaping ([ReaderTabItem]?) -> Void) {
        let service = ReaderTopicService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.fetchReaderMenu(success: { [weak self] in
            self?.fetchTabBarItems(completion: completion)
            }, failure: { error in
                DDLogError(ReaderTopicsConstants.remoteFetchError + String(describing: error))
                completion(nil)
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


// MARK: - Reader Content
extension ReaderTabViewModel {

    func makeChildViewController(at index: Int) -> ReaderContentViewController? {
        guard index < tabItems.count else {
            return nil
        }
        let controller = makeReaderContentViewController(tabItems[index].topic)

        topicSelectionCallback = { [weak controller] topic in
            controller?.setTopic(topic)
        }
        return controller
    }
}


// MARK: - Cleanup tasks
extension ReaderTabViewModel {

    private func addNotificationsObservers() {
        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification,
                                               object: nil,
                                               queue: nil) { notification in
                                                self.cleanupStaleContent(removeAllTopics: false)
                                                self.unflagInUseContent()
        }

        NotificationCenter.default.addObserver(forName: .WPAccountDefaultWordPressComAccountChanged,
                                               object: nil,
                                               queue: nil) { notification in
                                                self.unflagInUseContent()
                                                self.clearSavedPosts()
                                                self.cleanupStaleContent(removeAllTopics: true)
                                                self.clearSearchSuggestions()
                                                self.selectedIndex = 0
        }
    }

    /// Clears the inUse flag from any topics or posts so marked.
    private func unflagInUseContent() {
        let context = ContextManager.sharedInstance().mainContext
        ReaderPostService(managedObjectContext: context).clearInUseFlags()
        ReaderTopicService(managedObjectContext: context).clearInUseFlags()
    }

    /// Clean up topics that do not belong in the menu and posts that have no topic
    /// This is merely a convenient place to perform this task.
    private func cleanupStaleContent(removeAllTopics removeAll: Bool) {
        let context = ContextManager.sharedInstance().mainContext
        ReaderPostService(managedObjectContext: context).deletePostsWithNoTopic()

        if removeAll {
            ReaderTopicService(managedObjectContext: context).deleteAllTopics()
        } else {
            ReaderTopicService(managedObjectContext: context).deleteNonMenuTopics()
        }
    }

    /// Clears all saved posts, so they can be deleted by cleanup methods.
    private func clearSavedPosts() {
        let context = ContextManager.sharedInstance().mainContext
        ReaderPostService(managedObjectContext: context).clearSavedPostFlags()
    }

    private func clearSearchSuggestions() {
        let context = ContextManager.sharedInstance().mainContext
        ReaderSearchSuggestionService(managedObjectContext: context).deleteAllSuggestions()
    }
}
