import WordPressFlux


@objc class ReaderTabViewModel: NSObject {

    // MARK: - Properties
    /// tab bar items
    private let tabItemsStore: ItemsStore
    private var subscription: Receipt?
    private var onTabBarItemsDidChange: [(([ReaderTabItem], Int) -> Void)] = []

    private var tabItems: [ReaderTabItem] {
        tabItemsStore.items
    }
    /// completion handler for an external call that changes the tab index
    var didSelectIndex: ((Int) -> Void)?
    var selectedIndex = 0

    /// completion handler for a tap on a tab on the toolbar
    var setContent: ((ReaderContent) -> Void)?

    /// Creates an instance of ReaderContentViewController that gets installed in the ContentView
    var makeReaderContentViewController: (ReaderContent) -> ReaderContentViewController

    /// Completion handler for selecting a filter from the available filter list
    var filterTapped: ((UIView, @escaping (ReaderAbstractTopic?) -> Void) -> Void)?

    /// search
    var navigateToSearch: () -> Void

    /// if items are loaded
    var itemsLoaded: Bool {
        return tabItems.count > 0
    }

    /// Spotlight
    var shouldShowCommentSpotlight: Bool = false

    /// Settings
    private let settingsPresenter: ScenePresenter

    init(readerContentFactory: @escaping (ReaderContent) -> ReaderContentViewController,
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
            viewModel.onTabBarItemsDidChange.forEach { $0(viewModel.tabItems, viewModel.selectedIndex) }
        }
        addNotificationsObservers()
        observeNetworkStatus()
    }
}


// MARK: - Tab bar items
extension ReaderTabViewModel {

    func onTabBarItemsDidChange(completion: @escaping ([ReaderTabItem], Int) -> Void) {
        onTabBarItemsDidChange.append(completion)
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

        if tabItems[index].content.type == .saved {
            setContent?(tabItems[index].content)
        }
    }

    /// switch to the tab whose topic matches the given predicate
    func switchToTab(where predicate: (ReaderAbstractTopic) -> Bool) {
        guard let index = tabItems.firstIndex(where: { item in
            guard let topic = item.content.topic else {
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

        WPAnalytics.track(.readerFilterSheetDisplayed)
    }

    func presentManage(from: UIViewController) {
        settingsPresenter.present(on: from, animated: true, completion: nil)
    }

    func presentFilter(from: UIView, completion: @escaping (ReaderAbstractTopic?) -> Void) {
        filterTapped?(from, { [weak self] topic in
            if let topic = topic {
                self?.setFilterContent(topic: topic)
            }
            completion(topic)
        })
    }

    func resetFilter(selectedItem: FilterTabBarItem) {
        WPAnalytics.track(.readerFilterSheetCleared)
        if let content = (selectedItem as? ReaderTabItem)?.content {
            setContent?(content)
        }
    }

    func setFilterContent(topic: ReaderAbstractTopic) {
        let type = ((topic as? ReaderSiteTopic) != nil) ? "site" : "topic"
        WPAnalytics.track(.readerFilterSheetItemSelected, properties: ["type": type])

        setContent?(ReaderContent(topic: topic))
    }

}

// MARK: - Bottom Sheet
extension ReaderTabViewModel {
    private func makeFilterSheetViewController(completion: @escaping (ReaderAbstractTopic) -> Void) -> FilterSheetViewController {
        let selectedTab = tabItems[selectedIndex]

        let siteType: SiteOrganizationType = {
            if let teamTopic = selectedTab.content.topic as? ReaderTeamTopic {
                return teamTopic.organizationType
            }
            return .none
        }()

        var filters = [ReaderSiteTopic.filterProvider(for: siteType)]

        if !selectedTab.shouldHideTagFilter {
            filters.append(ReaderTagTopic.filterProvider())
        }

        return FilterSheetViewController(viewTitle: selectedTab.title,
                                         filters: filters,
                                         changedFilter: completion)
    }
}


// MARK: - Reader Content
extension ReaderTabViewModel {

    func makeChildContentViewController(at index: Int) -> ReaderContentViewController? {
        guard let tabItem = tabItems[safe: index] else {
            return tabItems.isEmpty ? makeReaderContentViewController(ReaderContent(topic: nil, contentType: .contentError)) : nil
        }
        let controller = makeReaderContentViewController(tabItem.content)

        setContent = { [weak controller] configuration in
            controller?.setContent(configuration)
        }
        return controller
    }
}


extension ReaderTabViewModel: NetworkStatusReceiver, NetworkStatusDelegate {
    func networkStatusDidChange(active: Bool) {
        guard active, tabItems.isEmpty else {
            return
        }
        fetchReaderMenu()
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
