import Foundation
import WordPressShared
import WordPressComAnalytics

class PageListViewController : AbstractPostListViewController, UIViewControllerRestoration {

    private static let pageSectionHeaderHeight = CGFloat(24.0)
    private static let pageCellEstimatedRowHeight = CGFloat(47.0)
    private static let pagesViewControllerRestorationKey = "PagesViewControllerRestorationKey"
    private static let pageCellIdentifier = "PageCellIdentifier"
    private static let pageCellNibName = "PageListTableViewCell"
    private static let restorePageCellIdentifier = "RestorePageCellIdentifier"
    private static let restorePageCellNibName = "RestorePageTableViewCell"
    private static let currentPageListStatusFilterKey = "CurrentPageListStatusFilterKey"

    private lazy var sectionFooterSeparatorView : UIView = {
        let footer = UIView()
        footer.backgroundColor = WPStyleGuide.greyLighten20()
        return footer
    }()

    // MARK: - GUI

    private let animatedBox = WPAnimatedBox()


    // MARK: - Convenience constructors

    class func controllerWithBlog(blog: Blog) -> PageListViewController {

        let storyBoard = UIStoryboard(name: "Pages", bundle: NSBundle.mainBundle())
        let controller = storyBoard.instantiateViewControllerWithIdentifier("PageListViewController") as! PageListViewController

        controller.blog = blog
        controller.restorationClass = self

        return controller
    }

    // MARK: - UIViewControllerRestoration

    class func viewControllerWithRestorationIdentifierPath(identifierComponents: [AnyObject], coder: NSCoder) -> UIViewController? {

        let context = ContextManager.sharedInstance().mainContext

        guard let blogID = coder.decodeObjectForKey(pagesViewControllerRestorationKey) as? String,
            let objectURL = NSURL(string: blogID),
            let objectID = context.persistentStoreCoordinator?.managedObjectIDForURIRepresentation(objectURL),
            let restoredBlog = try? context.existingObjectWithID(objectID) as! Blog else {

                return nil
        }

        return self.controllerWithBlog(restoredBlog)
    }

    // MARK: - UIStateRestoring

    override func encodeRestorableStateWithCoder(coder: NSCoder) {

        let objectString = blog?.objectID.URIRepresentation().absoluteString

        coder.encodeObject(objectString, forKey:self.dynamicType.pagesViewControllerRestorationKey)

        super.encodeRestorableStateWithCoder(coder)
    }

    // MARK: - UIViewController

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.refreshNoResultsView = { [weak self] noResultsView in
            self?.handleRefreshNoResultsView(noResultsView)
        }
        super.tableViewController = (segue.destinationViewController as! UITableViewController)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Pages", comment: "Tile of the screen showing the list of pages for a blog.")
    }

    // MARK: - Configuration

    override func configureTableView() {
        tableView.accessibilityIdentifier = "PagesTable"
        tableView.isAccessibilityElement = true
        tableView.estimatedRowHeight = self.dynamicType.pageCellEstimatedRowHeight
        tableView.rowHeight = UITableViewAutomaticDimension

        let bundle = NSBundle.mainBundle()

        // Register the cells
        let pageCellNib = UINib(nibName: self.dynamicType.pageCellNibName, bundle: bundle)
        tableView.registerNib(pageCellNib, forCellReuseIdentifier: self.dynamicType.pageCellIdentifier)

        let restorePageCellNib = UINib(nibName: self.dynamicType.restorePageCellNibName, bundle: bundle)
        tableView.registerNib(restorePageCellNib, forCellReuseIdentifier: self.dynamicType.restorePageCellIdentifier)

        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }

    override func configureSearchController() {
        super.configureSearchController()

        tableView.tableHeaderView = searchController.searchBar

        tableView.scrollIndicatorInsets.top = searchController.searchBar.bounds.height
    }

    private func noResultsTitles() -> [PostListFilter.Status:String] {
        if isSearching() {
            return noResultsTitlesWhenSearching()
        } else {
            return noResultsTitlesWhenFiltering()
        }
    }

    private func noResultsTitlesWhenSearching() -> [PostListFilter.Status:String] {

        let draftMessage = String(format: NSLocalizedString("No drafts match your search for %@", comment: "The '%@' is a placeholder for the search term."), currentSearchTerm()!)
        let scheduledMessage = String(format: NSLocalizedString("No scheduled pages match your search for %@", comment: "The '%@' is a placeholder for the search term."), currentSearchTerm()!)
        let trashedMessage = String(format: NSLocalizedString("No trashed pages match your search for %@", comment: "The '%@' is a placeholder for the search term."), currentSearchTerm()!)
        let publishedMessage = String(format: NSLocalizedString("No pages match your search for %@", comment: "The '%@' is a placeholder for the search term."), currentSearchTerm()!)

        return noResultsTitles(draftMessage, scheduled: scheduledMessage, trashed: trashedMessage, published: publishedMessage)
    }

    private func noResultsTitlesWhenFiltering() -> [PostListFilter.Status:String] {

        let draftMessage = NSLocalizedString("You don't have any drafts.", comment: "Displayed when the user views drafts in the pages list and there are no pages")
        let scheduledMessage = NSLocalizedString("You don't have any scheduled pages.", comment: "Displayed when the user views scheduled pages in the pages list and there are no pages")
        let trashedMessage = NSLocalizedString("You don't have any pages in your trash folder.", comment: "Displayed when the user views trashed in the pages list and there are no pages")
        let publishedMessage = NSLocalizedString("You haven't published any pages yet.", comment: "Displayed when the user views published pages in the pages list and there are no pages")

        return noResultsTitles(draftMessage, scheduled: scheduledMessage, trashed: trashedMessage, published: publishedMessage)
    }

    private func noResultsTitles(draft: String, scheduled: String, trashed: String, published: String) -> [PostListFilter.Status:String] {
        return [.Draft: draft,
                .Scheduled: scheduled,
                .Trashed: trashed,
                .Published: published]
    }

    override func configureAuthorFilter() {
        // Noop
    }

    // MARK: - Sync Methods

    override internal func postTypeToSync() -> PostServiceType {
        return PostServiceTypePage
    }

    override internal func lastSyncDate() -> NSDate? {
        return blog?.lastPagesSync
    }

    // MARK: - Model Interaction

    /// Retrieves the page object at the specified index path.
    ///
    /// - Parameter indexPath: the index path of the page object to retrieve.
    ///
    /// - Returns: the requested page.
    ///
    private func pageAtIndexPath(indexPath: NSIndexPath) -> Page {
        guard let page = tableViewHandler.resultsController.objectAtIndexPath(indexPath) as? Page else {
            // Retrieveing anything other than a post object means we have an app with an invalid
            // state.  Ignoring this error would be counter productive as we have no idea how this
            // can affect the App.  This controlled interruption is intentional.
            //
            // - Diego Rey Mendez, May 18 2016
            //
            fatalError("Expected a Page object.")
        }

        return page
    }

    // MARK: - TableView Handler Delegate Methods

    override func entityName() -> String {
        return String(Page.self)
    }


    override func predicateForFetchRequest() -> NSPredicate {
        var predicates = [NSPredicate]()

        if let blog = blog {
            let basePredicate = NSPredicate(format: "blog = %@ && original = nil", blog)
            predicates.append(basePredicate)
        }

        let searchText = currentSearchTerm()
        let filterPredicate = filterSettings.currentPostListFilter().predicateForFetchRequest

        // If we have recently trashed posts, create an OR predicate to find posts matching the filter,
        // or posts that were recently deleted.
        if searchText?.characters.count == 0 && recentlyTrashedPostObjectIDs.count > 0 {

            let trashedPredicate = NSPredicate(format: "SELF IN %@", recentlyTrashedPostObjectIDs)

            predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: [filterPredicate, trashedPredicate]))
        } else {
            predicates.append(filterPredicate)
        }

        if let searchText = searchText where searchText.characters.count > 0 {
            let searchPredicate = NSPredicate(format: "postTitle CONTAINS[cd] %@", searchText)
            predicates.append(searchPredicate)
        }

        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return predicate
    }

    // MARK: - Table View Handling

    func sectionNameKeyPath() -> String {
        return NSStringFromSelector(#selector(Page.sectionIdentifier))
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return self.dynamicType.pageSectionHeaderHeight
    }

    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == tableView.numberOfSections - 1 {
            return WPDeviceIdentification.isRetina() ? 0.5 : 1.0
        }
        return 0.0
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView! {
        let sectionInfo = tableViewHandler.resultsController.sections?[section]
        let nibName = String(PageListSectionHeaderView)
        let headerView = NSBundle.mainBundle().loadNibNamed(nibName, owner: nil, options: nil)[0] as! PageListSectionHeaderView

        if let sectionInfo = sectionInfo {
            headerView.setTite(sectionInfo.name)
        }

        return headerView
    }

    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView! {
        if section == tableView.numberOfSections - 1 {
            return sectionFooterSeparatorView
        }
        return UIView(frame: CGRectZero)
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        let page = pageAtIndexPath(indexPath)

        if page.remoteStatus != AbstractPostRemoteStatusPushing && page.status != PostStatusTrash {
            editPage(page)
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let windowlessCell = dequeCellForWindowlessLoadingIfNeeded(tableView) {
            return windowlessCell
        }

        let page = pageAtIndexPath(indexPath)

        let identifier = cellIdentifierForPage(page)
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath)

        configureCell(cell, atIndexPath: indexPath)

        return cell
    }

    override func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {

        guard let cell = cell as? BasePageListCell else {
            preconditionFailure("The cell should be of class \(String(BasePageListCell))")
        }

        cell.accessoryType = .None

        if cell.reuseIdentifier == self.dynamicType.pageCellIdentifier {
            cell.onAction = { [weak self] cell, button, page in
                self?.handleMenuAction(fromCell: cell, fromButton: button, forPage: page)
            }
        } else if cell.reuseIdentifier == self.dynamicType.restorePageCellIdentifier {
            cell.selectionStyle = .None
            cell.onAction = { [weak self] cell, _, page in
                self?.handleRestoreAction(fromCell: cell, forPage: page)
            }
        }

        let page = pageAtIndexPath(indexPath)

        cell.configureCell(page)
    }

    private func cellIdentifierForPage(page: Page) -> String {
        var identifier : String

        if recentlyTrashedPostObjectIDs.contains(page.objectID) == true && filterSettings.currentPostListFilter().filterType != .Trashed {
            identifier = self.dynamicType.restorePageCellIdentifier
        } else {
            identifier = self.dynamicType.pageCellIdentifier
        }

        return identifier
    }

    // MARK: - Post Actions

    override func createPost() {
        let navController : UINavigationController

        let editorSettings = EditorSettings()
        if editorSettings.visualEditorEnabled {
            let postViewController: UIViewController
            if editorSettings.nativeEditorEnabled {
                let page = PostService.createDraftPageInMainContextForBlog(blog)
                postViewController = AztecPostViewController(post:page)
                navController = UINavigationController(rootViewController: postViewController)
            } else {
                postViewController = EditPageViewController(draftForBlog: blog)

                navController = UINavigationController(rootViewController: postViewController)
                navController.restorationIdentifier = WPEditorNavigationRestorationID
                navController.restorationClass = EditPageViewController.self
            }
        } else {
            let editPostViewController = WPLegacyEditPageViewController(draftForLastUsedBlog: ())

            navController = UINavigationController(rootViewController: editPostViewController)
            navController.restorationIdentifier = WPLegacyEditorNavigationRestorationID
            navController.restorationClass = WPLegacyEditPageViewController.self
        }

        navController.modalPresentationStyle = .FullScreen

        presentViewController(navController, animated: true, completion: nil)

        WPAppAnalytics.track(.EditorCreatedPost, withProperties: ["tap_source": "posts_view"], withBlog: blog)
    }

    private func editPage(apost: AbstractPost) {
        WPAnalytics.track(.PostListEditAction, withProperties: propertiesForAnalytics())

        let editorSettings = EditorSettings()
        if editorSettings.visualEditorEnabled {
            let pageViewController: UIViewController
            if editorSettings.nativeEditorEnabled {
                pageViewController = AztecPostViewController(post: apost)
            } else {
                pageViewController = EditPageViewController(post: apost, mode: kWPPostViewControllerModePreview)
            }

            navigationController?.pushViewController(pageViewController, animated: true)
        } else {
            // In legacy mode, view means edit
            let editPageViewController = WPLegacyEditPageViewController(post: apost)
            let navController = UINavigationController(rootViewController: editPageViewController)

            navController.modalPresentationStyle = .FullScreen
            navController.restorationIdentifier = WPLegacyEditorNavigationRestorationID
            navController.restorationClass = WPLegacyEditPageViewController.self

            presentViewController(navController, animated: true, completion: nil)
        }
    }

    private func draftPage(apost: AbstractPost) {
        WPAnalytics.track(.PostListDraftAction, withProperties: propertiesForAnalytics())

        let previousStatus = apost.status
        apost.status = PostStatusDraft

        let contextManager = ContextManager.sharedInstance()
        let postService = PostService(managedObjectContext: contextManager.mainContext)

        postService.uploadPost(apost, success: nil) { [weak self] (error) in
            apost.status = previousStatus

            if let strongSelf = self {
                contextManager.saveContext(strongSelf.managedObjectContext())
            }

            WPError.showXMLRPCErrorAlert(error)
        }
    }

    override func promptThatPostRestoredToFilter(filter: PostListFilter) {
        var message = NSLocalizedString("Page Restored to Drafts", comment: "Prompts the user that a restored page was moved to the drafts list.")

        switch filter.filterType {
        case .Published:
            message = NSLocalizedString("Page Restored to Published", comment: "Prompts the user that a restored page was moved to the published list.")
        break
        case .Scheduled:
            message = NSLocalizedString("Page Restored to Scheduled", comment: "Prompts the user that a restored page was moved to the scheduled list.")
            break
        default:
            break
        }

        let alertCancel = NSLocalizedString("OK", comment: "Title of an OK button. Pressing the button acknowledges and dismisses a prompt.")

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .Alert)
        alertController.addCancelActionWithTitle(alertCancel, handler: nil)
        alertController.presentFromRootViewController()
    }

    // MARK: - Cell Action Handling

    private func handleMenuAction(fromCell cell: UITableViewCell, fromButton button: UIButton, forPage page: AbstractPost) {
        let objectID = page.objectID

        let viewButtonTitle = NSLocalizedString("View", comment: "Label for a button that opens the page when tapped.")
        let draftButtonTitle = NSLocalizedString("Move to Draft", comment: "Label for a button that moves a page to the draft folder")
        let publishButtonTitle = NSLocalizedString("Publish Immediately", comment: "Label for a button that moves a page to the published folder, publishing with the current date/time.")
        let trashButtonTitle = NSLocalizedString("Move to Trash", comment: "Label for a button that moves a page to the trash folder")
        let cancelButtonTitle = NSLocalizedString("Cancel", comment: "Label for a cancel button")
        let deleteButtonTitle = NSLocalizedString("Delete Permanently", comment: "Label for a button permanently deletes a page.")

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        alertController.addCancelActionWithTitle(cancelButtonTitle, handler: nil)

        let filter = filterSettings.currentPostListFilter().filterType

        if filter == .Trashed {
            alertController.addActionWithTitle(publishButtonTitle, style: .Default, handler: { [weak self] (action) in
                guard let strongSelf = self,
                    let page = strongSelf.pageForObjectID(objectID) else {
                    return
                }

                strongSelf.publishPost(page)
            })

            alertController.addActionWithTitle(draftButtonTitle, style: .Default, handler: { [weak self] (action) in
                guard let strongSelf = self,
                    let page = strongSelf.pageForObjectID(objectID) else {
                        return
                }

                strongSelf.draftPage(page)
            })

            alertController.addActionWithTitle(deleteButtonTitle, style: .Default, handler: { [weak self] (action) in
                guard let strongSelf = self,
                    let page = strongSelf.pageForObjectID(objectID) else {
                        return
                }

                strongSelf.deletePost(page)
            })
        } else if filter == .Published {
            alertController.addActionWithTitle(viewButtonTitle, style: .Default, handler: { [weak self] (action) in
                guard let strongSelf = self,
                    let page = strongSelf.pageForObjectID(objectID) else {
                        return
                }

                strongSelf.viewPost(page)
            })

            alertController.addActionWithTitle(draftButtonTitle, style: .Default, handler: { [weak self] (action) in
                guard let strongSelf = self,
                    let page = strongSelf.pageForObjectID(objectID) else {
                        return
                }

                strongSelf.draftPage(page)
            })

            alertController.addActionWithTitle(trashButtonTitle, style: .Default, handler: { [weak self] (action) in
                guard let strongSelf = self,
                    let page = strongSelf.pageForObjectID(objectID) else {
                        return
                }

                strongSelf.deletePost(page)
            })
        } else {
            alertController.addActionWithTitle(viewButtonTitle, style: .Default, handler: { [weak self] (action) in
                guard let strongSelf = self,
                    let page = strongSelf.pageForObjectID(objectID) else {
                        return
                }

                strongSelf.viewPost(page)
            })

            alertController.addActionWithTitle(publishButtonTitle, style: .Default, handler: { [weak self] (action) in
                guard let strongSelf = self,
                    let page = strongSelf.pageForObjectID(objectID) else {
                        return
                }

                strongSelf.publishPost(page)
            })

            alertController.addActionWithTitle(trashButtonTitle, style: .Default, handler: { [weak self] (action) in
                guard let strongSelf = self,
                    let page = strongSelf.pageForObjectID(objectID) else {
                        return
                }

                strongSelf.deletePost(page)
            })
        }

        WPAnalytics.track(.PostListOpenedCellMenu, withProperties: propertiesForAnalytics())

        alertController.modalPresentationStyle = .Popover
        presentViewController(alertController, animated: true, completion: nil)

        if let presentationController = alertController.popoverPresentationController {
            presentationController.permittedArrowDirections = .Any
            presentationController.sourceView = button
            presentationController.sourceRect = button.bounds
        }
    }

    private func pageForObjectID(objectID: NSManagedObjectID) -> Page? {

        var pageManagedOjbect : NSManagedObject

        do {
            pageManagedOjbect = try managedObjectContext().existingObjectWithID(objectID)

        } catch let error as NSError {
            DDLogSwift.logError("\(NSStringFromClass(self.dynamicType)), \(#function), \(error)")
            return nil
        } catch _ {
            DDLogSwift.logError("\(NSStringFromClass(self.dynamicType)), \(#function), Could not find Page with ID \(objectID)")
            return nil
        }

        let page = pageManagedOjbect as? Page
        return page
    }

    private func handleRestoreAction(fromCell cell: UITableViewCell, forPage page: AbstractPost) {
        restorePost(page)
    }

    // MARK: - Refreshing noResultsView

    func handleRefreshNoResultsView(noResultsView: WPNoResultsView) {
        noResultsView.titleText = noResultsTitle()
        noResultsView.messageText = noResultsMessage()
        noResultsView.accessoryView = noResultsAccessoryView()
        noResultsView.buttonTitle = noResultsButtonTitle()
    }

    // MARK: - NoResultsView Customizer helpers

    private func noResultsAccessoryView() -> UIView {
        if syncHelper.isSyncing {
            animatedBox.animateAfterDelay(0.1)
            return animatedBox
        }

        return UIImageView(image: UIImage(named: "illustration-posts"))
    }

    private func noResultsButtonTitle() -> String {
        if syncHelper.isSyncing == true || isSearching() {
            return ""
        }

        let filterType = filterSettings.currentPostListFilter().filterType

        switch filterType {
        case .Trashed:
            return ""
        default:
            return NSLocalizedString("Start a Page", comment: "Button title, encourages users to create their first page on their blog.")
        }
    }

    private func noResultsTitle() -> String {
        if syncHelper.isSyncing == true {
            return NSLocalizedString("Fetching pages...", comment: "A brief prompt shown when the reader is empty, letting the user know the app is currently fetching new pages.")
        }

        let filter = filterSettings.currentPostListFilter()
        let titles = noResultsTitles()
        let title = titles[filter.filterType]
        return title ?? ""
    }

    private func noResultsMessage() -> String {
        if syncHelper.isSyncing == true || isSearching() {
            return ""
        }

        let filterType = filterSettings.currentPostListFilter().filterType

        switch filterType {
        case .Draft:
            return NSLocalizedString("Would you like to create one?", comment: "Displayed when the user views drafts in the pages list and there are no pages")
        case .Scheduled:
            return NSLocalizedString("Would you like to create one?", comment: "Displayed when the user views scheduled pages in the pages list and there are no pages")
        case .Trashed:
            return NSLocalizedString("Everything you write is solid gold.", comment: "Displayed when the user views trashed pages in the pages list and there are no pages")
        default:
            return NSLocalizedString("Would you like to publish your first page?", comment: "Displayed when the user views published pages in the pages list and there are no pages")
        }
    }
}
