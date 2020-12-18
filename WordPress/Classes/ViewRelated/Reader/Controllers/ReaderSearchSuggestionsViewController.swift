import Foundation
import CocoaLumberjack
import WordPressShared

/// Defines methods that a delegate should implement for clearing suggestions
/// and for responding to a selected suggestion.
///
protocol ReaderSearchSuggestionsDelegate {
    func searchSuggestionsController(_ controller: ReaderSearchSuggestionsViewController, selectedItem: String)
}


/// Displays a list of previously saved reader searches, sorted by most recent,
/// and filtered by the value of `phrase`.
///
class ReaderSearchSuggestionsViewController: UIViewController {
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var clearButton: UIButton!
    @IBOutlet var borderImageView: UIImageView!
    @IBOutlet var stackViewHeightConstraint: NSLayoutConstraint!

    @objc var phrase = "" {
        didSet {
            updatePredicateAndRefresh()
            updateHeightConstraint()
        }
    }

    @objc var tableViewHandler: WPTableViewHandler!
    var delegate: ReaderSearchSuggestionsDelegate?
    @objc let cellIdentifier = "CellIdentifier"
    @objc let rowAndButtonHeight = CGFloat(44.0)
    @objc var maxTableViewRows: Int {
        let height = UIApplication.shared.keyWindow?.frame.size.height ?? 0
        if height == 320 {
            // iPhone 4s, 5, 5s, in landscape orientation
            return 1
        } else if height <= 480 {
            // iPhone 4s in portrait orientation
            return 2
        } else if height <= 568 {
            // iPhone 5, 5s in portrait orientation
            return 4
        }
        // Everything else
        return 5
    }


    /// A convenience method for instantiating the controller from the storyboard.
    ///
    /// - Returns: An instance of the controller.
    ///
    @objc class func controller() -> ReaderSearchSuggestionsViewController {
        let storyboard = UIStoryboard(name: "Reader", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "ReaderSearchSuggestionsViewController") as! ReaderSearchSuggestionsViewController

        return controller
    }


    // MARK: - Lifecycle Methods


    override func viewDidLoad() {
        super.viewDidLoad()

        tableViewHandler = WPTableViewHandler(tableView: tableView)
        tableViewHandler.delegate = self

        tableView.tableFooterView = UIView()
        tableView.rowHeight = rowAndButtonHeight
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        WPStyleGuide.configureColors(view: view, tableView: tableView)

        let buttonTitle = NSLocalizedString("Clear search history", comment: "Title of a button.")
        clearButton.setTitle(buttonTitle, for: UIControl.State())
        let buttonBackgroundImage = UIImage(color: .listBackground)
        clearButton.setBackgroundImage(buttonBackgroundImage, for: UIControl.State())

        borderImageView.image = UIImage(color: .neutral(.shade20), havingSize: CGSize(width: stackView.frame.width, height: 1))

        updateHeightConstraint()
    }


    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (_) in
            self.updateHeightConstraint()
            })
    }


    // MARK: - Instance Methods


    @objc func updateHeightConstraint() {
        clearButton.isHidden = suggestionsCount() == 0 || !phrase.isEmpty

        let count = suggestionsCount()
        let numVisibleRows = min(count, maxTableViewRows)
        var height = CGFloat(numVisibleRows) * tableView.rowHeight
        if !clearButton.isHidden {
            height += rowAndButtonHeight
        }
        stackViewHeightConstraint.constant = height
    }


    @objc func suggestionsCount() -> Int {
        return tableViewHandler.resultsController.fetchedObjects?.count ?? 0
    }


    @objc func predicateForFetchRequest() -> NSPredicate? {
        if phrase.isEmpty {
            return nil
        }
        return NSPredicate(format: "searchPhrase BEGINSWITH[cd] %@", phrase)
    }


    @objc func updatePredicateAndRefresh() {
        tableViewHandler.resultsController.fetchRequest.predicate = predicateForFetchRequest()
        do {
            try tableViewHandler.resultsController.performFetch()
        } catch let error as NSError {
            DDLogError("Error fetching suggestions after updating the fetch reqeust predicate: \(error.localizedDescription)")
        }
        tableView.reloadData()
    }


    @objc func clearSearchHistory() {
        let service = ReaderSearchSuggestionService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.deleteAllSuggestions()
        tableView.reloadData()
        updateHeightConstraint()
    }


    // MARK: - Actions


    @IBAction func handleClearButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: NSLocalizedString("Clear Search History", comment: "Title of an alert prompt."),
                                      message: NSLocalizedString("Would you like to clear your search history?", comment: "Asks the user if they would like to clear their search history."),
                                      preferredStyle: .alert)

        alert.addCancelActionWithTitle(NSLocalizedString("Cancel", comment: "Button title. Cancels a pending action."))
        alert.addDefaultActionWithTitle(NSLocalizedString("Yes", comment: "Button title. Confirms that the user wants to proceed with a pending action.")) { (action) in
            self.clearSearchHistory()
        }

        alert.presentFromRootViewController()
    }
}


extension ReaderSearchSuggestionsViewController: WPTableViewHandlerDelegate {
    func managedObjectContext() -> NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }


    func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ReaderSearchSuggestion")
        request.predicate = predicateForFetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return request
    }


    func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        guard let suggestions = tableViewHandler.resultsController.fetchedObjects as? [ReaderSearchSuggestion] else {
            return
        }
        let suggestion = suggestions[indexPath.row]
        cell.textLabel?.text = suggestion.searchPhrase
        cell.textLabel?.textColor = .neutral(.shade70)
    }


    func tableViewDidChangeContent(_ tableView: UITableView) {
        updateHeightConstraint()
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        configureCell(cell, at: indexPath)
        return cell
    }


    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let suggestion = tableViewHandler.resultsController.object(at: indexPath) as? ReaderSearchSuggestion else {
            return
        }
        delegate?.searchSuggestionsController(self, selectedItem: suggestion.searchPhrase)
    }


    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }


    func tableView(_ tableView: UITableView,
                   editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle.delete
    }


    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        guard let suggestion = tableViewHandler.resultsController.object(at: indexPath) as? ReaderSearchSuggestion else {
            return
        }
        managedObjectContext().delete(suggestion)
        ContextManager.sharedInstance().save(managedObjectContext())
    }


    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return NSLocalizedString("Delete", comment: "Title of a delete button")
    }
}
