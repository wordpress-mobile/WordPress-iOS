import Foundation
import Gridicons
import CocoaLumberjack
import WordPressShared
import wpxmlrpc
import WordPressFlux

class AbstractPostListViewController: UIViewController,
                                      WPContentSyncHelperDelegate,
                                      UISearchControllerDelegate,
                                      WPTableViewHandlerDelegate,
                                      NetworkAwareUI // This protocol is not in an extension so that subclasses can override noConnectionMessage()
{

    private static let postsControllerRefreshInterval = TimeInterval(300)
    private static let httpErrorCodeForbidden = 403
    private static let postsFetchRequestBatchSize = 10
    private static let pagesNumberOfLoadedElement = 100
    private static let postsLoadMoreThreshold = 4

    private var fetchBatchSize: Int {
        return postTypeToSync() == .page ? 0 : type(of: self).postsFetchRequestBatchSize
    }

    private var fetchLimit: Int {
        return postTypeToSync() == .page ? 0 : Int(numberOfPostsPerSync())
    }

    private var numberOfLoadedElement: NSNumber {
        return postTypeToSync() == .page ? NSNumber(value: type(of: self).pagesNumberOfLoadedElement) : NSNumber(value: numberOfPostsPerSync())
    }

    var blog: Blog!

    /// This closure will be executed whenever the noResultsView must be visually refreshed.  It's up
    /// to the subclass to define this property.
    ///
    var refreshNoResultsViewController: ((NoResultsViewController) -> ())!
    let tableViewController = UITableViewController(style: .grouped)
    private var reloadTableViewBeforeAppearing = false

    @objc var tableView: UITableView {
        get {
            return self.tableViewController.tableView
        }
    }

    private let buttonAuthorFilter = AuthorFilterButton()

    let refreshControl = UIRefreshControl()

    lazy var tableViewHandler: WPTableViewHandler = {
        let tableViewHandler = WPTableViewHandler(tableView: self.tableView)
        tableViewHandler.cacheRowHeights = false
        tableViewHandler.delegate = self
        tableViewHandler.updateRowAnimation = .none
        return tableViewHandler
    }()

    lazy var syncHelper: WPContentSyncHelper = {
        let syncHelper = WPContentSyncHelper()
        syncHelper.delegate = self
        return syncHelper
    }()

    lazy var noResultsViewController: NoResultsViewController = {
        let noResultsViewController = NoResultsViewController.controller()
        noResultsViewController.delegate = self
        return noResultsViewController
    }()

    lazy var filterSettings: PostListFilterSettings = {
        return PostListFilterSettings(blog: self.blog, postType: self.postTypeToSync())
    }()

    let filterTabBar = FilterTabBar()

    private lazy var searchResultsViewController = PostSearchViewController(viewModel: PostSearchViewModel(blog: blog, filters: filterSettings))

    private lazy var searchController = UISearchController(searchResultsController: searchResultsViewController)

    private var emptyResults: Bool {
        return tableViewHandler.resultsController?.fetchedObjects?.count == 0
    }

    private var atLeastSyncedOnce = false

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableViewController()
        configureFilterBar()
        configureTableView()
        configureNavbar()
        configureSearchController()
        configureAuthorFilter()
        configureNavigationBarAppearance()

        tableView.reloadData()

        observeNetworkStatus()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if reloadTableViewBeforeAppearing {
            reloadTableViewBeforeAppearing = false
            tableView.reloadData()
        }

        updateSelectedFilter()

        refreshResults()

        // Show it initially but allow the user to dismiss it by scrolling
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        automaticallySyncIfAppropriate()

        navigationItem.hidesSearchBarWhenScrolling = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        dismissAllNetworkErrorNotices()

        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    // MARK: - Configuration

    private func configureTableViewController() {
        addChild(tableViewController)
        view.addSubview(tableViewController.view)
        tableViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(tableViewController.view)
        tableViewController.didMove(toParent: self)

        tableView.backgroundColor = .systemBackground
        tableView.sectionHeaderTopPadding = 0
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }

    func configureNavbar() {
        // IMPORTANT: this code makes sure that the back button in WPPostViewController doesn't show
        // this VC's title.
        //
        let backButton = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
    }

    func configureFilterBar() {
        WPStyleGuide.configureFilterTabBar(filterTabBar)
        filterTabBar.isLayoutMarginsRelativeArrangement = false
        filterTabBar.backgroundColor = .clear
        filterTabBar.items = filterSettings.availablePostListFilters()
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)

        filterTabBar.translatesAutoresizingMaskIntoConstraints = true
        filterTabBar.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 40)
        tableView.tableHeaderView = filterTabBar
    }

    func configureTableView() {
        assert(false, "You should implement this method in the subclass")
    }

    private func refreshResults() {
        guard isViewLoaded == true else {
            return
        }

        let _ = DispatchDelayedAction(delay: .milliseconds(500)) { [weak self] in
            self?.refreshControl.endRefreshing()
        }

        hideNoResultsView()
        if emptyResults {
            showNoResultsView()
        }
    }

    private func configureSearchController() {
        searchController.delegate = self
        searchController.searchResultsUpdater = searchResultsViewController
        searchController.showsSearchResultsController = true
        searchResultsViewController.searchController = searchController
        searchResultsViewController.listViewController = self

        definesPresentationContext = true

        navigationItem.searchController = searchController
    }

    private func configureNavigationBarAppearance() {
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithDefaultBackground()

        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithTransparentBackground()

        navigationItem.standardAppearance = standardAppearance
        navigationItem.compactAppearance = standardAppearance
        navigationItem.scrollEdgeAppearance = scrollEdgeAppearance
        navigationItem.compactScrollEdgeAppearance = scrollEdgeAppearance
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

    // MARK: - Author Filter

    private func configureAuthorFilter() {
        guard filterSettings.canFilterByAuthor() else {
            return
        }
        buttonAuthorFilter.sizeToFit()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: buttonAuthorFilter)

        buttonAuthorFilter.addTarget(self, action: #selector(showAuthorSelectionPopover(_:)), for: .touchUpInside)
        updateAuthorFilter()
    }

    private func updateAuthorFilter() {
        if filterSettings.currentPostAuthorFilter() == .everyone {
            buttonAuthorFilter.filterType = .everyone
        } else {
            buttonAuthorFilter.filterType = .user(gravatarEmail: blog.account?.email)
        }
    }

    @objc private func showAuthorSelectionPopover(_ sender: UIView) {
        let filterController = AuthorFilterViewController(initialSelection: filterSettings.currentPostAuthorFilter(), gravatarEmail: blog.account?.email, postType: postTypeToSync()) { [weak self] filter in
            if filter != self?.filterSettings.currentPostAuthorFilter() {
                UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: sender)
            }

            self?.filterSettings.setCurrentPostAuthorFilter(filter)
            self?.updateAuthorFilter()
            self?.refreshAndReload()
            self?.syncItemsWithUserInteraction(false)
            self?.dismiss(animated: true)
        }

        ForcePopoverPresenter.configurePresentationControllerForViewController(filterController, presentingFromView: sender)
        filterController.popoverPresentationController?.permittedArrowDirections = .up

        present(filterController, animated: true)
    }

    // MARK: - GUI: No results view logic

    func hideNoResultsView() {
        setFooterHidden(false)
        noResultsViewController.removeFromView()
    }

    func showNoResultsView() {

        guard refreshNoResultsViewController != nil, atLeastSyncedOnce else {
            return
        }

        setFooterHidden(true)
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

    // MARK: - TableViewHandler Delegate Methods

    @objc func entityName() -> String {
        fatalError("You should implement this method in the subclass")
    }

    func managedObjectContext() -> NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }

    func fetchRequest() -> NSFetchRequest<NSFetchRequestResult>? {
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
        guard let fetchRequest = tableViewHandler.resultsController?.fetchRequest else {
            DDLogError("Error getting the fetch request")
            return
        }

        let filter = filterSettings.currentPostListFilter()

        if let oldestPostDate = filter.oldestPostDate {

            // Filter posts by any posts newer than the filter's oldestPostDate.
            // Also include any posts that don't have a date set, such as local posts created without a connection.
            let datePredicate = NSPredicate(format: "(date_created_gmt = NULL) OR (date_created_gmt >= %@)", oldestPostDate as CVarArg)

            predicate = NSCompoundPredicate.init(andPredicateWithSubpredicates: [predicate, datePredicate])
        }

        // Set up the fetchLimit based on filtering
        if filter.oldestPostDate != nil {
            // If filtering by the oldestPostDate, the fetchLimit should be disabled.
            fetchRequest.fetchLimit = 0
        } else {
            // If not filtering by the oldestPostDate, set the fetchLimit to the default number of posts.
            fetchRequest.fetchLimit = fetchLimit
        }

        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors

        do {
            try tableViewHandler.resultsController?.performFetch()
        } catch {
            DDLogError("Error fetching posts after updating the fetch request predicate: \(error)")
        }
    }

    @objc func updateAndPerformFetchRequestRefreshingResults() {
        updateAndPerformFetchRequest()
        tableView.reloadData()
        refreshResults()
    }

    @objc func predicateForFetchRequest() -> NSPredicate {
        fatalError("You should implement this method in the subclass")
    }

    // MARK: - Table View Handling

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        110
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        assert(false, "You should implement this method in the subclass")
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        nil
    }

    func tableViewDidChangeContent(_ tableView: UITableView) {
        refreshResults()
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard isViewOnScreen() else {
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
        let oldestPost = posts.min { ($0.date_created_gmt ?? .distantPast) < ($1.date_created_gmt ?? .distantPast) }
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
            success: { [weak self] posts in
                guard let self, let posts else {
                    return
                }

                if posts.count > 0 {
                    self.updateFilter(filter, withSyncedPosts: posts, syncOptions: options)
                    SearchManager.shared.indexItems(posts)
                }

                success?(filter.hasMore)
            }, failure: { [weak self] error in

                guard let self, let error else {
                    return
                }

                failure?(error as NSError)

                if userInteraction == true {
                    self.handleSyncFailure(error as NSError)
                }
        })
    }

    let loadMoreCounter = LoadMoreCounter()

    func syncHelper(_ syncHelper: WPContentSyncHelper, syncMoreWithSuccess success: ((_ hasMore: Bool) -> Void)?, failure: ((_ error: NSError) -> Void)?) {

        // See https://github.com/wordpress-mobile/WordPress-iOS/issues/6819
        loadMoreCounter.increment(properties: propertiesForAnalytics())

        setFooterHidden(false)

        let postType = postTypeToSync()
        let filter = filterSettings.currentPostListFilter()
        let author = filterSettings.shouldShowOnlyMyPosts() ? blogUserID() : nil

        let postService = PostService(managedObjectContext: managedObjectContext())

        let options = PostServiceSyncOptions()
        options.statuses = filter.statuses.strings
        options.authorID = author
        options.number = numberOfLoadedElement
        options.offset = tableViewHandler.resultsController?.fetchedObjects?.count as NSNumber?

        postService.syncPosts(
            ofType: postType,
            with: options,
            for: blog,
            success: { [weak self] posts in
                guard let self, let posts else {
                    return
                }

                if posts.count > 0 {
                    self.updateFilter(filter, withSyncedPosts: posts, syncOptions: options)
                    SearchManager.shared.indexItems(posts)
                }

                success?(filter.hasMore)
            }, failure: { error in
                guard let error else {
                    return
                }
                failure?(error as NSError)
            })
    }

    func syncContentStart(_ syncHelper: WPContentSyncHelper) {
        atLeastSyncedOnce = true
    }

    func syncContentEnded(_ syncHelper: WPContentSyncHelper) {
        refreshControl.endRefreshing()
        setFooterHidden(true)
        noResultsViewController.removeFromView()

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
            && error.code == type(of: self).httpErrorCodeForbidden {
            promptForPassword()
            return
        }

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

    // MARK: - Actions

    @objc func publishPost(_ apost: AbstractPost, completion: (() -> Void)? = nil) {
        let title = NSLocalizedString("Are you sure you want to publish?", comment: "Title of the message shown when the user taps Publish in the post list.")

        let cancelTitle = NSLocalizedString("Cancel", comment: "Button shown when the author is asked for publishing confirmation.")
        let publishTitle = NSLocalizedString("Publish", comment: "Button shown when the author is asked for publishing confirmation.")

        let style: UIAlertController.Style = UIDevice.isPad() ? .alert : .actionSheet
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: style)

        alertController.addCancelActionWithTitle(cancelTitle)
        alertController.addDefaultActionWithTitle(publishTitle) { [unowned self] _ in
            WPAnalytics.track(.postListPublishAction, withProperties: self.propertiesForAnalytics())

            PostCoordinator.shared.publish(apost)
            completion?()
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

        let controller = PreviewWebKitViewController(post: post, source: "posts_pages_view_post")
        controller.trackOpenEvent()
        // NOTE: We'll set the title to match the title of the View action button.
        // If the button title changes we should also update the title here.
        controller.navigationItem.title = NSLocalizedString("View", comment: "Verb. The screen title shown when viewing a post inside the app.")
        let navWrapper = LightNavigationController(rootViewController: controller)
        if navigationController?.traitCollection.userInterfaceIdiom == .pad {
            navWrapper.modalPresentationStyle = .fullScreen
        }
        navigationController?.present(navWrapper, animated: true)
    }

    @MainActor
    func deletePost(_ apost: AbstractPost) async {
        assert(apost.managedObjectContext == ContextManager.shared.mainContext)

        WPAnalytics.track(.postListTrashAction, withProperties: propertiesForAnalytics())

        // Remove the trashed post from spotlight
        SearchManager.shared.deleteSearchableItem(apost)

        // Update the fetch request *before* making the service call.
        updateAndPerformFetchRequest()

        let originalStatus = apost.status

        let trashed = (apost.status == .trash)

        let repository = PostRepository(coreDataStack: ContextManager.shared)
        do {
            try await repository.trash(TaggedManagedObjectID(apost))
            if trashed {
                PostCoordinator.shared.cancelAnyPendingSaveOf(post: apost)
                MediaCoordinator.shared.cancelUploadOfAllMedia(for: apost)
            }

            let message = NSLocalizedString("postsList.movePostToTrash.message", comment: "A short message explaining that a post was moved to the trash bin.")
            let undoAction = NSLocalizedString("postsList.movePostToTrash.undo", comment: "The title of an 'undo' button. Tapping the button moves a trashed post out of the trash folder.")
            let notice = Notice(title: message, actionTitle: undoAction, actionHandler: { [weak self] accepted in
                if accepted {
                    self?.restorePost(apost, toStatus: originalStatus ?? .draft)
                }
            })
            ActionDispatcher.dispatch(NoticeAction.dismiss)
            ActionDispatcher.dispatch(NoticeAction.post(notice))
        } catch {
            if let error = error as NSError?, error.code == AbstractPostListViewController.httpErrorCodeForbidden {
                promptForPassword()
            } else {
                WPError.showXMLRPCErrorAlert(error)
            }

            // We don't really know what happened here, why did the request fail?
            // Maybe we could not delete the post or maybe the post was already deleted
            // It is safer to re fetch the results than to reload that specific row
            DispatchQueue.main.async {
                self.updateAndPerformFetchRequestRefreshingResults()
            }
        }
    }

    func restorePost(_ apost: AbstractPost, toStatus status: BasePost.Status) {
        WPAnalytics.track(.postListRestoreAction, withProperties: propertiesForAnalytics())

        if filterSettings.currentPostListFilter().filterType != .draft {
            // Needed or else the post will remain in the published list.
            updateAndPerformFetchRequest()
            tableView.reloadData()
        }

        let repository = PostRepository(coreDataStack: ContextManager.shared)
        Task { @MainActor in
            do {
                try await repository.restore(.init(apost), to: status)

                if let postStatus = apost.status {
                    // If the post was restored, see if it appears in the current filter.
                    // If not, prompt the user to let it know under which filter it appears.
                    let filter = filterSettings.filterThatDisplaysPostsWithStatus(postStatus)

                    if filter.filterType == filterSettings.currentPostListFilter().filterType {
                        return
                    }

                    promptThatPostRestoredToFilter(filter)

                    // Reindex the restored post in spotlight
                    SearchManager.shared.indexItem(apost)
                }
            } catch {
                if let error = error as NSError?, error.code == AbstractPostListViewController.httpErrorCodeForbidden {
                    promptForPassword()
                } else {
                    WPError.showXMLRPCErrorAlert(error)
                }
            }
        }
    }

    @objc func copyPostLink(_ apost: AbstractPost) {
        let pasteboard = UIPasteboard.general
        guard let link = apost.permaLink else { return }
        pasteboard.string = link as String
        let noticeTitle = NSLocalizedString("Link Copied to Clipboard", comment: "Link copied to clipboard notice title")
        let notice = Notice(title: noticeTitle, feedbackType: .success)
        ActionDispatcher.dispatch(NoticeAction.dismiss) // Dismiss any old notices
        ActionDispatcher.dispatch(NoticeAction.post(notice))
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
        updateSelectedFilter()
        updateAndPerformFetchRequestRefreshingResults()
    }

    func updateFilterWithPostStatus(_ status: BasePost.Status) {
        filterSettings.setFilterWithPostStatus(status)
        refreshAndReload()
        WPAnalytics.track(.postListStatusFilterChanged, withProperties: propertiesForAnalytics())
    }

    func updateSelectedFilter() {
        if filterTabBar.selectedIndex != filterSettings.currentFilterIndex() {
            filterTabBar.setSelectedIndex(filterSettings.currentFilterIndex(), animated: false)
        }
    }

    @objc func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        filterSettings.setCurrentFilterIndex(filterBar.selectedIndex)

        refreshAndReload()

        syncItemsWithUserInteraction(false)

        WPAnalytics.track(.postListStatusFilterChanged, withProperties: propertiesForAnalytics())
    }

    // MARK: - UISearchControllerDelegate

    func willPresentSearchController(_ searchController: UISearchController) {
        WPAnalytics.track(.postListSearchOpened, withProperties: propertiesForAnalytics())
    }

    // MARK: - NetworkAwareUI

    func contentIsEmpty() -> Bool {
        return tableViewHandler.resultsController?.isEmpty() ?? true
    }

    func noConnectionMessage() -> String {
        return ReachabilityUtils.noConnectionMessage()
    }

    // MARK: - Misc

    private func setFooterHidden(_ isHidden: Bool) {
        if isHidden {
            tableView.tableFooterView = nil
        } else {
            tableView.tableFooterView = PagingFooterView(state: .loading)
            tableView.sizeToFitFooterView()
        }
    }

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

extension AbstractPostListViewController: EditorAnalyticsProperties { }

// MARK: - NoResultsViewControllerDelegate

extension AbstractPostListViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        WPAnalytics.track(.postListNoResultsButtonPressed, withProperties: propertiesForAnalytics())
        createPost()
    }
}
