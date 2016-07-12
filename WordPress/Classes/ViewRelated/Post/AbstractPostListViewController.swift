import Foundation
import WordPressComAnalytics
import WordPressShared
import wpxmlrpc

class AbstractPostListViewController : UIViewController, WPContentSyncHelperDelegate, WPNoResultsViewDelegate, WPSearchControllerDelegate, WPSearchResultsUpdating, WPTableViewHandlerDelegate {

    typealias WPNoResultsView = WordPressShared.WPNoResultsView

    enum PostAuthorFilter : UInt {
        case Mine = 0
        case Everyone = 1
    }

    private static let postsControllerRefreshInterval = NSTimeInterval(300)
    private static let HTTPErrorCodeForbidden = Int(403)
    private static let postsFetchRequestBatchSize = Int(10)
    private static let postsLoadMoreThreshold = Int(4)
    private static let preferredFiltersPopoverContentSize = CGSize(width: 320.0, height: 220.0)

    private static let defaultHeightForFooterView = CGFloat(44.0)

    var blog : Blog!

    /// This closure will be executed whenever the noResultsView must be visually refreshed.  It's up
    /// to the subclass to define this property.
    ///
    var refreshNoResultsView : ((WPNoResultsView) -> ())!
    var tableViewController : UITableViewController!

    var tableView : UITableView {
        get {
            return self.tableViewController.tableView
        }
    }

    var refreshControl : UIRefreshControl? {
        get {
            return self.tableViewController.refreshControl
        }
    }

    lazy var tableViewHandler : WPTableViewHandler = {
        let tableViewHandler = WPTableViewHandler(tableView: self.tableView)

        tableViewHandler.cacheRowHeights = true
        tableViewHandler.delegate = self
        tableViewHandler.updateRowAnimation = .None

        return tableViewHandler
    }()

    lazy var syncHelper : WPContentSyncHelper = {
        let syncHelper = WPContentSyncHelper()

        syncHelper.delegate = self

        return syncHelper
    }()

    lazy var searchHelper : WPContentSearchHelper = {
        let searchHelper = WPContentSearchHelper()
        return searchHelper
    }()

    lazy var noResultsView : WPNoResultsView = {
        let noResultsView = WPNoResultsView()
        noResultsView.delegate = self

        return noResultsView
    }()


    var postListFooterView : PostListFooterView!

    @IBOutlet var filterButton : NavBarTitleDropdownButton!
    @IBOutlet var rightBarButtonView : UIView!
    @IBOutlet var searchButton : UIButton!
    @IBOutlet var addButton : UIButton!
    @IBOutlet var searchWrapperView : UIView! // Used on iPhone for presenting the search bar.
    @IBOutlet var authorsFilterView : UIView! // Search lives here on iPad
    @IBOutlet var authorsFilterViewHeightConstraint : NSLayoutConstraint!
    @IBOutlet var searchWrapperViewHeightConstraint : NSLayoutConstraint!

    var searchController : WPSearchController! // Stand-in for UISearchController
    private var allPostListFilters = [String:[PostListFilter]]()
    var recentlyTrashedPostObjectIDs = [NSManagedObjectID]() // IDs of trashed posts. Cleared on refresh or when filter changes.

    private var needsRefreshCachedCellHeightsBeforeLayout = false
    private var searchesSyncing = 0

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl?.addTarget(self, action: #selector(refresh(_:)), forControlEvents: .ValueChanged)

        configureCellsForLayout()
        configureTableView()
        configureFooterView()
        configureNavbar()
        configureSearchController()
        configureSearchHelper()
        configureAuthorFilter()

        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
        tableView.reloadData()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refreshResults()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        automaticallySyncIfAppropriate()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AbstractPostListViewController.handleApplicationDidBecomeActive(_:)), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        searchController.active = false

        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)

        coordinator.animateAlongsideTransition({[weak self] context in
            guard let strongSelf = self else {
                return
            }

            if strongSelf.searchWrapperViewHeightConstraint.constant > 0 {
                strongSelf.searchWrapperViewHeightConstraint.constant = strongSelf.heightForSearchWrapperView()
            }
        }, completion: nil)
    }

    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        needsRefreshCachedCellHeightsBeforeLayout = true
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if needsRefreshCachedCellHeightsBeforeLayout {
            needsRefreshCachedCellHeightsBeforeLayout = false

            let width = view.frame.width

            tableViewHandler.refreshCachedRowHeightsForWidth(width)
            tableView.reloadData()
        }
    }

    // MARK: - Multitasking Support

    func handleApplicationDidBecomeActive(notification: NSNotification) {
        needsRefreshCachedCellHeightsBeforeLayout = true
    }

    // MARK: - Configuration


    func heightForFooterView() -> CGFloat
    {
        return self.dynamicType.defaultHeightForFooterView
    }


    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    func configureNavbar() {
        // IMPORTANT: this code makes sure that the back button in WPPostViewController doesn't show
        // this VC's title.
        //
        let backButton = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton

        let rightBarButtonItem = UIBarButtonItem(customView: rightBarButtonView)
        WPStyleGuide.setRightBarButtonItemWithCorrectSpacing(rightBarButtonItem, forNavigationItem:navigationItem)

        navigationItem.titleView = filterButton
        updateFilterTitle()
    }

    func configureCellsForLayout() {
        assert(false, "You should implement this method in the subclass")
    }

    func configureTableView() {
        assert(false, "You should implement this method in the subclass")
    }

    func configureFooterView() {

        let mainBundle = NSBundle.mainBundle()

        guard let footerView = mainBundle.loadNibNamed("PostListFooterView", owner: nil, options: nil)[0] as? PostListFooterView else {
            preconditionFailure("Could not load the footer view from the nib file.")
        }

        postListFooterView = footerView
        postListFooterView.showSpinner(false)

        var frame = postListFooterView.frame
        frame.size.height = heightForFooterView()

        postListFooterView.frame = frame
        tableView.tableFooterView = postListFooterView
    }

    private func refreshResults() {
        guard isViewLoaded() == true else {
            return
        }

        if tableViewHandler.resultsController.fetchedObjects?.count > 0 {
            hideNoResultsView()
        } else {
            showNoResultsView()
        }
    }

    func configureAuthorFilter() {
        fatalError("You should implement this method in the subclass")
    }

    func configureSearchController() {
        searchController = WPSearchController(searchResultsController: nil)

        let searchControllerConfigurator = WPSearchControllerConfigurator(searchController: searchController, withSearchWrapperView: searchWrapperView)
        searchControllerConfigurator.configureSearchControllerAndWrapperView()
        configureSearchBarPlaceholder()
        searchController.delegate = self
        searchController.searchResultsUpdater = self
    }

    func configureSearchBarPlaceholder() {

        // Adjust color depending on where the search bar is being presented.
        let placeholderColor = WPStyleGuide.wordPressBlue()
        let placeholderText = NSLocalizedString("Search", comment: "Placeholder text for the search bar on the post screen.")

        let defaultSearchBarTextAttributes = WPStyleGuide.defaultSearchBarTextAttributes(placeholderColor)
        let attrPlacholderText = NSAttributedString(string: placeholderText, attributes: defaultSearchBarTextAttributes)

        let defaultTextAttributes = WPStyleGuide.defaultSearchBarTextAttributes(UIColor.whiteColor())

        UITextField.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self, self.dynamicType]).attributedPlaceholder = attrPlacholderText

        UITextField.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self, self.dynamicType]).defaultTextAttributes = defaultTextAttributes
    }

    func configureSearchWrapper() {
        searchWrapperView.backgroundColor = WPStyleGuide.wordPressBlue()
    }

    func configureSearchHelper() {
        searchHelper.resetConfiguration()
        searchHelper.configureImmediateSearch({ [weak self] in
            self?.updateForLocalPostsMatchingSearchText()
        })
        searchHelper.configureDeferredSearch({ [weak self] in
            self?.syncPostsMatchingSearchText()
        })
    }

    func propertiesForAnalytics() -> [String:AnyObject] {
        var properties = [String:AnyObject]()

        properties["type"] = postTypeToSync()
        properties["filter"] = currentPostListFilter().title

        if let dotComID = blog.dotComID {
            properties[WPAppAnalyticsKeyBlogID] = dotComID
        }

        return properties
    }

    // MARK: - GUI: No results view logic

    private func hideNoResultsView() {
        postListFooterView.hidden = false
        noResultsView.removeFromSuperview()
    }

    private func showNoResultsView() {
        precondition(refreshNoResultsView != nil)

        postListFooterView.hidden = true
        refreshNoResultsView(noResultsView)

        // Only add and animate no results view if it isn't already
        // in the table view
        if noResultsView.isDescendantOfView(tableView) == false {
            tableView.addSubviewWithFadeAnimation(noResultsView)
        } else {
            noResultsView.centerInSuperview()
        }

        tableView.sendSubviewToBack(noResultsView)
    }

    // MARK: - TableViewHandler Delegate Methods

    func entityName() -> String {
        fatalError("You should implement this method in the subclass")
    }

    func managedObjectContext() -> NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }

    func fetchRequest() -> NSFetchRequest {
        let fetchRequest = NSFetchRequest(entityName: entityName())

        fetchRequest.predicate = predicateForFetchRequest()
        fetchRequest.sortDescriptors = sortDescriptorsForFetchRequest()
        fetchRequest.fetchBatchSize = self.dynamicType.postsFetchRequestBatchSize
        fetchRequest.fetchLimit = Int(numberOfPostsPerSync())

        return fetchRequest
    }

    func sortDescriptorsForFetchRequest() -> [NSSortDescriptor] {
        // Ascending only for scheduled posts/pages.
        let ascending = currentPostListFilter().filterType == .Scheduled

        let sortDescriptorLocal = NSSortDescriptor(key: "metaIsLocal", ascending: false)
        let sortDescriptorImmediately = NSSortDescriptor(key: "metaPublishImmediately", ascending: false)
        if currentPostListFilter().filterType == .Draft {
            return [sortDescriptorLocal, NSSortDescriptor(key: "dateModified", ascending: ascending)]
        }
        let sortDescriptorDate = NSSortDescriptor(key: "date_created_gmt", ascending: ascending)
        return [sortDescriptorLocal, sortDescriptorImmediately, sortDescriptorDate]
    }

    func updateAndPerformFetchRequest() {
        assert(NSThread.isMainThread(), "AbstractPostListViewController Error: NSFetchedResultsController accessed in BG")

        var predicate = predicateForFetchRequest()
        let sortDescriptors = sortDescriptorsForFetchRequest()
        let fetchRequest = tableViewHandler.resultsController.fetchRequest

        // Set the predicate based on filtering by the oldestPostDate and not searching.
        let filter = currentPostListFilter()

        if let oldestPostDate = filter.oldestPostDate where !isSearching() {

            // Filter posts by any posts newer than the filter's oldestPostDate.
            // Also include any posts that don't have a date set, such as local posts created without a connection.
            let datePredicate = NSPredicate(format: "(date_created_gmt = NULL) OR (date_created_gmt >= %@)", oldestPostDate)

            predicate = NSCompoundPredicate.init(andPredicateWithSubpredicates: [predicate, datePredicate])
        }

        // Set up the fetchLimit based on filtering or searching
        if filter.oldestPostDate != nil || isSearching() == true {
            // If filtering by the oldestPostDate or searching, the fetchLimit should be disabled.
            fetchRequest.fetchLimit = 0
        } else {
            // If not filtering by the oldestPostDate or searching, set the fetchLimit to the default number of posts.
            fetchRequest.fetchLimit = Int(numberOfPostsPerSync())
        }

        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors

        do {
            try tableViewHandler.resultsController.performFetch()
        } catch {
            DDLogSwift.logError("Error fetching posts after updating the fetch request predicate: \(error)")
        }
    }

    func refreshCachedRowHeightsForTableViewWidth() {
        let width = CGRectGetWidth(tableView.bounds)
        tableViewHandler.refreshCachedRowHeightsForWidth(width)
    }

    func updateAndPerformFetchRequestRefreshingResults() {
        updateAndPerformFetchRequest()
        refreshCachedRowHeightsForTableViewWidth()
        tableView.reloadData()
        refreshResults()
    }

    func resetTableViewContentOffset(animated: Bool = false) {
        // Reset the tableView contentOffset to the top before we make any dataSource changes.
        var tableOffset = tableView.contentOffset
        tableOffset.y = -tableView.contentInset.top
        tableView.setContentOffset(tableOffset, animated: animated)
    }

    func predicateForFetchRequest() -> NSPredicate {
        fatalError("You should implement this method in the subclass")
    }

    // MARK: - Table View Handling

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        assert(false, "You should implement this method in the subclass")
    }

    func tableViewDidChangeContent(tableView: UITableView) {
        refreshResults()
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        guard isViewOnScreen() && !isSearching() else {
            return
        }

        // Are we approaching the end of the table?
        if indexPath.section + 1 == tableView.numberOfSections
            && indexPath.row + self.dynamicType.postsLoadMoreThreshold >= tableView.numberOfRowsInSection(indexPath.section) {

            // Only 3 rows till the end of table
            if currentPostListFilter().hasMore {
                syncHelper.syncMoreContent()
            }
        }
    }

    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        assert(false, "You should implement this method in the subclass")
    }

    // MARK: - Actions

    @IBAction func refresh(sender: AnyObject) {
        syncItemsWithUserInteraction(true)

        WPAnalytics.track(.PostListPullToRefresh, withProperties: propertiesForAnalytics())
    }

    @IBAction func handleAddButtonTapped(sender: AnyObject) {
        createPost()
    }

    @IBAction func handleSearchButtonTapped(sender: AnyObject) {
        toggleSearch()
    }

    @IBAction func didTapNoResultsView(noResultsView: WPNoResultsView) {
        WPAnalytics.track(.PostListNoResultsButtonPressed, withProperties: propertiesForAnalytics())

        createPost()
    }

    @IBAction func didTapFilterButton(sender: AnyObject) {
        displayFilters()
    }

    // MARK: - Synching

    func automaticallySyncIfAppropriate() {
        // Only automatically refresh if the view is loaded and visible on the screen
        if !isViewLoaded() || view.window == nil {
            DDLogSwift.logVerbose("View is not visible and will not check for auto refresh.")
            return
        }

        // Do not start auto-sync if connection is down
        let appDelegate = WordPressAppDelegate.sharedInstance()

        if appDelegate.connectionAvailable == false {
            refreshResults()
            return
        }

        if let lastSynced = lastSyncDate()
            where abs(lastSynced.timeIntervalSinceNow) <= self.dynamicType.postsControllerRefreshInterval {

            refreshResults()
        } else {
            // Update in the background
            syncItemsWithUserInteraction(false)
        }
    }

    func syncItemsWithUserInteraction(userInteraction: Bool) {
        syncHelper.syncContentWithUserInteraction(userInteraction)
        refreshResults()
    }

    func updateFilter(filter: PostListFilter, withSyncedPosts posts:[AbstractPost], syncOptions options: PostServiceSyncOptions) {

        guard let oldestPost = posts.last else {
            assertionFailure("This method should not be called with no posts.")
            return
        }

        // Reset the filter to only show the latest sync point.
        filter.oldestPostDate = oldestPost.dateCreated()
        filter.hasMore = posts.count >= options.number.integerValue

        updateAndPerformFetchRequestRefreshingResults()
    }

    func numberOfPostsPerSync() -> UInt {
        return PostServiceDefaultNumberToSync
    }

    // MARK: - WPContentSyncHelperDelegate

    func postTypeToSync() -> String {
        // Subclasses should override.
        return PostServiceTypeAny
    }

    func lastSyncDate() -> NSDate? {
        return blog.lastPostsSync
    }

    func syncHelper(syncHelper: WPContentSyncHelper, syncContentWithUserInteraction userInteraction: Bool, success: ((hasMore: Bool) -> ())?, failure: ((error: NSError) -> ())?) {

        if recentlyTrashedPostObjectIDs.count > 0 {
            recentlyTrashedPostObjectIDs.removeAll()
            updateAndPerformFetchRequestRefreshingResults()
        }

        let filter = currentPostListFilter()
        let author = shouldShowOnlyMyPosts() ? blogUserID() : nil

        let postService = PostService(managedObjectContext: managedObjectContext())

        let options = PostServiceSyncOptions()
        options.statuses = filter.statuses
        options.authorID = author
        options.number = numberOfPostsPerSync()
        options.purgesLocalSync = true

        postService.syncPostsOfType(
            postTypeToSync(),
            withOptions: options,
            forBlog: blog,
            success: {[weak self] posts in
                guard let strongSelf = self,
                    let posts = posts else {
                    return
                }

                if posts.count > 0 {
                    strongSelf.updateFilter(filter, withSyncedPosts: posts, syncOptions: options)
                }

                success?(hasMore: filter.hasMore)

                if strongSelf.isSearching() {
                    // If we're currently searching, go ahead and request a sync with the searchText since
                    // an action was triggered to syncContent.
                    strongSelf.syncPostsMatchingSearchText()
                }

            }, failure: {[weak self] (error: NSError?) -> () in

                guard let strongSelf = self,
                    let error = error else {
                    return
                }

                failure?(error: error)

                if userInteraction == true {
                    strongSelf.handleSyncFailure(error)
                }
        })
    }

    func syncHelper(syncHelper: WPContentSyncHelper, syncMoreWithSuccess success: ((hasMore: Bool) -> Void)?, failure: ((error: NSError) -> Void)?) {

        WPAnalytics.track(.PostListLoadedMore, withProperties: propertiesForAnalytics())
        postListFooterView.showSpinner(true)

        let filter = currentPostListFilter()
        let author = shouldShowOnlyMyPosts() ? blogUserID() : nil

        let postService = PostService(managedObjectContext: managedObjectContext())

        let options = PostServiceSyncOptions()
        options.statuses = filter.statuses
        options.authorID = author
        options.number = numberOfPostsPerSync()
        options.offset = tableViewHandler.resultsController.fetchedObjects?.count

        postService.syncPostsOfType(
            postTypeToSync(),
            withOptions: options,
            forBlog: blog,
            success: {[weak self] posts in
                guard let strongSelf = self,
                    let posts = posts else {
                        return
                }

                if posts.count > 0 {
                    strongSelf.updateFilter(filter, withSyncedPosts: posts, syncOptions: options)
                }

                success?(hasMore: filter.hasMore)
            }, failure: {[weak self] (error: NSError?) -> () in

                guard let strongSelf = self,
                    let error = error else {
                        return
                }

                failure?(error: error)

                strongSelf.handleSyncFailure(error)
            })
    }

    func syncContentEnded() {
        refreshControl?.endRefreshing()
        postListFooterView.showSpinner(false)

        noResultsView.removeFromSuperview()

        if tableViewHandler.resultsController.fetchedObjects?.count == 0 {
            // This is a special case.  Core data can be a bit slow about notifying
            // NSFetchedResultsController delegates about changes to the fetched results.
            // To compensate, call configureNoResultsView after a short delay.
            // It will be redisplayed if necessary.

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(100 * NSEC_PER_MSEC)), dispatch_get_main_queue(), { [weak self] in
                self?.refreshResults()
            })
        }
    }

    func handleSyncFailure(error: NSError) {
        if error.domain == WPXMLRPCFaultErrorDomain
            && error.code == self.dynamicType.HTTPErrorCodeForbidden {
            promptForPassword()
            return
        }

        WPError.showNetworkingAlertWithError(error, title: NSLocalizedString("Unable to Sync", comment: "Title of error prompt shown when a sync the user initiated fails."))
    }

    func promptForPassword() {
        let message = NSLocalizedString("The username or password stored in the app may be out of date. Please re-enter your password in the settings and try again.", comment: "")

        // bad login/pass combination
        let editSiteViewController = SiteSettingsViewController(blog: blog)

        let navController = UINavigationController(rootViewController: editSiteViewController)
        navController.navigationBar.translucent = false

        navController.modalTransitionStyle = .CrossDissolve
        navController.modalPresentationStyle = .FormSheet

        WPError.showAlertWithTitle(NSLocalizedString("Unable to Connect", comment: ""), message: message, withSupportButton: true) { _ in
            self.presentViewController(navController, animated: true, completion: nil)
        }
    }

    // MARK: - Searching

    func toggleSearch() {
        searchController.active = !searchController.active
    }

    func heightForSearchWrapperView() -> CGFloat {

        guard let navigationController = navigationController else {
            return SearchWrapperViewMinHeight
        }

        let navBar = navigationController.navigationBar
        let height = navBar.frame.height + self.topLayoutGuide.length

        return max(height, SearchWrapperViewMinHeight)
    }

    func isSearching() -> Bool {
        return searchController.active && currentSearchTerm()?.characters.count > 0
    }

    func currentSearchTerm() -> String? {
        return searchController.searchBar.text
    }

    func updateForLocalPostsMatchingSearchText() {
        updateAndPerformFetchRequest()
        tableViewHandler.clearCachedRowHeights()
        tableView.reloadData()

        let filter = currentPostListFilter()
        if filter.hasMore && tableViewHandler.resultsController.fetchedObjects?.count == 0 {
            // If the filter detects there are more posts, but there are none that match the current search
            // hide the no results view while the upcoming syncPostsMatchingSearchText() may in fact load results.
            hideNoResultsView()
            postListFooterView.hidden = true
        } else {
            refreshResults()
        }
    }

    func isSyncingPostsWithSearch() -> Bool {
        return searchesSyncing > 0
    }

    func postsSyncWithSearchDidBegin() {
        searchesSyncing += 1
        postListFooterView.showSpinner(true)
        postListFooterView.hidden = false
    }

    func postsSyncWithSearchEnded() {
        searchesSyncing -= 1
        assert(searchesSyncing >= 0, "Expected Int searchesSyncing to be 0 or greater while searching.")
        if !isSyncingPostsWithSearch() {
            postListFooterView.showSpinner(false)
            refreshResults()
        }
    }

    func syncPostsMatchingSearchText() {
        guard let searchText = searchController.searchBar.text where !searchText.isEmpty() else {
            return
        }
        let filter = currentPostListFilter()
        guard filter.hasMore else {
            return
        }

        postsSyncWithSearchDidBegin()

        let author = shouldShowOnlyMyPosts() ? blogUserID() : nil
        let postService = PostService(managedObjectContext: managedObjectContext())
        let options = PostServiceSyncOptions()
        options.statuses = filter.statuses
        options.authorID = author
        options.number = 20
        options.purgesLocalSync = false
        options.search = searchText

        postService.syncPostsOfType(
            postTypeToSync(),
            withOptions: options,
            forBlog: blog,
            success: { [weak self] posts in
                self?.postsSyncWithSearchEnded()
            }, failure: { [weak self] (error: NSError?) in
                self?.postsSyncWithSearchEnded()
            }
        )
    }

    // MARK: - Actions

    func publishPost(apost: AbstractPost) {
        WPAnalytics.track(.PostListPublishAction, withProperties: propertiesForAnalytics())

        apost.status = PostStatusPublish
        if let date = apost.dateCreated() where date == NSDate().laterDate(date) {
            apost.setDateCreated(NSDate())
        }

        let postService = PostService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        postService.uploadPost(apost, success: nil) { [weak self] (error: NSError!) in

            guard let strongSelf = self else {
                return
            }

            if error.code == strongSelf.dynamicType.HTTPErrorCodeForbidden {
                strongSelf.promptForPassword()
            } else {
                WPError.showXMLRPCErrorAlert(error)
            }

            strongSelf.syncItemsWithUserInteraction(false)
        }
    }

    func viewPost(apost: AbstractPost) {
        WPAnalytics.track(.PostListViewAction, withProperties: propertiesForAnalytics())

        let post = apost.hasRevision() ? apost.revision : apost

        let controller = PostPreviewViewController(post: post)
        controller.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(controller, animated: true)
    }

    func deletePost(apost: AbstractPost) {
        WPAnalytics.track(.PostListTrashAction, withProperties: propertiesForAnalytics())

        let postObjectID = apost.objectID

        recentlyTrashedPostObjectIDs.append(postObjectID)

        // Update the fetch request *before* making the service call.
        updateAndPerformFetchRequest()

        let indexPath = tableViewHandler.resultsController.indexPathForObject(apost)

        if let indexPath = indexPath {
            tableViewHandler.invalidateCachedRowHeightAtIndexPath(indexPath)
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }

        let postService = PostService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        postService.trashPost(apost, success: nil) { [weak self] (error: NSError!) in

            guard let strongSelf = self else {
                return
            }

            if error.code == strongSelf.dynamicType.HTTPErrorCodeForbidden {
                strongSelf.promptForPassword()
            } else {
                WPError.showXMLRPCErrorAlert(error)
            }

            if let index = strongSelf.recentlyTrashedPostObjectIDs.indexOf(postObjectID) {
                strongSelf.recentlyTrashedPostObjectIDs.removeAtIndex(index)

                if let indexPath = indexPath {
                    strongSelf.tableViewHandler.invalidateCachedRowHeightAtIndexPath(indexPath)
                    strongSelf.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                }
            }
        }
    }

    func restorePost(apost: AbstractPost) {
        WPAnalytics.track(.PostListRestoreAction, withProperties: propertiesForAnalytics())

        // if the post was recently deleted, update the status helper and reload the cell to display a spinner
        let postObjectID = apost.objectID

        if let index = recentlyTrashedPostObjectIDs.indexOf(postObjectID) {
            recentlyTrashedPostObjectIDs.removeAtIndex(index)
        }

        let postService = PostService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        postService.restorePost(apost, success: { [weak self] in

            guard let strongSelf = self else {
                return
            }

            var apost : AbstractPost

            // Make sure the post still exists.
            do {
                apost = try strongSelf.managedObjectContext().existingObjectWithID(postObjectID) as! AbstractPost
            } catch {
                DDLogSwift.logError("\(error)")
                return
            }

            if let postStatus = apost.status {
                // If the post was restored, see if it appears in the current filter.
                // If not, prompt the user to let it know under which filter it appears.
                let filter = strongSelf.filterThatDisplaysPostsWithStatus(postStatus)

                if filter.filterType == strongSelf.currentPostListFilter().filterType {
                    return
                }

                strongSelf.promptThatPostRestoredToFilter(filter)
            }
        }) { [weak self] (error: NSError!) in

            guard let strongSelf = self else {
                return
            }

            if error.code == strongSelf.dynamicType.HTTPErrorCodeForbidden {
                strongSelf.promptForPassword()
            } else {
                WPError.showXMLRPCErrorAlert(error)
            }

            strongSelf.recentlyTrashedPostObjectIDs.append(postObjectID)
        }
    }

    func promptThatPostRestoredToFilter(filter: PostListFilter) {
        assert(false, "You should implement this method in the subclass")
    }

    // MARK: - Post Actions

    func createPost() {
        assert(false, "You should implement this method in the subclass")
    }

    // MARK: - Data Sources

    /// Retrieves the userID for the user of the current blog.
    ///
    /// - Returns: the userID for the user of the current WPCom blog.  If the blog is not hosted at
    ///     WordPress.com, `nil` is returned instead.
    ///
    func blogUserID() -> NSNumber? {
        return blog.account?.userID
    }

    // MARK: - Filter Related

    func canFilterByAuthor() -> Bool {
        return blog.isHostedAtWPcom && blog.isMultiAuthor && blogUserID() != nil
    }

    func shouldShowOnlyMyPosts() -> Bool {
        let filter = currentPostAuthorFilter()
        return filter == .Mine
    }

    func currentPostAuthorFilter() -> PostAuthorFilter {
        return .Everyone
    }

    func setCurrentPostAuthorFilter(filter: PostAuthorFilter) {
        // Noop. The default implementation is read only.
        // Subclasses may override the getter and setter for their own filter storage.
    }

    func availablePostListFilters() -> [PostListFilter] {
        let currentAuthorFilter = currentPostAuthorFilter()
        let authorFilterKey = "filter_key_\(currentAuthorFilter.rawValue)"

        if allPostListFilters[authorFilterKey] == nil {
            allPostListFilters[authorFilterKey] = PostListFilter.postListFilters()
        }

        return allPostListFilters[authorFilterKey]!
    }

    func currentPostListFilter() -> PostListFilter {
        return self.availablePostListFilters()[currentFilterIndex()]
    }

    func filterThatDisplaysPostsWithStatus(postStatus: String) -> PostListFilter {
        let index = indexOfFilterThatDisplaysPostsWithStatus(postStatus)
        return availablePostListFilters()[index]
    }

    func indexOfFilterThatDisplaysPostsWithStatus(postStatus: String) -> Int {
        var index = 0
        var found = false

        for (idx, filter) in availablePostListFilters().enumerate() {
            if filter.statuses.contains(postStatus) {
                found = true
                index = idx
                break
            }
        }

        if !found {
            // The draft filter is the catch all by convention.
            index = indexForFilterWithType(.Draft)
        }

        return index
    }

    func indexForFilterWithType(filterType: PostListFilter.Status) -> Int {
        if let index = availablePostListFilters().indexOf({ (filter: PostListFilter) -> Bool in
            return filter.filterType == filterType
        }) {
            return index
        } else {
            return NSNotFound
        }
    }

    func keyForCurrentListStatusFilter() -> String {
        fatalError("You should implement this method in the subclass")
    }

    func currentFilterIndex() -> Int {

        let userDefaults = NSUserDefaults.standardUserDefaults()

        if let filter = userDefaults.objectForKey(keyForCurrentListStatusFilter()) as? Int
            where filter < availablePostListFilters().count {

            return filter
        } else {
            return 0 // first item is the default
        }
     }

    func setCurrentFilterIndex(newIndex: Int) {
        let index = currentFilterIndex()

        guard newIndex != index else {
            return
        }

        WPAnalytics.track(.PostListStatusFilterChanged, withProperties: propertiesForAnalytics())
        NSUserDefaults.standardUserDefaults().setObject(newIndex, forKey: keyForCurrentListStatusFilter())
        NSUserDefaults.resetStandardUserDefaults()

        recentlyTrashedPostObjectIDs.removeAll()
        updateFilterTitle()
        resetTableViewContentOffset()
        updateAndPerformFetchRequestRefreshingResults()
    }

    func updateFilterTitle() {
        filterButton.setAttributedTitleForTitle(currentPostListFilter().title)
    }

    func displayFilters() {
        let titles = availablePostListFilters().map { (filter: PostListFilter) -> String in
            return filter.title
        }

        let dict = [SettingsSelectionDefaultValueKey: availablePostListFilters()[0],
                    SettingsSelectionTitleKey: NSLocalizedString("Filters", comment: "Title of the list of post status filters."),
                    SettingsSelectionTitlesKey: titles,
                    SettingsSelectionValuesKey: availablePostListFilters(),
                    SettingsSelectionCurrentValueKey: currentPostListFilter()]

        let controller = SettingsSelectionViewController(style: .Plain, andDictionary: dict as [NSObject : AnyObject])
        controller.onItemSelected = { [weak self] (selectedValue: AnyObject!) -> () in
            if let strongSelf = self,
                let index = strongSelf.availablePostListFilters().indexOf(selectedValue as! PostListFilter) {

                strongSelf.setCurrentFilterIndex(index)
                strongSelf.dismissViewControllerAnimated(true, completion: nil)
            }
        }

        controller.tableView.scrollEnabled = false

        displayFilterPopover(controller)
    }

    func displayFilterPopover(controller: UIViewController) {
        controller.preferredContentSize = self.dynamicType.preferredFiltersPopoverContentSize

        guard let titleView = navigationItem.titleView else {
            return
        }

        ForcePopoverPresenter.configurePresentationControllerForViewController(controller,
                                                                                                           presentingFromView: titleView)

        presentViewController(controller, animated: true, completion: nil)
    }

    func setFilterWithPostStatus(status: String) {
        let index = indexOfFilterThatDisplaysPostsWithStatus(status)
        setCurrentFilterIndex(index)
    }

    // MARK: - Search Controller Delegate Methods

    func presentSearchController(searchController: WPSearchController!) {
        WPAnalytics.track(.PostListSearchOpened, withProperties: propertiesForAnalytics())

        navigationController?.setNavigationBarHidden(true, animated: true) // Remove this line when switching to UISearchController.
        searchWrapperViewHeightConstraint.constant = heightForSearchWrapperView()

        UIView.animateWithDuration(SearchBarAnimationDuration, delay: 0.0, options: UIViewAnimationOptions.TransitionNone, animations: { [weak self] in
            self?.view.layoutIfNeeded()
            }, completion: { (finished: Bool) -> () in
                searchController.searchBar.becomeFirstResponder()
        })
    }

    func willDismissSearchController(searchController: WPSearchController!) {
        searchController.searchBar.resignFirstResponder()
        navigationController?.setNavigationBarHidden(false, animated: true) // Remove this line when switching to UISearchController
        searchWrapperViewHeightConstraint.constant = 0

        UIView.animateWithDuration(SearchBarAnimationDuration) { [weak self] in
            self?.view.layoutIfNeeded()
        }

        searchController.searchBar.text = nil
        searchHelper.searchCanceled()
    }

    func updateSearchResultsForSearchController(searchController: WPSearchController!) {
        resetTableViewContentOffset()
        searchHelper.searchUpdated(searchController.searchBar.text)
    }
}
