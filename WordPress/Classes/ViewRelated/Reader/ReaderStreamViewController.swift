import Foundation

@objc public class ReaderStreamViewController : UIViewController, UIActionSheetDelegate,
    WPContentSyncHelperDelegate,
    WPTableViewHandlerDelegate,
    ReaderPostCellDelegate,
    ReaderStreamHeaderDelegate
{
    // MARK: - Properties

    @IBOutlet private weak var footerView: UIView!

    private var tableView: UITableView!
    private var refreshControl: UIRefreshControl!
    private var tableViewHandler: WPTableViewHandler!
    private var syncHelper: WPContentSyncHelper!
    private var tableViewController: UITableViewController!
    private var cellForLayout: ReaderPostCardCell!
    private var resultsStatusView: WPNoResultsView!
    private var objectIDOfPostForMenu: NSManagedObjectID?
    private var actionSheet: UIActionSheet?

    private let ReaderCardCellNibName = "ReaderPostCardCell"
    private let ReaderCardCellReuseIdentifier = "ReaderCardCellReuseIdentifier"
    private let estimatedRowHeight = CGFloat(100.0)

    private let refreshInterval = 300
    private var displayContext: NSManagedObjectContext?
    private var cleanupAndRefreshAfterScrolling = false

    public var readerTopic: ReaderTopic? {
        didSet {
            if isViewLoaded() && readerTopic != nil {
                displayTopic()
            }
        }
    }

    /**
        Convenience method for instantiating an instance of ReaderListViewController
        for a particular topic. 
        
        @param topic The reader topic for the list.

        @return A ReaderListViewController instance.
    */
    public class func controllerWithTopic(topic:ReaderTopic) -> ReaderStreamViewController {
        let storyboard = UIStoryboard(name: "Reader", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("ReaderStreamViewController") as! ReaderStreamViewController
        controller.readerTopic = topic

        return controller
    }


    // MARK: - LifeCycle Methods

    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        tableViewController = segue.destinationViewController as? UITableViewController
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        configureCellForLayout()
        configureTableView()
        configureTableViewHandler()
        configureSyncHelper()
        configureResultsStatusView()

        WPStyleGuide.configureColorsForView(view, andTableView: tableView)

        if readerTopic != nil {
            displayTopic()
        }
    }


    // MARK: -

    public override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }


    // MARK: - Configuration

    private func configureTableView() {
        assert(tableViewController != nil, "The tableViewController must be assigned before configuring the tableView")

        tableView = tableViewController.tableView
        tableView.separatorStyle = .None
        refreshControl = tableViewController.refreshControl!
        refreshControl.addTarget(self, action: Selector("handleRefresh:"), forControlEvents: .ValueChanged)

        let nib = UINib(nibName: ReaderCardCellNibName, bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: ReaderCardCellReuseIdentifier)
    }

    private func configureTableViewHandler() {
        assert(tableView != nil, "A tableView must be assigned before configuring a handler")

        tableViewHandler = WPTableViewHandler(tableView: tableView)
        tableViewHandler.cacheRowHeights = true
        tableViewHandler.updateRowAnimation = .None
        tableViewHandler.delegate = self
    }

    private func configureSyncHelper() {
        syncHelper = WPContentSyncHelper()
        syncHelper.delegate = self
    }

    private func configureCellForLayout() {
        cellForLayout = NSBundle.mainBundle().loadNibNamed("ReaderPostCardCell", owner: nil, options: nil).first as! ReaderPostCardCell

        // Add layout cell to superview (briefly) so constraint constants reflect the correct size class.
        view.addSubview(cellForLayout)
        cellForLayout.removeFromSuperview()
    }

    private func configureResultsStatusView() {
        resultsStatusView = WPNoResultsView()
    }


    // MARK: - Handling Loading and No Results

    func displayLoadingViewIfNeeded() {
        if let count = tableViewHandler.resultsController.fetchedObjects?.count {
            if count > 0 {
                return
            }
        }
        resultsStatusView.titleText = NSLocalizedString("Fetching posts...", comment:"A brief prompt shown when the reader is empty, letting the user know the app is currently fetching new posts.")
        resultsStatusView.messageText = ""
        resultsStatusView.accessoryView = WPAnimatedBox()
        displayResultsStatus()
    }

    func displayNoResultsView() {
        let response:NoResultsResponse = ReaderStreamViewController.responseForNoResults(readerTopic!)
        resultsStatusView.titleText = response.title
        resultsStatusView.messageText = response.message
        resultsStatusView.accessoryView = nil
        displayResultsStatus()
    }

    func displayResultsStatus() {
        if resultsStatusView.isDescendantOfView(view) {
            resultsStatusView.centerInSuperview()
        } else {
            view.addSubviewWithFadeAnimation(resultsStatusView)
        }
    }

    func hideResultsStatus() {
        resultsStatusView.removeFromSuperview()
    }


    // MARK: - Topic Presentation

    func displayStreamHeader() {
        assert(readerTopic != nil, "A reader topic is required")
        var header:ReaderStreamHeader? = ReaderStreamViewController.headerForStream(readerTopic!)
        header?.configureHeader(readerTopic!)
        header?.delegate = self

        tableView.tableHeaderView = header as? UIView
    }

    func displayTopic() {
        assert(readerTopic != nil, "A reader topic is required")
        assert(isViewLoaded(), "The controller's view must be loaded before displaying the topic")

        // TODO: Configure header view for the new topic (if needed)
        displayStreamHeader()
        tableViewHandler.resultsController.fetchRequest.predicate = predicateForFetchRequest()
        var error:NSError?
        tableViewHandler.resultsController.performFetch(&error)
        if let anError = error {
            // TODO: Log Error
        }
        tableView.setContentOffset(CGPointZero, animated: false)
        tableViewHandler.refreshTableView()
        syncIfAppropriate()

        var count = 0
        if let fetchedCount = tableViewHandler.resultsController.fetchedObjects?.count {
            count = fetchedCount
        }

        // Make sure we're showing the no results view if appropriate
        if !syncHelper.isSyncing && count == 0 {
            displayNoResultsView()
        }

        WPAnalytics.track(.ReaderLoadedTag, withProperties: tagPropertyForStats())
        if ReaderStreamViewController.topicIsFreshlyPressed(readerTopic!) {
            WPAnalytics.track(.ReaderLoadedFreshlyPressed)
        }
    }


    // MARK: - Instance Methods

    private func tagPropertyForStats() -> [NSObject: AnyObject] {
        return ["tag" : readerTopic!.title]
    }

    private func showMenuForPost(post:ReaderPost, fromView anchorView:UIView) {
        objectIDOfPostForMenu = post.objectID

        let cancel = NSLocalizedString("Cancel", comment:"The title of a cancel button.")
        let blockSite = NSLocalizedString("Block This Site", comment:"The title of a button that triggers blocking a site from the user's reader.")

        actionSheet = UIActionSheet(title: nil,
            delegate: self,
            cancelButtonTitle: cancel,
            destructiveButtonTitle: blockSite)

        if UIDevice.isPad() {
            actionSheet!.showFromRect(anchorView.bounds, inView:anchorView, animated:true)
        } else {
            actionSheet!.showFromTabBar(tabBarController?.tabBar)
        }
    }

    private func showAttributionForPost(post: ReaderPost) {
        // Fail safe. If there is no attribution exit.
        if post.sourceAttribution == nil {
            return
        }

        // If there is a blogID preview the site
        if post.sourceAttribution!.blogID != nil {
            let siteID = post.sourceAttribution.blogID
            let siteURL = post.sourceAttribution.blogURL

            // TODO: Make this a new instance of ReaderListViewController
            let controller = ReaderBrowseSiteViewController(siteID: siteID, siteURL: siteURL, isWPcom: true)
            navigationController?.pushViewController(controller, animated: true)
            return
        }

        if post.sourceAttribution!.attributionType != SourcePostAttributionTypeSite {
            return
        }

        let linkURL = NSURL(string: post.sourceAttribution.blogURL)
        let controller = WPWebViewController(URL: linkURL)
        let navController = UINavigationController(rootViewController: controller)
        presentViewController(navController, animated: true, completion: nil)
    }

    private func toggleLikeForPost(post: ReaderPost) {
        // TODO: Refactor so the service handles this properly
//        ReaderPost *post = [self postFromCellSubview:sender];
//        BOOL wasLiked = post.isLiked;
//
//        NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
//        ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
//
//        [context performBlock:^{
//            ReaderPost *postInContext = (ReaderPost *)[context existingObjectWithID:post.objectID error:nil];
//            if (!postInContext) {
//            return;
//            }
//
//            [service toggleLikedForPost:postInContext success:^{
//            if (wasLiked) {
//            return;
//            }
//            dispatch_async(dispatch_get_main_queue(), ^{
//            [WPAnalytics track:WPAnalyticsStatReaderLikedArticle];
//            });
//            } failure:^(NSError *error) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//            DDLogError(@"Error Liking Post : %@", [error localizedDescription]);
//            [postView updateActionButtons];
//            });
//            }];
//            }];
//        
//        [postView updateActionButtons];
    }


    // MARK: - Blocking

    private func blockSiteForPost(post: ReaderPost) {
/*
        NSNumber *postID = post.postID;
        self.tableViewHandler.updateRowAnimation = UITableViewRowAnimationFade;
        [self addBlockedPostID:postID];

        __weak __typeof(self) weakSelf = self;
        ReaderSiteService *service = [[ReaderSiteService alloc] initWithManagedObjectContext:[self managedObjectContext]];
        [service flagSiteWithID:post.siteID asBlocked:YES success:^{

        } failure:^(NSError *error) {
        weakSelf.tableViewHandler.updateRowAnimation = UITableViewRowAnimationNone;
        [weakSelf removeBlockedPostID:postID];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Blocking Site", @"Title of a prompt letting the user know there was an error trying to block a site from appearing in the reader.")
        message:[error localizedDescription]
        delegate:nil
        cancelButtonTitle:NSLocalizedString(@"OK", @"Text for an alert's dismissal button.")
        otherButtonTitles:nil, nil];
        [alertView show];
        }];

*/
    }

    private func unblockSiteForPost(post: ReaderPost) {
/*
        NSNumber *postID = post.postID;
        self.tableViewHandler.updateRowAnimation = UITableViewRowAnimationFade;

        __weak __typeof(self) weakSelf = self;
        ReaderSiteService *service = [[ReaderSiteService alloc] initWithManagedObjectContext:[self managedObjectContext]];
        [service flagSiteWithID:post.siteID asBlocked:NO success:^{
        [weakSelf removeBlockedPostID:postID];

        } failure:^(NSError *error) {
        weakSelf.tableViewHandler.updateRowAnimation = UITableViewRowAnimationNone;
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Unblocking Site", @"Title of a prompt letting the user know there was an error trying to unblock a site from appearing in the reader.")
        message:[error localizedDescription]
        delegate:nil
        cancelButtonTitle:NSLocalizedString(@"OK", @"Text for an alert's dismissal button.")
        otherButtonTitles:nil, nil];
        [alertView show];
        }];

*/
    }

    private func addBlockedPostID(post: ReaderPost) {
/*
        if ([self.postIDsForUndoBlockCells containsObject:postID]) {
        return;
        }

        [self.postIDsForUndoBlockCells addObject:postID];
        [self updateAndPerformFetchRequest];
*/
    }

    private func removeBlockedPostID(post: ReaderPost) {
/*
        if (![self.postIDsForUndoBlockCells containsObject:postID]) {
        return;
        }

        [self.postIDsForUndoBlockCells removeObject:postID];
        [self updateAndPerformFetchRequest];
*/
    }

    private func removeAllBlockedPostIDs() {
/*
        if ([self.postIDsForUndoBlockCells count] == 0) {
        return;
        }
        [self.postIDsForUndoBlockCells removeAllObjects];
        [self updateAndPerformFetchRequest];
*/
    }


    // MARK: - Actions

    /**
        Handles the user initiated pull to refresh action.
    */
    func handleRefresh(sender:UIRefreshControl) {
        if !canSync() {
            cleanupAfterSync()
            return
        }
        syncHelper.syncContentWithUserInteraction(true)
    }


    // MARK: - Sync Methods

    func canSync() -> Bool {
        let appDelegate = WordPressAppDelegate.sharedInstance()
        return (readerTopic != nil) && appDelegate.connectionAvailable
    }

    func canLoadMore() -> Bool {
        if let fetchedObjects = tableViewHandler.resultsController.fetchedObjects {
            if fetchedObjects.count == 0 {
                return false
            }
        }
        return canSync()
    }

    /**
        Kicks off a "background" sync without updating the UI if certain conditions
        are met.
        - The app must have a internet connection.
        - The current time must be greater than the last sync interval.
    */
    func syncIfAppropriate() {
        let lastSynced = readerTopic?.lastSynced == nil ? NSDate(timeIntervalSince1970: 0) : readerTopic!.lastSynced
        if canSync() && Int(lastSynced.timeIntervalSinceNow) < refreshInterval {
            syncHelper.syncContentWithUserInteraction(false)
        }
    }

    func syncItems(success:((hasMore: Bool) -> Void)?, failure: ((error: NSError) -> Void)?) {
        let syncContext = ContextManager.sharedInstance().newDerivedContext()
        let service =  ReaderPostService(managedObjectContext: syncContext)

        syncContext.performBlock {[weak self] () -> Void in
            var error: NSError?
            let topic = syncContext.existingObjectWithID(self!.readerTopic!.objectID, error: &error) as! ReaderTopic

            service.fetchPostsForTopic(topic,
                earlierThan: NSDate(),
                success: { (count:Int, hasMore:Bool) in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if success != nil {
                            success!(hasMore: hasMore)
                        }
                    })
                }, failure: { (error:NSError!) in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if failure != nil {
                            failure!(error: error)
                        }
                    })
                })
        }
    }

    func backfillItems(success:((hasMore: Bool) -> Void)?, failure: ((error: NSError) -> Void)?) {
        let syncContext = ContextManager.sharedInstance().newDerivedContext()
        let service =  ReaderPostService(managedObjectContext: syncContext)

        syncContext.performBlock {[weak self] () -> Void in
            var error: NSError?
            let topic = syncContext.existingObjectWithID(self!.readerTopic!.objectID, error: &error) as! ReaderTopic
            
            service.backfillPostsForTopic(topic,
                success: { (count:Int, hasMore:Bool) -> Void in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if success != nil {
                            success!(hasMore: hasMore)
                        }
                    })
                }, failure: { (error:NSError!) -> Void in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if failure != nil {
                            failure!(error: error)
                        }
                    })
                })
        }
    }

    func loadMoreItems(success:((hasMore: Bool) -> Void)?, failure: ((error: NSError) -> Void)?) {
        let post = tableViewHandler.resultsController.fetchedObjects?.last as? ReaderPost
        if post == nil {
            // failsafe 
            return
        }

        // TODO: show loading more ...

        let earlierThan = post!.sortDate
        let syncContext = ContextManager.sharedInstance().newDerivedContext()
        let service =  ReaderPostService(managedObjectContext: syncContext)

        syncContext.performBlock { [weak self] () -> Void in
            var error: NSError?
            let topic = syncContext.existingObjectWithID(self!.readerTopic!.objectID, error: &error) as! ReaderTopic
            service.fetchPostsForTopic(topic,
                earlierThan: earlierThan,
                success: { (count:Int, hasMore:Bool) -> Void in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if success != nil {
                            success!(hasMore: hasMore)
                        }
                    })
                },
                failure: { (error:NSError!) -> Void in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if failure != nil {
                            failure!(error: error)
                        }
                    })
                })
        }

        WPAnalytics.track(.ReaderInfiniteScroll, withProperties: tagPropertyForStats())
    }

    func syncHelper(syncHelper: WPContentSyncHelper, syncContentWithUserInteraction userInteraction: Bool, success: ((hasMore: Bool) -> Void)?, failure: ((error: NSError) -> Void)?) {
        displayLoadingViewIfNeeded()
        if userInteraction {
            syncItems(success, failure: failure)

        } else {
            backfillItems(success, failure: failure)
        }
    }

    func syncHelper(syncHelper: WPContentSyncHelper, syncMoreWithSuccess success: ((hasMore: Bool) -> Void)?, failure: ((error: NSError) -> Void)?) {
        loadMoreItems(success, failure: failure)
    }

    public func syncContentEnded() {
        if tableViewHandler.isScrolling {
            cleanupAndRefreshAfterScrolling = true
            return
        }
        cleanupAfterSync()
    }

    public func cleanupAfterSync() {
        tableViewHandler.refreshTableViewPreservingOffset()
        refreshControl.endRefreshing()
    }

    public func tableViewHandlerWillRefreshTableViewPreservingOffset(tableViewHandler: WPTableViewHandler!) {
        // Reload the table view to reflect new content.
        managedObjectContext().performBlockAndWait { () -> Void in
           self.managedObjectContext().reset()
            var error:NSError?
            self.tableViewHandler.resultsController.performFetch(&error);
            if let anError = error {
                DDLogSwift.logError(anError.description)
            }
        }
    }

    public func tableViewHandlerDidRefreshTableViewPreservingOffset(tableViewHandler: WPTableViewHandler!) {
        if self.tableViewHandler.resultsController.fetchedObjects?.count == 0 {
            self.displayNoResultsView()
        } else {
            self.hideResultsStatus()
        }
    }

    // MARK: - Helpers for TableViewHelper

    func predicateForFetchRequest() -> NSPredicate {
        return NSPredicate(format: "topic = %@", readerTopic!)
    }

    func sortDescriptorsForFetchRequest() -> [NSSortDescriptor] {
        let sortDescriptor = NSSortDescriptor(key: "sortDate", ascending: false)
        return [sortDescriptor]
    }


    // MARK: - TableViewHandler Delegate Methods

    public func scrollViewWillBeginDragging(scrollView: UIScrollView!) {
        if refreshControl.refreshing {
            refreshControl.endRefreshing()
        }
    }

    public func scrollViewDidEndDragging(scrollView: UIScrollView!, willDecelerate decelerate: Bool) {
        if decelerate {
            return
        }
        if cleanupAndRefreshAfterScrolling {
            cleanupAfterSync()
        }
        cleanupAndRefreshAfterScrolling = false
    }

    public func scrollViewDidEndDecelerating(scrollView: UIScrollView!) {
        if cleanupAndRefreshAfterScrolling {
            cleanupAfterSync()
        }
        cleanupAndRefreshAfterScrolling = false
    }

    public func managedObjectContext() -> NSManagedObjectContext {
        if let context = displayContext {
            return context
        }
        displayContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        displayContext!.parentContext = ContextManager.sharedInstance().mainContext
        return displayContext!
    }

    public func fetchRequest() -> NSFetchRequest {
        let fetchRequest = NSFetchRequest(entityName: ReaderPost.classNameWithoutNamespaces())
        fetchRequest.predicate = predicateForFetchRequest()
        fetchRequest.sortDescriptors = sortDescriptorsForFetchRequest()
        return fetchRequest
    }

    public func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return estimatedRowHeight
    }

    public func tableView(aTableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let width = aTableView.bounds.width
        return tableView(aTableView, heightForRowAtIndexPath: indexPath, forWidth: width)
    }

    public func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!, forWidth width: CGFloat) -> CGFloat {
        if tableViewHandler.resultsController.fetchedObjects == nil {
            return 0.0
        }

        // TODO: handle cells for blocked content

        configureCell(cellForLayout, atIndexPath: indexPath)
        let size = cellForLayout.sizeThatFits(CGSize(width:width, height:CGFloat.max))
        return size.height
    }

    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell? {
        var cell = tableView.dequeueReusableCellWithIdentifier(ReaderCardCellReuseIdentifier) as! ReaderPostCardCell
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    public func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        if tableViewHandler.resultsController.fetchedObjects == nil {
            return
        }
        cell.accessoryType = .None
        cell.selectionStyle = .None

        let postCell = cell as! ReaderPostCardCell
        let posts = tableViewHandler.resultsController.fetchedObjects as! [ReaderPost]
        let post = posts[indexPath.row]
        let shouldLoadMedia = postCell != cellForLayout

        postCell.configureCell(post, loadingMedia: shouldLoadMedia)
        postCell.delegate = self
    }

    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)

        let posts = tableViewHandler.resultsController.fetchedObjects as! [ReaderPost]
        let post = posts[indexPath.row]
        let controller = ReaderPostDetailViewController.detailControllerWithPost(post)
        navigationController?.pushViewController(controller, animated: true)
    }


    // MARK: - ReaderStreamHeader Delegate Methods

    public func handleFollowActionForHeader(header:ReaderStreamHeader) {
        // TODO: Implement method
    }


    // MARK: - ReaderCard Delegate Methods

    public func readerCell(cell: ReaderPostCardCell, headerActionForProvider provider: ReaderPostContentProvider) {
        let post = provider as! ReaderPost
        // TODO: Should be a new instance of ReaderListViewController
        let controller = ReaderBrowseSiteViewController(post: post)
        navigationController?.pushViewController(controller, animated: true)
        WPAnalytics.track(.ReaderPreviewedSite)
    }

    public func readerCell(cell: ReaderPostCardCell, commentActionForProvider provider: ReaderPostContentProvider) {
        let post = provider as! ReaderPost
        let controller = ReaderCommentsViewController(post: post)
        navigationController?.pushViewController(controller, animated: true)
    }

    public func readerCell(cell: ReaderPostCardCell, likeActionForProvider provider: ReaderPostContentProvider) {
        let post = provider as! ReaderPost
        toggleLikeForPost(post)
    }

    public func readerCell(cell: ReaderPostCardCell, visitActionForProvider provider: ReaderPostContentProvider) {
        // TODO:  Still needed?
    }

    public func readerCell(cell: ReaderPostCardCell, tagActionForProvider provider: ReaderPostContentProvider) {
        // TODO: Waiting on Core Data support
    }

    public func readerCell(cell: ReaderPostCardCell, menuActionForProvider provider: ReaderPostContentProvider, fromView sender: UIView) {
        let post = provider as! ReaderPost
        showMenuForPost(post, fromView:sender)
    }

    public func readerCell(cell: ReaderPostCardCell, attributionActionForProvider provider: ReaderPostContentProvider) {
        let post = provider as! ReaderPost
        showAttributionForPost(post)
    }


    // MARK: - UIActionSheet Delegate Methods

    public func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == actionSheet.cancelButtonIndex {
            return
        }
        // TODO: Wire up the menu
    }

    public func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        objectIDOfPostForMenu = nil
        actionSheet.delegate = nil
        self.actionSheet = nil
    }

}
