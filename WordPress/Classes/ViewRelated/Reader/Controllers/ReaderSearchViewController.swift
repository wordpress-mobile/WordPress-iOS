import Foundation
import SwiftUI
import CoreData
import WordPressUI
import WordPressShared

final class ReaderSearchViewController: UIViewController {
    private enum Section: Int, FilterTabBarItem {
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
            case .posts: "posts"
            case .sites: "sites"
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
    private var postsResulsViewContoller: UIViewController?
    private var sitesResulsViewContoller: UIViewController?
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
        showSearchSuggestions()

        WPAppAnalytics.track(.readerSearchLoaded)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DispatchQueue.main.async {
            self.searchController.searchBar.becomeFirstResponder()
        }
    }

    public override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)

        if parent == nil {
            ReaderTopicService(coreDataStack: ContextManager.shared)
                .deleteAllSearchTopics()
        }
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
        searchController.hidesNavigationBarDuringPresentation = false
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
        searchController.searchBar.resignFirstResponder()
        if source == .userInput {
            suggestionsViewModel.saveSearchText(searchText)
        }
        trackSearchPerformed(source: source)

        postsResulsViewContoller = nil
        sitesResulsViewContoller = nil

        let section = sections[filterBar.selectedIndex]
        showResults(searchText: searchText, section: section)
    }

    private func showResults(searchText: String, section: Section) {
        guard !searchText.isEmpty else {
            return
        }
        switch section {
        case .posts:
            if let postsResulsViewContoller {
                showChild(postsResulsViewContoller)
            } else {
                showPostSearch(for: searchText)
            }
        case .sites:
            if let sitesResulsViewContoller {
                showChild(sitesResulsViewContoller)
            } else {
                showSiteSearch(for: searchText)
            }
        }
    }

    private func showPostSearch(for searchText: String) {
        let service = ReaderTopicService(coreDataStack: contextManager)
        service.createSearchTopic(forSearchPhrase: searchText) {
            assert(Thread.isMainThread)
            self.didCreateSearchTopic(withID: $0)
        }
    }

    private func didCreateSearchTopic(withID topicID: NSManagedObjectID?) {
        guard let topicID, let topic = try? contextManager.mainContext.existingObject(with: topicID) as? ReaderAbstractTopic else {
            wpAssertionFailure("Failed to create a search topic")
            return
        }
        let postSearchVC = ReaderStreamViewController.controllerWithTopic(topic)
        showChild(postSearchVC)
        postsResulsViewContoller = postSearchVC

        if let previousTopic = self.previousSearchTopic, topic != previousTopic {
            ReaderTopicService(coreDataStack: contextManager).delete(previousTopic)
        }
        previousSearchTopic = topic
    }

    private func showSiteSearch(for searchText: String) {
        let siteSearchVC = ReaderSiteSearchViewController()
        siteSearchVC.searchQuery = searchText
        showChild(siteSearchVC)
        sitesResulsViewContoller = siteSearchVC
    }

    private func trackSearchPerformed(source: SearchSource) {
        let selectedTab: Section = Section(rawValue: filterBar.selectedIndex) ?? .posts
        let properties: [AnyHashable: Any] = [
            "source": source.rawValue,
            "type": selectedTab.trackingValue
        ]
        WPAppAnalytics.track(.readerSearchPerformed, withProperties: properties)
    }

    @objc private func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        let section = sections[filterBar.selectedIndex]
        let searchText = (searchController.searchBar.text ?? "").trim()
        showResults(searchText: searchText, section: section)
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

    private func showSearchSuggestions() {
        let suggestionsVC = UIHostingController(rootView: ReaderSearchSuggestionsView(viewModel: suggestionsViewModel))
        self.showChild(suggestionsVC)
        self.suggestionsVC = suggestionsVC
    }
}

extension ReaderSearchViewController: UISearchBarDelegate {

    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        suggestionsViewModel.searchText = searchText.trim()
    }

    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        showSearchSuggestions()
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch()
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        suggestionsViewModel.searchText == ""
        showSearchSuggestions()
    }
}

private enum Strings {
    static let title = NSLocalizedString("reader.search.title", value: "Search", comment: "Title of the Reader's search feature")
    static let posts = NSLocalizedString("reader.search.tab.posts", value: "Posts", comment: "Title of a Reader tab showing Posts matching a user's search query")
    static let blogs = NSLocalizedString("reader.search.tab.blogs", value: "Blogs", comment: "Title of a Reader tab showing Sites matching a user's search query")
}
