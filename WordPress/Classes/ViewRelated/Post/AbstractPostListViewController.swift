import Foundation
import Gridicons
import CocoaLumberjack
import WordPressShared
import wpxmlrpc

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class AbstractPostListViewController: UIViewController,
    WPContentSyncHelperDelegate,
    UISearchControllerDelegate,
    UISearchResultsUpdating,
    WPTableViewHandlerDelegate,
    // This protocol is not in an extension so that subclasses can override noConnectionMessage()
    NetworkAwareUI {

    fileprivate static let postsControllerRefreshInterval = TimeInterval(300)
    fileprivate static let HTTPErrorCodeForbidden = Int(403)
    fileprivate static let postsFetchRequestBatchSize = Int(10)
    fileprivate static let pagesNumberOfLoadedElement = Int(100)
    fileprivate static let postsLoadMoreThreshold = Int(4)
    fileprivate static let preferredFiltersPopoverContentSize = CGSize(width: 320.0, height: 220.0)

    fileprivate static let defaultHeightForFooterView = CGFloat(44.0)

    fileprivate let abstractPostWindowlessCellIdenfitier = "AbstractPostWindowlessCellIdenfitier"

    private var fetchBatchSize: Int {
        return postTypeToSync() == .page ? 0 : type(of: self).postsFetchRequestBatchSize
    }

    private var fetchLimit: Int {
        return postTypeToSync() == .page ? 0 : Int(numberOfPostsPerSync())
    }

    private var numberOfLoadedElement: NSNumber {
        return postTypeToSync() == .page ? NSNumber(value: type(of: self).pagesNumberOfLoadedElement) : NSNumber(value: numberOfPostsPerSync())
    }

    @objc var blog: Blog!

    /// This closure will be executed whenever the noResultsView must be visually refreshed.  It's up
    /// to the subclass to define this property.
    ///
    @objc var refreshNoResultsViewController: ((NoResultsViewController) -> ())!
    @objc var tableViewController: UITableViewController!
    @objc var reloadTableViewBeforeAppearing = false

    @objc var tableView: UITableView {
        get {
            return self.tableViewController.tableView
        }
    }

    @objc var refreshControl: UIRefreshControl? {
        get {
            return self.tableViewController.refreshControl
        }
    }

    @objc lazy var tableViewHandler: WPTableViewHandler = {
        let tableViewHandler = WPTableViewHandler(tableView: self.tableView)

        tableViewHandler.cacheRowHeights = false
        tableViewHandler.delegate = self
        tableViewHandler.updateRowAnimation = .none

        return tableViewHandler
    }()

    @objc lazy var estimatedHeightsCache: NSCache = { () -> NSCache<AnyObject, AnyObject> in
        let estimatedHeightsCache = NSCache<AnyObject, AnyObject>()
        return estimatedHeightsCache
    }()

    @objc lazy var syncHelper: WPContentSyncHelper = {
        let syncHelper = WPContentSyncHelper()

        syncHelper.delegate = self

        return syncHelper
    }()

    @objc lazy var searchHelper: WPContentSearchHelper = {
        let searchHelper = WPContentSearchHelper()
        return searchHelper
    }()

    @objc lazy var noResultsViewController: NoResultsViewController = {
        let noResultsViewController = NoResultsViewController.controller()
        noResultsViewController.delegate = self

        return noResultsViewController
    }()

    @objc lazy var filterSettings: PostListFilterSettings = {
        return PostListFilterSettings(blog: self.blog, postType: self.postTypeToSync())
    }()


    @objc var postListFooterView: PostListFooterView!

    @IBOutlet var filterTabBar: FilterTabBar!

    @objc lazy var addButton: UIBarButtonItem = {
        return UIBarButtonItem(image: Gridicon.iconOfType(.plus), style: .plain, target: self, action: #selector(handleAddButtonTapped))
    }()

    @objc var searchController: UISearchController!
    @objc var recentlyTrashedPostObjectIDs = [NSManagedObjectID]() // IDs of trashed posts. Cleared on refresh or when filter changes.

    fileprivate var searchesSyncing = 0

    var ghostOptions: GhostOptions?

    private var emptyResults: Bool {
        return tableViewHandler.resultsController.fetchedObjects?.count == 0
    }

    private var atLeastSyncedOnce = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)

        configureFilterBar()
        configureTableView()
        configureFooterView()
        configureWindowlessCell()
        configureNavbar()
        configureSearchController()
        configureSearchHelper()
        configureAuthorFilter()
        configureSearchBackingView()

        WPStyleGuide.configureColors(view: view, tableView: tableView)
        tableView.reloadData()

        observeNetworkStatus()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        startGhost()

        if reloadTableViewBeforeAppearing {
            reloadTableViewBeforeAppearing = false
            tableView.reloadData()
        }

        filterTabBar.layoutIfNeeded()
        updateSelectedFilter()

        refreshResults()
    }

    fileprivate var searchBarHeight: CGFloat {
        return searchController.searchBar.bounds.height + view.safeAreaInsets.top
    }

    fileprivate func localKeyboardFrameFromNotification(_ notification: Foundation.Notification) -> CGRect {
        let key = UIResponder.keyboardFrameEndUserInfoKey
        guard let keyboardFrame = (notification.userInfo?[key] as? NSValue)?.cgRectValue else {
                return .zero
        }

        // Convert the frame from window coordinates
        return view.convert(keyboardFrame, from: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        automaticallySyncIfAppropriate()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if searchController.isActive {
            searchController.isActive = false
        }

        dismissAllNetworkErrorNotices()

        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    // MARK: - Configuration

    func heightForFooterView() -> CGFloat {
        return type(of: self).defaultHeightForFooterView
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    func configureNavbar() {
        // IMPORTANT: this code makes sure that the back button in WPPostViewController doesn't show
        // this VC's title.
        //
        let backButton = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        navigationItem.rightBarButtonItem = addButton
    }

    func configureFilterBar() {
        WPStyleGuide.configureFilterTabBar(filterTabBar)

        filterTabBar.items = filterSettings.availablePostListFilters()

        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
    }

    func configureTableView() {
        assert(false, "You should implement this method in the subclass")
    }

    func configureFooterView() {

        let mainBundle = Bundle.main

        guard let footerView = mainBundle.loadNibNamed("PostListFooterView", owner: nil, options: nil)![0] as? PostListFooterView else {
            preconditionFailure("Could not load the footer view from the nib file.")
        }

        postListFooterView = footerView
        postListFooterView.showSpinner(false)

        var frame = postListFooterView.frame
        frame.size.height = heightForFooterView()

        postListFooterView.frame = frame
        tableView.tableFooterView = postListFooterView
    }

    @objc func configureWindowlessCell() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: abstractPostWindowlessCellIdenfitier)
    }

    private func refreshResults() {
        guard isViewLoaded == true else {
            return
        }

        let _ = DispatchDelayedAction(delay: .milliseconds(500)) { [weak self] in
            self?.refreshControl?.endRefreshing()
        }

        hideNoResultsView()
        if emptyResults {
            stopGhostIfConnectionIsNotAvailable()
            showNoResultsView()
        }

        updateBackgroundColor()
    }

    // Update controller's background color to avoid a white line below
    // the search bar - due to a margin between searchBar and the tableView
    private func updateBackgroundColor() {
        if searchController.isActive && emptyResults {
            view.backgroundColor = noResultsViewController.view.backgroundColor
        } else {
            view.backgroundColor = tableView.backgroundColor
        }
    }

    func configureAuthorFilter() {
        fatalError("You should implement this method in the subclass")
    }

    /// Subclasses should override this method (and call super) to insert the
    /// search controller's search bar into the view hierarchy
    @objc func configureSearchController() {
        // Required for insets to work out correctly when the search bar becomes active
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true

        searchController = UISearchController(searchResultsController: nil)
        searchController.dimsBackgroundDuringPresentation = false

        searchController.delegate = self
        searchController.searchResultsUpdater = self

        WPStyleGuide.configureSearchBar(searchController.searchBar)

        searchController.searchBar.autocorrectionType = .default
    }

    fileprivate func configureInitialScrollInsets() {
        tableView.layoutIfNeeded()
        tableView.contentInset = .zero
        tableView.scrollIndicatorInsets = .zero
        tableView.contentOffset = .zero
    }

    fileprivate func configureSearchBackingView() {
        // This mask view is required to cover the area between the top of the search
        // bar and the top of the screen on an iPhone X and on iOS 10.
        let topAnchor = view.safeAreaLayoutGuide.topAnchor

        let backingView = UIView()
        view.addSubview(backingView)

        backingView.backgroundColor = searchController.searchBar.barTintColor
        backingView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backingView.topAnchor.constraint(equalTo: view.topAnchor),
            backingView.bottomAnchor.constraint(equalTo: topAnchor)
            ])
    }

    @objc func configureSearchHelper() {
        searchHelper.resetConfiguration()
        searchHelper.configureImmediateSearch({ [weak self] in
            self?.updateForLocalPostsMatchingSearchText()
        })
        searchHelper.configureDeferredSearch({ [weak self] in
            self?.syncPostsMatchingSearchText()
        })
    }

    @objc func propertiesForAnalytics() -> [String: AnyObject] {
        var properties = [String: AnyObject]()

        properties["type"] = postTypeToSync().rawValue as AnyObject?
        properties["filter"] = filterSettings.currentPostListFilter().title as AnyObject?

        if let dotComID = blog.dotComID {
            properties[WPAppAnalyticsKeyBlogID] = dotComID
        }

        return properties
    }

    // MARK: - GUI: No results view logic

    func hideNoResultsView() {
        postListFooterView.isHidden = false
        noResultsViewController.removeFromView()
    }

    func showNoResultsView() {

        guard refreshNoResultsViewController != nil, atLeastSyncedOnce else {
            return
        }

        postListFooterView.isHidden = true
        refreshNoResultsViewController(noResultsViewController)

        // Only add no results view if it isn't already in the table view
        if noResultsViewController.view.isDescendant(of: tableView) == false {
            tableViewController.addChild(noResultsViewController)
            tableView.addSubview(withFadeAnimation: noResultsViewController.view)
            noResultsViewController.view.frame = tableView.frame

            // Adjust the NRV to accommodate for the search bar.
            if let tableHeaderView = tableView.tableHeaderView {
                noResultsViewController.view.frame.origin.y = tableHeaderView.frame.origin.y
            }

            noResultsViewController.didMove(toParent: tableViewController)
        }

        tableView.sendSubviewToBack(noResultsViewController.view)
    }

    // MARK: - TableView Helpers

    @objc func dequeCellForWindowlessLoadingIfNeeded(_ tableView: UITableView) -> UITableViewCell? {
        // As also seen in ReaderStreamViewController:
        // We want to avoid dequeuing card cells when we're not present in a window, on the iPad.
        // Doing so can create a situation where cells are not updated with the correct NSTraitCollection.
        // The result is the cells do not show the correct layouts relative to superview margins.
        // HACK: kurzee, 2016-07-12
        // Use a generic cell in this situation and reload the table view once its back in a window.
        if tableView.window == nil {
            reloadTableViewBeforeAppearing = true
            return tableView.dequeueReusableCell(withIdentifier: abstractPostWindowlessCellIdenfitier)
        }
        return nil
    }

    // MARK: - TableViewHandler Delegate Methods

    @objc func entityName() -> String {
        fatalError("You should implement this method in the subclass")
    }

    func managedObjectContext() -> NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }

    func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName())
        fetchRequest.predicate = predicateForFetchRequest()
        fetchRequest.sortDescriptors = sortDescriptorsForFetchRequest()
        fetchRequest.fetchBatchSize = fetchBatchSize
        fetchRequest.fetchLimit = fetchLimit
        return fetchRequest
    }

    @objc func sortDescriptorsForFetchRequest() -> [NSSortDescriptor] {
        return filterSettings.currentPostListFilter().sortDescriptors
    }

    @objc func updateAndPerformFetchRequest() {
        assert(Thread.isMainThread, "AbstractPostListViewController Error: NSFetchedResultsController accessed in BG")

        var predicate = predicateForFetchRequest()
        let sortDescriptors = sortDescriptorsForFetchRequest()
        let fetchRequest = tableViewHandler.resultsController.fetchRequest

        // Set the predicate based on filtering by the oldestPostDate and not searching.
        let filter = filterSettings.currentPostListFilter()

        if let oldestPostDate = filter.oldestPostDate, !isSearching() {

            // Filter posts by any posts newer than the filter's oldestPostDate.
            // Also include any posts that don't have a date set, such as local posts created without a connection.
            let datePredicate = NSPredicate(format: "(date_created_gmt = NULL) OR (date_created_gmt >= %@)", oldestPostDate as CVarArg)

            predicate = NSCompoundPredicate.init(andPredicateWithSubpredicates: [predicate, datePredicate])
        }

        // Set up the fetchLimit based on filtering or searching
        if filter.oldestPostDate != nil || isSearching() == true {
            // If filtering by the oldestPostDate or searching, the fetchLimit should be disabled.
            fetchRequest.fetchLimit = 0
        } else {
            // If not filtering by the oldestPostDate or searching, set the fetchLimit to the default number of posts.
            fetchRequest.fetchLimit = fetchLimit
        }

        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors

        do {
            try tableViewHandler.resultsController.performFetch()
        } catch {
            DDLogError("Error fetching posts after updating the fetch request predicate: \(error)")
        }
    }

    @objc func updateAndPerformFetchRequestRefreshingResults() {
        updateAndPerformFetchRequest()
        tableView.reloadData()
        refreshResults()
    }

    @objc func resetTableViewContentOffset(_ animated: Bool = false) {
        // Reset the tableView contentOffset to the top before we make any dataSource changes.
        var tableOffset = tableView.contentOffset
        tableOffset.y = -tableView.contentInset.top
        tableView.setContentOffset(tableOffset, animated: animated)
    }

    @objc func predicateForFetchRequest() -> NSPredicate {
        fatalError("You should implement this method in the subclass")
    }

    // MARK: - Table View Handling

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        // When using UITableViewAutomaticDimension for auto-sizing cells, UITableView
        // likes to reload rows in a strange way.
        // It uses the estimated height as a starting value for reloading animations.
        // So this estimated value needs to be as accurate as possible to avoid any "jumping" in
        // the cell heights during reload animations.
        // Note: There may (and should) be a way to get around this, but there is currently no obvious solution.
        // Brent C. August 2/2016
        if let height = estimatedHeightsCache.object(forKey: indexPath as AnyObject) as? CGFloat {
            // Return the previously known height as it was cached via willDisplayCell.
            return height
        }
        // Otherwise return whatever we have set to the tableView explicitly, and ideally a pretty close value.
        return tableView.estimatedRowHeight
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        assert(false, "You should implement this method in the subclass")
    }

    func tableViewDidChangeContent(_ tableView: UITableView) {
        refreshResults()
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        // Cache the cell's layout height as the currently known height, for estimation.
        // See estimatedHeightForRowAtIndexPath
        estimatedHeightsCache.setObject(cell.frame.height as AnyObject, forKey: indexPath as AnyObject)

        guard isViewOnScreen() && !isSearching() else {
            return
        }

        // Are we approaching the end of the table?
        if indexPath.section + 1 == tableView.numberOfSections
            && indexPath.row + type(of: self).postsLoadMoreThreshold >= tableView.numberOfRows(inSection: indexPath.section)
            && postTypeToSync() == .post {
            // Only 3 rows till the end of table
            if filterSettings.currentPostListFilter().hasMore {
                syncHelper.syncMoreContent()
            }
        }
    }

    func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        assert(false, "You should implement this method in the subclass")
    }

    // MARK: - Actions

    @IBAction func refresh(_ sender: AnyObject) {
        syncItemsWithUserInteraction(true)

        WPAnalytics.track(.postListPullToRefresh, withProperties: propertiesForAnalytics())
    }

    @objc func handleAddButtonTapped() {
        createPost()
    }

    // MARK: - Synching

    @objc func automaticallySyncIfAppropriate() {
        // Only automatically refresh if the view is loaded and visible on the screen
        if !isViewLoaded || view.window == nil {
            DDLogVerbose("View is not visible and will not check for auto refresh.")
            return
        }

        // Do not start auto-sync if connection is down
        let appDelegate = WordPressAppDelegate.shared

        if appDelegate?.connectionAvailable == false {
            refreshResults()
            dismissAllNetworkErrorNotices()
            handleConnectionError()
            return
        }

        if let lastSynced = lastSyncDate(), abs(lastSynced.timeIntervalSinceNow) <= type(of: self).postsControllerRefreshInterval {

            refreshResults()
        } else {
            // Update in the background
            syncItemsWithUserInteraction(false)
        }
    }

    @objc func syncItemsWithUserInteraction(_ userInteraction: Bool) {
        syncHelper.syncContentWithUserInteraction(userInteraction)
        refreshResults()
    }

    @objc func updateFilter(_ filter: PostListFilter, withSyncedPosts posts: [AbstractPost], syncOptions options: PostServiceSyncOptions) {
        guard posts.count > 0 else {
            assertionFailure("This method should not be called with no posts.")
            return
        }
        // Reset the filter to only show the latest sync point, based on the oldest post date in the posts just synced.
        // Note: Getting oldest date manually as the API may return results out of order if there are
        // differing time offsets in the created dates.
        let oldestPost = posts.min {$0.date_created_gmt < $1.date_created_gmt}
        filter.oldestPostDate = oldestPost?.date_created_gmt
        filter.hasMore = posts.count >= options.number.intValue

        updateAndPerformFetchRequestRefreshingResults()
    }

    @objc func numberOfPostsPerSync() -> UInt {
        return PostServiceDefaultNumberToSync
    }

    // MARK: - WPContentSyncHelperDelegate

    @objc internal func postTypeToSync() -> PostServiceType {
        // Subclasses should override.
        return .any
    }

    @objc func lastSyncDate() -> Date? {
        return blog.lastPostsSync
    }

    func syncHelper(_ syncHelper: WPContentSyncHelper, syncContentWithUserInteraction userInteraction: Bool, success: ((_ hasMore: Bool) -> ())?, failure: ((_ error: NSError) -> ())?) {
        if recentlyTrashedPostObjectIDs.count > 0 {
            refreshAndReload()
        }

        let postType = postTypeToSync()
        let filter = filterSettings.currentPostListFilter()
        let author = filterSettings.shouldShowOnlyMyPosts() ? blogUserID() : nil

        let postService = PostService(managedObjectContext: managedObjectContext())

        let options = PostServiceSyncOptions()
        options.statuses = filter.statuses.strings
        options.authorID = author
        options.number = numberOfLoadedElement
        options.purgesLocalSync = true

        postService.syncPosts(
            ofType: postType,
            with: options,
            for: blog,
            success: {[weak self] posts in
                guard let strongSelf = self,
                    let posts = posts else {
                    return
                }

                if posts.count > 0 {
                    strongSelf.updateFilter(filter, withSyncedPosts: posts, syncOptions: options)
                    SearchManager.shared.indexItems(posts)
                }

                success?(filter.hasMore)

                if strongSelf.isSearching() {
                    // If we're currently searching, go ahead and request a sync with the searchText since
                    // an action was triggered to syncContent.
                    strongSelf.syncPostsMatchingSearchText()
                }
            }, failure: {[weak self] (error: Error?) -> () in

                guard let strongSelf = self,
                    let error = error else {
                    return
                }

                failure?(error as NSError)

                if userInteraction == true {
                    strongSelf.handleSyncFailure(error as NSError)
                }
        })
    }

    let loadMoreCounter = LoadMoreCounter()
    func syncHelper(_ syncHelper: WPContentSyncHelper, syncMoreWithSuccess success: ((_ hasMore: Bool) -> Void)?, failure: ((_ error: NSError) -> Void)?) {

        // See https://github.com/wordpress-mobile/WordPress-iOS/issues/6819
        loadMoreCounter.increment(properties: propertiesForAnalytics())

        postListFooterView.showSpinner(true)

        let postType = postTypeToSync()
        let filter = filterSettings.currentPostListFilter()
        let author = filterSettings.shouldShowOnlyMyPosts() ? blogUserID() : nil

        let postService = PostService(managedObjectContext: managedObjectContext())

        let options = PostServiceSyncOptions()
        options.statuses = filter.statuses.strings
        options.authorID = author
        options.number = numberOfLoadedElement
        options.offset = tableViewHandler.resultsController.fetchedObjects?.count as NSNumber?

        postService.syncPosts(
            ofType: postType,
            with: options,
            for: blog,
            success: {[weak self] posts in
                guard let strongSelf = self,
                    let posts = posts else {
                        return
                }

                if posts.count > 0 {
                    strongSelf.updateFilter(filter, withSyncedPosts: posts, syncOptions: options)
                    SearchManager.shared.indexItems(posts)
                }

                success?(filter.hasMore)
            }, failure: { (error) -> () in

                guard let error = error else {
                    return
                }

                failure?(error as NSError)
            })
    }

    func syncContentStart(_ syncHelper: WPContentSyncHelper) {
        startGhost()
        atLeastSyncedOnce = true
    }

    func syncContentEnded(_ syncHelper: WPContentSyncHelper) {
        refreshControl?.endRefreshing()
        postListFooterView.showSpinner(false)
        noResultsViewController.removeFromView()

        stopGhost()

        if emptyResults {
            // This is a special case.  Core data can be a bit slow about notifying
            // NSFetchedResultsController delegates about changes to the fetched results.
            // To compensate, call configureNoResultsView after a short delay.
            // It will be redisplayed if necessary.

            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(100 * NSEC_PER_MSEC)) / Double(NSEC_PER_SEC), execute: { [weak self] in
                self?.refreshResults()
            })
        }
    }

    @objc func handleSyncFailure(_ error: NSError) {
        if error.domain == WPXMLRPCFaultErrorDomain
            && error.code == type(of: self).HTTPErrorCodeForbidden {
            promptForPassword()
            return
        }

        stopGhost()

        dismissAllNetworkErrorNotices()

        // If there is no internet connection, we'll show the specific error message defined in
        // `noConnectionMessage()` (overridden by subclasses). For everything else, we let
        // `WPError.showNetworkingNotice` determine the user-friendly error message.
        if !connectionAvailable() {
            handleConnectionError()
        } else {
            let title = NSLocalizedString("Unable to Sync", comment: "Title of error prompt shown when a sync the user initiated fails.")
            WPError.showNetworkingNotice(title: title, error: error)
        }
    }

    @objc func promptForPassword() {
        let message = NSLocalizedString("The username or password stored in the app may be out of date. Please re-enter your password in the settings and try again.", comment: "Error message informing a user about an invalid password.")

        // bad login/pass combination
        let editSiteViewController = SiteSettingsViewController(blog: blog)

        let navController = UINavigationController(rootViewController: editSiteViewController!)
        navController.navigationBar.isTranslucent = false

        navController.modalTransitionStyle = .crossDissolve
        navController.modalPresentationStyle = .formSheet

        WPError.showAlert(withTitle: NSLocalizedString("Unable to Connect", comment: "An error message."), message: message, withSupportButton: true) { _ in
            self.present(navController, animated: true)
        }
    }

    // MARK: - Ghost cells

    func startGhost() {
        guard let ghostOptions = ghostOptions, emptyResults else {
            return
        }

        let style = GhostStyle(beatDuration: GhostStyle.Defaults.beatDuration,
                               beatStartColor: .placeholderElement,
                               beatEndColor: .placeholderElementFaded)
        tableView.displayGhostContent(options: ghostOptions, style: style)
        tableView.isScrollEnabled = false
        noResultsViewController.view.isHidden = true
    }

    func stopGhost() {
        tableView.removeGhostContent()
        tableView.isScrollEnabled = true
        noResultsViewController.view.isHidden = false
    }

    func stopGhostIfConnectionIsNotAvailable() {
        guard WordPressAppDelegate.shared?.connectionAvailable == false else {
            return
        }

        atLeastSyncedOnce = true
        stopGhost()
    }

    // MARK: - Searching

    @objc func isSearching() -> Bool {
        return searchController.isActive && currentSearchTerm()?.count > 0
    }

    @objc func currentSearchTerm() -> String? {
        return searchController.searchBar.text
    }

    @objc func updateForLocalPostsMatchingSearchText() {
        updateAndPerformFetchRequest()
        tableView.reloadData()

        let filter = filterSettings.currentPostListFilter()
        if filter.hasMore && emptyResults {
            // If the filter detects there are more posts, but there are none that match the current search
            // hide the no results view while the upcoming syncPostsMatchingSearchText() may in fact load results.
            hideNoResultsView()
            postListFooterView.isHidden = true
        } else {
            refreshResults()
        }
    }

    @objc func isSyncingPostsWithSearch() -> Bool {
        return searchesSyncing > 0
    }

    @objc func postsSyncWithSearchDidBegin() {
        searchesSyncing += 1
        postListFooterView.showSpinner(true)
        postListFooterView.isHidden = false
    }

    @objc func postsSyncWithSearchEnded() {
        searchesSyncing -= 1
        assert(searchesSyncing >= 0, "Expected Int searchesSyncing to be 0 or greater while searching.")
        if !isSyncingPostsWithSearch() {
            postListFooterView.showSpinner(false)
            refreshResults()
        }
    }

    @objc func syncPostsMatchingSearchText() {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty() else {
            return
        }
        let filter = filterSettings.currentPostListFilter()
        guard filter.hasMore else {
            return
        }

        postsSyncWithSearchDidBegin()

        let author = filterSettings.shouldShowOnlyMyPosts() ? blogUserID() : nil
        let postService = PostService(managedObjectContext: managedObjectContext())
        let options = PostServiceSyncOptions()
        options.statuses = filter.statuses.strings
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

    // MARK: - Actions

    @objc func publishPost(_ apost: AbstractPost) {
        let title = NSLocalizedString("Are you sure you want to publish?", comment: "Title of the message shown when the user taps Publish in the post list.")

        let cancelTitle = NSLocalizedString("Cancel", comment: "Button shown when the author is asked for publishing confirmation.")
        let publishTitle = NSLocalizedString("Publish", comment: "Button shown when the author is asked for publishing confirmation.")

        let style: UIAlertController.Style = UIDevice.isPad() ? .alert : .actionSheet
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: style)

        alertController.addCancelActionWithTitle(cancelTitle)
        alertController.addDefaultActionWithTitle(publishTitle) { [unowned self] _ in
            WPAnalytics.track(.postListPublishAction, withProperties: self.propertiesForAnalytics())

            PostCoordinator.shared.publish(apost)
        }

        present(alertController, animated: true)
    }

    @objc func moveToDraft(_ apost: AbstractPost) {
        WPAnalytics.track(.postListDraftAction, withProperties: propertiesForAnalytics())

        PostCoordinator.shared.moveToDraft(apost)
    }

    @objc func viewPost(_ apost: AbstractPost) {
        WPAnalytics.track(.postListViewAction, withProperties: propertiesForAnalytics())

        let post = apost.hasRevision() ? apost.revision! : apost

        let controller = PostPreviewViewController(post: post)
        // NOTE: We'll set the title to match the title of the View action button.
        // If the button title changes we should also update the title here.
        controller.navigationItem.title = NSLocalizedString("View", comment: "Verb. The screen title shown when viewing a post inside the app.")
        controller.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc func deletePost(_ apost: AbstractPost) {
        WPAnalytics.track(.postListTrashAction, withProperties: propertiesForAnalytics())

        let postObjectID = apost.objectID

        recentlyTrashedPostObjectIDs.append(postObjectID)

        // Remove the trashed post from spotlight
        SearchManager.shared.deleteSearchableItem(apost)

        // Update the fetch request *before* making the service call.
        updateAndPerformFetchRequest()

        let indexPath = tableViewHandler.resultsController.indexPath(forObject: apost)

        if let indexPath = indexPath {
            tableView.reloadRows(at: [indexPath], with: .fade)
        }

        let postService = PostService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        let trashed = (apost.status == .trash)

        postService.trashPost(apost, success: {
            // If we permanently deleted the post
            if trashed {
                PostCoordinator.shared.cancelAnyPendingSaveOf(post: apost)
                MediaCoordinator.shared.cancelUploadOfAllMedia(for: apost)
            }
        }, failure: { [weak self] (error) in

            guard let strongSelf = self else {
                return
            }

            if let error = error as NSError?, error.code == type(of: strongSelf).HTTPErrorCodeForbidden {
                strongSelf.promptForPassword()
            } else {
                WPError.showXMLRPCErrorAlert(error)
            }

            if let index = strongSelf.recentlyTrashedPostObjectIDs.index(of: postObjectID) {
                strongSelf.recentlyTrashedPostObjectIDs.remove(at: index)
                // We don't really know what happened here, why did the request fail?
                // Maybe we could not delete the post or maybe the post was already deleted
                // It is safer to re fetch the results than to reload that specific row
                DispatchQueue.main.async {
                    strongSelf.updateAndPerformFetchRequestRefreshingResults()
                }
            }
        })
    }

    @objc func restorePost(_ apost: AbstractPost, completion: (() -> Void)? = nil) {
        WPAnalytics.track(.postListRestoreAction, withProperties: propertiesForAnalytics())

        // if the post was recently deleted, update the status helper and reload the cell to display a spinner
        let postObjectID = apost.objectID

        if let index = recentlyTrashedPostObjectIDs.index(of: postObjectID) {
            recentlyTrashedPostObjectIDs.remove(at: index)
        }

        let postService = PostService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        postService.restore(apost, success: { [weak self] in

            guard let strongSelf = self else {
                return
            }

            var apost: AbstractPost

            // Make sure the post still exists.
            do {
                apost = try strongSelf.managedObjectContext().existingObject(with: postObjectID) as! AbstractPost
            } catch {
                DDLogError("\(error)")
                return
            }

            DispatchQueue.main.async {
                completion?()
            }

            if let postStatus = apost.status {
                // If the post was restored, see if it appears in the current filter.
                // If not, prompt the user to let it know under which filter it appears.
                let filter = strongSelf.filterSettings.filterThatDisplaysPostsWithStatus(postStatus)

                if filter.filterType == strongSelf.filterSettings.currentPostListFilter().filterType {
                    return
                }

                strongSelf.promptThatPostRestoredToFilter(filter)

                // Reindex the restored post in spotlight
                SearchManager.shared.indexItem(apost)
            }
        }) { [weak self] (error) in

            guard let strongSelf = self else {
                return
            }

            if let error = error as NSError?, error.code == type(of: strongSelf).HTTPErrorCodeForbidden {
                strongSelf.promptForPassword()
            } else {
                WPError.showXMLRPCErrorAlert(error)
            }

            strongSelf.recentlyTrashedPostObjectIDs.append(postObjectID)
        }
    }

    @objc func promptThatPostRestoredToFilter(_ filter: PostListFilter) {
        assert(false, "You should implement this method in the subclass")
    }

    private func dismissAllNetworkErrorNotices() {
        dismissNoNetworkAlert()
        WPError.dismissNetworkingNotice()
    }

    // MARK: - Post Actions

    @objc func createPost() {
        assert(false, "You should implement this method in the subclass")
    }

    // MARK: - Data Sources

    /// Retrieves the userID for the user of the current blog.
    ///
    /// - Returns: the userID for the user of the current WPCom blog.  If the blog is not hosted at
    ///     WordPress.com, `nil` is returned instead.
    ///
    @objc func blogUserID() -> NSNumber? {
        return blog.userID
    }

    // MARK: - Filtering

    @objc func refreshAndReload() {
        recentlyTrashedPostObjectIDs.removeAll()
        updateSelectedFilter()
        resetTableViewContentOffset()
        updateAndPerformFetchRequestRefreshingResults()
    }

    func updateFilterWithPostStatus(_ status: BasePost.Status) {
        filterSettings.setFilterWithPostStatus(status)
        refreshAndReload()
        WPAnalytics.track(.postListStatusFilterChanged, withProperties: propertiesForAnalytics())
    }

    func updateFilter(index: Int) {
        filterSettings.setCurrentFilterIndex(index)
        refreshAndReload()
    }

    func updateSelectedFilter() {
        if filterTabBar.selectedIndex != filterSettings.currentFilterIndex() {
            filterTabBar.setSelectedIndex(filterSettings.currentFilterIndex(), animated: false)
        }
    }

    @objc func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        filterSettings.setCurrentFilterIndex(filterBar.selectedIndex)

        refreshAndReload()

        startGhost()

        syncItemsWithUserInteraction(false)

        configureInitialScrollInsets()

        WPAnalytics.track(.postListStatusFilterChanged, withProperties: propertiesForAnalytics())
    }

    // MARK: - Search Controller Delegate Methods

    func willPresentSearchController(_ searchController: UISearchController) {
        WPAnalytics.track(.postListSearchOpened, withProperties: propertiesForAnalytics())
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        searchController.searchBar.text = nil
        searchHelper.searchCanceled()

        configureInitialScrollInsets()
    }

    func updateSearchResults(for searchController: UISearchController) {
        resetTableViewContentOffset()
        searchHelper.searchUpdated(searchController.searchBar.text)
    }

    // MARK: - NetworkAwareUI

    func contentIsEmpty() -> Bool {
        return tableViewHandler.resultsController.isEmpty()
    }

    func noConnectionMessage() -> String {
        return ReachabilityUtils.noConnectionMessage()
    }

    // MARK: - Others

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        // We override this method to dismiss any Notice that is currently being shown. If we
        // don't do this, the present Notice will be shown on top of the ViewController we are
        // presenting.
        dismissAllNetworkErrorNotices()
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
}

extension AbstractPostListViewController: NetworkStatusDelegate {
    func networkStatusDidChange(active: Bool) {
        automaticallySyncIfAppropriate()
    }
}

// MARK: - NoResultsViewControllerDelegate

extension AbstractPostListViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        WPAnalytics.track(.postListNoResultsButtonPressed, withProperties: propertiesForAnalytics())
        createPost()
    }
}
