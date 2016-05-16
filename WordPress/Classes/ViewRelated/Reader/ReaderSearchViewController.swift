import Foundation

/// Displays a version of the post stream with a search bar positioned above the
/// list of posts.  The user supplied search phrase is converted into a ReaderSearchTopic
/// the results of which are displayed in the embedded ReaderStreamViewController.
///
@objc public class ReaderSearchViewController : UIViewController
{
    @IBOutlet private weak var searchBar: UISearchBar!
    private var streamController: ReaderStreamViewController!

    /// A convenience method for instantiating the controller from the storyboard.
    ///
    /// - Returns: An instance of the controller.
    ///
    public class func controller() -> ReaderSearchViewController {
        let storyboard = UIStoryboard(name: "Reader", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("ReaderSearchViewController") as! ReaderSearchViewController

        return controller
    }


    // MARK: Lifecycle methods

    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        streamController = segue.destinationViewController as? ReaderStreamViewController
    }


    // MARK: - Actions

    /// Constructs a ReaderSearchTopic from the search phrase and sets the
    /// embedded stream to the topic.
    ///
    func performSearch() {
        guard let phrase = searchBar.text else {
            return
        }

        let context = ContextManager.sharedInstance().mainContext
        let service = ReaderTopicService(managedObjectContext: context)

        let topic = service.searchTopicForSearchPhrase(phrase)
        streamController.readerTopic = topic
    }
}


extension ReaderSearchViewController : UISearchBarDelegate {

    public func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        performSearch()
    }

    public func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

}
