import Foundation
import CocoaLumberjack
import WordPressShared
import WordPressFlux


class PageListViewController: AbstractPostListViewController, UIViewControllerRestoration {
    private struct Constant {
        struct Size {
            static let pageSectionHeaderHeight = CGFloat(40.0)
            static let pageCellEstimatedRowHeight = CGFloat(44.0)
            static let pageCellWithTagEstimatedRowHeight = CGFloat(60.0)
            static let pageListTableViewCellLeading = CGFloat(16.0)
        }

        struct Identifiers {
            static let pagesViewControllerRestorationKey = "PagesViewControllerRestorationKey"
            static let pageCellIdentifier = "PageCellIdentifier"
            static let pageCellNibName = "PageListTableViewCell"
            static let restorePageCellIdentifier = "RestorePageCellIdentifier"
            static let restorePageCellNibName = "RestorePageTableViewCell"
            static let currentPageListStatusFilterKey = "CurrentPageListStatusFilterKey"
        }
    }

    fileprivate lazy var sectionFooterSeparatorView: UIView = {
        let footer = UIView()
        footer.backgroundColor = .neutral(.shade10)
        return footer
    }()

    private lazy var _tableViewHandler: PageListTableViewHandler = {
        let tableViewHandler = PageListTableViewHandler(tableView: self.tableView, blog: self.blog)
        tableViewHandler.cacheRowHeights = false
        tableViewHandler.delegate = self
        tableViewHandler.listensForContentChanges = false
        tableViewHandler.updateRowAnimation = .none
        return tableViewHandler
    }()

    override var tableViewHandler: WPTableViewHandler {
        get {
            return _tableViewHandler
        } set {
            super.tableViewHandler = newValue
        }
    }

    lazy var homepageSettingsService = {
        return HomepageSettingsService(blog: blog, context: blog.managedObjectContext ?? ContextManager.shared.mainContext)
    }()

    private lazy var createButtonCoordinator: CreateButtonCoordinator = {
        return CreateButtonCoordinator(self, actions: [PageAction(handler: { [weak self] in
            self?.createPost()
        })])
    }()

    // MARK: - GUI

    @IBOutlet weak var filterTabBarTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var filterTabBariOS10TopConstraint: NSLayoutConstraint!
    @IBOutlet weak var filterTabBarBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewTopConstraint: NSLayoutConstraint!

    // MARK: - Convenience constructors

    @objc class func controllerWithBlog(_ blog: Blog) -> PageListViewController {

        let storyBoard = UIStoryboard(name: "Pages", bundle: Bundle.main)
        let controller = storyBoard.instantiateViewController(withIdentifier: "PageListViewController") as! PageListViewController

        controller.blog = blog
        controller.restorationClass = self

        return controller
    }

    // MARK: - UIViewControllerRestoration

    class func viewController(withRestorationIdentifierPath identifierComponents: [String],
                              coder: NSCoder) -> UIViewController? {

        let context = ContextManager.sharedInstance().mainContext

        guard let blogID = coder.decodeObject(forKey: Constant.Identifiers.pagesViewControllerRestorationKey) as? String,
            let objectURL = URL(string: blogID),
            let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: objectURL),
            let restoredBlog = try? context.existingObject(with: objectID) as? Blog else {

                return nil
        }

        return controllerWithBlog(restoredBlog)
    }


    // MARK: - UIStateRestoring

    override func encodeRestorableState(with coder: NSCoder) {

        let objectString = blog?.objectID.uriRepresentation().absoluteString

        coder.encode(objectString, forKey: Constant.Identifiers.pagesViewControllerRestorationKey)

        super.encodeRestorableState(with: coder)
    }


    // MARK: - UIViewController

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.refreshNoResultsViewController = { [weak self] noResultsViewController in
            self?.handleRefreshNoResultsViewController(noResultsViewController)
        }
        super.tableViewController = (segue.destination as! UITableViewController)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if QuickStartTourGuide.shared.isCurrentElement(.newPage) {
            updateFilterWithPostStatus(.publish)
        }

        super.updateAndPerformFetchRequest()

        title = NSLocalizedString("Site Pages", comment: "Title of the screen showing the list of pages for a blog.")

        configureFilterBarTopConstraint()

        createButtonCoordinator.add(to: view, trailingAnchor: view.safeAreaLayoutGuide.trailingAnchor, bottomAnchor: view.safeAreaLayoutGuide.bottomAnchor)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        _tableViewHandler.status = filterSettings.currentPostListFilter().filterType
        _tableViewHandler.refreshTableView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if traitCollection.horizontalSizeClass == .compact {
            createButtonCoordinator.showCreateButton(for: blog)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.horizontalSizeClass == .compact {
            createButtonCoordinator.showCreateButton(for: blog)
        } else {
            createButtonCoordinator.hideCreateButton()
        }
    }

    // MARK: - Configuration

    private func configureFilterBarTopConstraint() {
        filterTabBariOS10TopConstraint.isActive = false
    }

    override func configureTableView() {
        tableView.accessibilityIdentifier = "PagesTable"
        tableView.estimatedRowHeight = Constant.Size.pageCellEstimatedRowHeight
        tableView.rowHeight = UITableView.automaticDimension

        let bundle = Bundle.main

        // Register the cells
        let pageCellNib = UINib(nibName: Constant.Identifiers.pageCellNibName, bundle: bundle)
        tableView.register(pageCellNib, forCellReuseIdentifier: Constant.Identifiers.pageCellIdentifier)

        let restorePageCellNib = UINib(nibName: Constant.Identifiers.restorePageCellNibName, bundle: bundle)
        tableView.register(restorePageCellNib, forCellReuseIdentifier: Constant.Identifiers.restorePageCellIdentifier)

        WPStyleGuide.configureColors(view: view, tableView: tableView)
    }

    override func configureSearchController() {
        super.configureSearchController()

        tableView.tableHeaderView = searchController.searchBar

        tableView.scrollIndicatorInsets.top = searchController.searchBar.bounds.height
    }

    override func configureAuthorFilter() {
        // Noop
    }

    override func configureFooterView() {
        super.configureFooterView()
        tableView.tableFooterView = UIView(frame: .zero)
    }

    fileprivate func beginRefreshingManually() {
        guard let refreshControl = refreshControl else {
            return
        }

        refreshControl.beginRefreshing()
        tableView.setContentOffset(CGPoint(x: 0, y: tableView.contentOffset.y - refreshControl.frame.size.height), animated: true)
    }

    // MARK: - Sync Methods

    override internal func postTypeToSync() -> PostServiceType {
        return .page
    }

    override internal func lastSyncDate() -> Date? {
        return blog?.lastPagesSync
    }

    override func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        filterSettings.setCurrentFilterIndex(filterBar.selectedIndex)
        _tableViewHandler.status = filterSettings.currentPostListFilter().filterType
        _tableViewHandler.refreshTableView()

        super.selectedFilterDidChange(filterBar)
    }

    override func updateFilterWithPostStatus(_ status: BasePost.Status) {
        filterSettings.setFilterWithPostStatus(status)
        _tableViewHandler.status = filterSettings.currentPostListFilter().filterType
        _tableViewHandler.refreshTableView()
        super.updateFilterWithPostStatus(status)
    }

    override func updateAndPerformFetchRequest() {
        super.updateAndPerformFetchRequest()

        _tableViewHandler.refreshTableView()
    }

    override func syncPostsMatchingSearchText() {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty() else {
            return
        }

        postsSyncWithSearchDidBegin()

        let author = filterSettings.shouldShowOnlyMyPosts() ? blogUserID() : nil
        let postService = PostService(managedObjectContext: managedObjectContext())
        let options = PostServiceSyncOptions()
        options.statuses = filterSettings.availablePostListFilters().flatMap { $0.statuses.strings }
        options.authorID = author
        options.number = 20
        options.purgesLocalSync = false
        options.search = searchText

        postService.syncPosts(
            ofType: postTypeToSync(),
            with: options,
            for: blog,
            success: { [weak self] posts in
                self?.postsSyncWithSearchEnded()
            }, failure: { [weak self] (error) in
                self?.postsSyncWithSearchEnded()
            }
        )
    }

    override func sortDescriptorsForFetchRequest() -> [NSSortDescriptor] {
        if !searchController.isActive {
            return super.sortDescriptorsForFetchRequest()
        }

        let descriptor = NSSortDescriptor(key: BasePost.statusKeyPath, ascending: true)
        return [descriptor]
    }

    override func updateForLocalPostsMatchingSearchText() {
        guard searchController.isActive else {
            hideNoResultsView()
            return
        }

        _tableViewHandler.isSearching = true
        updateAndPerformFetchRequest()
        tableView.reloadData()

        hideNoResultsView()

        if let text = searchController.searchBar.text,
            text.isEmpty ||
            tableViewHandler.resultsController.fetchedObjects?.count == 0 {
            showNoResultsView()
        }
    }

    override func showNoResultsView() {
        super.showNoResultsView()

        if searchController.isActive {
            noResultsViewController.view.frame = CGRect(x: 0.0,
                                                        y: searchController.searchBar.bounds.height,
                                                        width: tableView.frame.width,
                                                        height: max(tableView.frame.height, tableView.contentSize.height))
            tableView.bringSubviewToFront(noResultsViewController.view)
        }
    }

    override func syncContentEnded(_ syncHelper: WPContentSyncHelper) {
        guard syncHelper.hasMoreContent else {
            super.syncContentEnded(syncHelper)
            return
        }
    }


    // MARK: - Model Interaction

    /// Retrieves the page object at the specified index path.
    ///
    /// - Parameter indexPath: the index path of the page object to retrieve.
    ///
    /// - Returns: the requested page.
    ///
    fileprivate func pageAtIndexPath(_ indexPath: IndexPath) -> Page {
        return _tableViewHandler.page(at: indexPath)
    }

    // MARK: - TableView Handler Delegate Methods

    override func entityName() -> String {
        return String(describing: Page.self)
    }

    override func predicateForFetchRequest() -> NSPredicate {
        var predicates = [NSPredicate]()

        if let blog = blog {
            let basePredicate = NSPredicate(format: "blog = %@ && revision = nil", blog)
            predicates.append(basePredicate)
        }

        let searchText = currentSearchTerm() ?? ""
        let filterPredicate = searchController.isActive ? NSPredicate(format: "postTitle CONTAINS[cd] %@", searchText) : filterSettings.currentPostListFilter().predicateForFetchRequest

        // If we have recently trashed posts, create an OR predicate to find posts matching the filter,
        // or posts that were recently deleted.
        if searchText.count == 0 && recentlyTrashedPostObjectIDs.count > 0 {

            let trashedPredicate = NSPredicate(format: "SELF IN %@", recentlyTrashedPostObjectIDs)

            predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: [filterPredicate, trashedPredicate]))
        } else {
            predicates.append(filterPredicate)
        }

        if searchText.count > 0 {
            let searchPredicate = NSPredicate(format: "postTitle CONTAINS[cd] %@", searchText)
            predicates.append(searchPredicate)
        }

        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return predicate
    }


    // MARK: - Table View Handling

    func sectionNameKeyPath() -> String {
        let sortField = filterSettings.currentPostListFilter().sortField
        return Page.sectionIdentifier(dateKeyPath: sortField.keyPath)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard _tableViewHandler.groupResults else {
            return 0.0
        }
        return Constant.Size.pageSectionHeaderHeight
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constant.Size.pageCellWithTagEstimatedRowHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard _tableViewHandler.groupResults else {
            return UIView(frame: .zero)
        }

        let sectionInfo = _tableViewHandler.resultsController.sections?[section]
        let nibName = String(describing: PageListSectionHeaderView.self)
        let headerView = Bundle.main.loadNibNamed(nibName, owner: nil, options: nil)?.first as? PageListSectionHeaderView

        if let sectionInfo = sectionInfo, let headerView = headerView {
            headerView.setTitle(PostSearchHeader.title(forStatus: sectionInfo.name))
        }

        return headerView
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let page = pageAtIndexPath(indexPath)

        guard page.status != .trash else {
            return
        }

        editPage(page)
    }

    @objc func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        if let windowlessCell = dequeCellForWindowlessLoadingIfNeeded(tableView) {
            return windowlessCell
        }

        let page = pageAtIndexPath(indexPath)

        let identifier = cellIdentifierForPage(page)
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)

        configureCell(cell, at: indexPath)

        return cell
    }

    override func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        guard let cell = cell as? BasePageListCell else {
            preconditionFailure("The cell should be of class \(String(describing: BasePageListCell.self))")
        }

        cell.accessoryType = .none

        let page = pageAtIndexPath(indexPath)
        let filterType = filterSettings.currentPostListFilter().filterType

        if cell.reuseIdentifier == Constant.Identifiers.pageCellIdentifier {
            cell.indentationWidth = _tableViewHandler.isSearching ? 0.0 : Constant.Size.pageListTableViewCellLeading
            cell.indentationLevel = filterType != .published ? 0 : page.hierarchyIndex
            cell.onAction = { [weak self] cell, button, page in
                self?.handleMenuAction(fromCell: cell, fromButton: button, forPage: page)
            }
        } else if cell.reuseIdentifier == Constant.Identifiers.restorePageCellIdentifier {
            cell.selectionStyle = .none
            cell.onAction = { [weak self] cell, _, page in
                self?.handleRestoreAction(fromCell: cell, forPage: page)
            }
        }

        cell.contentView.backgroundColor = UIColor.listForeground

        cell.configureCell(page)
    }

    fileprivate func cellIdentifierForPage(_ page: Page) -> String {
        var identifier: String

        if recentlyTrashedPostObjectIDs.contains(page.objectID) == true && filterSettings.currentPostListFilter().filterType != .trashed {
            identifier = Constant.Identifiers.restorePageCellIdentifier
        } else {
            identifier = Constant.Identifiers.pageCellIdentifier
        }

        return identifier
    }

    // MARK: - Post Actions

    override func createPost() {
        WPAppAnalytics.track(.editorCreatedPost, withProperties: [WPAppAnalyticsKeyTapSource: "posts_view", WPAppAnalyticsKeyPostType: "page"], with: blog)

        PageCoordinator.showLayoutPickerIfNeeded(from: self, forBlog: blog) { [weak self] (selectedLayout) in
            self?.createPage(selectedLayout)
        }
    }

    private func createPage(_ starterLayout: PageTemplateLayout?) {
        let editorViewController = EditPageViewController(blog: blog, postTitle: starterLayout?.title, content: starterLayout?.content, appliedTemplate: starterLayout?.slug)
        present(editorViewController, animated: false)

        QuickStartTourGuide.shared.visited(.newPage)
    }

    fileprivate func editPage(_ page: Page) {
        guard !PostCoordinator.shared.isUploading(post: page) else {
            presentAlertForPageBeingUploaded()
            return
        }
        WPAppAnalytics.track(.postListEditAction, withProperties: propertiesForAnalytics(), with: page)

        let editorViewController = EditPageViewController(page: page)
        present(editorViewController, animated: false)
    }

    fileprivate func retryPage(_ apost: AbstractPost) {
        PostCoordinator.shared.save(apost)
    }

    // MARK: - Alert

    func presentAlertForPageBeingUploaded() {
        let message = NSLocalizedString("This page is currently uploading. It won't take long – try again soon and you'll be able to edit it.", comment: "Prompts the user that the page is being uploaded and cannot be edited while that process is ongoing.")

        let alertCancel = NSLocalizedString("OK", comment: "Title of an OK button. Pressing the button acknowledges and dismisses a prompt.")

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addCancelActionWithTitle(alertCancel, handler: nil)
        alertController.presentFromRootViewController()
    }

    fileprivate func draftPage(_ apost: AbstractPost, at indexPath: IndexPath?) {
        WPAnalytics.track(.postListDraftAction, withProperties: propertiesForAnalytics())

        let previousStatus = apost.status
        apost.status = .draft

        let contextManager = ContextManager.sharedInstance()
        let postService = PostService(managedObjectContext: contextManager.mainContext)

        postService.uploadPost(apost, success: { [weak self] _ in
            DispatchQueue.main.async {
                self?._tableViewHandler.refreshTableView(at: indexPath)
            }
        }) { [weak self] (error) in
            apost.status = previousStatus

            if let strongSelf = self {
                contextManager.save(strongSelf.managedObjectContext())
            }

            WPError.showXMLRPCErrorAlert(error)
        }
    }

    override func promptThatPostRestoredToFilter(_ filter: PostListFilter) {
        var message = NSLocalizedString("Page Restored to Drafts", comment: "Prompts the user that a restored page was moved to the drafts list.")

        switch filter.filterType {
        case .published:
            message = NSLocalizedString("Page Restored to Published", comment: "Prompts the user that a restored page was moved to the published list.")
        break
        case .scheduled:
            message = NSLocalizedString("Page Restored to Scheduled", comment: "Prompts the user that a restored page was moved to the scheduled list.")
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

    fileprivate func handleMenuAction(fromCell cell: UITableViewCell, fromButton button: UIButton, forPage page: AbstractPost) {
        let objectID = page.objectID

        let retryButtonTitle = NSLocalizedString("Retry", comment: "Label for a button that attempts to re-upload a page that previously failed to upload.")
        let viewButtonTitle = NSLocalizedString("View", comment: "Label for a button that opens the page when tapped.")
        let draftButtonTitle = NSLocalizedString("Move to Draft", comment: "Label for a button that moves a page to the draft folder")
        let publishButtonTitle = NSLocalizedString("Publish Immediately", comment: "Label for a button that moves a page to the published folder, publishing with the current date/time.")
        let trashButtonTitle = NSLocalizedString("Move to Trash", comment: "Label for a button that moves a page to the trash folder")
        let cancelButtonTitle = NSLocalizedString("Cancel", comment: "Label for a cancel button")
        let deleteButtonTitle = NSLocalizedString("Delete Permanently", comment: "Label for a button permanently deletes a page.")

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addCancelActionWithTitle(cancelButtonTitle, handler: nil)

        let indexPath = tableView.indexPath(for: cell)

        let filter = filterSettings.currentPostListFilter().filterType

        if filter == .trashed {
            alertController.addActionWithTitle(publishButtonTitle, style: .default, handler: { [weak self] (action) in
                guard let strongSelf = self,
                    let page = strongSelf.pageForObjectID(objectID) else {
                    return
                }

                strongSelf.publishPost(page)
            })

            alertController.addActionWithTitle(draftButtonTitle, style: .default, handler: { [weak self] (action) in
                guard let strongSelf = self,
                    let page = strongSelf.pageForObjectID(objectID) else {
                        return
                }

                strongSelf.draftPage(page, at: indexPath)
            })

            alertController.addActionWithTitle(deleteButtonTitle, style: .default, handler: { [weak self] (action) in
                guard let strongSelf = self,
                    let page = strongSelf.pageForObjectID(objectID) else {
                        return
                }

                strongSelf.deletePost(page)
            })
        } else if filter == .published {
            if page.isFailed {
                alertController.addActionWithTitle(retryButtonTitle, style: .default, handler: { [weak self] (action) in
                    guard let strongSelf = self,
                        let page = strongSelf.pageForObjectID(objectID) else {
                            return
                    }

                    strongSelf.retryPage(page)
                })
            } else {
                addEditAction(to: alertController, for: page)

                alertController.addActionWithTitle(viewButtonTitle, style: .default, handler: { [weak self] (action) in
                    guard let strongSelf = self,
                        let page = strongSelf.pageForObjectID(objectID) else {
                            return
                    }

                    strongSelf.viewPost(page)
                })

                addSetParentAction(to: alertController, for: page, at: indexPath)
                addSetHomepageAction(to: alertController, for: page, at: indexPath)
                addSetPostsPageAction(to: alertController, for: page, at: indexPath)

                alertController.addActionWithTitle(draftButtonTitle, style: .default, handler: { [weak self] (action) in
                    guard let strongSelf = self,
                        let page = strongSelf.pageForObjectID(objectID) else {
                            return
                    }

                    strongSelf.draftPage(page, at: indexPath)
                })
            }

            alertController.addActionWithTitle(trashButtonTitle, style: .default, handler: { [weak self] (action) in
                guard let strongSelf = self,
                    let page = strongSelf.pageForObjectID(objectID) else {
                        return
                }

                strongSelf.deletePost(page)
            })
        } else {
            if page.isFailed {
                alertController.addActionWithTitle(retryButtonTitle, style: .default, handler: { [weak self] (action) in
                    guard let strongSelf = self,
                        let page = strongSelf.pageForObjectID(objectID) else {
                            return
                    }

                    strongSelf.retryPage(page)
                })
            } else {
                addEditAction(to: alertController, for: page)

                alertController.addActionWithTitle(viewButtonTitle, style: .default, handler: { [weak self] (action) in
                    guard let strongSelf = self,
                        let page = strongSelf.pageForObjectID(objectID) else {
                            return
                    }

                    strongSelf.viewPost(page)
                })

                addSetParentAction(to: alertController, for: page, at: indexPath)

                alertController.addActionWithTitle(publishButtonTitle, style: .default, handler: { [weak self] (action) in
                    guard let strongSelf = self,
                        let page = strongSelf.pageForObjectID(objectID) else {
                            return
                    }

                    strongSelf.publishPost(page)
                })
            }

            alertController.addActionWithTitle(trashButtonTitle, style: .default, handler: { [weak self] (action) in
                guard let strongSelf = self,
                    let page = strongSelf.pageForObjectID(objectID) else {
                        return
                }

                strongSelf.deletePost(page)
            })
        }

        WPAnalytics.track(.postListOpenedCellMenu, withProperties: propertiesForAnalytics())

        alertController.modalPresentationStyle = .popover
        present(alertController, animated: true)

        if let presentationController = alertController.popoverPresentationController {
            presentationController.permittedArrowDirections = .any
            presentationController.sourceView = button
            presentationController.sourceRect = button.bounds
        }
    }

    private func addEditAction(to controller: UIAlertController, for page: AbstractPost) {
        if page.status == .trash {
            return
        }

        let buttonTitle = NSLocalizedString("Edit", comment: "Label for a button that opens the Edit Page view controller")
        controller.addActionWithTitle(buttonTitle, style: .default, handler: { [weak self] _ in
            if let page = self?.pageForObjectID(page.objectID) {
                self?.editPage(page)
            }
        })
    }

    private func addSetParentAction(to controller: UIAlertController, for page: AbstractPost, at index: IndexPath?) {
        /// This button is disabled for trashed pages
        //
        if page.status == .trash {
            return
        }

        let objectID = page.objectID
        let setParentButtonTitle = NSLocalizedString("Set Parent", comment: "Label for a button that opens the Set Parent options view controller")
        controller.addActionWithTitle(setParentButtonTitle, style: .default, handler: { [weak self] _ in
            if let page = self?.pageForObjectID(objectID) {
                self?.setParent(for: page, at: index)
            }
        })
    }

    private func setParent(for page: Page, at index: IndexPath?) {
        guard let index = index else {
            return
        }

        let selectedPage = pageAtIndexPath(index)
        let newIndex = _tableViewHandler.index(for: selectedPage)
        let pages = _tableViewHandler.removePage(from: newIndex)
        let parentPageNavigationController = ParentPageSettingsViewController.navigationController(with: pages, selectedPage: selectedPage) {
            self._tableViewHandler.isSearching = false
        }
        present(parentPageNavigationController, animated: true)
    }

    fileprivate func pageForObjectID(_ objectID: NSManagedObjectID) -> Page? {

        var pageManagedOjbect: NSManagedObject

        do {
            pageManagedOjbect = try managedObjectContext().existingObject(with: objectID)

        } catch let error as NSError {
            DDLogError("\(NSStringFromClass(type(of: self))), \(#function), \(error)")
            return nil
        } catch _ {
            DDLogError("\(NSStringFromClass(type(of: self))), \(#function), Could not find Page with ID \(objectID)")
            return nil
        }

        let page = pageManagedOjbect as? Page
        return page
    }

    fileprivate func handleRestoreAction(fromCell cell: UITableViewCell, forPage page: AbstractPost) {
        restorePost(page) { [weak self] in
            self?._tableViewHandler.refreshTableView(at: self?.tableView.indexPath(for: cell))
        }
    }

    private func addSetHomepageAction(to controller: UIAlertController, for page: AbstractPost, at index: IndexPath?) {
        let objectID = page.objectID

        /// This button is enabled if
        /// - Page is not trashed
        /// - The site's homepage type is .page
        /// - The page isn't currently the homepage
        //
        guard page.status != .trash,
            let homepageType = blog.homepageType,
            homepageType == .page,
            let page = pageForObjectID(objectID),
            page.isSiteHomepage == false else {
            return
        }

        let setHomepageButtonTitle = NSLocalizedString("Set as Homepage", comment: "Label for a button that sets the selected page as the site's Homepage")
        controller.addActionWithTitle(setHomepageButtonTitle, style: .default, handler: { [weak self] _ in
            if let pageID = page.postID?.intValue {
                self?.beginRefreshingManually()
                self?.homepageSettingsService?.setHomepageType(.page,
                                                               homePageID: pageID, success: {
                                                                self?.refreshAndReload()
                                                                self?.handleHomepageSettingsSuccess()
                }, failure: { error in
                    self?.refreshControl?.endRefreshing()
                    self?.handleHomepageSettingsFailure()
                })
            }
        })
    }

    private func addSetPostsPageAction(to controller: UIAlertController, for page: AbstractPost, at index: IndexPath?) {
        let objectID = page.objectID

        /// This button is enabled if
        /// - Page is not trashed
        /// - The site's homepage type is .page
        /// - The page isn't currently the posts page
        //
        guard page.status != .trash,
            let homepageType = blog.homepageType,
            homepageType == .page,
            let page = pageForObjectID(objectID),
            page.isSitePostsPage == false else {
            return
        }

        let setPostsPageButtonTitle = NSLocalizedString("Set as Posts Page", comment: "Label for a button that sets the selected page as the site's Posts page")
        controller.addActionWithTitle(setPostsPageButtonTitle, style: .default, handler: { [weak self] _ in
            if let pageID = page.postID?.intValue {
                self?.beginRefreshingManually()
                self?.homepageSettingsService?.setHomepageType(.page,
                                                               withPostsPageID: pageID, success: {
                                                                self?.refreshAndReload()
                                                                self?.handleHomepagePostsPageSettingsSuccess()
                }, failure: { error in
                    self?.refreshControl?.endRefreshing()
                    self?.handleHomepageSettingsFailure()
                })
            }
        })
    }

    private func handleHomepageSettingsSuccess() {
        let notice = Notice(title: HomepageSettingsText.updateHomepageSuccessTitle, feedbackType: .success)
        ActionDispatcher.global.dispatch(NoticeAction.post(notice))
    }

    private func handleHomepagePostsPageSettingsSuccess() {
        let notice = Notice(title: HomepageSettingsText.updatePostsPageSuccessTitle, feedbackType: .success)
        ActionDispatcher.global.dispatch(NoticeAction.post(notice))
    }

    private func handleHomepageSettingsFailure() {
        let notice = Notice(title: HomepageSettingsText.updateErrorTitle, message: HomepageSettingsText.updateErrorMessage, feedbackType: .error)
        ActionDispatcher.global.dispatch(NoticeAction.post(notice))
    }

    // MARK: - UISearchControllerDelegate

    override func willPresentSearchController(_ searchController: UISearchController) {
        super.willPresentSearchController(searchController)

        filterTabBar.alpha = WPAlphaZero

        tableView.contentInset.top = -searchController.searchBar.bounds.height
    }

    override func updateSearchResults(for searchController: UISearchController) {
        super.updateSearchResults(for: searchController)
    }

    override func willDismissSearchController(_ searchController: UISearchController) {
        _tableViewHandler.isSearching = false
        _tableViewHandler.refreshTableView()
        super.willDismissSearchController(searchController)
    }

    func didPresentSearchController(_ searchController: UISearchController) {
        tableView.scrollIndicatorInsets.top = searchController.searchBar.bounds.height + searchController.searchBar.frame.origin.y - view.safeAreaInsets.top
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        UIView.animate(withDuration: Animations.searchDismissDuration, delay: 0, options: .curveLinear, animations: {
            self.filterTabBar.alpha = WPAlphaFull
        }) { _ in
            self.hideNoResultsView()
        }
    }

    enum Animations {
        static let searchDismissDuration: TimeInterval = 0.3
    }

    // MARK: - NetworkAwareUI

    override func noConnectionMessage() -> String {
        return NSLocalizedString("No internet connection. Some pages may be unavailable while offline.",
                                 comment: "Error message shown when the user is browsing Site Pages without an internet connection.")
    }

    struct HomepageSettingsText {
        static let updateErrorTitle = NSLocalizedString("Unable to update homepage settings", comment: "Error informing the user that their homepage settings could not be updated")
        static let updateErrorMessage = NSLocalizedString("Please try again later.", comment: "Prompt for the user to retry a failed action again later")
        static let updateHomepageSuccessTitle = NSLocalizedString("Homepage successfully updated", comment: "Message informing the user that their static homepage page was set successfully")
        static let updatePostsPageSuccessTitle = NSLocalizedString("Posts page successfully updated", comment: "Message informing the user that their static homepage for posts was set successfully")
    }
}

// MARK: - No Results Handling

private extension PageListViewController {

    func handleRefreshNoResultsViewController(_ noResultsViewController: NoResultsViewController) {

        guard connectionAvailable() else {
              noResultsViewController.configure(title: "", noConnectionTitle: NoResultsText.noConnectionTitle, buttonTitle: NoResultsText.buttonTitle, subtitle: nil, noConnectionSubtitle: NoResultsText.noConnectionSubtitle, attributedSubtitle: nil, attributedSubtitleConfiguration: nil, image: nil, subtitleImage: nil, accessoryView: nil)
            return
        }

        if searchController.isActive {
            if currentSearchTerm()?.count == 0 {
                noResultsViewController.configureForNoSearchResults(title: NoResultsText.searchPages)
            } else {
                noResultsViewController.configureForNoSearchResults(title: noResultsTitle())
            }
        } else {
            let accessoryView = syncHelper.isSyncing ? NoResultsViewController.loadingAccessoryView() : nil

            noResultsViewController.configure(title: noResultsTitle(),
                                              buttonTitle: noResultsButtonTitle(),
                                              image: noResultsImageName,
                                              accessoryView: accessoryView)
        }
    }

    var noResultsImageName: String {
        return "pages-no-results"
    }

    func noResultsButtonTitle() -> String? {
        if syncHelper.isSyncing == true || isSearching() {
            return nil
        }

        let filterType = filterSettings.currentPostListFilter().filterType
        return filterType == .trashed ? nil : NoResultsText.buttonTitle
    }

    func noResultsTitle() -> String {
        if syncHelper.isSyncing == true {
            return NoResultsText.fetchingTitle
        }

        if isSearching() {
            return NoResultsText.noMatchesTitle
        }

        return noResultsFilteredTitle()
    }

    func noResultsFilteredTitle() -> String {
        let filterType = filterSettings.currentPostListFilter().filterType
        switch filterType {
        case .draft:
            return NoResultsText.noDraftsTitle
        case .scheduled:
            return NoResultsText.noScheduledTitle
        case .trashed:
            return NoResultsText.noTrashedTitle
        case .published:
            return NoResultsText.noPublishedTitle
        }
    }

    struct NoResultsText {
        static let buttonTitle = NSLocalizedString("Create Page", comment: "Button title, encourages users to create their first page on their blog.")
        static let fetchingTitle = NSLocalizedString("Fetching pages...", comment: "A brief prompt shown when the reader is empty, letting the user know the app is currently fetching new pages.")
        static let noMatchesTitle = NSLocalizedString("No pages matching your search", comment: "Displayed when the user is searching the pages list and there are no matching pages")
        static let noDraftsTitle = NSLocalizedString("You don't have any draft pages", comment: "Displayed when the user views drafts in the pages list and there are no pages")
        static let noScheduledTitle = NSLocalizedString("You don't have any scheduled pages", comment: "Displayed when the user views scheduled pages in the pages list and there are no pages")
        static let noTrashedTitle = NSLocalizedString("You don't have any trashed pages", comment: "Displayed when the user views trashed in the pages list and there are no pages")
        static let noPublishedTitle = NSLocalizedString("You haven't published any pages yet", comment: "Displayed when the user views published pages in the pages list and there are no pages")
        static let searchPages = NSLocalizedString("Search pages", comment: "Text displayed when the search controller will be presented")
        static let noConnectionTitle: String = NSLocalizedString("Unable to load pages right now.", comment: "Title for No results full page screen displayedfrom pages list when there is no connection")
        static let noConnectionSubtitle: String = NSLocalizedString("Check your network connection and try again. Or draft a page.", comment: "Subtitle for No results full page screen displayed from pages list when there is no connection")
    }

}
