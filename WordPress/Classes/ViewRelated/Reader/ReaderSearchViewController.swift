import Foundation
import WordPressShared
import Gridicons

/// Displays a version of the post stream with a search bar positioned above the
/// list of posts.  The user supplied search phrase is converted into a ReaderSearchTopic
/// the results of which are displayed in the embedded ReaderStreamViewController.
///
@objc open class ReaderSearchViewController: UIViewController, UIViewControllerRestoration {
    @objc static let restorationClassIdentifier = "ReaderSearchViewControllerRestorationIdentifier"
    @objc static let restorableSearchTopicPathKey: String = "RestorableSearchTopicPathKey"

    fileprivate enum Section: Int, FilterTabBarItem {
        case posts
        case sites

        var title: String {
            switch self {
            case .posts: return NSLocalizedString("Posts", comment: "Title of a Reader tab showing Posts matching a user's search query")
            case .sites: return NSLocalizedString("Sites", comment: "Title of a Reader tab showing Sites matching a user's search query")
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

    fileprivate var backgroundTapRecognizer: UITapGestureRecognizer!
    fileprivate var streamController: ReaderStreamViewController?
    fileprivate lazy var jpSiteSearchController = JetpackBannerWrapperViewController(
        childVC: ReaderSiteSearchViewController(),
        screen: .readerSearch
    )
    fileprivate var siteSearchController: ReaderSiteSearchViewController? {
        return jpSiteSearchController.childVC as? ReaderSiteSearchViewController
    }
    fileprivate var suggestionsController: ReaderSearchSuggestionsViewController?
    fileprivate var restoredSearchTopic: ReaderSearchTopic?
    fileprivate var didBumpStats = false

    private lazy var bannerView: JetpackBannerView = {
        let textProvider = JetpackBrandingTextProvider(screen: JetpackBannerScreen.readerSearch)
        let bannerView = JetpackBannerView()
        bannerView.configure(title: textProvider.brandingText()) { [unowned self] in
            JetpackBrandingCoordinator.presentOverlay(from: self)
            JetpackBrandingAnalyticsHelper.trackJetpackPoweredBannerTapped(screen: .readerSearch)
        }
        bannerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: JetpackBannerView.minimumHeight)
        return bannerView
    }()

    fileprivate let sections: [Section] = [ .posts, .sites ]

    /// A convenience method for instantiating the controller from the storyboard.
    ///
    /// - Returns: An instance of the controller.
    ///
    @objc open class func controller() -> ReaderSearchViewController {
        let storyboard = UIStoryboard(name: "Reader", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "ReaderSearchViewController") as! ReaderSearchViewController
        return controller
    }

    @objc open class func controller(withSearchText searchText: String) -> ReaderSearchViewController {
        let controller = controller()
        controller.loadViewIfNeeded()
        controller.searchBar.searchTextField.text = searchText
        controller.performSearch()
        return controller
    }

    // MARK: - State Restoration

    public static func viewController(withRestorationIdentifierPath identifierComponents: [String],
                                      coder: NSCoder) -> UIViewController? {
        guard let path = coder.decodeObject(forKey: restorableSearchTopicPathKey) as? String else {
            return ReaderSearchViewController.controller()
        }

        guard let topic = try? ReaderAbstractTopic.lookup(withPath: path, in: ContextManager.shared.mainContext) as? ReaderSearchTopic else {
            return ReaderSearchViewController.controller()
        }

        let storyboard = UIStoryboard(name: "Reader", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "ReaderSearchViewController") as! ReaderSearchViewController
        controller.restoredSearchTopic = topic
        return controller
    }

    open override func encodeRestorableState(with coder: NSCoder) {
        if let topic = streamController?.readerTopic {
            coder.encode(topic.path, forKey: type(of: self).restorableSearchTopicPathKey)
        }
        super.encodeRestorableState(with: coder)
    }

    // MARK: Lifecycle methods

    open override func awakeAfter(using aDecoder: NSCoder) -> Any? {
        restorationIdentifier = type(of: self).restorationClassIdentifier
        restorationClass = type(of: self)

        return super.awakeAfter(using: aDecoder)
    }

    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        streamController = segue.destination as? ReaderStreamViewController
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Search", comment: "Title of the Reader's search feature")
        navigationItem.largeTitleDisplayMode = .never

        WPStyleGuide.configureColors(view: view, tableView: nil)
        setupSearchBar()
        configureFilterBar()
        configureBackgroundTapRecognizer()
        configureForRestoredTopic()
        configureSiteSearchViewController()
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

        searchBar.becomeFirstResponder()
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

    @objc func configureBackgroundTapRecognizer() {
        backgroundTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ReaderSearchViewController.handleBackgroundTap(_:)))
        backgroundTapRecognizer.cancelsTouchesInView = true
        backgroundTapRecognizer.isEnabled = false
        backgroundTapRecognizer.delegate = self
        view.addGestureRecognizer(backgroundTapRecognizer)
    }

    @objc func configureForRestoredTopic() {
        guard let topic = restoredSearchTopic else {
            return
        }
        searchBar.text = topic.title
        streamController?.readerTopic = topic
    }

    private func configureSiteSearchViewController() {
        jpSiteSearchController.view.translatesAutoresizingMaskIntoConstraints = false

        addChild(jpSiteSearchController)

        view.addSubview(jpSiteSearchController.view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: jpSiteSearchController.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: jpSiteSearchController.view.trailingAnchor),
            filterBar.bottomAnchor.constraint(equalTo: jpSiteSearchController.view.topAnchor),
            view.bottomAnchor.constraint(equalTo: jpSiteSearchController.view.bottomAnchor),
            ])

        jpSiteSearchController.didMove(toParent: self)

        if let topic = restoredSearchTopic {
            siteSearchController?.searchQuery = topic.title
        }

        jpSiteSearchController.view.isHidden = true
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

        performPostsSearch(for: phrase)
        performSitesSearch(for: phrase)
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

    private func performPostsSearch(for phrase: String) {
        guard let streamController = streamController else {
            return
        }

        let previousTopic = streamController.readerTopic

        let service = ReaderTopicService(coreDataStack: ContextManager.shared)
        service.createSearchTopic(forSearchPhrase: phrase) { topicID in
            assert(Thread.isMainThread)
            self.endSearch()

            guard let topicID, let topic = try? ContextManager.shared.mainContext.existingObject(with: topicID) as? ReaderAbstractTopic else {
                DDLogError("Failed to create a search topic")
                return
            }
            streamController.readerTopic = topic

            if let previousTopic, topic != previousTopic {
                service.delete(previousTopic)
            }
        }
    }

    private func performSitesSearch(for query: String) {
        siteSearchController?.searchQuery = query
    }

    @objc func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
        endSearch()
    }

    @objc private func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        let section = sections[filterBar.selectedIndex]

        switch section {
        case .posts:
            streamController?.view.isHidden = false
            jpSiteSearchController.view.isHidden = true
        case .sites:
            streamController?.view.isHidden = true
            jpSiteSearchController.view.isHidden = false
        }
    }

    // MARK: - Autocomplete

    /// Display the search suggestions view
    ///
    @objc func presentAutoCompleteView() {
        let controller = ReaderSearchSuggestionsViewController.controller()
        controller.delegate = self
        addChild(controller)

        guard let autoView = controller.view, let searchBar = searchBar else {
            fatalError("Unexpected")
        }

        autoView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(autoView)

        let views = [
            "searchBar": searchBar,
            "autoView": autoView
        ]

        // Match the width of the search bar.
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "[autoView(==searchBar)]",
            options: .alignAllLastBaseline,
            metrics: nil,
            views: views))
        // Pin below the search bar.
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[searchBar][autoView]",
            options: .alignAllCenterX,
            metrics: nil,
            views: views))
        // Center on the search bar.
        view.addConstraint(NSLayoutConstraint(
            item: autoView,
            attribute: .centerX,
            relatedBy: .equal,
            toItem: searchBar,
            attribute: .centerX,
            multiplier: 1,
            constant: 0))

        view.setNeedsUpdateConstraints()

        controller.didMove(toParent: self)
        suggestionsController = controller
    }

    /// Remove the search suggestions view.
    ///
    @objc func dismissAutoCompleteView() {
        guard let controller = suggestionsController else {
            return
        }
        controller.willMove(toParent: nil)
        controller.view.removeFromSuperview()
        controller.removeFromParent()
        suggestionsController = nil
    }

}

extension ReaderSearchViewController: UIGestureRecognizerDelegate {

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let suggestionsView = suggestionsController?.view else {
            return true
        }

        // The gesture recognizer should not handle touches inside the suggestions view.
        // We want those taps to be processed normally.
        let point = touch.location(in: suggestionsView)
        if suggestionsView.bounds.contains(point) {
            return false
        }

        return true
    }
}

extension ReaderSearchViewController: UISearchBarDelegate {

    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // update the autocomplete suggestions
        suggestionsController?.phrase = searchText.trim()
    }

    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        backgroundTapRecognizer.isEnabled = true
        // prepare autocomplete view
        presentAutoCompleteView()
    }

    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        // remove auto complete view
        dismissAutoCompleteView()
        backgroundTapRecognizer.isEnabled = false
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch()
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        endSearch()
    }

}

extension ReaderSearchViewController: ReaderSearchSuggestionsDelegate {

    @objc func searchSuggestionsController(_ controller: ReaderSearchSuggestionsViewController, selectedItem: String) {
        searchBar.text = selectedItem
        performSearch(source: .searchHistory)
    }

}
