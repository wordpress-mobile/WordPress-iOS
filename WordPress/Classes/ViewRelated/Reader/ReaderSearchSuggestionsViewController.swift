import Foundation
import WordPressShared

/// Defines methods that a delegate should implement for clearing suggestions
/// and for responding to a selected suggestion.
///
protocol ReaderSearchSuggestionsDelegate
{
    func searchSuggestionsController(controller: ReaderSearchSuggestionsViewController, selectedItem: String)
    func clearSuggestionsForSearchController(controller: ReaderSearchSuggestionsViewController)
}


/// Displays a list of previously saved reader searches, sorted by most recent,
/// and filtered by the value of `phrase`.
///
class ReaderSearchSuggestionsViewController : UIViewController
{
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var clearButton: UIButton!
    @IBOutlet var borderImageView: UIImageView!
    @IBOutlet var stackViewHeightConstraint: NSLayoutConstraint!

    var phrase = "" {
        didSet {
            updatePredicateAndRefresh()
            updateHeightConstraint()
        }
    }

    var tableViewHandler: WPTableViewHandler!
    var delegate: ReaderSearchSuggestionsDelegate?
    let cellIdentifier = "CellIdentifier"
    let maxTableViewRows = 5
    let rowAndButtonHeight = CGFloat(44.0)


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
        tableView.rowHeight = rowAndButtonHeight
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)

        let buttonTitle = NSLocalizedString("Clear search history", comment: "Title of a button.")
        clearButton.setTitle(buttonTitle, forState: .Normal)
        let buttonBackgroundImage = UIImage(color: WPStyleGuide.lightGrey())
        clearButton.setBackgroundImage(buttonBackgroundImage, forState:.Normal)

        borderImageView.image = UIImage(color: WPStyleGuide.greyLighten10(), havingSize: CGSize(width: stackView.frame.width, height: 1))

        updateHeightConstraint()
    }


    // MARK: -  Instance Methods


    func updateHeightConstraint() {
        clearButton.hidden = suggestionsCount() == 0 || !phrase.isEmpty

        let count = suggestionsCount()
        let numVisibleRows = min(count, maxTableViewRows)
        var height = CGFloat(numVisibleRows) * tableView.rowHeight
        if !clearButton.hidden {
            height += rowAndButtonHeight
        }
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


    func clearSearchHistory() {
        let service = ReaderSearchSuggestionService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.deleteAllSuggestions()
        tableView.reloadData()
        updateHeightConstraint()
    }


    // MARK: - Actions


    @IBAction func handleClearButtonTapped(sender: UIButton) {
        let alert = UIAlertController(title: NSLocalizedString("Clear Search History", comment: "Title of an alert prompt."),
                                      message: NSLocalizedString("Would you like to clear your search history?", comment: "Asks the user if they would like to clear their search history."),
                                      preferredStyle: .Alert)

        alert.addCancelActionWithTitle(NSLocalizedString("Cancel", comment: "Button title. Cancels a pending action."))
        alert.addDefaultActionWithTitle(NSLocalizedString("Yes", comment: "Button title. Confirms that the user wants to proceed with a pending action.")) { (action) in
            self.clearSearchHistory()
        }

        alert.presentFromRootViewController()
    }
}


extension ReaderSearchSuggestionsViewController : WPTableViewHandlerDelegate
{
    func managedObjectContext() -> NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }


    func fetchRequest() -> NSFetchRequest {
        let request = NSFetchRequest(entityName: "ReaderSearchSuggestion")
        request.predicate = predicateForFetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return request
    }


    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let suggestions = tableViewHandler.resultsController.fetchedObjects as! [ReaderSearchSuggestion]
        let suggestion = suggestions[indexPath.row]
        cell.textLabel?.text = suggestion.searchPhrase
        cell.textLabel?.textColor = WPStyleGuide.darkGrey()
    }


    func tableViewDidChangeContent(tableView: UITableView) {
        updateHeightConstraint()
    }


    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }


    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        guard let suggestion = tableViewHandler.resultsController.objectOfType(ReaderSearchSuggestion.self, atIndexPath: indexPath) else {
            return
        }
        delegate?.searchSuggestionsController(self, selectedItem: suggestion.searchPhrase)
    }


    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }


    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }


    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        guard let suggestion = tableViewHandler.resultsController.objectOfType(ReaderSearchSuggestion.self, atIndexPath: indexPath) else {
            return
        }
        managedObjectContext().deleteObject(suggestion)
        ContextManager.sharedInstance().saveContext(managedObjectContext())
    }


    func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
        return NSLocalizedString("Delete", comment: "Title of a delete button")
    }
}
