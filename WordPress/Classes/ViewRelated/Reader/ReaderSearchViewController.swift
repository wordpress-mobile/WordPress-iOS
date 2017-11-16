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


    // MARK: - Properties

    @IBOutlet fileprivate weak var searchBar: UISearchBar!
    @IBOutlet fileprivate weak var label: UILabel!

    fileprivate var backgroundTapRecognizer: UITapGestureRecognizer!
    fileprivate var streamController: ReaderStreamViewController?
    fileprivate let searchBarSearchIconSize = CGFloat(13.0)
    fileprivate var suggestionsController: ReaderSearchSuggestionsViewController?
    fileprivate var restoredSearchTopic: ReaderSearchTopic?
    fileprivate var didBumpStats = false


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


    open static func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {
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


    deinit {
        NotificationCenter.default.removeObserver(self)
    }


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

        WPStyleGuide.configureColors(for: view, andTableView: nil)
        setupSearchBar()
        configureLabel()
        configureBackgroundTapRecognizer()
        configureForRestoredTopic()
    }


    open override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent)
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

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
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


    @objc func setupSearchBar() {
        // Appearance must be set before the search bar is added to the view hierarchy.
        let placeholderText = NSLocalizedString("Search WordPress.com", comment: "Placeholder text for the Reader search feature.")
        let attributes = WPStyleGuide.defaultSearchBarTextAttributesSwifted(WPStyleGuide.grey())
        let attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: attributes)
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self, ReaderSearchViewController.self]).attributedPlaceholder = attributedPlaceholder
        let textAttributes = WPStyleGuide.defaultSearchBarTextAttributes(WPStyleGuide.greyDarken30())
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self, ReaderSearchViewController.self]).defaultTextAttributes = textAttributes

        WPStyleGuide.configureSearchBar(searchBar)
    }


    @objc func configureLabel() {
        let text = NSLocalizedString("What would you like to find?", comment: "A short message that is a call to action for the Reader's Search feature.")
        let rawAttributes = WPNUXUtility.titleAttributes(with: WPStyleGuide.greyDarken20()) as! [String: Any]
        let swiftedAttributes = NSAttributedStringKey.convertFromRaw(attributes: rawAttributes)
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


    // MARK: - Actions


    @objc func endSearch() {
        searchBar.resignFirstResponder()
    }


    /// Constructs a ReaderSearchTopic from the search phrase and sets the
    /// embedded stream to the topic.
    ///
    @objc func performSearch() {
        guard let streamController = streamController else {
            return
        }

        guard let phrase = searchBar.text?.trim(), !phrase.isEmpty else {
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


    @objc func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
        endSearch()
    }


    // MARK: - Autocomplete


    /// Display the search suggestions view
    ///
    @objc func presentAutoCompleteView() {
        let controller = ReaderSearchSuggestionsViewController.controller()
        controller.delegate = self
        addChildViewController(controller)

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

        controller.didMove(toParentViewController: self)
        suggestionsController = controller
    }


    /// Remove the search suggestions view.
    ///
    @objc func dismissAutoCompleteView() {
        guard let controller = suggestionsController else {
            return
        }
        controller.willMove(toParentViewController: nil)
        controller.view.removeFromSuperview()
        controller.removeFromParentViewController()
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
