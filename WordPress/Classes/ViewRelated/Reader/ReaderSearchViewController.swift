import Foundation
import WordPressShared
import Gridicons

/// Displays a version of the post stream with a search bar positioned above the
/// list of posts.  The user supplied search phrase is converted into a ReaderSearchTopic
/// the results of which are displayed in the embedded ReaderStreamViewController.
///
@objc public class ReaderSearchViewController : UIViewController
{
    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var label: UILabel!

    private var backgroundTapRecognizer: UITapGestureRecognizer!
    private var streamController: ReaderStreamViewController!
    private let searchBarSearchIconSize = CGFloat(13.0)


    /// A convenience method for instantiating the controller from the storyboard.
    ///
    /// - Returns: An instance of the controller.
    ///
    public class func controller() -> ReaderSearchViewController {
        let storyboard = UIStoryboard(name: "Reader", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("ReaderSearchViewController") as! ReaderSearchViewController

        return controller
    }


    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: Lifecycle methods


    public override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Search", comment: "Title of the Reader's search feature")

        WPStyleGuide.configureColorsForView(view, andTableView: nil)
        setupSearchBar()
        configureLabel()
        configureBackgroundTapRecognizer()
    }


    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ReaderSearchViewController.handleKeyboardDidShow(_:)), name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ReaderSearchViewController.handleKeyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }


    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        // Dismiss the keyboard if it was visible.
        endSearch()

        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }


    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        streamController = segue.destinationViewController as? ReaderStreamViewController
    }



    // MARK: - Configuration


    func setupSearchBar() {
        // Appearance must be set before the search bar is added to the view hierarchy.
        let placeholderText = NSLocalizedString("Search on WordPress.com", comment: "Placeholder text for the Reader search feature.")
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
        view.addGestureRecognizer(backgroundTapRecognizer)
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

        guard let phrase = searchBar.text else {
            return
        }

        let context = ContextManager.sharedInstance().mainContext
        let service = ReaderTopicService(managedObjectContext: context)

        let topic = service.searchTopicForSearchPhrase(phrase)
        streamController.readerTopic = topic

        // Hide the starting label now that a topic has been set.
        label.hidden = true
        endSearch()
    }


    func handleBackgroundTap(gesture: UITapGestureRecognizer) {
        endSearch()
    }


    func handleKeyboardDidShow(notification: NSNotification) {
        backgroundTapRecognizer.enabled = true
    }


    func handleKeyboardWillHide(notification: NSNotification) {
        backgroundTapRecognizer.enabled = false
    }
}


extension ReaderSearchViewController : UISearchBarDelegate {

    public func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        performSearch()
    }

    public func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        endSearch()
    }

}
