import Foundation
import CoreData
import Gridicons
import CocoaLumberjack
import WordPressShared
import wpxmlrpc
import WordPressFlux
import WordPressUI

class AbstractPostListViewController: UIViewController,
                                      WPContentSyncHelperDelegate,
                                      NSFetchedResultsControllerDelegate,
                                      UITableViewDelegate,
                                      UITableViewDataSource,
                                      NetworkAwareUI // This protocol is not in an extension so that subclasses can override noConnectionMessage()
{
    typealias SyncPostResult = (posts: [AbstractPost], hasMore: Bool)

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
    private var reloadTableViewBeforeAppearing = false

    let tableView = UITableView(frame: .zero, style: .plain)

    var shouldHideAuthor: Bool {
        guard filterSettings.canFilterByAuthor() else {
            return true
        }
        return filterSettings.currentPostAuthorFilter() == .mine
    }

    private let buttonAuthorFilter = AuthorFilterButton()

    let refreshControl = UIRefreshControl()

    private(set) var fetchResultsController: NSFetchedResultsController<AbstractPost>!

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
        fetchResultsController?.fetchedObjects?.count == 0
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

        configureFetchResultsController()
        configureTableView()
        configureFilterBar()
        configureTableView()
        configureSearchController()
        configureAuthorFilter()
        configureDefaultNavigationBarAppearance()

        updateAndPerformFetchRequest()

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

    private func configureFetchResultsController() {
        fetchResultsController = NSFetchedResultsController<AbstractPost>(fetchRequest: fetchRequest(), managedObjectContext: managedObjectContext(), sectionNameKeyPath: nil, cacheName: nil)
        fetchResultsController.delegate = self
    }

    func configureTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(tableView)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .systemBackground
        tableView.sectionHeaderTopPadding = 0
        tableView.estimatedRowHeight = 110
        tableView.rowHeight = UITableView.automaticDimension
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }

    private func configureFilterBar() {
        WPStyleGuide.configureFilterTabBar(filterTabBar)
        filterTabBar.backgroundColor = .clear
        filterTabBar.items = filterSettings.availablePostListFilters()
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)

        filterTabBar.translatesAutoresizingMaskIntoConstraints = true
        filterTabBar.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 40)
        tableView.tableHeaderView = filterTabBar
    }

    func refreshResults() {
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
        assert(self is InteractivePostViewDelegate, "The subclass has to implement InteractivePostViewDelegate protocol")

        searchResultsViewController.configure(searchController, self as? InteractivePostViewDelegate)

        definesPresentationContext = true
        navigationItem.searchController = searchController
        if #available(iOS 16.0, *) {
            navigationItem.preferredSearchBarPlacement = .stacked
        }
    }

    func propertiesForAnalytics() -> [String: AnyObject] {
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
        noResultsViewController.removeFromView()
    }

    func showNoResultsView() {
        guard refreshNoResultsViewController != nil, atLeastSyncedOnce else {
            return
        }
        refreshNoResultsViewController(noResultsViewController)

        // Only add no results view if it isn't already in the table view
        if noResultsViewController.view.isDescendant(of: tableView) == false {
            self.addChild(noResultsViewController)
            tableView.addSubview(noResultsViewController.view)
            noResultsViewController.view.frame = tableView.frame.offsetBy(dx: 0, dy: -view.safeAreaInsets.top + 40)
            noResultsViewController.didMove(toParent: self)
        }

        tableView.sendSubviewToBack(noResultsViewController.view)
    }

    // MARK: - Core Data

    func entityName() -> String {
        fatalError("You should implement this method in the subclass")
    }

    func managedObjectContext() -> NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }

    func fetchRequest() -> NSFetchRequest<AbstractPost> {
        let fetchRequest = NSFetchRequest<AbstractPost>(entityName: entityName())
        fetchRequest.predicate = predicateForFetchRequest()
        fetchRequest.sortDescriptors = sortDescriptorsForFetchRequest()
        fetchRequest.fetchBatchSize = fetchBatchSize
        fetchRequest.fetchLimit = fetchLimit
        return fetchRequest
    }

    func sortDescriptorsForFetchRequest() -> [NSSortDescriptor] {
        return filterSettings.currentPostListFilter().sortDescriptors
    }

    func updateAndPerformFetchRequest() {
        assert(Thread.isMainThread, "AbstractPostListViewController Error: NSFetchedResultsController accessed in BG")

        var predicate = predicateForFetchRequest()
        let sortDescriptors = sortDescriptorsForFetchRequest()
        let fetchRequest = fetchResultsController.fetchRequest

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
            try fetchResultsController.performFetch()
        } catch {
            DDLogError("Error fetching posts after updating the fetch request predicate: \(error)")
        }
    }

    func updateAndPerformFetchRequestRefreshingResults() {
        updateAndPerformFetchRequest()
        tableView.reloadData()
        refreshResults()
    }

    func predicateForFetchRequest() -> NSPredicate {
        fatalError("You should implement this method in the subclass")
    }

    // MARK: - NSFetchedResultsControllerDelegate

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath else { return }
            tableView.insertRows(at: [newIndexPath], with: .none)
        case .delete:
            guard let indexPath else { return }
            tableView.deleteRows(at: [indexPath], with: .fade)
        case .update:
            guard let indexPath else { return }
            tableView.reloadRows(at: [indexPath], with: .none)
        case .move:
            guard let indexPath, let newIndexPath else { return }
            tableView.moveRow(at: indexPath, to: newIndexPath)
        @unknown default:
            break
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        do { // Some defensive code, just in case
            try WPException.objcTry {
                self.tableView.endUpdates()
            }
        } catch {
            tableView.reloadData()
        }
        refreshResults()
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fetchResultsController.fetchedObjects?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        fatalError("Not implemented")
    }

    // MARK: - UITableViewDelegate

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

    // MARK: - Actions

    @objc private func refresh(_ sender: AnyObject) {
        syncItemsWithUserInteraction(true)

        WPAnalytics.track(.postListPullToRefresh, withProperties: propertiesForAnalytics())
    }

    // MARK: - Syncing

    private func automaticallySyncIfAppropriate() {
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

        // Update in the background
        syncItemsWithUserInteraction(false)
    }

    @objc func syncItemsWithUserInteraction(_ userInteraction: Bool) {
        syncHelper.syncContentWithUserInteraction(userInteraction)
        refreshResults()
    }

    @objc func updateFilter(_ filter: PostListFilter, withSyncedPosts posts: [AbstractPost], hasMore: Bool) {
        guard posts.count > 0 else {
            assertionFailure("This method should not be called with no posts.")
            return
        }
        // Reset the filter to only show the latest sync point, based on the oldest post date in the posts just synced.
        // Note: Getting oldest date manually as the API may return results out of order if there are
        // differing time offsets in the created dates.
        let oldestPost = posts.min { ($0.date_created_gmt ?? .distantPast) < ($1.date_created_gmt ?? .distantPast) }
        filter.oldestPostDate = oldestPost?.date_created_gmt
        filter.hasMore = hasMore

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

    @MainActor
    func syncPosts(isFirstPage: Bool) async throws -> SyncPostResult {
        let postType = postTypeToSync()
        let filter = filterSettings.currentPostListFilter()
        let author = filterSettings.shouldShowOnlyMyPosts() ? blogUserID() : nil

        let coreDataStack = ContextManager.shared
        let blogID = TaggedManagedObjectID(blog)
        let number = numberOfLoadedElement.intValue

        let repository = PostRepository(coreDataStack: coreDataStack)
        let result = try await repository.paginate(
            type: postType == .post ? Post.self : Page.self,
            statuses: filter.statuses,
            authorUserID: author,
            offset: isFirstPage ? 0 : fetchResultsController.fetchedObjects?.count ?? 0,
            number: number,
            in: blogID
        )

        let posts = try result.map { try coreDataStack.mainContext.existingObject(with: $0) }
        let hasMore = result.count >= number

        return (posts, hasMore)
    }

    func syncHelper(_ syncHelper: WPContentSyncHelper, syncContentWithUserInteraction userInteraction: Bool, success: ((_ hasMore: Bool) -> ())?, failure: ((_ error: NSError) -> ())?) {
        let filter = filterSettings.currentPostListFilter()
        Task { @MainActor [weak self] in
            do {
                guard let (posts, hasMore) = try await self?.syncPosts(isFirstPage: true) else { return }

                guard let self else { return }

                if posts.count > 0 {
                    self.updateFilter(filter, withSyncedPosts: posts, hasMore: hasMore)
                    SearchManager.shared.indexItems(posts)
                }

                success?(filter.hasMore)
            } catch {
                guard let self else { return }

                failure?(error as NSError)

                if userInteraction == true {
                    self.handleSyncFailure(error as NSError)
                }
            }
        }
    }

    func syncHelper(_ syncHelper: WPContentSyncHelper, syncMoreWithSuccess success: ((_ hasMore: Bool) -> Void)?, failure: ((_ error: NSError) -> Void)?) {

        setFooterHidden(false)

        let filter = filterSettings.currentPostListFilter()

        Task { @MainActor [weak self] in
            do {
                guard let (posts, hasMore) = try await self?.syncPosts(isFirstPage: false) else { return }

                // User may have exit the screen when the "syncPosts" call above completes.
                guard let self else { return }

                if posts.count > 0 {
                    self.updateFilter(filter, withSyncedPosts: posts, hasMore: hasMore)
                    SearchManager.shared.indexItems(posts)
                }

                success?(filter.hasMore)
            } catch {
                failure?(error as NSError)
            }
        }
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
            WordPressAppDelegate.shared?.showPasswordInvalidPrompt(for: blog)
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

    // MARK: - Actions

    func publish(_ post: AbstractPost) {
        let action = AbstractPostHelper.editorPublishAction(for: post)

        func showPrepublishingFlow(for post: Post) {
            let viewController = PrepublishingViewController(post: post, identifiers: PrepublishingIdentifier.defaultIdentifiers) { [weak self] result in
                switch result {
                case .confirmed:
                    self?.didConfirmPublish(for: post)
                case .published:
                    self?.dismiss(animated: true)
                case .cancelled:
                    break
                }
            }
            viewController.presentAsSheet(from: self)
        }

        func showPublishingConfirmation() {
            let cancelTitle = NSLocalizedString("Cancel", comment: "Button shown when the author is asked for publishing confirmation.")

            let style: UIAlertController.Style = UIDevice.isPad() ? .alert : .actionSheet
            let alertController = UIAlertController(title: action.publishingActionQuestionLabel, message: nil, preferredStyle: style)

            alertController.addCancelActionWithTitle(cancelTitle)
            alertController.addDefaultActionWithTitle(action.publishingActionQuestionLabel) { [unowned self] _ in
                self.didConfirmPublish(for: post)
            }

            present(alertController, animated: true)
        }

        if let post = post as? Post {
            showPrepublishingFlow(for: post)
        } else {
            showPublishingConfirmation()
        }
    }

    private func didConfirmPublish(for post: AbstractPost) {
        WPAnalytics.track(.postListPublishAction, withProperties: propertiesForAnalytics())
        PostCoordinator.shared.publish(post)

        if post is Post {
            BloggingRemindersFlow.present(from: self, for: post.blog, source: .publishFlow, alwaysShow: false)
        }
    }

    @objc func moveToDraft(_ post: AbstractPost) {
        WPAnalytics.track(.postListDraftAction, withProperties: propertiesForAnalytics())

        PostCoordinator.shared.moveToDraft(post)
    }

    @objc func viewPost(_ post: AbstractPost) {
        WPAnalytics.track(.postListViewAction, withProperties: propertiesForAnalytics())

        let post = post.hasRevision() ? post.revision! : post

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

    func deletePost(_ post: AbstractPost) {
        Task {
            await PostCoordinator.shared.delete(post)
        }
    }

    @objc func copyPostLink(_ post: AbstractPost) {
        let pasteboard = UIPasteboard.general
        guard let link = post.permaLink else { return }
        pasteboard.string = link as String
        let noticeTitle = NSLocalizedString("Link Copied to Clipboard", comment: "Link copied to clipboard notice title")
        let notice = Notice(title: noticeTitle, feedbackType: .success)
        ActionDispatcher.dispatch(NoticeAction.dismiss) // Dismiss any old notices
        ActionDispatcher.dispatch(NoticeAction.post(notice))
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

    private func updateSelectedFilter() {
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

    // MARK: - NetworkAwareUI

    func contentIsEmpty() -> Bool {
        fetchResultsController.isEmpty()
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
