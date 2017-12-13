import Foundation
import CocoaLumberjack
import WordPressShared

class PortfolioListViewController: AbstractPostListViewController, UIViewControllerRestoration {

    fileprivate static let portfolioSectionHeaderHeight = CGFloat(24.0)
    fileprivate static let portfolioCellEstimatedRowHeight = CGFloat(60.0)
    fileprivate static let portfolioViewControllerRestorationKey = "PortfolioViewControllerRestorationKey"
    fileprivate static let projectCellIdentifier = "ProjectCellIdentifier"
    fileprivate static let projectCellNibName = "ProjectTableViewCell"
    fileprivate static let restoreProjectCellIdentifier = "RestoreProjectCellIdentifier"
    fileprivate static let restoreProjectCellNibName = "RestoreProjectTableViewCell"
    fileprivate static let currentPortfolioListStatusFilterKey = "CurrentPortfolioListStatusFilterKey"

    fileprivate lazy var sectionFooterSeparatorView: UIView = {
        let footer = UIView()
        footer.backgroundColor = WPStyleGuide.greyLighten20()
        return footer
    }()

    // MARK: - GUI

    fileprivate let animatedBox = WPAnimatedBox()

    // MARK: - Convenience constructors

    @objc class func controllerWithBlog(_ blog: Blog) -> PortfolioListViewController {

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
            self?.handleRefreshNoResultsView(noResultsView)
        }
        super.tableViewController = (segue.destination as! UITableViewController)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Portfolio", comment: "Tile of the screen showing the list of projects (Portfolio) for a blog.")
    }

    // MARK: - Configuration

    override func configureTableView() {
        tableView.accessibilityIdentifier = "PortfolioTable"
        tableView.isAccessibilityElement = true
        tableView.estimatedRowHeight = type(of: self).portfolioCellEstimatedRowHeight
        tableView.rowHeight = UITableViewAutomaticDimension

        let bundle = Bundle.main

        // Register the cells
        let projectCellNib = UINib(nibName: type(of: self).projectCellNibName, bundle: bundle)
        tableView.register(projectCellNib, forCellReuseIdentifier: type(of: self).projectCellIdentifier)

        let restoreProjectCellNib = UINib(nibName: type(of: self).restoreProjectCellNibName, bundle: bundle)
        tableView.register(restoreProjectCellNib, forCellReuseIdentifier: type(of: self).restoreProjectCellIdentifier)

        WPStyleGuide.configureColors(for: view, andTableView: tableView)
    }

    override func configureSearchController() {
        super.configureSearchController()

        tableView.tableHeaderView = searchController.searchBar

        tableView.scrollIndicatorInsets.top = searchController.searchBar.bounds.height
    }

    fileprivate func noResultsTitles() -> [PostListFilter.Status: String] {
        if isSearching() {
            return noResultsTitlesWhenSearching()
        } else {
            return noResultsTitlesWhenFiltering()
        }
    }

    fileprivate func noResultsTitlesWhenSearching() -> [PostListFilter.Status: String] {
        let draftMessage = String(format: NSLocalizedString("No drafts match your search for %@", comment: "The '%@' is a placeholder for the search term."), currentSearchTerm()!)
        let scheduledMessage = String(format: NSLocalizedString("No scheduled projects match your search for %@", comment: "The '%@' is a placeholder for the search term."), currentSearchTerm()!)
        let trashedMessage = String(format: NSLocalizedString("No trashed projects match your search for %@", comment: "The '%@' is a placeholder for the search term."), currentSearchTerm()!)
        let publishedMessage = String(format: NSLocalizedString("No projects match your search for %@", comment: "The '%@' is a placeholder for the search term."), currentSearchTerm()!)

        return noResultsTitles(draftMessage, scheduled: scheduledMessage, trashed: trashedMessage, published: publishedMessage)
    }

    fileprivate func noResultsTitlesWhenFiltering() -> [PostListFilter.Status: String] {
        let draftMessage = NSLocalizedString("You don't have any drafts.", comment: "Displayed when the user views drafts in the portfolio list and there are no projects")
        let scheduledMessage = NSLocalizedString("You don't have any scheduled projects.", comment: "Displayed when the user views scheduled projects in the portfolio list and there are no projects")
        let trashedMessage = NSLocalizedString("You don't have any projects in your trash folder.", comment: "Displayed when the user views trashed in the portfolio list and there are no projects")
        let publishedMessage = NSLocalizedString("You haven't published any projects yet.", comment: "Displayed when the user views published projects in the portfolio list and there are no projects")

        return noResultsTitles(draftMessage, scheduled: scheduledMessage, trashed: trashedMessage, published: publishedMessage)
    }

    fileprivate func noResultsTitles(_ draft: String, scheduled: String, trashed: String, published: String) -> [PostListFilter.Status: String] {
        return [.draft: draft,
                .scheduled: scheduled,
                .trashed: trashed,
                .published: published]
    }

    override func configureAuthorFilter() {
        // Noop
    }

    // MARK: - Sync Methods

    override internal func postTypeToSync() -> PostServiceType {
        return .project
    }

    override internal func lastSyncDate() -> Date? {
        return blog?.lastProjectsSync
    }

    // MARK: - Model Interaction

    fileprivate func projectAtIndexPath(_ indexPath: IndexPath) -> Project {
        guard let project = tableViewHandler.resultsController.object(at: indexPath) as? Project else {
            fatalError("Expected a Project object.")
        }

        return project
    }

    // MARK: - TableView Handler Delegate Methods

    override func entityName() -> String {
        return String(describing: Project.self)
    }

    override func predicateForFetchRequest() -> NSPredicate {
        var predicates = [NSPredicate]()

        if let blog = blog {
            let basePredicate = NSPredicate(format: "blog = %@ && revision = nil", blog)
            predicates.append(basePredicate)
        }

        let searchText = currentSearchTerm()
        let filterPredicate = filterSettings.currentPostListFilter().predicateForFetchRequest

        // If we have recently trashed posts, create an OR predicate to find posts matching the filter,
        // or posts that were recently deleted.
        if searchText?.count == 0 && recentlyTrashedPostObjectIDs.count > 0 {

            let trashedPredicate = NSPredicate(format: "SELF IN %@", recentlyTrashedPostObjectIDs)

            predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: [filterPredicate, trashedPredicate]))
        } else {
            predicates.append(filterPredicate)
        }

        if let searchText = searchText, searchText.count > 0 {
            let searchPredicate = NSPredicate(format: "postTitle CONTAINS[cd] %@", searchText)
            predicates.append(searchPredicate)
        }

        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return predicate
    }

    // MARK: - Table View Handling

    func sectionNameKeyPath() -> String {
        let sortField = filterSettings.currentPostListFilter().sortField
        return Project.sectionIdentifier(dateKeyPath: sortField.keyPath)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return type(of: self).portfolioSectionHeaderHeight
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == tableView.numberOfSections - 1 {
            return WPDeviceIdentification.isRetina() ? 0.5 : 1.0
        }
        return 0.0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView! {
        let sectionInfo = tableViewHandler.resultsController.sections?[section]
        let nibName = String(describing: PageListSectionHeaderView.self)
        let headerView = Bundle.main.loadNibNamed(nibName, owner: nil, options: nil)![0] as! PageListSectionHeaderView

        if let sectionInfo = sectionInfo {
            headerView.setTite(sectionInfo.name)
        }

        return headerView
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView! {
        if section == tableView.numberOfSections - 1 {
            return sectionFooterSeparatorView
        }
        return UIView(frame: CGRect.zero)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let project = projectAtIndexPath(indexPath)

        if project.remoteStatus != .pushing && project.status != .trash {
            editProject(project)
        }
    }

    @objc func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        if let windowlessCell = dequeCellForWindowlessLoadingIfNeeded(tableView) {
            return windowlessCell
        }

        let project = projectAtIndexPath(indexPath)

        let identifier = cellIdentifierForProject(project)
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)

        configureCell(cell, at: indexPath)

        return cell
    }

    override func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {

        guard let cell = cell as? BasePageListCell else {
            preconditionFailure("The cell should be of class \(String(describing: BasePageListCell.self))")
        }

        cell.accessoryType = .none

        if cell.reuseIdentifier == type(of: self).projectCellIdentifier {
            cell.onAction = { [weak self] cell, button, project in
                self?.handleMenuAction(fromCell: cell, fromButton: button, forProject: project)
            }
        } else if cell.reuseIdentifier == type(of: self).restoreProjectCellIdentifier {
            cell.selectionStyle = .none
            cell.onAction = { [weak self] cell, _, project in
                self?.handleRestoreAction(fromCell: cell, forProject: project)
            }
        }

        let project = projectAtIndexPath(indexPath)

        cell.configureCell(project)
    }

    fileprivate func cellIdentifierForProject(_ project: Project) -> String {
        var identifier: String

        if recentlyTrashedPostObjectIDs.contains(project.objectID) == true && filterSettings.currentPostListFilter().filterType != .trashed {
            identifier = type(of: self).restoreProjectCellIdentifier
        } else {
            identifier = type(of: self).projectCellIdentifier
        }

        return identifier
    }

    // MARK: - Portfolio Actions

    override func createPost() {
        // TODO: implement this for edit mode
    }

    fileprivate func editProject(_ apost: AbstractPost) {
        // TODO: implement this for edit mode
    }

    fileprivate func showEditor(post: AbstractPost) {
        // TODO: implement this for edit mode
    }

    fileprivate func draftProject(_ apost: AbstractPost) {
        // TODO: implement this for edit mode
    }

    override func promptThatPostRestoredToFilter(_ filter: PostListFilter) {
        var message = NSLocalizedString("Project Restored to Drafts", comment: "Prompts the user that a restored project was moved to the drafts list.")

        switch filter.filterType {
        case .published:
            message = NSLocalizedString("Project Restored to Published", comment: "Prompts the user that a restored project was moved to the published list.")
            break
        case .scheduled:
            message = NSLocalizedString("Project Restored to Scheduled", comment: "Prompts the user that a restored project was moved to the scheduled list.")
            break
        default:
            break
        }

        let alertCancel = NSLocalizedString("OK", comment: "Title of an OK button. Pressing the button acknowledges and dismisses a prompt.")

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addCancelActionWithTitle(alertCancel, handler: nil)
        alertController.presentFromRootViewController()
    }

    // MARK: - Cell Action Handling

    fileprivate func handleMenuAction(fromCell cell: UITableViewCell, fromButton button: UIButton, forProject project: AbstractPost) {
        let objectID = project.objectID

        let viewButtonTitle = NSLocalizedString("View", comment: "Label for a button that opens the project when tapped.")
        let draftButtonTitle = NSLocalizedString("Move to Draft", comment: "Label for a button that moves a project to the draft folder")
        let publishButtonTitle = NSLocalizedString("Publish Immediately", comment: "Label for a button that moves a project to the published folder, publishing with the current date/time.")
        let trashButtonTitle = NSLocalizedString("Move to Trash", comment: "Label for a button that moves a project to the trash folder")
        let cancelButtonTitle = NSLocalizedString("Cancel", comment: "Label for a cancel button")
        let deleteButtonTitle = NSLocalizedString("Delete Permanently", comment: "Label for a button that permanently deletes a project.")

        // UIAlertAction handlers
        let publishHandler = { [weak self] (action: UIAlertAction) in
            guard let strongSelf = self,
                let project = strongSelf.projectForObjectID(objectID) else {
                    return
            }

            strongSelf.publishPost(project)
        }
        let draftHandler = { [weak self] (action: UIAlertAction) in
            guard let strongSelf = self,
                let project = strongSelf.projectForObjectID(objectID) else {
                    return
            }

            strongSelf.draftProject(project)
        }
        let deleteHandler = { [weak self] (action: UIAlertAction) in
            guard let strongSelf = self,
                let project = strongSelf.projectForObjectID(objectID) else {
                    return
            }

            strongSelf.deletePost(project)
        }
        let viewHandler = { [weak self] (action: UIAlertAction) in
            guard let strongSelf = self,
                let project = strongSelf.projectForObjectID(objectID) else {
                    return
            }

            strongSelf.viewPost(project)
        }

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addCancelActionWithTitle(cancelButtonTitle, handler: nil)

        let filter = filterSettings.currentPostListFilter().filterType

        if filter == .trashed {
            alertController.addActionWithTitle(publishButtonTitle, style: .default, handler: publishHandler)
            alertController.addActionWithTitle(draftButtonTitle, style: .default, handler: draftHandler)
            alertController.addActionWithTitle(deleteButtonTitle, style: .default, handler: deleteHandler)
        } else if filter == .published {
            alertController.addActionWithTitle(viewButtonTitle, style: .default, handler: viewHandler)
            alertController.addActionWithTitle(draftButtonTitle, style: .default, handler: draftHandler)
            alertController.addActionWithTitle(trashButtonTitle, style: .default, handler: deleteHandler)
        } else {
            alertController.addActionWithTitle(viewButtonTitle, style: .default, handler: viewHandler)
            alertController.addActionWithTitle(publishButtonTitle, style: .default, handler: publishHandler)
            alertController.addActionWithTitle(trashButtonTitle, style: .default, handler: deleteHandler)
        }

        WPAnalytics.track(.postListOpenedCellMenu, withProperties: propertiesForAnalytics())

        alertController.modalPresentationStyle = .popover
        present(alertController, animated: true, completion: nil)

        if let presentationController = alertController.popoverPresentationController {
            presentationController.permittedArrowDirections = .any
            presentationController.sourceView = button
            presentationController.sourceRect = button.bounds
        }
    }

    fileprivate func projectForObjectID(_ objectID: NSManagedObjectID) -> Project? {

        var projectManagedObject: NSManagedObject

        do {
            projectManagedObject = try managedObjectContext().existingObject(with: objectID)

        } catch let error as NSError {
            DDLogError("\(NSStringFromClass(type(of: self))), \(#function), \(error)")
            return nil
        } catch _ {
            DDLogError("\(NSStringFromClass(type(of: self))), \(#function), Could not find Project with ID \(objectID)")
            return nil
        }

        let project = projectManagedObject as? Project
        return project
    }

    fileprivate func handleRestoreAction(fromCell cell: UITableViewCell, forProject project: AbstractPost) {
        restorePost(project)
    }

    // MARK: - Refreshing noResultsView

    @objc func handleRefreshNoResultsView(_ noResultsView: WPNoResultsView) {
        noResultsView.titleText = noResultsTitle()
        noResultsView.messageText = noResultsMessage()
        noResultsView.accessoryView = noResultsAccessoryView()
        noResultsView.buttonTitle = noResultsButtonTitle()
    }

    // MARK: - NoResultsView Customizer helpers

    fileprivate func noResultsAccessoryView() -> UIView {
        if syncHelper.isSyncing {
            animatedBox.animate(afterDelay: 0.1)
            return animatedBox
        }

        return UIImageView(image: UIImage(named: "illustration-posts"))
    }

    fileprivate func noResultsButtonTitle() -> String {
        if syncHelper.isSyncing == true || isSearching() {
            return ""
        }

        let filterType = filterSettings.currentPostListFilter().filterType

        switch filterType {
        case .trashed:
            return ""
        default:
            return NSLocalizedString("Start a Project", comment: "Button title, encourages users to create their first project on their blog.")
        }
    }

    fileprivate func noResultsTitle() -> String {
        if syncHelper.isSyncing == true {
            return NSLocalizedString("Fetching projects...", comment: "A brief prompt shown when the reader is empty, letting the user know the app is currently fetching new projects.")
        }

        let filter = filterSettings.currentPostListFilter()
        let titles = noResultsTitles()
        let title = titles[filter.filterType]
        return title ?? ""
    }

    fileprivate func noResultsMessage() -> String {
        if syncHelper.isSyncing == true || isSearching() {
            return ""
        }

        let filterType = filterSettings.currentPostListFilter().filterType

        switch filterType {
        case .draft:
            return NSLocalizedString("Would you like to create one?", comment: "Displayed when the user views drafts in the portfolio and there are no projects")
        case .scheduled:
            return NSLocalizedString("Would you like to create one?", comment: "Displayed when the user views scheduled projects in the portfolio and there are no projects")
        case .trashed:
            return NSLocalizedString("Everything you write is solid gold.", comment: "Displayed when the user views trashed projects in the portfolio and there are no projects")
        default:
            return NSLocalizedString("Would you like to publish your first project?", comment: "Displayed when the user views published projects in the portfolio and there are no projects")
        }
    }

    // MARK: - UISearchControllerDelegate

    func didPresentSearchController(_ searchController: UISearchController) {
        if #available(iOS 11.0, *) {
            tableView.scrollIndicatorInsets.top = searchController.searchBar.bounds.height + searchController.searchBar.frame.origin.y - topLayoutGuide.length
            tableView.contentInset.top = 0
        }
    }
}
