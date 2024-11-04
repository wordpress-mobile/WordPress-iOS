import Foundation
import SwiftUI
import WordPressUI
import WordPressShared

/// Displays a version of the post stream with a search bar positioned above the
/// list of posts.  The user supplied search phrase is converted into a ReaderSearchTopic
/// the results of which are displayed in the embedded ReaderStreamViewController.
///
final class ReaderSearchViewController: UIViewController {
    enum Section: Int, FilterTabBarItem {
        case posts
        case sites

        var title: String {
            switch self {
            case .posts: Strings.posts
            case .sites: Strings.blogs
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

    private let filterBar = FilterTabBar()
    private let contentView = UIView()
    private let sections: [Section] = [.posts, .sites]

    private let searchController = UISearchController()
    private let suggestionsViewModel = ReaderSearchSuggestionsViewModel()
    private var suggestionsVC: UIViewController?
    private var currentChildVC: UIViewController?

    private var previousSearchTopic: ReaderAbstractTopic?
    private let contextManager = ContextManager.shared

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        setupView()
        setupNavigationBar()

        suggestionsViewModel.onSelection = { [weak self] in
            self?.searchController.searchBar.text = $0
            self?.performSearch(source: .searchHistory)
        }

        WPAppAnalytics.track(.readerSearchLoaded)
    }

    public override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)

        if parent == nil {
            ReaderTopicService(coreDataStack: ContextManager.shared)
                .deleteAllSearchTopics()
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // TODO: fix this
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // MARK: Setup

    private func setupView() {
        WPStyleGuide.configureFilterTabBar(filterBar)
        filterBar.tabSizingStyle = .equalWidths
        filterBar.items = sections
        filterBar.addTarget(self, action: #selector(selectedFilterDidChange), for: .valueChanged)

        let stackView = UIStackView(axis: .vertical, [filterBar, contentView])
        view.addSubview(stackView)
        stackView.pinEdges(to: view.safeAreaLayoutGuide)
    }

    private func setupNavigationBar() {
        navigationItem.title = Strings.title
        navigationItem.largeTitleDisplayMode = .never

        navigationItem.searchController = searchController
        searchController.delegate = self
        searchController.searchBar.delegate = self

        if isModal() {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed))
        }
    }

    // MARK: Actions

    private func performSearch(source: SearchSource = .userInput) {
        guard let searchText = searchController.searchBar.text?.trim(),
                !searchText.isEmpty else {
            return
        }
        ReaderSearchSuggestionService(coreDataStack: contextManager)
            .createOrUpdateSuggestion(forPhrase: searchText)

        let section = sections[filterBar.selectedIndex]
        showSearch(searchText: searchText, section: section)

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
        let searchText = (searchController.searchBar.text ?? "").trim()
        showSearch(searchText: searchText, section: section)
    }

    @objc private func doneButtonPressed() {
        dismiss(animated: true)
    }

    private func showChild(_ viewController: UIViewController?) {
        if let currentChildVC {
            currentChildVC.willMove(toParent: nil)
            currentChildVC.view.removeFromSuperview()
            currentChildVC.removeFromParent()
        }

        guard let viewController else { return }

        viewController.willMove(toParent: self)
        addChild(viewController)
        contentView.addSubview(viewController.view)
        viewController.view.pinEdges()
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

extension ReaderSearchViewController: UISearchControllerDelegate {
    func didPresentSearchController(_ searchController: UISearchController) {
        searchController.searchBar.becomeFirstResponder()
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
        searchBar.resignFirstResponder()
    }
}

private enum Strings {
    static let title = NSLocalizedString("reader.search.title", value: "Search", comment: "Title of the Reader's search feature")
    static let posts = NSLocalizedString("reader.search.tab.posts", value: "Posts", comment: "Title of a Reader tab showing Posts matching a user's search query")
    static let blogs = NSLocalizedString("reader.search.tab.blogs", value: "Blogs", comment: "Title of a Reader tab showing Sites matching a user's search query")
}
