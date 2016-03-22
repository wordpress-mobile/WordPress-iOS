import Foundation
import SVProgressHUD
import WordPressShared
import WordPressComAnalytics

@objc public class ReaderStreamViewController : UIViewController,
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
    private var crossPostCellForLayout:ReaderCrossPostCell!
    private var resultsStatusView: WPNoResultsView!
    private var footerView: PostListFooterView!
    private var objectIDOfPostForMenu: NSManagedObjectID?
    private var anchorViewForMenu: UIView?

    private let footerViewNibName = "PostListFooterView"
    private let readerCardCellNibName = "ReaderPostCardCell"
    private let readerCardCellReuseIdentifier = "ReaderCardCellReuseIdentifier"
    private let readerBlockedCellNibName = "ReaderBlockedSiteCell"
    private let readerBlockedCellReuseIdentifier = "ReaderBlockedCellReuseIdentifier"
    private let readerGapMarkerCellNibName = "ReaderGapMarkerCell"
    private let readerGapMarkerCellReuseIdentifier = "ReaderGapMarkerCellReuseIdentifier"
    private let readerCrossPostCellNibName = "ReaderCrossPostCell"
    private let readerCrossPostCellReuseIdentifier = "ReaderCrossPostCellReuseIdentifier"
    private let estimatedRowHeight = CGFloat(100.0)
    private let blockedRowHeight = CGFloat(66.0)
    private let gapMarkerRowHeight = CGFloat(60.0)
    private let loadMoreThreashold = 4

    private let refreshInterval = 300
    private var displayContext: NSManagedObjectContext?
    private var cleanupAndRefreshAfterScrolling = false
    private let recentlyBlockedSitePostObjectIDs = NSMutableArray()
    private let frameForEmptyHeaderView = CGRect(x: 0.0, y: 0.0, width: 320.0, height: 30.0)
    private let heightForFooterView = CGFloat(34.0)
    private var isLoggedIn = false
    private var isFeed = false
    private var syncIsFillingGap = false
    private var indexPathForGapMarker: NSIndexPath?
    private var needsRefreshCachedCellHeightsBeforeLayout = false
    private var didSetupView = false
    private var listentingForBlockedSiteNotification = false

    private var siteID:NSNumber? {
        didSet {
            if siteID != nil {
                fetchSiteTopic()
            }
        }
    }

    private var tagSlug:String? {
        didSet {
            if tagSlug != nil {
                fetchTagTopic()
            }
        }
    }

    public var readerTopic: ReaderAbstractTopic? {
        didSet {
            if readerTopic != nil && readerTopic != oldValue {
                if didSetupView {
                    configureControllerForTopic()
                }
                // Discard the siteID (if there was one) now that we have a good topic
                siteID = nil
                tagSlug = nil
            }
        }
    }

    /**
        Convenience method for instantiating an instance of ReaderListViewController
        for a particular topic. 
        
        @param topic The reader topic for the list.

        @return A ReaderListViewController instance.
    */
    public class func controllerWithTopic(topic:ReaderAbstractTopic) -> ReaderStreamViewController {
        let storyboard = UIStoryboard(name: "Reader", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("ReaderStreamViewController") as! ReaderStreamViewController
        controller.readerTopic = topic

        return controller
    }

    public class func controllerWithSiteID(siteID:NSNumber, isFeed:Bool) -> ReaderStreamViewController {
        let storyboard = UIStoryboard(name: "Reader", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("ReaderStreamViewController") as! ReaderStreamViewController
        controller.isFeed = isFeed
        controller.siteID = siteID

        return controller
    }

    public class func controllerWithTagSlug(tagSlug:String) -> ReaderStreamViewController {
        let storyboard = UIStoryboard(name: "Reader", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("ReaderStreamViewController") as! ReaderStreamViewController
        controller.tagSlug = tagSlug

        return controller
    }


    // MARK: - LifeCycle Methods

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        tableViewController = segue.destinationViewController as? UITableViewController
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setupCellForLayout()
        setupTableView()
        setupFooterView()
        setupTableViewHandler()
        setupSyncHelper()
        setupResultsStatusView()

        WPStyleGuide.configureColorsForView(view, andTableView: tableView)

        didSetupView = true

        if readerTopic != nil {
            configureControllerForTopic()
        } else if siteID != nil || tagSlug != nil {
            displayLoadingStream()
        }
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // There appears to be a scenario where this method can be called prior to
        // the view being fully setup in viewDidLoad.
        // See: https://github.com/wordpress-mobile/WordPress-iOS/issues/4419
        if didSetupView {
            refreshTableViewHeaderLayout()
        }
    }

    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ReaderStreamViewController.handleApplicationDidBecomeActive(_:)), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }

    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
    }

    public override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // There appears to be a scenario where this method can be called prior to
        // the view being fully setup in viewDidLoad.
        // See: https://github.com/wordpress-mobile/WordPress-iOS/issues/4419
        if didSetupView && needsRefreshCachedCellHeightsBeforeLayout {
            needsRefreshCachedCellHeightsBeforeLayout = false

            let width = view.frame.width
            tableViewHandler.refreshCachedRowHeightsForWidth(width)

            if let indexPaths = tableView.indexPathsForVisibleRows {
                tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: .None)
            }
        }
    }

    public override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        needsRefreshCachedCellHeightsBeforeLayout = true
    }


    // MARK: - Split view support

    public func handleApplicationDidBecomeActive(notification:NSNotification) {
        needsRefreshCachedCellHeightsBeforeLayout = true
    }


    // MARK: - Topic acquisition

    private func fetchSiteTopic() {
        if isViewLoaded() {
            displayLoadingStream()
        }
        assert(siteID != nil, "A siteID is required before fetching a site topic")
        let service = ReaderTopicService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.siteTopicForSiteWithID(siteID!,
            isFeed:isFeed,
            success: { [weak self] (objectID:NSManagedObjectID!, isFollowing:Bool) -> Void in
                do {
                    let context = ContextManager.sharedInstance().mainContext
                    let topic = try context.existingObjectWithID(objectID) as? ReaderAbstractTopic
                    self?.readerTopic = topic
                } catch let error as NSError {
                    DDLogSwift.logError(error.localizedDescription)
                }
            },
            failure: {[weak self] (error:NSError!) -> Void in
                self?.displayLoadingStreamFailed()
            })
    }

    private func fetchTagTopic() {
        if isViewLoaded() {
            displayLoadingStream()
        }
        assert(tagSlug != nil, "A tag slug is requred before fetching a tag topic");
        let service = ReaderTopicService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.tagTopicForTagWithSlug(tagSlug,
            success: { [weak self] (objectID:NSManagedObjectID!) -> Void in
                do {
                    let context = ContextManager.sharedInstance().mainContext
                    let topic = try context.existingObjectWithID(objectID) as? ReaderAbstractTopic
                    self?.readerTopic = topic
                } catch let error as NSError {
                    DDLogSwift.logError(error.localizedDescription)
                }
            }, failure: { [weak self] (error:NSError!) -> Void in
                self?.displayLoadingStreamFailed()
            })
    }


    // MARK: - Setup

    private func setupTableView() {
        assert(tableViewController != nil, "The tableViewController must be assigned before configuring the tableView")

        tableView = tableViewController.tableView
        tableView.separatorStyle = .None
        refreshControl = tableViewController.refreshControl!
        refreshControl.addTarget(self, action: #selector(ReaderStreamViewController.handleRefresh(_:)), forControlEvents: .ValueChanged)

        var nib = UINib(nibName: readerCardCellNibName, bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: readerCardCellReuseIdentifier)

        nib = UINib(nibName: readerBlockedCellNibName, bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: readerBlockedCellReuseIdentifier)

        nib = UINib(nibName: readerGapMarkerCellNibName, bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: readerGapMarkerCellReuseIdentifier)

        nib = UINib(nibName: readerCrossPostCellNibName, bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: readerCrossPostCellReuseIdentifier)
    }

    private func setupTableViewHandler() {
        assert(tableView != nil, "A tableView must be assigned before configuring a handler")

        tableViewHandler = WPTableViewHandler(tableView: tableView)
        tableViewHandler.cacheRowHeights = true
        tableViewHandler.updateRowAnimation = .None
        tableViewHandler.delegate = self
    }

    private func setupSyncHelper() {
        syncHelper = WPContentSyncHelper()
        syncHelper.delegate = self
    }

    private func setupCellForLayout() {
        // Construct the layout cells
        cellForLayout = NSBundle.mainBundle().loadNibNamed(readerCardCellNibName, owner: nil, options: nil).first as! ReaderPostCardCell
        crossPostCellForLayout = NSBundle.mainBundle().loadNibNamed(readerCrossPostCellNibName, owner: nil, options: nil).first as! ReaderCrossPostCell

        // Add layout cells to superview (briefly) so constraint constants reflect the correct size class.
        view.addSubview(cellForLayout)
        cellForLayout.removeFromSuperview()

        view.addSubview(crossPostCellForLayout)
        crossPostCellForLayout.removeFromSuperview()
    }

    private func setupResultsStatusView() {
        resultsStatusView = WPNoResultsView()
    }

    private func setupFooterView() {
        footerView = NSBundle.mainBundle().loadNibNamed(footerViewNibName, owner: nil, options: nil).first as! PostListFooterView
        footerView.showSpinner(false)
        var frame = footerView.frame
        frame.size.height = heightForFooterView
        footerView.frame = frame
        tableView.tableFooterView = footerView
    }


    // MARK: - Handling Loading and No Results

    func displayLoadingStream() {
        resultsStatusView.titleText = NSLocalizedString("Loading stream...", comment:"A short message to inform the user the requested stream is being loaded.")
        resultsStatusView.messageText = ""
        displayResultsStatus()
    }

    func displayLoadingStreamFailed() {
        resultsStatusView.titleText = NSLocalizedString("Problem loading stream", comment:"Error message title informing the user that a stream could not be loaded.");
        resultsStatusView.messageText = NSLocalizedString("Sorry. The stream could not be loaded.", comment:"A short error message leting the user know the requested stream could not be loaded.");
        displayResultsStatus()
    }

    func displayLoadingViewIfNeeded() {
        let count = tableViewHandler.resultsController.fetchedObjects?.count ?? 0
        if count > 0 {
            return
        }

        tableView.tableHeaderView?.hidden = true
        resultsStatusView.titleText = NSLocalizedString("Fetching posts...", comment:"A brief prompt shown when the reader is empty, letting the user know the app is currently fetching new posts.")
        resultsStatusView.messageText = ""

        let boxView = WPAnimatedBox.newAnimatedBox()
        resultsStatusView.accessoryView = boxView
        displayResultsStatus()
        boxView.prepareAndAnimateAfterDelay(0.3)
    }

    func displayNoResultsView() {
        // Its possible the topic was deleted before a sync could be completed,
        // so make certain its not nil.
        if readerTopic == nil {
            return
        }
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
        footerView.hidden = true
    }

    func hideResultsStatus() {
        resultsStatusView.removeFromSuperview()
        footerView.hidden = false
        tableView.tableHeaderView?.hidden = false
    }


    // MARK: - Configuration / Topic Presentation

    func configureStreamHeader() {
        assert(readerTopic != nil, "A reader topic is required")

        let header:ReaderStreamHeader? = ReaderStreamViewController.headerForStream(readerTopic!)
        if header == nil {
            if UIDevice.isPad() {
                let headerView = UIView(frame: frameForEmptyHeaderView)
                headerView.backgroundColor = UIColor.clearColor()
                tableView.tableHeaderView = headerView
            } else {
                tableView.tableHeaderView = nil
            }
            return
        }

        header!.enableLoggedInFeatures(isLoggedIn)
        header!.configureHeader(readerTopic!)
        header!.delegate = self

        tableView.tableHeaderView = header as? UIView
        refreshTableViewHeaderLayout()
    }

    func configureControllerForTopic() {
        assert(readerTopic != nil, "A reader topic is required")
        assert(isViewLoaded(), "The controller's view must be loaded before displaying the topic")

        // Rather than repeatedly creating a service to check if the user is logged in, cache it here.
        let service = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        let account = service.defaultWordPressComAccount()
        isLoggedIn = account != nil

        // Reset our display context to ensure its current. 
        managedObjectContext().reset()

        configureTitleForTopic()
        hideResultsStatus()
        recentlyBlockedSitePostObjectIDs.removeAllObjects()
        updateAndPerformFetchRequest()
        configureStreamHeader()
        tableView.setContentOffset(CGPointZero, animated: false)
        tableViewHandler.refreshTableView()
        syncIfAppropriate()

        let count = tableViewHandler.resultsController.fetchedObjects?.count ?? 0

        // Make sure we're showing the no results view if appropriate
        if !syncHelper.isSyncing && count == 0 {
            displayNoResultsView()
        }

        if !listentingForBlockedSiteNotification {
            listentingForBlockedSiteNotification = true
            NSNotificationCenter.defaultCenter().addObserver(self,
                selector: #selector(ReaderStreamViewController.handleBlockSiteNotification(_:)),
                name: ReaderPostMenu.BlockSiteNotification,
                object: nil)
        }

        ReaderHelpers.trackLoadedTopic(readerTopic!, withProperties: topicPropertyForStats())
    }

    func configureTitleForTopic() {
        if readerTopic == nil {
            title = NSLocalizedString("Reader", comment: "The default title of the Reader")
            return
        }
        if readerTopic?.type == ReaderSiteTopic.TopicType {
            title = NSLocalizedString("Site Details", comment: "The title of the reader when previewing posts from a site.")
            return
        }

        title = readerTopic?.title
    }


    // MARK: - Instance Methods

    func postInMainContext(post:ReaderPost) -> ReaderPost? {
        do {
            return try ContextManager.sharedInstance().mainContext.existingObjectWithID(post.objectID) as? ReaderPost
        } catch let error as NSError {
            DDLogSwift.logError("\(error.localizedDescription)")
        }
        return nil
    }

    func refreshTableViewHeaderLayout() {
        if tableView.tableHeaderView == nil {
            return
        }
        let headerView = tableView.tableHeaderView!

        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()

        let height = headerView.sizeThatFits(CGSize(width: tableView.frame.size.width, height: CGFloat.max)).height
        var frame = headerView.frame
        frame.size.height = height
        headerView.frame = frame

        tableView.tableHeaderView = headerView
    }

    public func scrollViewToTop() {
        tableView.setContentOffset(CGPoint.zero, animated: true)
    }

    private func topicPropertyForStats() -> [NSObject: AnyObject] {
        assert(readerTopic != nil, "A reader topic is required")
        let title = readerTopic!.title ?? ""
        var key: String = "list"
        if ReaderHelpers.isTopicTag(readerTopic!) {
            key = "tag"
        } else if ReaderHelpers.isTopicSite(readerTopic!) {
            key = "site"
        }
        return [key : title]
    }

    private func shouldShowBlockSiteMenuItem() -> Bool {
        if (isLoggedIn) {
            return ReaderHelpers.isTopicTag(readerTopic!) || ReaderHelpers.topicIsFreshlyPressed(readerTopic!)
        }
        return false
    }

    private func showMenuForPost(post:ReaderPost, fromView anchorView:UIView) {
        objectIDOfPostForMenu = post.objectID
        anchorViewForMenu = anchorView

        // Create the action sheet
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        alertController.addCancelActionWithTitle(ActionSheetButtonTitles.cancel,
            handler: { (action:UIAlertAction) in
                self.cleanUpAfterPostMenu()
            })

        // Block button
        if shouldShowBlockSiteMenuItem() {
            alertController.addActionWithTitle(ActionSheetButtonTitles.blockSite,
                style: .Destructive,
                handler: { (action:UIAlertAction) in
                    if let post = self.postForObjectIDOfPostForMenu() {
                        self.blockSiteForPost(post)
                    }
                    self.cleanUpAfterPostMenu()
                })
        }

        // Following
        if ReaderHelpers.topicIsFollowing(readerTopic!) {
            let buttonTitle = post.isFollowing ? ActionSheetButtonTitles.unfollow : ActionSheetButtonTitles.follow
            alertController.addActionWithTitle(buttonTitle,
                style: .Default,
                handler: { (action:UIAlertAction) in
                    if let post = self.postForObjectIDOfPostForMenu() {
                        self.toggleFollowingForPost(post)
                    }
                    self.cleanUpAfterPostMenu()
                })
        }

        // Visit site
        alertController.addActionWithTitle(ActionSheetButtonTitles.visit,
            style: .Default,
            handler: { (action:UIAlertAction) in
                if let post = self.postForObjectIDOfPostForMenu() {
                    self.visitSiteForPost(post)
                }
                self.cleanUpAfterPostMenu()
        })

        // Share
        alertController.addActionWithTitle(ActionSheetButtonTitles.share,
            style: .Default,
            handler: { (action:UIAlertAction) in
                if let post = self.postForObjectIDOfPostForMenu() {
                    self.sharePost(post)
                }
                self.cleanUpAfterPostMenu()
        })

        if UIDevice.isPad() {
            alertController.modalPresentationStyle = .Popover
            presentViewController(alertController, animated: true, completion: nil)
            let presentationController = alertController.popoverPresentationController
            presentationController?.permittedArrowDirections = .Any
            presentationController?.sourceView = anchorViewForMenu!
            presentationController?.sourceRect = anchorViewForMenu!.bounds

        } else {
            presentViewController(alertController, animated: true, completion: nil)
        }
    }

    private func postForObjectIDOfPostForMenu() -> ReaderPost? {
        do {
            return try managedObjectContext().existingObjectWithID(objectIDOfPostForMenu!) as? ReaderPost
        } catch let error as NSError {
            DDLogSwift.logError(error.localizedDescription)
            return nil
        }
    }

    private func cleanUpAfterPostMenu() {
        objectIDOfPostForMenu = nil
        anchorViewForMenu = nil
    }

    private func sharePost(post: ReaderPost) {
        let controller = ReaderHelpers.shareController(
            post.titleForDisplay(),
            summary: post.contentPreviewForDisplay(),
            tags: post.tags,
            link: post.permaLink
        )

        if !UIDevice.isPad() {
            presentViewController(controller, animated: true, completion: nil)
            return
        }

        // Silly iPad popover rules.
        controller.modalPresentationStyle = .Popover
        presentViewController(controller, animated: true, completion: nil)
        let presentationController = controller.popoverPresentationController
        presentationController?.permittedArrowDirections = .Unknown
        presentationController?.sourceView = anchorViewForMenu!
        presentationController?.sourceRect = anchorViewForMenu!.bounds
    }

    private func toggleFollowingForPost(post:ReaderPost) {
        var successMessage:String!
        var errorMessage:String!
        var errorTitle:String!
        if post.isFollowing {
            successMessage = NSLocalizedString("Unfollowed site", comment: "Short confirmation that unfollowing a site was successful")
            errorTitle = NSLocalizedString("Problem Unfollowing Site", comment: "Title of a prompt")
            errorMessage = NSLocalizedString("There was a problem unfollowing the site. If the problem persists you can contact us via the Me > Help & Support screen.", comment: "Short notice that there was a problem unfollowing a site and instructions on how to notify us of the problem.")
        } else {
            successMessage = NSLocalizedString("Followed site", comment: "Short confirmation that unfollowing a site was successful")
            errorTitle = NSLocalizedString("Problem Following Site", comment: "Title of a prompt")
            errorMessage = NSLocalizedString("There was a problem following the site.  If the problem persists you can contact us via the Me > Help & Support screen.", comment: "Short notice that there was a problem following a site and instructions on how to notify us of the problem.")
        }

        SVProgressHUD.show()
        let postService = ReaderPostService(managedObjectContext: managedObjectContext())
        postService.toggleFollowingForPost(post, success: { () -> Void in
                SVProgressHUD.showSuccessWithStatus(successMessage)
            }, failure: { (error:NSError!) -> Void in
                SVProgressHUD.dismiss()

                let cancelTitle = NSLocalizedString("OK", comment: "Text of an OK button to dismiss a prompt.")
                let alertController = UIAlertController(title: errorTitle,
                    message: errorMessage,
                    preferredStyle: .Alert)
                alertController.addCancelActionWithTitle(cancelTitle, handler: nil)
                alertController.presentFromRootViewController()
        })
    }

    private func visitSiteForPost(post:ReaderPost) {
        let siteURL = NSURL(string: post.blogURL)!
        let controller = WPWebViewController(URL: siteURL)
        let navController = UINavigationController(rootViewController: controller)
        presentViewController(navController, animated: true, completion: nil)
    }

    private func showAttributionForPost(post: ReaderPost) {
        // Fail safe. If there is no attribution exit.
        if post.sourceAttribution == nil {
            return
        }

        // If there is a blogID preview the site
        if post.sourceAttribution!.blogID != nil {
            let controller = ReaderStreamViewController.controllerWithSiteID(post.sourceAttribution!.blogID, isFeed: false)
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

        tableViewHandler.resultsController.fetchRequest.predicate = predicateForFetchRequest()
        do {
            try tableViewHandler.resultsController.performFetch()
        } catch let error as NSError {
            DDLogSwift.logError("Error fetching posts after updating the fetch reqeust predicate: \(error.localizedDescription)")
        }
    }

    func updateStreamHeaderIfNeeded() {
        assert(readerTopic != nil, "A reader topic is required")

        guard let header = tableView.tableHeaderView as? ReaderStreamHeader else {
            return
        }

        header.configureHeader(readerTopic!)
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

                let errorTitle = NSLocalizedString("Error Blocking Site", comment:"Title of a prompt letting the user know there was an error trying to block a site from appearing in the reader.")
                let cancelTitle = NSLocalizedString("OK", comment:"Text for an alert's dismissal button.")
                let alertController = UIAlertController(title: errorTitle,
                    message: error.localizedDescription,
                    preferredStyle: .Alert)
                alertController.addCancelActionWithTitle(cancelTitle, handler: nil)
                alertController.presentFromRootViewController()
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
            asBlocked: false,
            success: nil,
            failure: { [weak self] (error:NSError!) in
                self?.recentlyBlockedSitePostObjectIDs.addObject(objectID)
                self?.tableViewHandler.invalidateCachedRowHeightAtIndexPath(indexPath)
                self?.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)

                let errorTitle = NSLocalizedString("Error Unblocking Site", comment:"Title of a prompt letting the user know there was an error trying to unblock a site from appearing in the reader.")
                let cancelTitle = NSLocalizedString("OK", comment:"Text for an alert's dismissal button.")
                let alertController = UIAlertController(title: errorTitle,
                    message: error.localizedDescription,
                    preferredStyle: .Alert)
                alertController.addCancelActionWithTitle(cancelTitle, handler: nil)
                alertController.presentFromRootViewController()
            })
    }


    func handleBlockSiteNotification(notification:NSNotification) {
        guard let userInfo = notification.userInfo, aPost = userInfo["post"] as? ReaderPost else {
            return
        }

        do {
            guard let post = try managedObjectContext().existingObjectWithID(aPost.objectID) as? ReaderPost else {
                return
            }

            if let _ = tableViewHandler.resultsController.indexPathForObject(post) {
                blockSiteForPost(post)
            }

        } catch let error as NSError {
            DDLogSwift.logError("Error fetching existing post from context: \(error.localizedDescription)")
        }
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

    func updateLastSyncedForTopic(objectID:NSManagedObjectID) {
        do {
            let topic = try managedObjectContext().existingObjectWithID(objectID) as! ReaderAbstractTopic
            topic.lastSynced = NSDate()
            ContextManager.sharedInstance().saveContext(managedObjectContext())
        } catch let error as NSError {
            DDLogSwift.logError("Failed to update topic last synced date: \(error.localizedDescription)")
        }
    }

    func canSync() -> Bool {
        let appDelegate = WordPressAppDelegate.sharedInstance()
        return (readerTopic != nil) && appDelegate.connectionAvailable
    }

    func canLoadMore() -> Bool {
        let fetchedObjects = tableViewHandler.resultsController.fetchedObjects ?? []
        if fetchedObjects.count == 0 {
            return false
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
        if WordPressAppDelegate.sharedInstance().testSuiteIsRunning {
            return
        }
        let lastSynced = readerTopic?.lastSynced == nil ? NSDate(timeIntervalSince1970: 0) : readerTopic!.lastSynced
        if canSync() && Int(lastSynced.timeIntervalSinceNow) < refreshInterval {
            syncHelper.syncContentWithUserInteraction(false)
        }
    }

    func syncFillingGap(indexPath:NSIndexPath) {
        if !canSync() {
            let alertTitle = NSLocalizedString("Unable to Load Posts", comment: "Title of a prompt saying the app needs an internet connection before it can load posts")
            let alertMessage = NSLocalizedString("Please check your internet connection and try again.", comment: "Politely asks the user to check their internet connection before trying again. ")
            let cancelTitle = NSLocalizedString("OK", comment: "Title of a button that dismisses a prompt")
            let alertController = UIAlertController(title: alertTitle,
                message: alertMessage,
                preferredStyle: .Alert)
            alertController.addCancelActionWithTitle(cancelTitle, handler: nil)
            alertController.presentFromRootViewController()

            return
        }
        if syncHelper.isSyncing {
            let alertTitle = NSLocalizedString("Busy", comment: "Title of a prompt letting the user know that they must wait until the current aciton completes.")
            let alertMessage = NSLocalizedString("Please wait til the current fetch completes.", comment: "Asks the usre to wait until the currently running fetch request completes.")
            let cancelTitle = NSLocalizedString("OK", comment: "Title of a button that dismisses a prompt")
            let alertController = UIAlertController(title: alertTitle,
                message: alertMessage,
                preferredStyle: .Alert)
            alertController.addCancelActionWithTitle(cancelTitle, handler: nil)
            alertController.presentFromRootViewController()

            return
        }
        indexPathForGapMarker = indexPath
        syncIsFillingGap = true
        syncHelper.syncContentWithUserInteraction(true)
    }

    func syncItems(success:((hasMore: Bool) -> Void)?, failure: ((error: NSError) -> Void)?) {
        let syncContext = ContextManager.sharedInstance().newDerivedContext()
        let service =  ReaderPostService(managedObjectContext: syncContext)

        syncContext.performBlock {[weak self] () -> Void in
            do {
                let topic = try syncContext.existingObjectWithID(self!.readerTopic!.objectID) as! ReaderAbstractTopic
                let objectID = topic.objectID
                service.fetchPostsForTopic(topic,
                    earlierThan: NSDate(),
                    success: {[weak self] (count:Int, hasMore:Bool) in
                        dispatch_async(dispatch_get_main_queue(), {
                            if let strongSelf = self {
                                if strongSelf.recentlyBlockedSitePostObjectIDs.count > 0 {
                                    strongSelf.recentlyBlockedSitePostObjectIDs.removeAllObjects()
                                    strongSelf.updateAndPerformFetchRequest()
                                }
                                strongSelf.updateLastSyncedForTopic(objectID)
                            }
                            success?(hasMore: hasMore)
                        })
                    }, failure: { (error:NSError!) in
                        dispatch_async(dispatch_get_main_queue(), {
                            failure?(error: error)
                        })
                })

            } catch let error as NSError {
                DDLogSwift.logError(error.localizedDescription)
            }
        }
    }

    func syncItemsForGap(success:((hasMore: Bool) -> Void)?, failure: ((error: NSError) -> Void)?) {
        assert(syncIsFillingGap)
        assert(indexPathForGapMarker != nil)

        let post = tableViewHandler.resultsController.objectAtIndexPath(indexPathForGapMarker!) as? ReaderGapMarker
        if post == nil {
            // failsafe
            return
        }

        // Reload the gap cell so it will start animating.
        tableView.reloadRowsAtIndexPaths([indexPathForGapMarker!], withRowAnimation: .None)

        let syncContext = ContextManager.sharedInstance().newDerivedContext()
        let service =  ReaderPostService(managedObjectContext: syncContext)
        let sortDate = post!.sortDate

        syncContext.performBlock {[weak self] () -> Void in
            do {
                let topic = try syncContext.existingObjectWithID(self!.readerTopic!.objectID) as! ReaderAbstractTopic
                service.fetchPostsForTopic(topic,
                    earlierThan:sortDate,
                    deletingEarlier:true,
                    success: {[weak self] (count:Int, hasMore:Bool) in
                        dispatch_async(dispatch_get_main_queue(), {
                            if let strongSelf = self {
                                if strongSelf.recentlyBlockedSitePostObjectIDs.count > 0 {
                                    strongSelf.recentlyBlockedSitePostObjectIDs.removeAllObjects()
                                    strongSelf.updateAndPerformFetchRequest()
                                }
                            }

                            success?(hasMore: hasMore)
                        })
                    }, failure: { (error:NSError!) in
                        dispatch_async(dispatch_get_main_queue(), {
                            failure?(error: error)
                        })
                })

            } catch let error as NSError {
                DDLogSwift.logError(error.localizedDescription)
            }
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

            do  {
                let topic = try syncContext.existingObjectWithID(self!.readerTopic!.objectID) as! ReaderAbstractTopic
                service.fetchPostsForTopic(topic,
                    earlierThan: earlierThan,
                    success: { (count:Int, hasMore:Bool) -> Void in
                        dispatch_async(dispatch_get_main_queue(), {
                            success?(hasMore: hasMore)
                        })
                    },
                    failure: { (error:NSError!) -> Void in
                        dispatch_async(dispatch_get_main_queue(), {
                            failure?(error: error)
                        })
                })
            } catch let error as NSError {
                DDLogSwift.logError(error.localizedDescription)
            }
        }

        WPAppAnalytics.track(.ReaderInfiniteScroll, withProperties: topicPropertyForStats())
    }

    func syncHelper(syncHelper: WPContentSyncHelper, syncContentWithUserInteraction userInteraction: Bool, success: ((hasMore: Bool) -> Void)?, failure: ((error: NSError) -> Void)?) {
        displayLoadingViewIfNeeded()
        if syncIsFillingGap {
            syncItemsForGap(success, failure: failure)
        } else {
            syncItems(success, failure: failure)
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
        syncIsFillingGap = false
        indexPathForGapMarker = nil
        cleanupAndRefreshAfterScrolling = false
        tableViewHandler.refreshTableViewPreservingOffset()
        refreshControl.endRefreshing()
        footerView.showSpinner(false)
    }

    public func tableViewHandlerWillRefreshTableViewPreservingOffset(tableViewHandler: WPTableViewHandler!) {
        // Reload the table view to reflect new content.
        managedObjectContext().reset()
        updateAndPerformFetchRequest()
    }

    public func tableViewHandlerDidRefreshTableViewPreservingOffset(tableViewHandler: WPTableViewHandler!) {
        if self.tableViewHandler.resultsController.fetchedObjects?.count == 0 {
            displayNoResultsView()
        } else {
            hideResultsStatus()
        }
    }


    // MARK: - Helpers for TableViewHandler

    func predicateForFetchRequest() -> NSPredicate {
        if readerTopic == nil {
            return NSPredicate(format: "topic = NULL")
        }

        var topic: ReaderAbstractTopic!
        do {
            topic = try managedObjectContext().existingObjectWithID(readerTopic!.objectID) as! ReaderAbstractTopic
        } catch let error as NSError {
            DDLogSwift.logError(error.description)
            return NSPredicate(format: "topic = NULL")
        }

        if recentlyBlockedSitePostObjectIDs.count > 0 {
            return NSPredicate(format: "topic = %@ AND (isSiteBlocked = NO OR SELF in %@)", topic, recentlyBlockedSitePostObjectIDs)
        }

        return NSPredicate(format: "topic = %@ AND isSiteBlocked = NO", topic)
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
    }

    public func scrollViewDidEndDecelerating(scrollView: UIScrollView!) {
        if cleanupAndRefreshAfterScrolling {
            cleanupAfterSync()
        }
    }

    public func managedObjectContext() -> NSManagedObjectContext {
        if let context = displayContext {
            return context
        }

        displayContext = ContextManager.sharedInstance().newMainContextChildContext()

        let mainContext = ContextManager.sharedInstance().mainContext
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ReaderStreamViewController.handleContextDidSaveNotification(_:)), name: NSManagedObjectContextDidSaveNotification, object: mainContext)

        return displayContext!
    }

    func handleContextDidSaveNotification(notification:NSNotification) {
        // We want to ignore these notifications when our view has focus so as not
        // to conflict with the list refresh mechanism. 
        if view.window != nil {
            return
        }
        displayContext?.mergeChangesFromContextDidSaveNotification(notification)
    }

    public func fetchRequest() -> NSFetchRequest? {
        if readerTopic == nil {
            return nil
        }

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

        let posts = tableViewHandler.resultsController.fetchedObjects as! [ReaderPost]
        let post = posts[indexPath.row]

        if post.isKindOfClass(ReaderGapMarker) {
            return gapMarkerRowHeight
        }

        if recentlyBlockedSitePostObjectIDs.containsObject(post.objectID) {
            return blockedRowHeight
        }

        if post.isCrossPost() {
            configureCrossPostCell(crossPostCellForLayout, atIndexPath: indexPath)
            let size = crossPostCellForLayout.sizeThatFits(CGSize(width:width, height:CGFloat.max))
            return size.height
        }

        configureCell(cellForLayout, atIndexPath: indexPath)
        let size = cellForLayout.sizeThatFits(CGSize(width:width, height:CGFloat.max))
        return size.height
    }

    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell? {
        let posts = tableViewHandler.resultsController.fetchedObjects as! [ReaderPost]
        let post = posts[indexPath.row]

        if post.isKindOfClass(ReaderGapMarker) {
            let cell = tableView.dequeueReusableCellWithIdentifier(readerGapMarkerCellReuseIdentifier) as! ReaderGapMarkerCell
            configureGapMarker(cell)
            return cell
        }

        if recentlyBlockedSitePostObjectIDs.containsObject(post.objectID) {
            let cell = tableView.dequeueReusableCellWithIdentifier(readerBlockedCellReuseIdentifier) as! ReaderBlockedSiteCell
            configureBlockedCell(cell, atIndexPath: indexPath)
            return cell
        }

        if post.isCrossPost() {
            let cell = tableView.dequeueReusableCellWithIdentifier(readerCrossPostCellReuseIdentifier) as! ReaderCrossPostCell
            configureCrossPostCell(cell, atIndexPath: indexPath)
            return cell;
        }

        let cell = tableView.dequeueReusableCellWithIdentifier(readerCardCellReuseIdentifier) as! ReaderPostCardCell
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    public func tableView(tableView: UITableView!, willDisplayCell cell: UITableViewCell!, forRowAtIndexPath indexPath: NSIndexPath!) {
        // Check to see if we need to load more.
        let criticalRow = tableView.numberOfRowsInSection(indexPath.section) - loadMoreThreashold
        if (indexPath.section == tableView.numberOfSections - 1) && (indexPath.row >= criticalRow) {
            if syncHelper.hasMoreContent {
                syncHelper.syncMoreContent()
            }
        }
    }

    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)

        guard let posts = tableViewHandler.resultsController.fetchedObjects as? [ReaderPost] else {
            DDLogSwift.logError("[ReaderStreamViewController tableView:didSelectRowAtIndexPath:] fetchedObjects was nil.")
            return
        }

        var post = posts[indexPath.row]

        if post.isKindOfClass(ReaderGapMarker) {
            syncFillingGap(indexPath)
            return
        }

        if recentlyBlockedSitePostObjectIDs.containsObject(post.objectID) {
            unblockSiteForPost(post)
            return
        }

        var controller: ReaderDetailViewController?
        if post.sourceAttributionStyle() == .Post &&
            post.sourceAttribution.postID != nil &&
            post.sourceAttribution.blogID != nil {

            controller = ReaderDetailViewController.controllerWithPostID(post.sourceAttribution.postID!, siteID: post.sourceAttribution.blogID!)

        } else if post.isCrossPost() {
            controller = ReaderDetailViewController.controllerWithPostID(post.crossPostMeta.postID, siteID: post.crossPostMeta.siteID)

        } else {
            post = postInMainContext(post)!
            controller = ReaderDetailViewController.controllerWithPost(post)
        }

        navigationController?.pushViewController(controller!, animated: true)
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
        let layoutOnly = postCell == cellForLayout

        postCell.enableLoggedInFeatures = isLoggedIn
        postCell.blogNameButtonIsEnabled = !ReaderHelpers.isTopicSite(readerTopic!)
        postCell.configureCell(post, layoutOnly: layoutOnly)
        postCell.delegate = self
    }

    public func configureCrossPostCell(cell: ReaderCrossPostCell, atIndexPath indexPath:NSIndexPath) {
        if tableViewHandler.resultsController.fetchedObjects == nil {
            return
        }
        cell.accessoryType = .None
        cell.selectionStyle = .None

        let posts = tableViewHandler.resultsController.fetchedObjects as! [ReaderPost]
        let post = posts[indexPath.row]
        cell.configureCell(post)
    }

    public func configureBlockedCell(cell: ReaderBlockedSiteCell, atIndexPath indexPath: NSIndexPath) {
        if tableViewHandler.resultsController.fetchedObjects == nil {
            return
        }
        cell.accessoryType = .None
        cell.selectionStyle = .None

        let posts = tableViewHandler.resultsController.fetchedObjects as! [ReaderPost]
        let post = posts[indexPath.row]
        cell.setSiteName(post.blogName)
    }

    public func configureGapMarker(cell: ReaderGapMarkerCell) {
        cell.animateActivityView(syncIsFillingGap)
    }


    // MARK: - ReaderStreamHeader Delegate Methods

    public func handleFollowActionForHeader(header:ReaderStreamHeader) {
        // Toggle following for the topic
        if readerTopic!.isKindOfClass(ReaderTagTopic) {
            toggleFollowingForTag(readerTopic as! ReaderTagTopic)
        } else if readerTopic!.isKindOfClass(ReaderSiteTopic) {
            toggleFollowingForSite(readerTopic as! ReaderSiteTopic)
        }
    }

    func toggleFollowingForTag(topic:ReaderTagTopic) {
        let service = ReaderTopicService(managedObjectContext: topic.managedObjectContext)
        service.toggleFollowingForTag(topic, success: nil, failure: { (error:NSError!) -> Void in
            self.updateStreamHeaderIfNeeded()
        })
        self.updateStreamHeaderIfNeeded()
    }

    func toggleFollowingForSite(topic:ReaderSiteTopic) {
        let service = ReaderTopicService(managedObjectContext: topic.managedObjectContext)
        service.toggleFollowingForSite(topic, success:nil, failure: { (error:NSError!) -> Void in
            self.updateStreamHeaderIfNeeded()
        })
        self.updateStreamHeaderIfNeeded()
    }

    // MARK: - ReaderCard Delegate Methods

    public func readerCell(cell: ReaderPostCardCell, headerActionForProvider provider: ReaderPostContentProvider) {
        let post = provider as! ReaderPost

        let controller = ReaderStreamViewController.controllerWithSiteID(post.siteID, isFeed: post.isExternal)
        navigationController?.pushViewController(controller, animated: true)

        let properties = ReaderHelpers.statsPropertiesForPost(post, andValue: post.blogURL, forKey: "url")
        WPAppAnalytics.track(.ReaderSitePreviewed, withProperties: properties)
    }

    public func readerCell(cell: ReaderPostCardCell, commentActionForProvider provider: ReaderPostContentProvider) {
        var post = provider as! ReaderPost
        post = postInMainContext(post)!
        let controller = ReaderCommentsViewController(post: post)
        navigationController?.pushViewController(controller, animated: true)
    }

    public func readerCell(cell: ReaderPostCardCell, likeActionForProvider provider: ReaderPostContentProvider) {
        let post = provider as! ReaderPost
        toggleLikeForPost(post)
    }

    public func readerCell(cell: ReaderPostCardCell, tagActionForProvider provider: ReaderPostContentProvider) {
        let post = provider as! ReaderPost

        let controller = ReaderStreamViewController.controllerWithTagSlug(post.primaryTagSlug)
        navigationController?.pushViewController(controller, animated: true)

        let properties =  ReaderHelpers.statsPropertiesForPost(post, andValue: post.primaryTagSlug, forKey: "tag")
        WPAppAnalytics.track(.ReaderTagPreviewed, withProperties: properties)
    }

    public func readerCell(cell: ReaderPostCardCell, menuActionForProvider provider: ReaderPostContentProvider, fromView sender: UIView) {
        let post = provider as! ReaderPost
        showMenuForPost(post, fromView:sender)
    }

    public func readerCell(cell: ReaderPostCardCell, attributionActionForProvider provider: ReaderPostContentProvider) {
        let post = provider as! ReaderPost
        showAttributionForPost(post)
    }

}
