import WordPressFlux


@objc class ReaderTabViewModel: NSObject {

    // MARK: - Properties
    /// tab bar items
    private let tabItemsStore: ItemsStore
    private var subscription: Receipt?
    private var setTabBarItems: (([ReaderTabItem], Int) -> Void)?

    private var tabItems: [ReaderTabItem] {
        tabItemsStore.items
    }
    /// completion handler for an external call that changes the tab index
    var didSelectIndex: ((Int) -> Void)?
    var selectedIndex = 0

    /// completion handler for a tap on a tab on the toolbar
    var setContentTopic: ((ReaderAbstractTopic?) -> Void)?

    /// Creates an instance of ReaderContentViewController that gets installed in the ContentView
    var makeReaderContentViewController: (ReaderAbstractTopic?) -> ReaderContentViewController

    /// Completion handler for selecting a filter from the available filter list
    var filterTapped: ((UIView, @escaping (ReaderAbstractTopic?) -> Void) -> Void)?
    var selectedFilter: ReaderAbstractTopic?

    /// search
    var navigateToSearch: () -> Void

    /// Settings
    private let settingsPresenter: ScenePresenter
    var settingsTapped: ((UIView) -> Void)?

    init(readerContentFactory: @escaping (ReaderAbstractTopic?) -> ReaderContentViewController,
         searchNavigationFactory: @escaping () -> Void,
         tabItemsStore: ItemsStore,
         settingsPresenter: ScenePresenter) {
        self.makeReaderContentViewController = readerContentFactory
        self.navigateToSearch = searchNavigationFactory
        self.tabItemsStore = tabItemsStore
        self.settingsPresenter = settingsPresenter
        super.init()

        subscription = tabItemsStore.onChange { [weak self] in
            guard let viewModel = self else {
                return
            }
            viewModel.setTabBarItems?(viewModel.tabItems, viewModel.selectedIndex)
        }
        addNotificationsObservers()
    }
}


// MARK: - Tab bar items
extension ReaderTabViewModel {

    func refreshTabBar(completion: @escaping ([ReaderTabItem], Int) -> Void) {
        setTabBarItems = completion
    }

    func fetchReaderMenu() {
        tabItemsStore.getItems()
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
        setContentTopic?(selectedTopic)
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
        didSelectIndex?(index)
    }

    /// switch to the tab  whose title matches the given predicate
    func switchToTab(where predicate: (String) -> Bool) {
        guard let index = tabItems.firstIndex(where: {
            predicate($0.title)
        }) else {
            return
        }
        showTab(at: index)
        didSelectIndex?(index)
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

    func presentManage(from: UIViewController) {
        settingsPresenter.present(on: from, animated: true, completion: nil)
    }

    func presentFilter(from: UIView, completion: @escaping (String?) -> Void) {
        filterTapped?(from, { [weak self] topic in
            self?.selectedFilter = topic
            if let topic = topic {
                self?.setContentTopic?(topic)
            }
            completion(topic?.title)
        })
    }

    func resetFilter(selectedItem: FilterTabBarItem) {
        selectedFilter = nil
        if let topic = (selectedItem as? ReaderTabItem)?.topic {
            setContentTopic?(topic)
        }
    }
}


// MARK: - Settings
extension ReaderTabViewModel {

    func presentSettings(from: UIView) {
        settingsTapped?(from)
    }
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


// MARK: - Reader Content
extension ReaderTabViewModel {

    func makeChildContentViewController(at index: Int) -> ReaderContentViewController? {
        guard index < tabItems.count else {
            return nil
        }
        let controller = makeReaderContentViewController(tabItems[index].topic)

        setContentTopic = { [weak controller] topic in
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
                                                self.clearTopics(removeAllTopics: false)
                                                self.clearFlags()
        }

        NotificationCenter.default.addObserver(forName: .WPAccountDefaultWordPressComAccountChanged,
                                               object: nil,
                                               queue: nil) { notification in
                                                self.clearFlags()
                                                self.clearSavedPosts()
                                                self.clearTopics(removeAllTopics: true)
                                                self.clearSearchSuggestions()
                                                self.selectedIndex = 0
        }
    }

    private func clearFlags() {
        let context = ContextManager.sharedInstance().mainContext
        ReaderPostService(managedObjectContext: context).clearInUseFlags()
        ReaderTopicService(managedObjectContext: context).clearInUseFlags()
    }

    private func clearTopics(removeAllTopics removeAll: Bool) {
        let context = ContextManager.sharedInstance().mainContext
        ReaderPostService(managedObjectContext: context).deletePostsWithNoTopic()

        if removeAll {
            ReaderTopicService(managedObjectContext: context).deleteAllTopics()
        } else {
            ReaderTopicService(managedObjectContext: context).deleteNonMenuTopics()
        }
    }

    private func clearSavedPosts() {
        let context = ContextManager.sharedInstance().mainContext
        ReaderPostService(managedObjectContext: context).clearSavedPostFlags()
    }

    private func clearSearchSuggestions() {
        let context = ContextManager.sharedInstance().mainContext
        ReaderSearchSuggestionService(managedObjectContext: context).deleteAllSuggestions()
    }
}
