import Foundation
import CocoaLumberjack
import WordPressShared

class PortfolioListViewController: AbstractPostListViewController, UIViewControllerRestoration {
    
    fileprivate static let portfolioViewControllerRestorationKey = "PortfolioViewControllerRestorationKey"
    
    // MARK: - Convenience constructors
    
    class func controllerWithBlog(_ blog: Blog) -> PortfolioListViewController {
        
        let storyBoard = UIStoryboard(name: "Portfolio", bundle: Bundle.main)
        let controller = storyBoard.instantiateViewController(withIdentifier: "PortfolioListViewController") as! PortfolioListViewController
        
        controller.blog = blog
        controller.restorationClass = self
        
        return controller
    }
    
    // MARK: - UIViewControllerRestoration
    
    class func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {
        
        let context = ContextManager.sharedInstance().mainContext

        guard let blogID = coder.decodeObject(forKey: portfolioViewControllerRestorationKey) as? String,
            let objectURL = URL(string: blogID),
            let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: objectURL),
            let restoredBlog = try? context.existingObject(with: objectID) as! Blog else {

                return nil
        }

        return self.controllerWithBlog(restoredBlog)
    }
    
    // MARK: - UIStateRestoring
    
    override func encodeRestorableState(with coder: NSCoder) {
        
        let objectString = blog?.objectID.uriRepresentation().absoluteString
        
        coder.encode(objectString, forKey: type(of: self).portfolioViewControllerRestorationKey)
        
        super.encodeRestorableState(with: coder)
    }
    
    // MARK: - UIViewController
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.refreshNoResultsView = { [weak self] noResultsView in
            // TODO:
//            self?.handleRefreshNoResultsView(noResultsView)
        }
        super.tableViewController = (segue.destination as! UITableViewController)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO:
//        title = NSLocalizedString("Pages", comment: "Tile of the screen showing the list of pages for a blog.")
    }
    
    // MARK: - Configuration
    
    override func configureTableView() {
        tableView.accessibilityIdentifier = "PortfolioTable"
        tableView.isAccessibilityElement = true
        // TODO:
//        tableView.estimatedRowHeight = type(of: self).pageCellEstimatedRowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        
//        let bundle = Bundle.main
        
        // Register the cells
        // TODO:
//        let pageCellNib = UINib(nibName: type(of: self).pageCellNibName, bundle: bundle)
//        tableView.register(pageCellNib, forCellReuseIdentifier: type(of: self).pageCellIdentifier)
//
//        let restorePageCellNib = UINib(nibName: type(of: self).restorePageCellNibName, bundle: bundle)
//        tableView.register(restorePageCellNib, forCellReuseIdentifier: type(of: self).restorePageCellIdentifier)
        
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
    }
    
    override func configureAuthorFilter() {
        // Noop
    }
    
    // MARK: - TableView Handler Delegate Methods
    
    override func entityName() -> String {
        // TODO: model for Project
        return String(describing: Post.self)
    }
    
    override func predicateForFetchRequest() -> NSPredicate {
        var predicates = [NSPredicate]()
        
        if let blog = blog {
            let basePredicate = NSPredicate(format: "blog = %@ && revision = nil", blog)
            predicates.append(basePredicate)
        }
        
        // TODO:
//        let searchText = currentSearchTerm()
//        let filterPredicate = filterSettings.currentPostListFilter().predicateForFetchRequest
//
//        // If we have recently trashed posts, create an OR predicate to find posts matching the filter,
//        // or posts that were recently deleted.
//        if searchText?.count == 0 && recentlyTrashedPostObjectIDs.count > 0 {
//
//            let trashedPredicate = NSPredicate(format: "SELF IN %@", recentlyTrashedPostObjectIDs)
//
//            predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: [filterPredicate, trashedPredicate]))
//        } else {
//            predicates.append(filterPredicate)
//        }
//
//        if let searchText = searchText, searchText.count > 0 {
//            let searchPredicate = NSPredicate(format: "postTitle CONTAINS[cd] %@", searchText)
//            predicates.append(searchPredicate)
//        }
        
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return predicate
    }
    
    // MARK: - Table View Handling
    
    override func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        // TODO:
//        guard let cell = cell as? BasePageListCell else {
//            preconditionFailure("The cell should be of class \(String(describing: BasePageListCell.self))")
//        }
//
//        cell.accessoryType = .none
//
//        if cell.reuseIdentifier == type(of: self).pageCellIdentifier {
//            cell.onAction = { [weak self] cell, button, page in
//                self?.handleMenuAction(fromCell: cell, fromButton: button, forPage: page)
//            }
//        } else if cell.reuseIdentifier == type(of: self).restorePageCellIdentifier {
//            cell.selectionStyle = .none
//            cell.onAction = { [weak self] cell, _, page in
//                self?.handleRestoreAction(fromCell: cell, forPage: page)
//            }
//        }
//
//        let page = pageAtIndexPath(indexPath)
//
//        cell.configureCell(page)
    }
    
    // MARK: - Portfolio Actions
    
    override func createPost() {
        self.createProject()
    }
    
    func createProject() {
        // TODO: implement this
    }
}
