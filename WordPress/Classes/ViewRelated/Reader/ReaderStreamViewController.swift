import Foundation

@objc public class ReaderStreamViewController : UIViewController, UIActionSheetDelegate,
    WPContentSyncHelperDelegate,
    WPTableViewHandlerDelegate,
    ReaderPostCellDelegate,
    ReaderStreamHeaderDelegate
{
    // MARK: - Properties

    private var tableView: UITableView!
    private var refreshControl: UIRefreshControl!
    private var tableViewHandler: WPTableViewHandler!
    private var syncHelper: WPContentSyncHelper!
    private var tableViewController: UITableViewController!
    private var cellForLayout: ReaderPostCardCell!
    private var resultsStatusView: WPNoResultsView!
    private var objectIDOfPostForMenu: NSManagedObjectID?
    private var actionSheet: UIActionSheet?
    private var footerView: PostListFooterView!

    private let readerCardCellNibName = "ReaderPostCardCell"
    private let readerCardCellReuseIdentifier = "ReaderCardCellReuseIdentifier"
    private let estimatedRowHeight = CGFloat(100.0)

    private let refreshInterval = 300
    private var displayContext: NSManagedObjectContext?
    private var cleanupAndRefreshAfterScrolling = false
    private let recentlyBlockedSitePostObjectIDs = NSMutableArray()

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
        configureFooterView()
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

        let nib = UINib(nibName: readerCardCellNibName, bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: readerCardCellReuseIdentifier)
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

    private func configureFooterView() {
        footerView = NSBundle.mainBundle().loadNibNamed("PostListFooterView", owner: nil, options: nil).first as! PostListFooterView
        footerView.showSpinner(false)
        tableView.tableFooterView = footerView
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
        if resultsStatusView.isDescendantOfView(tableView) {
            resultsStatusView.centerInSuperview()
        } else {
            tableView.addSubviewWithFadeAnimation(resultsStatusView)
        }
        footerView.hidden = false
    }

    func hideResultsStatus() {
        resultsStatusView.removeFromSuperview()
        footerView.hidden = false
    }


    // MARK: - Topic Presentation

    func displayStreamHeader() {
        assert(readerTopic != nil, "A reader topic is required")

        var header:ReaderStreamHeader? = ReaderStreamViewController.headerForStream(readerTopic!)
        if header == nil {
            tableView.tableHeaderView = nil
            return
        }

        header!.configureHeader(readerTopic!)
        header!.delegate = self

        // Wrap the header in another view as a layout helper
        var headerView = header as! UIView
        var headerWrapper = UIView(frame: headerView.frame)
        headerWrapper.autoresizingMask = .FlexibleWidth
        headerWrapper.addSubview(headerView)

        tableView.tableHeaderView = headerWrapper
    }

    func displayTopic() {
        assert(readerTopic != nil, "A reader topic is required")
        assert(isViewLoaded(), "The controller's view must be loaded before displaying the topic")

        recentlyBlockedSitePostObjectIDs.removeAllObjects()
        displayStreamHeader()
        updateAndPerformFetchRequest()

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
        let service = ReaderPostService(managedObjectContext: managedObjectContext())
        service.toggleLikedForPost(post, success: nil, failure: { (error:NSError?) in
            if let anError = error {
                DDLogSwift.logError("Error (un)liking post: \(anError.localizedDescription)")
            }
        })
    }

    private func updateAndPerformFetchRequest() {
        assert(NSThread.isMainThread(), "ReaderStreamViewController Error: updating fetch request on a background thread.")

        var error:NSError?
        tableViewHandler.resultsController.fetchRequest.predicate = predicateForFetchRequest()
        tableViewHandler.resultsController.performFetch(&error)
        if let anError = error {

            DDLogSwift.logError("Error fetching posts after updating the fetch reqeust predicate: \(anError.localizedDescription)")
        }
    }


    // MARK: - Blocking

    private func blockSiteForPost(post: ReaderPost) {
        let objectID = post.objectID
        recentlyBlockedSitePostObjectIDs.addObject(objectID)
        updateAndPerformFetchRequest()

        let indexPath = tableViewHandler.resultsController.indexPathForObject(post)!
        tableViewHandler.invalidateCachedRowHeightAtIndexPath(indexPath)
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)

        let service = ReaderSiteService(managedObjectContext: managedObjectContext())
        service.flagSiteWithID(post.siteID,
            asBlocked: true,
            success: nil,
            failure: { [weak self] (error:NSError!) in
                self?.recentlyBlockedSitePostObjectIDs.removeObject(objectID)
                self?.tableViewHandler.invalidateCachedRowHeightAtIndexPath(indexPath)
                self?.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)

                let alertView = UIAlertView(
                    title: NSLocalizedString("Error Blocking Site", comment:"Title of a prompt letting the user know there was an error trying to block a site from appearing in the reader."),
                    message: error.localizedDescription,
                    delegate: nil,
                    cancelButtonTitle: NSLocalizedString("OK", comment:"Text for an alert's dismissal button.")
                )
                alertView.show()
            })
    }

    private func unblockSiteForPost(post: ReaderPost) {
        let objectID = post.objectID
        recentlyBlockedSitePostObjectIDs.removeObject(objectID)

        let indexPath = tableViewHandler.resultsController.indexPathForObject(post)!
        tableViewHandler.invalidateCachedRowHeightAtIndexPath(indexPath)
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)

        let service = ReaderSiteService(managedObjectContext: managedObjectContext())
        service.flagSiteWithID(post.siteID,
            asBlocked: true,
            success: nil,
            failure: { [weak self] (error:NSError!) in
                self?.recentlyBlockedSitePostObjectIDs.addObject(objectID)
                self?.tableViewHandler.invalidateCachedRowHeightAtIndexPath(indexPath)
                self?.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)

                let alertView = UIAlertView(
                    title: NSLocalizedString("Error Unblocking Site", comment:"Title of a prompt letting the user know there was an error trying to unblock a site from appearing in the reader."),
                    message: error.localizedDescription,
                    delegate: nil,
                    cancelButtonTitle: NSLocalizedString("OK", comment:"Text for an alert's dismissal button.")
                )
                alertView.show()
            })
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
                success: {[weak self] (count:Int, hasMore:Bool) in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in

                        if let strongSelf = self {
                            if strongSelf.recentlyBlockedSitePostObjectIDs.count > 0 {
                                strongSelf.recentlyBlockedSitePostObjectIDs.removeAllObjects()
                                strongSelf.updateAndPerformFetchRequest()
                            }
                        }

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

        footerView.showSpinner(true)

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
        footerView.showSpinner(false)
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

    // MARK: - Helpers for TableViewHandler

    func predicateForFetchRequest() -> NSPredicate {
        if recentlyBlockedSitePostObjectIDs.count > 0 {
            return NSPredicate(format: "topic = %@ AND (isSiteBlocked = NO OR SELF in %@)", readerTopic!, recentlyBlockedSitePostObjectIDs)
        }

        return NSPredicate(format: "topic = %@ AND isSiteBlocked = NO", readerTopic!)
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
        var cell = tableView.dequeueReusableCellWithIdentifier(readerCardCellReuseIdentifier) as! ReaderPostCardCell
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
        if objectIDOfPostForMenu == nil {
            return
        }

        var error: NSError?
        var post = managedObjectContext().existingObjectWithID(objectIDOfPostForMenu!, error: &error) as? ReaderPost
        if let readerPost = post {
            blockSiteForPost(readerPost)
        }
    }

    public func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        objectIDOfPostForMenu = nil
        actionSheet.delegate = nil
        self.actionSheet = nil
    }

}
