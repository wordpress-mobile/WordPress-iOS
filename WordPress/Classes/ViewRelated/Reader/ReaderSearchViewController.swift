import Foundation
import WordPressShared
import Gridicons

/// Displays a version of the post stream with a search bar positioned above the
/// list of posts.  The user supplied search phrase is converted into a ReaderSearchTopic
/// the results of which are displayed in the embedded ReaderStreamViewController.
///
@objc public class ReaderSearchViewController : UIViewController, UIViewControllerRestoration
{

    static let restorableSearchTopicPathKey: String = "RestorableSearchTopicPathKey"


    // MARK: - Properties

    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var label: UILabel!

    private var backgroundTapRecognizer: UITapGestureRecognizer!
    private var streamController: ReaderStreamViewController!
    private let searchBarSearchIconSize = CGFloat(13.0)
    private var suggestionsController: ReaderSearchSuggestionsViewController?
    private var restoredSearchTopic: ReaderSearchTopic?


    /// A convenience method for instantiating the controller from the storyboard.
    ///
    /// - Returns: An instance of the controller.
    ///
    public class func controller() -> ReaderSearchViewController {
        let storyboard = UIStoryboard(name: "Reader", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("ReaderSearchViewController") as! ReaderSearchViewController
        WPAppAnalytics.track(.ReaderSearchLoaded)
        return controller
    }


    // MARK: - State Restoration


    public static func viewControllerWithRestorationIdentifierPath(identifierComponents: [AnyObject], coder: NSCoder) -> UIViewController? {
        guard let path = coder.decodeObjectForKey(restorableSearchTopicPathKey) as? String else {
            return nil
        }

        let context = ContextManager.sharedInstance().mainContext
        let service = ReaderTopicService(managedObjectContext: context)
        guard let topic = service.findWithPath(path) as? ReaderSearchTopic else {
            return nil
        }

        topic.preserveForRestoration = false
        ContextManager.sharedInstance().saveContextAndWait(context)

        let storyboard = UIStoryboard(name: "Reader", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("ReaderSearchViewController") as! ReaderSearchViewController
        controller.restoredSearchTopic = topic
        return controller
    }


    public override func encodeRestorableStateWithCoder(coder: NSCoder) {
        if let topic = streamController.readerTopic {
            topic.preserveForRestoration = true
            ContextManager.sharedInstance().saveContextAndWait(topic.managedObjectContext)
            coder.encodeObject(topic.path, forKey: self.dynamicType.restorableSearchTopicPathKey)
        }
        super.encodeRestorableStateWithCoder(coder)
    }


    // MARK: Lifecycle methods


    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }


    public override func awakeAfterUsingCoder(aDecoder: NSCoder) -> AnyObject? {
        restorationClass = self.dynamicType

        return super.awakeAfterUsingCoder(aDecoder)
    }


    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        streamController = segue.destinationViewController as? ReaderStreamViewController
    }


    public override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Search", comment: "Title of the Reader's search feature")

        WPStyleGuide.configureColorsForView(view, andTableView: nil)
        setupSearchBar()
        configureLabel()
        configureBackgroundTapRecognizer()
        configureForRestoredTopic()
    }


    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        // Dismiss the keyboard if it was visible.
        endSearch()

        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }


    // MARK: - Configuration


    func setupSearchBar() {
        // Appearance must be set before the search bar is added to the view hierarchy.
        let placeholderText = NSLocalizedString("Search WordPress.com", comment: "Placeholder text for the Reader search feature.")
        let attributes = WPStyleGuide.defaultSearchBarTextAttributes(WPStyleGuide.grey())
        let attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: attributes)
        UITextField.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self, ReaderSearchViewController.self]).attributedPlaceholder = attributedPlaceholder
        let textAttributes = WPStyleGuide.defaultSearchBarTextAttributes(WPStyleGuide.greyDarken30())
        UITextField.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self, ReaderSearchViewController.self]).defaultTextAttributes = textAttributes

        searchBar.autocapitalizationType = .None
        searchBar.translucent = false
        searchBar.tintColor = WPStyleGuide.grey()
        searchBar.barTintColor = WPStyleGuide.greyLighten30()
        searchBar.backgroundImage = UIImage()
        searchBar.setImage(UIImage(named: "icon-clear-textfield"), forSearchBarIcon: .Clear, state: .Normal)

        let size = searchBarSearchIconSize * UIScreen.mainScreen().scale
        let image = Gridicon.iconOfType(GridiconType.Search, withSize: CGSize(width: size, height: size))

        searchBar.setImage(image, forSearchBarIcon: .Search, state: .Normal)
        searchBar.accessibilityIdentifier = "Search"
    }


    func configureLabel() {
        let text = NSLocalizedString("What would you like to find?", comment: "A short message that is a call to action for the Reader's Search feature.")
        let attributes = WPNUXUtility.titleAttributesWithColor(WPStyleGuide.greyDarken20()) as! [String: AnyObject]
        label.attributedText = NSAttributedString(string: text, attributes: attributes)
    }


    func configureBackgroundTapRecognizer() {
        backgroundTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ReaderSearchViewController.handleBackgroundTap(_:)))
        backgroundTapRecognizer.cancelsTouchesInView = true
        backgroundTapRecognizer.enabled = false
        backgroundTapRecognizer.delegate = self
        view.addGestureRecognizer(backgroundTapRecognizer)
    }


    func configureForRestoredTopic() {
        guard let topic = restoredSearchTopic else {
            return
        }
        label.hidden = true
        searchBar.text = topic.title
        streamController.readerTopic = topic
    }


    // MARK: - Actions


    func endSearch() {
        searchBar.resignFirstResponder()
    }


    /// Constructs a ReaderSearchTopic from the search phrase and sets the
    /// embedded stream to the topic.
    ///
    func performSearch() {
        assert(streamController != nil)

        guard let phrase = searchBar.text?.trim() where !phrase.isEmpty else {
            return
        }

        let context = ContextManager.sharedInstance().mainContext
        let service = ReaderTopicService(managedObjectContext: context)

        let topic = service.searchTopicForSearchPhrase(phrase)
        streamController.readerTopic = topic
        WPAppAnalytics.track(.ReaderSearchPerformed)

        // Hide the starting label now that a topic has been set.
        label.hidden = true
        endSearch()
    }


    func handleBackgroundTap(gesture: UITapGestureRecognizer) {
        endSearch()
    }


    // MARK: - Autocomplete


    /// Display the search suggestions view
    ///
    func presentAutoCompleteView() {
        let controller = ReaderSearchSuggestionsViewController.controller()
        controller.delegate = self
        addChildViewController(controller)

        let autoView = controller.view
        autoView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(autoView)

        let views = [
            "searchBar": searchBar,
            "autoView" : autoView
        ]

        // Match the width of the search bar.
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("[autoView(==searchBar)]",
            options: .AlignAllBaseline,
            metrics: nil,
            views: views))
        // Pin below the search bar.
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[searchBar][autoView]",
            options: .AlignAllCenterX,
            metrics: nil,
            views: views))
        // Center on the search bar.
        view.addConstraint(NSLayoutConstraint(
            item: autoView,
            attribute: .CenterX,
            relatedBy: .Equal,
            toItem: searchBar,
            attribute: .CenterX,
            multiplier: 1,
            constant: 0))

        view.setNeedsUpdateConstraints()

        controller.didMoveToParentViewController(self)
        suggestionsController = controller
    }


    /// Remove the search suggestions view.
    ///
    func dismissAutoCompleteView() {
        guard let controller = suggestionsController else {
            return
        }
        controller.willMoveToParentViewController(nil)
        controller.view.removeFromSuperview()
        controller.removeFromParentViewController()
        suggestionsController = nil
    }

}


extension ReaderSearchViewController : UIGestureRecognizerDelegate {

    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        guard let suggestionsView = suggestionsController?.view else {
            return true
        }

        // The gesture recognizer should not handle touches inside the suggestions view.
        // We want those taps to be processed normally.
        let point = touch.locationInView(suggestionsView)
        if CGRectContainsPoint(suggestionsView.bounds, point) {
            return false
        }

        return true
    }
}


extension ReaderSearchViewController : UISearchBarDelegate {

    public func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        // update the autocomplete suggestions
        suggestionsController?.phrase = searchText.trim()
    }


    public func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        backgroundTapRecognizer.enabled = true
        // prepare autocomplete view
        presentAutoCompleteView()
    }


    public func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        // remove auto complete view
        dismissAutoCompleteView()
        backgroundTapRecognizer.enabled = false
    }


    public func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        performSearch()
    }


    public func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        endSearch()
    }

}


extension ReaderSearchViewController : ReaderSearchSuggestionsDelegate {

    func searchSuggestionsController(controller: ReaderSearchSuggestionsViewController, selectedItem: String) {
        searchBar.text = selectedItem
        performSearch()
    }


    func clearSuggestionsForSearchController(controller: ReaderSearchSuggestionsViewController) {
        let service = ReaderSearchSuggestionService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.deleteAllSuggestions()
    }
}
