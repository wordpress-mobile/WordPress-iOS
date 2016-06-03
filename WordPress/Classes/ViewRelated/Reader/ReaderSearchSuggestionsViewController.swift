import UIKit
import WordPressShared

///
///
protocol ReaderSearchSuggestionsDelegate
{
    func searchSuggestionsController(controller: ReaderSearchSuggestionsViewController, selectedItem: String)
    func clearSuggestionsForSearchController(controller: ReaderSearchSuggestionsViewController)
}


///
///
class ReaderSearchSuggestionsViewController : UIViewController
{

    @IBOutlet var tableView: UITableView!
    @IBOutlet var clearButton: UIButton!
    @IBOutlet var stackViewHeightConstraint: NSLayoutConstraint!

    var phrase = "" {
        didSet {
            updatePredicateAndRefresh()
            updateHeightConstraint()
        }
    }

    var tableViewHandler: WPTableViewHandler!
    var delegate: ReaderSearchSuggestionsDelegate?
    var cellIdentifier = "CellIdentifier"
    let MaxTableViewRows = 5
    let ButtonHeight = CGFloat(44.0)


    /// A convenience method for instantiating the controller from the storyboard.
    ///
    /// - Returns: An instance of the controller.
    ///
    class func controller() -> ReaderSearchSuggestionsViewController {
        let storyboard = UIStoryboard(name: "Reader", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("ReaderSearchSuggestionsViewController") as! ReaderSearchSuggestionsViewController

        return controller
    }


    // MARK: - Lifecycle Methods


    override func viewDidLoad() {
        super.viewDidLoad()

        tableViewHandler = WPTableViewHandler(tableView: tableView)
        tableViewHandler.delegate = self

        tableView.tableFooterView = UIView()
        tableView.rowHeight = 44.0
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)

        let buttonTitle = NSLocalizedString("Clear search suggestions", comment: "Title of a button.")
        clearButton.setTitle(buttonTitle, forState: .Normal)

        updateHeightConstraint()
    }


    func updateHeightConstraint() {
        let count = suggestionsCount()
        let numVisibleRows = min(count, MaxTableViewRows)
        var height = CGFloat(numVisibleRows) * tableView.rowHeight
        height += ButtonHeight
        stackViewHeightConstraint.constant = height
    }


    func suggestionsCount() -> Int {
        return tableViewHandler.resultsController.fetchedObjects?.count ?? 0
    }


    func predicateForFetchRequest() -> NSPredicate? {
        if phrase.isEmpty {
            return nil
        }
        return NSPredicate(format: "searchPhrase BEGINSWITH[cd] %@", phrase)
    }


    func updatePredicateAndRefresh() {
        tableViewHandler.resultsController.fetchRequest.predicate = predicateForFetchRequest()
        do {
            try tableViewHandler.resultsController.performFetch()
        } catch let error as NSError {
            DDLogSwift.logError("Error fetching suggestions after updating the fetch reqeust predicate: \(error.localizedDescription)")
        }
        tableView.reloadData()
    }


    // MARK: - Actions


    @IBAction func handleClearButtonTapped(sender: UIButton) {
        let service = ReaderSearchSuggestionService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.deleteAllSuggestions()
        tableView.reloadData()
        updateHeightConstraint()
    }
}


extension ReaderSearchSuggestionsViewController : WPTableViewHandlerDelegate
{
    func managedObjectContext() -> NSManagedObjectContext! {
        return ContextManager.sharedInstance().mainContext
    }


    func fetchRequest() -> NSFetchRequest! {
        let request = NSFetchRequest(entityName: "ReaderSearchSuggestion")
        request.predicate = predicateForFetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return request
    }


    func configureCell(cell: UITableViewCell!, atIndexPath indexPath: NSIndexPath!) {
        let suggestions = tableViewHandler.resultsController.fetchedObjects as! [ReaderSearchSuggestion]
        let suggestion = suggestions[indexPath.row]
        cell.textLabel?.text = suggestion.searchPhrase
    }


    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }


    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        let suggestions = tableViewHandler.resultsController.fetchedObjects as! [ReaderSearchSuggestion]
        let suggestion = suggestions[indexPath.row]
        delegate?.searchSuggestionsController(self, selectedItem: suggestion.searchPhrase)
    }

}
