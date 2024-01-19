import WordPressFlux
import Combine

@objc class ReaderTabViewModel: NSObject, ObservableObject {

    // MARK: - Properties
    /// tab bar items
    private let tabItemsStore: ItemsStore
    private var subscription: Receipt?
    private var onTabBarItemsDidChange: [(([ReaderTabItem], Int) -> Void)] = []

    var tabItems: [ReaderTabItem] = [] {
        didSet {
            filterItems = tabItems.filter { !($0.content.topic is ReaderListTopic) }
            listItems = tabItems.filter { $0.content.topic is ReaderListTopic }
        }
    }

    @Published var filterItems: [ReaderTabItem] = []
    @Published var listItems: [ReaderTabItem] = []

    /// completion handler for an external call that changes the tab index
    var didSelectIndex: ((Int) -> Void)?
    var selectedIndex = 0

    /// completion handler for a tap on a tab on the toolbar
    var setContent: ((ReaderContent) -> Void)?

    /// Creates an instance of ReaderContentViewController that gets installed in the ContentView
    var makeReaderContentViewController: (ReaderContent) -> ReaderContentViewController

    /// if items are loaded
    var itemsLoaded: Bool {
        return tabItems.count > 0
    }

    /// Completion handler for selecting a filter from the available filter list
    var filterTapped: ((FilterProvider, UIView?, @escaping (ReaderAbstractTopic?) -> Void) -> Void)?

    /// search
    var navigateToSearch: () -> Void

    /// Spotlight
    var shouldShowCommentSpotlight: Bool = false

    /// Settings
    private let settingsPresenter: ScenePresenter

    private var receipts = [Receipt]()

    /// The available filters for the current stream.
    @Published var streamFilters = [FilterProvider]() {
        didSet {
            // clear the receipts each time we replace these with new filters.
            receipts = []

            // refresh the filter list immediately upon update.
            streamFilters.forEach { [weak self] filter in
                filter.refresh()

                // listen to internal filter changes so that we can "force" the view model
                // to push changes down to the SwiftUI view. This is to ensure that the strings
                // are up-to-date (e.g., after subscribing to new blogs or tags from the manage flow.)
                self?.receipts.append(filter.onChange {
                    self?.objectWillChange.send()
                })
            }
        }
    }

    /// The active stream filter for the stream.
    ///
    /// The `FilterProvider`'s ID is stored to identify where the `ReaderAbstractTopic` is coming from.
    /// When this property is nil, it means the stream is in an unfiltered state.
    @Published var activeStreamFilter: (filterID: FilterProvider.ID, topic: ReaderAbstractTopic)?

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
            viewModel.tabItems = viewModel.tabItemsStore.items
            viewModel.reloadStreamFilters()
            viewModel.onTabBarItemsDidChange.forEach { $0(viewModel.tabItemsStore.items, viewModel.selectedIndex) }
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

        // reload filters for the new stream.
        reloadStreamFilters()

        didSelectIndex?(index)
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
    }

    /// switch to the tab  whose title matches the given predicate
    func switchToTab(where predicate: (String) -> Bool) {
        guard let index = tabItems.firstIndex(where: {
            predicate($0.title)
        }) else {
            return
        }
        showTab(at: index)
    }
}


// MARK: - Filter
extension ReaderTabViewModel {

    func reloadStreamFilters() {
        guard let selectedStream = tabItems[safe: selectedIndex] else {
            return
        }

        // always reset active stream filters
        activeStreamFilter = nil

        // remove stream filters if the current stream does not allow filtering.
        if selectedStream.shouldHideStreamFilters {
            streamFilters = []
            return
        }

        let siteType: SiteOrganizationType = {
            if let teamTopic = selectedStream.content.topic as? ReaderTeamTopic {
                return teamTopic.organizationType
            }
            return .none
        }()

        var filters = [ReaderSiteTopic.filterProvider(for: siteType)]

        if !selectedStream.shouldHideTagFilter {
            filters.append(ReaderTagTopic.filterProvider())
        }

        streamFilters = filters
    }

    func presentFilter(filter: FilterProvider,
                       from: UIViewController,
                       sourceView: UIView?,
                       completion: @escaping (ReaderAbstractTopic?) -> Void) {
        let viewController = makeFilterSheetViewController(filter: filter, completion: completion)
        let bottomSheet = BottomSheetViewController(childViewController: viewController)
        bottomSheet.additionalSafeAreaInsetsRegular = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        bottomSheet.show(from: from, sourceView: sourceView, arrowDirections: .up)

        WPAnalytics.track(.readerFilterSheetDisplayed)
    }

    func presentManage(filter: FilterProvider, from: UIViewController) {
        guard let managePresenter = settingsPresenter as? ReaderManageScenePresenter else {
            settingsPresenter.present(on: from, animated: true, completion: nil)
            return
        }

        managePresenter.present(on: from, selectedSection: filter.section, animated: true) {
            // on completion, ensure that the FilterProvider is refreshed so the latest changes
            // can be reflected on the UI.
            filter.refresh()
        }
    }

    func didTapStreamFilterButton(with filter: FilterProvider) {
        // TODO: @dvdchr Figure out the source rect.
        filterTapped?(filter, nil) { [weak self, filterID = filter.id] topic in
            guard let topic else {
                return
            }
            self?.setFilterContent(topic: topic)
            self?.activeStreamFilter = (filterID, topic)
        }
    }

    // Reset filter
    func resetStreamFilter() {
        guard let currentTab = tabItems[safe: selectedIndex] else {
            return
        }

        WPAnalytics.track(.readerFilterSheetCleared)
        activeStreamFilter = nil
        setContent?(currentTab.content)
    }

    func setFilterContent(topic: ReaderAbstractTopic) {
        let type = ((topic as? ReaderSiteTopic) != nil) ? "site" : "topic"
        WPAnalytics.track(.readerFilterSheetItemSelected, properties: ["type": type])

        setContent?(ReaderContent(topic: topic))
    }

}

// MARK: - Bottom Sheet
extension ReaderTabViewModel {
    private func makeFilterSheetViewController(filter: FilterProvider,
                                               completion: @escaping (ReaderAbstractTopic) -> Void) -> FilterSheetViewController {
        return FilterSheetViewController(filter: filter, changedFilter: completion) { [weak self] viewController in
            self?.presentManage(filter: filter, from: viewController)
        }
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
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppTerminationNotification), name: UIApplication.willTerminateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAccountChangedNotification), name: .WPAccountDefaultWordPressComAccountChanged, object: nil)
    }

    @objc private func handleAppTerminationNotification() {
         clearTopics(removeAllTopics: false)
         clearFlags()
    }

    @objc private func handleAccountChangedNotification() {
         clearFlags()
         clearSavedPosts()
         clearTopics(removeAllTopics: true)
         clearSearchSuggestions()
         selectedIndex = 0
    }

    private func clearFlags() {
        ReaderPostService(coreDataStack: ContextManager.shared).clearInUseFlags()
        ReaderTopicService(coreDataStack: ContextManager.shared).clearInUseFlags()
    }

    private func clearTopics(removeAllTopics removeAll: Bool) {
        ReaderPostService(coreDataStack: ContextManager.shared).deletePostsWithNoTopic()

        if removeAll {
            ReaderTopicService(coreDataStack: ContextManager.shared).deleteAllTopics()
        } else {
            ReaderTopicService(coreDataStack: ContextManager.shared).deleteNonMenuTopics()
        }
    }

    private func clearSavedPosts() {
        ReaderPostService(coreDataStack: ContextManager.shared).clearSavedPostFlags()
    }

    private func clearSearchSuggestions() {
        ReaderSearchSuggestionService(coreDataStack: ContextManager.sharedInstance()).deleteAllSuggestions()
    }
}
