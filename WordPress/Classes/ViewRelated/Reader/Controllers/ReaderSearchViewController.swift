import Foundation
import SwiftUI
import WordPressShared

/// Displays a version of the post stream with a search bar positioned above the
/// list of posts.  The user supplied search phrase is converted into a ReaderSearchTopic
/// the results of which are displayed in the embedded ReaderStreamViewController.
///
@objc open class ReaderSearchViewController: UIViewController {
    enum Section: Int, FilterTabBarItem {
        case posts
        case sites

        var title: String {
            switch self {
            case .posts: return NSLocalizedString("Posts", comment: "Title of a Reader tab showing Posts matching a user's search query")
            case .sites: return NSLocalizedString(
                "reader.search.tab.blogs",
                value: "Blogs",
                comment: "Title of a Reader tab showing Sites matching a user's search query"
            )
            }
        }

        var trackingValue: String {
            switch self {
            case .posts: return "posts"
            case .sites: return "sites"
            }
        }
    }

    private enum SearchSource: String {
        case userInput = "user_input"
        case searchHistory = "search_history"
    }

    // MARK: - Properties

    @IBOutlet fileprivate weak var searchBar: UISearchBar!
    @IBOutlet fileprivate weak var filterBar: FilterTabBar!

    private var previousSearchTopic: ReaderAbstractTopic?

    fileprivate var didBumpStats = false

    private lazy var bannerView: JetpackBannerView = {
        let textProvider = JetpackBrandingTextProvider(screen: JetpackBannerScreen.readerSearch)
        let bannerView = JetpackBannerView()
        bannerView.configure(title: textProvider.brandingText()) { [weak self] in
            guard let self else {
                return
            }
            JetpackBrandingCoordinator.presentOverlay(from: self)
            JetpackBrandingAnalyticsHelper.trackJetpackPoweredBannerTapped(screen: .readerSearch)
        }
        bannerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: JetpackBannerView.minimumHeight)
        return bannerView
    }()

    fileprivate let sections: [Section] = [ .posts, .sites ]

    private let suggestionsViewModel = ReaderSearchSuggestionsViewModel()
    private var suggestionsVC: UIViewController?
    private var currentChildVC: UIViewController?

    private let contextManager = ContextManager.shared

    /// A convenience method for instantiating the controller from the storyboard.
    ///
    /// - Returns: An instance of the controller.
    ///
    @objc open class func controller() -> ReaderSearchViewController {
        let storyboard = UIStoryboard(name: "Reader", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "ReaderSearchViewController") as! ReaderSearchViewController
        return controller
    }

    // MARK: Lifecycle methods

    open override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Search", comment: "Title of the Reader's search feature")
        navigationItem.largeTitleDisplayMode = .never

        WPStyleGuide.configureColors(view: view, tableView: nil)
        setupSearchBar()
        configureFilterBar()
        configureNavigationBar()

        suggestionsViewModel.onSelection = { [weak self] in
            self?.searchBar.text = $0
            self?.performSearch(source: .searchHistory)
        }
    }

    open override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if let _ = parent {
            return
        }
        // When the parent is nil then we've been removed from the nav stack.
        // Clean up any search topics at this point.
        ReaderTopicService(coreDataStack: ContextManager.shared).deleteAllSearchTopics()
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        searchBar.becomeFirstResponder()
        bumpStats()
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Dismiss the keyboard if it was visible.
        endSearch()

        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // MARK: - Analytics

    @objc func bumpStats() {
        if didBumpStats {
            return
        }

        WPAppAnalytics.track(.readerSearchLoaded)
        didBumpStats = true
    }

    // MARK: - Configuration

    private func setupSearchBar() {
        // Appearance must be set before the search bar is added to the view hierarchy.
        let placeholderText = NSLocalizedString("Search WordPress", comment: "Placeholder text for the Reader search feature.")
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self, ReaderSearchViewController.self]).placeholder = placeholderText

        WPStyleGuide.configureSearchBar(searchBar)
        guard JetpackBrandingVisibility.all.enabled else {
            return
        }
        searchBar.inputAccessoryView = bannerView
        hideBannerViewIfNeeded()
    }

    /// hides the Jetpack powered banner on iPhone landscape
    private func hideBannerViewIfNeeded() {
        guard JetpackBrandingVisibility.all.enabled else {
            return
        }
        // hide the banner on iPhone landscape
        bannerView.isHidden = traitCollection.verticalSizeClass == .compact
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        hideBannerViewIfNeeded()
    }

    func configureFilterBar() {
        WPStyleGuide.configureFilterTabBar(filterBar)

        filterBar.tabSizingStyle = .equalWidths
        filterBar.items = sections

        filterBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
    }

    private func configureNavigationBar() {
        guard isModal() else {
            return
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                           target: self,
                                                           action: #selector(doneButtonPressed))
    }

    // MARK: - Actions

    @objc func endSearch() {
        searchBar.resignFirstResponder()
    }

    /// Constructs a ReaderSearchTopic from the search phrase and sets the
    /// embedded stream to the topic.
    ///
    private func performSearch(source: SearchSource = .userInput) {
        guard let phrase = searchBar.text?.trim(), !phrase.isEmpty else {
            return
        }
        ReaderSearchSuggestionService(coreDataStack: contextManager)
            .createOrUpdateSuggestion(forPhrase: phrase)

        let section = sections[filterBar.selectedIndex]
        showSearch(searchText: phrase, section: section)

        trackSearchPerformed(source: source)
    }

    private func trackSearchPerformed(source: SearchSource) {
        let selectedTab: Section = Section(rawValue: filterBar.selectedIndex) ?? .posts
        let properties: [AnyHashable: Any] = [
            "source": source.rawValue,
            "type": selectedTab.trackingValue
        ]
        WPAppAnalytics.track(.readerSearchPerformed, withProperties: properties)
    }

    private func showSearch(searchText: String, section: Section) {
        // TODO: handle empty

        switch section {
        case .posts:
            showPostSearch(for: searchText)
        case .sites:
            showSiteSearch(for: searchText)
        }
    }

    private func showPostSearch(for searchText: String) {
        let service = ReaderTopicService(coreDataStack: ContextManager.shared)
        service.createSearchTopic(forSearchPhrase: searchText) { topicID in
            assert(Thread.isMainThread)
            // TODO: needed?
            self.endSearch()

            guard let topicID, let topic = try? ContextManager.shared.mainContext.existingObject(with: topicID) as? ReaderAbstractTopic else {
                DDLogError("Failed to create a search topic")
                return
            }
            let postSearchVC = ReaderStreamViewController.controllerWithTopic(topic)
            self.showChild(postSearchVC)

            if let previousTopic = self.previousSearchTopic, topic != previousTopic {
                service.delete(previousTopic)
            }
            self.previousSearchTopic = topic
        }
    }

    private func showSiteSearch(for searchText: String) {
        let siteSearchVC = ReaderSiteSearchViewController()
        siteSearchVC.searchQuery = searchText
        showChild(siteSearchVC)
    }

    @objc private func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        let section = sections[filterBar.selectedIndex]
        let searchText = (searchBar.text ?? "").trim()
        showSearch(searchText: searchText, section: section)
    }

    // TODO: needed?
    @objc private func doneButtonPressed() {
        dismiss(animated: true)
    }

    private func showChild(_ viewController: UIViewController?) {
        if let currentChildVC {
            currentChildVC.willMove(toParent: nil)
            currentChildVC.view.removeFromSuperview()
            currentChildVC.removeFromParent()
        }

        guard let viewController else {
            return
        }

        viewController.willMove(toParent: self)
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.view.pinEdges(.horizontal)
        NSLayoutConstraint.activate([
            viewController.view.topAnchor.constraint(equalTo: filterBar.bottomAnchor),
            viewController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        viewController.didMove(toParent: self)

        self.currentChildVC = viewController
    }

    // MARK: Search Suggestions

    private func showSearchSuggestions() {
        let suggestionsVC = UIHostingController(rootView: ReaderSearchSuggestionsView(viewModel: suggestionsViewModel))
        self.showChild(suggestionsVC)
        self.suggestionsVC = suggestionsVC
    }

    // TODO: needed?
    private func hideSearchSuggestions() {
        guard let suggestionsVC else { return }
        suggestionsVC.willMove(toParent: nil)
        suggestionsVC.view.removeFromSuperview()
        suggestionsVC.removeFromParent()
        self.suggestionsVC = nil
    }
}

extension ReaderSearchViewController: UISearchBarDelegate {

    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        suggestionsViewModel.searchText = searchText.trim()
    }

    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        showSearchSuggestions()
    }

    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        hideSearchSuggestions()
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch()
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        endSearch()
    }

}
