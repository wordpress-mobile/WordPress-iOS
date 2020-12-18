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
    }

    // MARK: - Properties

    @IBOutlet fileprivate weak var searchBar: UISearchBar!
    @IBOutlet fileprivate weak var filterBar: FilterTabBar!
    @IBOutlet fileprivate weak var label: UILabel!

    fileprivate var backgroundTapRecognizer: UITapGestureRecognizer!
    fileprivate var streamController: ReaderStreamViewController?
    fileprivate var siteSearchController = ReaderSiteSearchViewController()
    fileprivate let searchBarSearchIconSize = CGFloat(13.0)
    fileprivate var suggestionsController: ReaderSearchSuggestionsViewController?
    fileprivate var restoredSearchTopic: ReaderSearchTopic?
    fileprivate var didBumpStats = false


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


    // MARK: - State Restoration


    public static func viewController(withRestorationIdentifierPath identifierComponents: [String],
                                      coder: NSCoder) -> UIViewController? {
        guard let path = coder.decodeObject(forKey: restorableSearchTopicPathKey) as? String else {
            return ReaderSearchViewController.controller()
        }

        let context = ContextManager.sharedInstance().mainContext
        let service = ReaderTopicService(managedObjectContext: context)
        guard let topic = service.find(withPath: path) as? ReaderSearchTopic else {
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

        WPStyleGuide.configureColors(view: view, tableView: nil)
        setupSearchBar()
        configureFilterBar()
        configureLabel()
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
        let context = ContextManager.sharedInstance().mainContext
        ReaderTopicService(managedObjectContext: context).deleteAllSearchTopics()
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

        QuickStartTourGuide.shared.visited(.readerSearch)
        WPAppAnalytics.track(.readerSearchLoaded)
        didBumpStats = true
    }


    // MARK: - Configuration


    @objc func setupSearchBar() {
        // Appearance must be set before the search bar is added to the view hierarchy.
        let placeholderText = NSLocalizedString("Search WordPress", comment: "Placeholder text for the Reader search feature.")
        let attributes = WPStyleGuide.defaultSearchBarTextAttributesSwifted(.neutral(.shade30))
        let attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: attributes)
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self, ReaderSearchViewController.self]).attributedPlaceholder = attributedPlaceholder
        let textAttributes = WPStyleGuide.defaultSearchBarTextAttributesSwifted(.neutral(.shade60))
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self, ReaderSearchViewController.self]).defaultTextAttributes = textAttributes
        searchBar.becomeFirstResponder()
        WPStyleGuide.configureSearchBar(searchBar)
    }

    func configureFilterBar() {
        WPStyleGuide.configureFilterTabBar(filterBar)

        filterBar.tabSizingStyle = .equalWidths
        filterBar.items = sections

        filterBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
    }

    @objc func configureLabel() {
        let text = NSLocalizedString("Search WordPress\nfor a site or post", comment: "A short message that is a call to action for the Reader's Search feature.")
        let rawAttributes = WPNUXUtility.titleAttributes(with: .neutral(.shade50)) as! [String: Any]
        let swiftedAttributes = NSAttributedString.Key.convertFromRaw(attributes: rawAttributes)
        label.numberOfLines = 2
        label.attributedText = NSAttributedString(string: text, attributes: swiftedAttributes)
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
        label.isHidden = true
        searchBar.text = topic.title
        streamController?.readerTopic = topic
    }

    private func configureSiteSearchViewController() {
        siteSearchController.view.translatesAutoresizingMaskIntoConstraints = false

        addChild(siteSearchController)

        view.addSubview(siteSearchController.view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: siteSearchController.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: siteSearchController.view.trailingAnchor),
            filterBar.bottomAnchor.constraint(equalTo: siteSearchController.view.topAnchor),
            view.bottomAnchor.constraint(equalTo: siteSearchController.view.bottomAnchor),
            ])

        siteSearchController.didMove(toParent: self)

        if let topic = restoredSearchTopic {
            siteSearchController.searchQuery = topic.title
        }

        siteSearchController.view.isHidden = true
    }

    // MARK: - Actions


    @objc func endSearch() {
        searchBar.resignFirstResponder()
    }


    /// Constructs a ReaderSearchTopic from the search phrase and sets the
    /// embedded stream to the topic.
    ///
    @objc func performSearch() {
        guard let phrase = searchBar.text?.trim(), !phrase.isEmpty else {
            return
        }

        performPostsSearch(for: phrase)
        performSitesSearch(for: phrase)
    }

    private func performPostsSearch(for phrase: String) {
        guard let streamController = streamController else {
            return
        }

        let previousTopic = streamController.readerTopic

        let context = ContextManager.sharedInstance().mainContext
        let service = ReaderTopicService(managedObjectContext: context)

        let topic = service.searchTopic(forSearchPhrase: phrase)
        streamController.readerTopic = topic
        WPAppAnalytics.track(.readerSearchPerformed)

        // Hide the starting label now that a topic has been set.
        label.isHidden = true
        endSearch()

        if let previousTopic = previousTopic {
            service.delete(previousTopic)
        }
    }

    private func performSitesSearch(for query: String) {
        siteSearchController.searchQuery = query
    }


    @objc func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
        endSearch()
    }

    @objc private func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        let section = sections[filterBar.selectedIndex]

        switch section {
        case .posts:
            streamController?.view.isHidden = false
            siteSearchController.view.isHidden = true
        case .sites:
            streamController?.view.isHidden = true
            siteSearchController.view.isHidden = false
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
        performSearch()
    }

}
