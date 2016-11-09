import Foundation
import SVProgressHUD
import WordPressShared
import WordPressComAnalytics

/// Displays a list of posts for a particular reader topic.
/// - note:
///   - Pull to refresh will load new content above the current content, preserving what is currently visible.
///   - Gaps in content are represented by a "Gap Marker" cell.
///   - This controller uses MULTIPLE NSManagedObjectContexts to manage syncing and state.
///     - The topic exists in the main context
///     - Syncing is performed on a derived (background) context.
///     - Content is fetched on a child context of the main context.  This allows
///         new content to be synced without interrupting the UI until desired.
///   - Row heights are auto-calculated via UITableViewAutomaticDimension and estimated heights
///         are cached via willDisplayCell.
///
@objc public class ReaderStreamViewController : UIViewController, UIViewControllerRestoration
{

    static let restorableTopicPathKey: String = "RestorableTopicPathKey"


    // MARK: - Properties

    private var tableView: UITableView!
    private var refreshControl: UIRefreshControl!
    private var tableViewHandler: WPTableViewHandler!
    private var syncHelper: WPContentSyncHelper!
    private var tableViewController: UITableViewController!
    private var resultsStatusView: WPNoResultsView!
    private var footerView: PostListFooterView!

    private let footerViewNibName = "PostListFooterView"
    private let readerCardCellNibName = "ReaderPostCardCell"
    private let readerCardCellReuseIdentifier = "ReaderCardCellReuseIdentifier"
    private let readerBlockedCellNibName = "ReaderBlockedSiteCell"
    private let readerBlockedCellReuseIdentifier = "ReaderBlockedCellReuseIdentifier"
    private let readerGapMarkerCellNibName = "ReaderGapMarkerCell"
    private let readerGapMarkerCellReuseIdentifier = "ReaderGapMarkerCellReuseIdentifier"
    private let readerCrossPostCellNibName = "ReaderCrossPostCell"
    private let readerCrossPostCellReuseIdentifier = "ReaderCrossPostCellReuseIdentifier"
    private let estimatedRowHeight = CGFloat(300.0)
    private let loadMoreThreashold = 4

    private let refreshInterval = 300
    private var cleanupAndRefreshAfterScrolling = false
    private let recentlyBlockedSitePostObjectIDs = NSMutableArray()
    private let frameForEmptyHeaderView = CGRect(x: 0.0, y: 0.0, width: 320.0, height: 30.0)
    private let heightForFooterView = CGFloat(34.0)
    private let estimatedHeightsCache = NSCache()
    private var isLoggedIn = false
    private var isFeed = false
    private var syncIsFillingGap = false
    private var indexPathForGapMarker: NSIndexPath?
    private var didSetupView = false
    private var listentingForBlockedSiteNotification = false
    private var imageRequestAuthToken: String?
    private var didBumpStats = false

    /// Used for fetching content.
    private lazy var displayContext = ContextManager.sharedInstance().newMainContextChildContext()


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
                // Fixes https://github.com/wordpress-mobile/WordPress-iOS/issues/5223
                title = tagSlug

                fetchTagTopic()
            }
        }
    }


    /// The topic can be nil while a site or tag topic is being fetched, hence, optional.
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


    /// Convenience method for instantiating an instance of ReaderStreamViewController
    /// for a existing topic.
    ///
    /// - Parameters:
    ///     - topic: Any subclass of ReaderAbstractTopic
    ///
    /// - Returns: An instance of the controller
    ///
    public class func controllerWithTopic(topic:ReaderAbstractTopic) -> ReaderStreamViewController {
        let storyboard = UIStoryboard(name: "Reader", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("ReaderStreamViewController") as! ReaderStreamViewController
        controller.readerTopic = topic

        return controller
    }


    /// Convenience method for instantiating an instance of ReaderStreamViewController
    /// for previewing the content of a site.
    ///
    /// - Parameters:
    ///     - siteID: The siteID of a blog to preview
    ///     - isFeed: If the site is an external feed (not hosted at WPcom and not using Jetpack)
    ///
    /// - Returns: An instance of the controller
    ///
    public class func controllerWithSiteID(siteID:NSNumber, isFeed:Bool) -> ReaderStreamViewController {
        let storyboard = UIStoryboard(name: "Reader", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("ReaderStreamViewController") as! ReaderStreamViewController
        controller.isFeed = isFeed
        controller.siteID = siteID

        return controller
    }


    /// Convenience method for instantiating an instance of ReaderStreamViewController
    /// to preview a tag.
    ///
    /// - Parameters:
    ///     - tagSlug: The slug of a tag to preview.
    ///
    /// - Returns: An instance of the controller
    ///
    public class func controllerWithTagSlug(tagSlug:String) -> ReaderStreamViewController {
        let storyboard = UIStoryboard(name: "Reader", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("ReaderStreamViewController") as! ReaderStreamViewController
        controller.tagSlug = tagSlug

        return controller
    }


    // MARK: - State Restoration


    public static func viewControllerWithRestorationIdentifierPath(identifierComponents: [AnyObject], coder: NSCoder) -> UIViewController? {
        guard let path = coder.decodeObjectForKey(restorableTopicPathKey) as? String else {
            return nil
        }

        let context = ContextManager.sharedInstance().mainContext
        let service = ReaderTopicService(managedObjectContext: context)
        guard let topic = service.findWithPath(path) else {
            return nil
        }

        topic.preserveForRestoration = false
        ContextManager.sharedInstance().saveContextAndWait(context)

        let storyboard = UIStoryboard(name: "Reader", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("ReaderStreamViewController") as! ReaderStreamViewController
        controller.readerTopic = topic
        return controller
    }


    public override func encodeRestorableStateWithCoder(coder: NSCoder) {
        if let topic = readerTopic {
            topic.preserveForRestoration = true
            ContextManager.sharedInstance().saveContextAndWait(topic.managedObjectContext)
            coder.encodeObject(topic.path, forKey: self.dynamicType.restorableTopicPathKey)
        }
        super.encodeRestorableStateWithCoder(coder)
    }


    // MARK: - LifeCycle Methods


    public override func awakeAfterUsingCoder(aDecoder: NSCoder) -> AnyObject? {
        restorationClass = self.dynamicType

        return super.awakeAfterUsingCoder(aDecoder)
    }


    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        tableViewController = segue.destinationViewController as? UITableViewController
    }


    public override func viewDidLoad() {
        super.viewDidLoad()

        // Disable the view until we have a topic.  This prevents a premature
        // pull to refresh animation.
        view.userInteractionEnabled = readerTopic != nil

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(defaultAccountDidChange(_:)), name: WPAccountDefaultWordPressComAccountChangedNotification, object: nil)
        refreshImageRequestAuthToken()

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


    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Trigger layouts, if needed, to correct for any inherited layout changes, such as margins.
        refreshTableHeaderIfNeeded()
    }


    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        let mainContext = ContextManager.sharedInstance().mainContext
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSManagedObjectContextDidSaveNotification, object: mainContext)

        bumpStats()
    }


    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        // We want to listen for any changes (following, liked) in a post detail so we can refresh the child context.
        let mainContext = ContextManager.sharedInstance().mainContext
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ReaderStreamViewController.handleContextDidSaveNotification(_:)), name: NSManagedObjectContextDidSaveNotification, object: mainContext)
    }


    public override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }


    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // There appears to be a scenario where this method can be called prior to
        // the view being fully setup in viewDidLoad.
        // See: https://github.com/wordpress-mobile/WordPress-iOS/issues/4419
        if didSetupView {
            refreshTableViewHeaderLayout()
        }
        centerResultsStatusViewIfNeeded()
    }


    // MARK: - Topic acquisition

    /// Fetches a site topic for the value of the `siteID` property.
    ///
    private func fetchSiteTopic() {
        if isViewLoaded() {
            displayLoadingStream()
        }
        assert(siteID != nil, "A siteID is required before fetching a site topic")
        let service = ReaderTopicService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.siteTopicForSiteWithID(siteID!,
            isFeed:isFeed,
            success: { [weak self] (objectID:NSManagedObjectID!, isFollowing:Bool) in

                let context = ContextManager.sharedInstance().mainContext
                guard let topic = (try? context.existingObjectWithID(objectID)) as? ReaderAbstractTopic else {
                    DDLogSwift.logError("Reader: Error retriving an existing site topic by its objectID")
                    self?.displayLoadingStreamFailed()
                    return
                }
                self?.readerTopic = topic

            },
            failure: { [weak self] (error:NSError!) in
                self?.displayLoadingStreamFailed()
            })
    }


    /// Fetches a tag topic for the value of the `tagSlug` property
    ///
    private func fetchTagTopic() {
        if isViewLoaded() {
            displayLoadingStream()
        }
        assert(tagSlug != nil, "A tag slug is requred before fetching a tag topic")
        let service = ReaderTopicService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.tagTopicForTagWithSlug(tagSlug,
            success: { [weak self] (objectID:NSManagedObjectID!) in

                let context = ContextManager.sharedInstance().mainContext
                guard let topic = (try? context.existingObjectWithID(objectID)) as? ReaderAbstractTopic else {
                    DDLogSwift.logError("Reader: Error retriving an existing tag topic by its objectID")
                    self?.displayLoadingStreamFailed()
                    return
                }
                self?.readerTopic = topic

            },
            failure: { [weak self] (error:NSError!) in
                self?.displayLoadingStreamFailed()
            })
    }


    // MARK: - Setup

    private func setupTableView() {
        assert(tableViewController != nil, "The tableViewController must be assigned before configuring the tableView")

        tableView = tableViewController.tableView
        tableView.accessibilityIdentifier = "Reader"
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
        tableViewHandler.cacheRowHeights = false
        tableViewHandler.updateRowAnimation = .None
        tableViewHandler.delegate = self
    }


    private func setupSyncHelper() {
        syncHelper = WPContentSyncHelper()
        syncHelper.delegate = self
    }

    private func setupResultsStatusView() {
        resultsStatusView = WPNoResultsView()
    }


    private func setupFooterView() {
        guard let footer = NSBundle.mainBundle().loadNibNamed(footerViewNibName, owner: nil, options: nil)!.first as? PostListFooterView else {
            assertionFailure()
            return
        }

        footerView = footer
        footerView.showSpinner(false)
        var frame = footerView.frame
        frame.size.height = heightForFooterView
        footerView.frame = frame
        tableView.tableFooterView = footerView
        footerView.hidden = true
    }


    // MARK: - Handling Loading and No Results

    func displayLoadingStream() {
        resultsStatusView.titleText = NSLocalizedString("Loading stream...", comment:"A short message to inform the user the requested stream is being loaded.")
        resultsStatusView.messageText = ""
        displayResultsStatus()
    }


    func displayLoadingStreamFailed() {
        resultsStatusView.titleText = NSLocalizedString("Problem loading stream", comment:"Error message title informing the user that a stream could not be loaded.")
        resultsStatusView.messageText = NSLocalizedString("Sorry. The stream could not be loaded.", comment:"A short error message leting the user know the requested stream could not be loaded.")
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
        resultsStatusView.buttonTitle = nil
        resultsStatusView.delegate = nil

        let boxView = WPAnimatedBox()
        resultsStatusView.accessoryView = boxView
        displayResultsStatus()
        boxView.animateAfterDelay(0.3)
    }


    func displayNoResultsView() {
        // Its possible the topic was deleted before a sync could be completed,
        // so make certain its not nil.
        guard let topic = readerTopic else {
            return
        }

        tableView.tableHeaderView?.hidden = true
        let response:NoResultsResponse = ReaderStreamViewController.responseForNoResults(topic)
        resultsStatusView.titleText = response.title
        resultsStatusView.messageText = response.message
        resultsStatusView.accessoryView = nil
        if ReaderHelpers.topicIsFollowing(topic) {
            resultsStatusView.buttonTitle = NSLocalizedString("Manage Sites", comment: "Button title. Tapping lets the user manage the sites they follow.")
            resultsStatusView.delegate = self
        } else {
            resultsStatusView.buttonTitle = nil
            resultsStatusView.delegate = nil
        }
        displayResultsStatus()
    }


    func displayResultsStatus() {
        if !resultsStatusView.isDescendantOfView(tableView) {
            tableView.addSubviewWithFadeAnimation(resultsStatusView)
        }
        resultsStatusView.centerInSuperview()
        footerView.hidden = true
    }


    func centerResultsStatusViewIfNeeded() {
        if resultsStatusView.isDescendantOfView(tableView) {
            resultsStatusView.centerInSuperview()
        }
    }


    func hideResultsStatus() {
        resultsStatusView.removeFromSuperview()
        footerView.hidden = false
        tableView.tableHeaderView?.hidden = false
    }


    // MARK: - Configuration / Topic Presentation


    func configureStreamHeader() {
        guard let topic = readerTopic else {
            assertionFailure()
            return
        }

        guard let header = ReaderStreamViewController.headerForStream(topic) else {
            tableView.tableHeaderView = nil
            return
        }

        header.enableLoggedInFeatures(isLoggedIn)
        header.configureHeader(readerTopic!)
        header.delegate = self

        tableView.tableHeaderView = header as? UIView
    }


    // Refresh the header of a site topic when returning in case the
    // topic's following status changed.
    func refreshTableHeaderIfNeeded() {
        guard let siteTopic = readerTopic as? ReaderSiteTopic,
            header = tableView.tableHeaderView as? ReaderStreamHeader else {
            return
        }
        header.configureHeader(siteTopic)
    }


    /// Configures the controller for the `readerTopic`.  This should only be called
    /// once when the topic is set.
    func configureControllerForTopic() {
        assert(readerTopic != nil, "A reader topic is required")
        assert(isViewLoaded(), "The controller's view must be loaded before displaying the topic")

        // Enable the view now that we have a topic.
        view.userInteractionEnabled = true

        if let topic = readerTopic where ReaderHelpers.isTopicSearchTopic(topic) || topic.path == nil {
            // Disable pull to refresh for search topics.
            // Searches are a snap shot in time, and ephemeral. There should be no
            // need to refresh.
            tableViewController.refreshControl = nil
        }

        // Rather than repeatedly creating a service to check if the user is logged in, cache it here.
        isLoggedIn = AccountHelper.isDotcomAvailable()

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

        bumpStats()

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
    }


    func configureTitleForTopic() {
        guard let topic = readerTopic else {
            title = NSLocalizedString("Reader", comment: "The default title of the Reader")
            return
        }
        if topic.type == ReaderSiteTopic.TopicType {
            title = NSLocalizedString("Site Details", comment: "The title of the reader when previewing posts from a site.")
            return
        }

        title = topic.title
    }


    /// Fetch and cache the current defaultAccount authtoken, if available.
    private func refreshImageRequestAuthToken() {
        let acctServ = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        imageRequestAuthToken = acctServ.defaultWordPressComAccount()?.authToken
    }


    // MARK: - Instance Methods


    /// Retrieve an instance of the specified post from the main NSManagedObjectContext.
    ///
    /// - Parameters:
    ///     - post: The post to retrieve.
    ///
    /// - Returns: The post fetched from the main context or nil if the post does not exist in the context.
    ///
    func postInMainContext(post:ReaderPost) -> ReaderPost? {
        guard let post = (try? ContextManager.sharedInstance().mainContext.existingObjectWithID(post.objectID)) as? ReaderPost else {
            DDLogSwift.logError("Error retrieving an exsting post from the main context by its object ID.")
            return nil
        }
        return post
    }


    /// Refreshes the layout of the header.  Required for sizing the tableHeaderView according
    /// to its intrinsic content layout, and after major layout changes on the viewcontroller itself.
    ///
    func refreshTableViewHeaderLayout() {
        guard let headerView = tableView.tableHeaderView else {
            return
        }

        // The tableView may need to layout, run this layout now, if needed.
        // This ensures the proper margins, such as readable margins, are
        // inherited and calculated by the headerView.
        tableView.layoutIfNeeded()

        // Start with the provided UILayoutFittingCompressedSize to let iOS handle its own magic
        // number for a "compressed" height, meaning we want our fitting size to be the minimal height.
        var fittingSize = UILayoutFittingCompressedSize

        // Set the width to the tableView's width since this is a known width for the headerView.
        // Otherwise, the layout will try and adopt 'any' width and may break based on the how
        // the constraints are set up in the nib.
        fittingSize.width = tableView.frame.size.width

        // Require horizontal fitting since our width is known.
        // Use the lower fitting size priority as we want to minimize our height consumption
        // according to the layout's contraints and intrinsic size.
        let size = headerView.systemLayoutSizeFittingSize(fittingSize,
                                                          withHorizontalFittingPriority: UILayoutPriorityRequired,
                                                          verticalFittingPriority: UILayoutPriorityFittingSizeLevel)
        // Update the tableHeaderView itself. Classic.
        var headerFrame = headerView.frame
        headerFrame.size.height = size.height
        headerView.frame = headerFrame
        tableView.tableHeaderView = headerView
    }


    /// Scrolls to the top of the list of posts.
    ///
    public func scrollViewToTop() {
        tableView.setContentOffset(CGPoint.zero, animated: true)
    }


    /// Returns the analytics property dictionary for the current topic.
    private func topicPropertyForStats() -> [NSObject: AnyObject]? {
        guard let topic = readerTopic else {
            assertionFailure("A reader topic is required")
            return nil
        }
        let title = topic.title ?? ""
        var key: String = "list"
        if ReaderHelpers.isTopicTag(topic) {
            key = "tag"
        } else if ReaderHelpers.isTopicSite(topic) {
            key = "site"
        }
        return [key : title]
    }


    private func shouldShowBlockSiteMenuItem() -> Bool {
        guard let topic = readerTopic else {
            return false
        }
        if (isLoggedIn) {
            return ReaderHelpers.isTopicTag(topic) || ReaderHelpers.topicIsFreshlyPressed(topic)
        }
        return false
    }


    /// Displays the options menu for the specifed post.  On the iPad the menu
    /// is displayed as a popover from the anchorview.
    ///
    /// - Parameters:
    ///     - post: The post in question.
    ///     - fromView: The view to anchor a popover.
    ///
    private func showMenuForPost(post:ReaderPost, fromView anchorView:UIView) {
        guard let topic = readerTopic else {
            return
        }

        // Create the action sheet
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        alertController.addCancelActionWithTitle(ReaderPostMenuButtonTitles.cancel, handler: nil)

        // Block button
        if shouldShowBlockSiteMenuItem() {
            alertController.addActionWithTitle(ReaderPostMenuButtonTitles.blockSite,
                style: .Destructive,
                handler: { (action:UIAlertAction) in
                    if let post = self.postWithObjectID(post.objectID) {
                        self.blockSiteForPost(post)
                    }
                })
        }

        // Following
        if ReaderHelpers.topicIsFollowing(topic) {
            let buttonTitle = post.isFollowing ? ReaderPostMenuButtonTitles.unfollow : ReaderPostMenuButtonTitles.follow
            alertController.addActionWithTitle(buttonTitle,
                style: .Default,
                handler: { (action:UIAlertAction) in
                    if let post = self.postWithObjectID(post.objectID) {
                        self.toggleFollowingForPost(post)
                    }
                })
        }

        // Visit site
        alertController.addActionWithTitle(ReaderPostMenuButtonTitles.visit,
            style: .Default,
            handler: { (action:UIAlertAction) in
                if let post = self.postWithObjectID(post.objectID) {
                    self.visitSiteForPost(post)
                }
        })

        // Share
        alertController.addActionWithTitle(ReaderPostMenuButtonTitles.share,
            style: .Default,
            handler: { [weak self] (action:UIAlertAction) in
                self?.sharePost(post.objectID, fromView: anchorView)
        })

        if WPDeviceIdentification.isiPad() {
            alertController.modalPresentationStyle = .Popover
            presentViewController(alertController, animated: true, completion: nil)
            if let presentationController = alertController.popoverPresentationController {
                presentationController.permittedArrowDirections = .Any
                presentationController.sourceView = anchorView
                presentationController.sourceRect = anchorView.bounds
            }

        } else {
            presentViewController(alertController, animated: true, completion: nil)
        }
    }


    /// Shares a post from the share controller.
    ///
    /// - Parameters:
    ///     - postID: Object ID for the post.
    ///     - fromView: The view to present the sharing controller as a popover.
    ///
    private func sharePost(postID: NSManagedObjectID, fromView anchorView: UIView) {
        if let post = self.postWithObjectID(postID) {
            let sharingController = PostSharingController()

            sharingController.shareReaderPost(post, fromView: anchorView, inViewController: self)
        }
    }


    /// Retrieves a post for the specified object ID from the display context.
    ///
    /// - Parameters:
    ///     - objectID: The object ID of the post.
    ///
    /// - Return: The matching post or nil if there is no match.
    ///
    private func postWithObjectID(objectID: NSManagedObjectID) -> ReaderPost? {
        do {
            return (try managedObjectContext().existingObjectWithID(objectID)) as? ReaderPost
        } catch let error as NSError {
            DDLogSwift.logError(error.localizedDescription)
            return nil
        }
    }


    private func toggleFollowingForPost(post:ReaderPost) {
        var successMessage:String
        var errorMessage:String
        var errorTitle:String
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
        postService.toggleFollowingForPost(post,
                                            success: {
                                                SVProgressHUD.showSuccessWithStatus(successMessage)
                                            },
                                            failure: { (error:NSError!) in
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
        guard
            let permalink = post.permaLink,
            let siteURL = NSURL(string: permalink) else {
                return
        }

        let controller = WPWebViewController(URL: siteURL)
        controller.addsWPComReferrer = true
        let navController = UINavigationController(rootViewController: controller)
        presentViewController(navController, animated: true, completion: nil)
    }


    /// Shows the attribution for a Discover post.
    ///
    private func showAttributionForPost(post: ReaderPost) {
        // Fail safe. If there is no attribution exit.
        guard let sourceAttribution = post.sourceAttribution else {
            return
        }

        // If there is a blogID preview the site
        if let blogID = sourceAttribution.blogID {
            let controller = ReaderStreamViewController.controllerWithSiteID(blogID, isFeed: false)
            navigationController?.pushViewController(controller, animated: true)
            return
        }

        if sourceAttribution.attributionType != SourcePostAttributionTypeSite {
            return
        }

        let linkURL = NSURL(string: sourceAttribution.blogURL)
        let controller = WPWebViewController(URL: linkURL)
        controller.addsWPComReferrer = true
        let navController = UINavigationController(rootViewController: controller)
        presentViewController(navController, animated: true, completion: nil)
    }


    private func toggleLikeForPost(post: ReaderPost) {
        if !post.isLiked {
            // Consider a like from the list to be enough to push a page view.
            // Solves a long-standing question from folks who ask 'why do I
            // have more likes than page views?'.
            ReaderHelpers.bumpPageViewForPost(post)
            WPNotificationFeedbackGenerator.notificationOccurred(.Success)
        }
        let service = ReaderPostService(managedObjectContext: managedObjectContext())
        service.toggleLikedForPost(post, success: nil, failure: { (error:NSError?) in
            if let anError = error {
                DDLogSwift.logError("Error (un)liking post: \(anError.localizedDescription)")
            }
        })
    }

    private func toggleSavedForPost(post: ReaderPost) {
        let service = ReaderPostService(managedObjectContext: managedObjectContext())
        service.toggleSavedForPost(post, success: nil, failure: { (error:NSError?) in
            if let anError = error {
                DDLogSwift.logError("Error (un)saving post: \(anError.localizedDescription)")
            }
        })
    }

    /// The fetch request can need a different predicate depending on how the content
    /// being displayed has changed (blocking sites for instance).  Call this method to
    /// update the fetch request predicate and then perform a new fetch.
    ///
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
        guard let topic = readerTopic else {
            assertionFailure("A reader topic is required")
            return
        }
        guard let header = tableView.tableHeaderView as? ReaderStreamHeader else {
            return
        }
        header.configureHeader(topic)
    }


    func showManageSites() {
        let controller = ReaderFollowedSitesViewController.controller()
        navigationController?.pushViewController(controller, animated: true)
    }


    // MARK: - Blocking


    private func blockSiteForPost(post: ReaderPost) {
        guard let indexPath = tableViewHandler.resultsController.indexPathForObject(post) else {
            return
        }

        let objectID = post.objectID
        recentlyBlockedSitePostObjectIDs.addObject(objectID)
        updateAndPerformFetchRequest()

        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)

        let service = ReaderSiteService(managedObjectContext: managedObjectContext())
        service.flagSiteWithID(post.siteID,
            asBlocked: true,
            success: nil,
            failure: { [weak self] (error:NSError?) in
                self?.recentlyBlockedSitePostObjectIDs.removeObject(objectID)
                self?.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)

                let message = error?.localizedDescription ?? ""
                let errorTitle = NSLocalizedString("Error Blocking Site", comment:"Title of a prompt letting the user know there was an error trying to block a site from appearing in the reader.")
                let cancelTitle = NSLocalizedString("OK", comment:"Text for an alert's dismissal button.")
                let alertController = UIAlertController(title: errorTitle,
                    message: message,
                    preferredStyle: .Alert)
                alertController.addCancelActionWithTitle(cancelTitle, handler: nil)
                alertController.presentFromRootViewController()
            })
    }


    private func unblockSiteForPost(post: ReaderPost) {
        guard let indexPath = tableViewHandler.resultsController.indexPathForObject(post) else {
            return
        }

        let objectID = post.objectID
        recentlyBlockedSitePostObjectIDs.removeObject(objectID)

        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)

        let service = ReaderSiteService(managedObjectContext: managedObjectContext())
        service.flagSiteWithID(post.siteID,
            asBlocked: false,
            success: nil,
            failure: { [weak self] (error:NSError?) in
                self?.recentlyBlockedSitePostObjectIDs.addObject(objectID)
                self?.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)

                let message = error?.localizedDescription ?? ""
                let errorTitle = NSLocalizedString("Error Unblocking Site", comment:"Title of a prompt letting the user know there was an error trying to unblock a site from appearing in the reader.")
                let cancelTitle = NSLocalizedString("OK", comment:"Text for an alert's dismissal button.")
                let alertController = UIAlertController(title: errorTitle,
                    message: message,
                    preferredStyle: .Alert)
                alertController.addCancelActionWithTitle(cancelTitle, handler: nil)
                alertController.presentFromRootViewController()
            })
    }


    /// A user can block a site from the detail screen.  When this happens, we need
    /// to update the list UI to properly reflect the change. Listen for the
    /// notification and call blockSiteForPost as needed.
    ///
    func handleBlockSiteNotification(notification:NSNotification) {
        guard let userInfo = notification.userInfo, aPost = userInfo["post"] as? ReaderPost else {
            return
        }

        guard let post = (try? managedObjectContext().existingObjectWithID(aPost.objectID)) as? ReaderPost else {
            DDLogSwift.logError("Error fetching existing post from context.")
            return
        }

        if let _ = tableViewHandler.resultsController.indexPathForObject(post) {
            blockSiteForPost(post)
        }
    }


    // MARK: - Actions


    /// Handles the user initiated pull to refresh action.
    ///
    func handleRefresh(sender:UIRefreshControl) {
        if !canSync() {
            cleanupAfterSync()
            return
        }
        syncHelper.syncContentWithUserInteraction(true)
    }


    /// Handle's the user tapping the search button.  Displays the search controller
    ///
    func handleSearchButtonTapped(sender: UIBarButtonItem) {
        let controller = ReaderSearchViewController.controller()
        navigationController?.pushViewController(controller, animated: true)
    }


    // MARK: - Analytics


    /// Bump tracked analytics stats if necessary.
    ///
    func bumpStats() {
        if didBumpStats {
            return
        }

        guard let topic = readerTopic, properties = topicPropertyForStats() where isViewLoaded() && view.window != nil else {
            return
        }

        didBumpStats = true
        ReaderHelpers.trackLoadedTopic(topic, withProperties: properties)
    }


    // MARK: - Sync Methods


    /// Updates the last synced date for a topic.  Since its possible for a sync
    /// to complete *after* the current topic is changed we fetch the correct topic
    /// via its objectID.
    ///
    /// - Parameters:
    ///     - objectID: The objectID of the topic that was synced.
    ///
    func updateLastSyncedForTopic(objectID:NSManagedObjectID) {
        let context = ContextManager.sharedInstance().mainContext
        guard let topic = (try? context.existingObjectWithID(objectID)) as? ReaderAbstractTopic else {
            DDLogSwift.logError("Failed to retrive an existing topic when updating last sync date.")
            return
        }
        topic.lastSynced = NSDate()
        ContextManager.sharedInstance().saveContext(context)
    }


    func canSync() -> Bool {
        let appDelegate = WordPressAppDelegate.sharedInstance()
        return (readerTopic != nil) && appDelegate.connectionAvailable && (readerTopic?.path != nil)
    }


    func canLoadMore() -> Bool {
        let fetchedObjects = tableViewHandler.resultsController.fetchedObjects ?? []
        if fetchedObjects.count == 0 {
            return false
        }
        return canSync()
    }


    /// Kicks off a "background" sync without updating the UI if certain conditions
    /// are met.
    /// - The app must have a internet connection.
    /// - The current time must be greater than the last sync interval.
    func syncIfAppropriate() {
        if WordPressAppDelegate.sharedInstance().testSuiteIsRunning {
            return
        }

        guard let topic = readerTopic else {
            return
        }

        if ReaderHelpers.isTopicSearchTopic(topic) && topic.posts.count > 0 {
            // We only perform an initial sync if the topic has no results.
            // The rest of the time it should just support infinite scroll.
            // Normal the newly added topic will have no existing posts. The
            // exception is state restoration of a search topic that was being
            // viewed when the app was backgrounded.
            return
        }

        let lastSynced = topic.lastSynced ?? NSDate(timeIntervalSince1970: 0)
        let interval = Int( NSDate().timeIntervalSinceDate(lastSynced))
        if canSync() && (interval >= refreshInterval || topic.posts.count == 0) {
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
        guard let topic = readerTopic else {
            DDLogSwift.logError("Error: Reader tried to sync items when the topic was nil.")
            return
        }

        let syncContext = ContextManager.sharedInstance().newDerivedContext()
        let service =  ReaderPostService(managedObjectContext: syncContext)

        syncContext.performBlock { [weak self] in
            guard let topicInContext = (try? syncContext.existingObjectWithID(topic.objectID)) as? ReaderAbstractTopic else {
                DDLogSwift.logError("Error: Could not retrieve an existing topic via its objectID")
                return
            }

            let objectID = topicInContext.objectID

            let successBlock = { [weak self] (count:Int, hasMore:Bool) in
                dispatch_async(dispatch_get_main_queue()) {
                    if let strongSelf = self {
                        if strongSelf.recentlyBlockedSitePostObjectIDs.count > 0 {
                            strongSelf.recentlyBlockedSitePostObjectIDs.removeAllObjects()
                            strongSelf.updateAndPerformFetchRequest()
                        }
                        strongSelf.updateLastSyncedForTopic(objectID)
                    }
                    success?(hasMore: hasMore)
                }
            }

            let failureBlock = { (error:NSError?) in
                dispatch_async(dispatch_get_main_queue()) {
                    if let error = error {
                        failure?(error: error)
                    }
                }
            }

            if ReaderHelpers.isTopicSearchTopic(topicInContext) {
                service.fetchPostsForTopic(topicInContext, atOffset: 0, deletingEarlier: false, success: successBlock, failure: failureBlock)
            } else {
                service.fetchPostsForTopic(topicInContext, earlierThan: NSDate(), success: successBlock, failure: failureBlock)
            }
        }
    }


    func syncItemsForGap(success:((hasMore: Bool) -> Void)?, failure: ((error: NSError) -> Void)?) {
        assert(syncIsFillingGap)
        guard let topic = readerTopic else {
            assertionFailure("Tried to fill a gap when the topic was nil.")
            return
        }

        guard let indexPath = indexPathForGapMarker else {
            DDLogSwift.logError("Error: Tried to sync a gap when the index path for the gap was nil.")
            return
        }

        guard let post = tableViewHandler.resultsController.objectAtIndexPath(indexPath) as? ReaderGapMarker else {
            DDLogSwift.logError("Error: Unable to retrieve an existing reader gap marker.")
            return
        }

        // Reload the gap cell so it will start animating.
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)

        let syncContext = ContextManager.sharedInstance().newDerivedContext()
        let service =  ReaderPostService(managedObjectContext: syncContext)
        let sortDate = post.sortDate

        syncContext.performBlock { [weak self] in
            guard let topicInContext = (try? syncContext.existingObjectWithID(topic.objectID)) as? ReaderAbstractTopic else {
                DDLogSwift.logError("Error: Could not retrieve an existing topic via its objectID")
                return
            }

            let successBlock = { [weak self] (count:Int, hasMore:Bool) in
                dispatch_async(dispatch_get_main_queue()) {
                    if let strongSelf = self {
                        if strongSelf.recentlyBlockedSitePostObjectIDs.count > 0 {
                            strongSelf.recentlyBlockedSitePostObjectIDs.removeAllObjects()
                            strongSelf.updateAndPerformFetchRequest()
                        }
                    }

                    success?(hasMore: hasMore)
                }
            }

            let failureBlock = { (error:NSError!) in
                dispatch_async(dispatch_get_main_queue()) {
                    failure?(error: error)
                }
            }

            if ReaderHelpers.isTopicSearchTopic(topicInContext) {
                assertionFailure("Search topics should no have a gap to fill.")
                service.fetchPostsForTopic(topicInContext, atOffset: 0, deletingEarlier: true, success: successBlock, failure: failureBlock)
            } else {
                service.fetchPostsForTopic(topicInContext, earlierThan: sortDate, deletingEarlier: true, success: successBlock, failure: failureBlock)
            }
        }
    }


    func loadMoreItems(success:((hasMore: Bool) -> Void)?, failure: ((error: NSError) -> Void)?) {
        guard let topic = readerTopic else {
            assertionFailure("Tried to fill a gap when the topic was nil.")
            return
        }

        guard let post = tableViewHandler.resultsController.fetchedObjects?.last as? ReaderPost else {
            DDLogSwift.logError("Error: Unable to retrieve an existing reader gap marker.")
            return
        }

        footerView.showSpinner(true)

        let earlierThan = post.sortDate
        let syncContext = ContextManager.sharedInstance().newDerivedContext()
        let service =  ReaderPostService(managedObjectContext: syncContext)
        let offset = tableViewHandler.resultsController.fetchedObjects?.count ?? 0
        syncContext.performBlock {
            guard let topicInContext = (try? syncContext.existingObjectWithID(topic.objectID)) as? ReaderAbstractTopic else {
                DDLogSwift.logError("Error: Could not retrieve an existing topic via its objectID")
                return
            }

            let successBlock = { (count:Int, hasMore:Bool) in
                dispatch_async(dispatch_get_main_queue(), {
                    success?(hasMore: hasMore)
                })
            }

            let failureBlock = { (error:NSError!) in
                dispatch_async(dispatch_get_main_queue(), {
                    failure?(error: error)
                })
            }

            if ReaderHelpers.isTopicSearchTopic(topicInContext) {
                service.fetchPostsForTopic(topicInContext, atOffset: UInt(offset), deletingEarlier: false, success: successBlock, failure: failureBlock)
            } else {
                service.fetchPostsForTopic(topicInContext, earlierThan: earlierThan, success: successBlock, failure: failureBlock)
            }
        }

        if let properties = topicPropertyForStats() {
            WPAppAnalytics.track(.ReaderInfiniteScroll, withProperties: properties)
        }
    }


    public func cleanupAfterSync(refresh refresh: Bool = true) {
        syncIsFillingGap = false
        indexPathForGapMarker = nil
        cleanupAndRefreshAfterScrolling = false
        if refresh {
            tableViewHandler.refreshTableViewPreservingOffset()
        }
        refreshControl.endRefreshing()
        footerView.showSpinner(false)
    }


    // MARK: - Notifications

    @objc private func defaultAccountDidChange(notification: NSNotification) {
        refreshImageRequestAuthToken()
    }


    // MARK: - Helpers for TableViewHandler


    func predicateForFetchRequest() -> NSPredicate {

        // If readerTopic is nil return a predicate that is valid, but still
        // avoids returning readerPosts that do not belong to a topic (e.g. those
        // loaded from a notification). We can do this by specifying that self
        // has to exist within an empty set.
        let predicateForNilTopic = NSPredicate(format: "topics.@count = 0 AND SELF in %@", [])

        guard let topic = readerTopic else {
            return predicateForNilTopic
        }

        guard let topicInContext = (try? managedObjectContext().existingObjectWithID(topic.objectID)) as? ReaderAbstractTopic else {
            DDLogSwift.logError("Error: Could not retrieve an existing topic via its objectID")
            return predicateForNilTopic
        }

        if recentlyBlockedSitePostObjectIDs.count > 0 {
            return NSPredicate(format: "ANY topics = %@ AND (isSiteBlocked = NO OR SELF in %@)", topicInContext, recentlyBlockedSitePostObjectIDs)
        }

        return NSPredicate(format: "ANY topics = %@ AND isSiteBlocked = NO", topicInContext)
    }


    func sortDescriptorsForFetchRequest() -> [NSSortDescriptor] {
        let sortDescriptor = NSSortDescriptor(key: "sortRank", ascending: false)
        return [sortDescriptor]
    }


    public func configurePostCardCell(cell: UITableViewCell, post: ReaderPost) {

        let postCell = cell as! ReaderPostCardCell

        postCell.delegate = self
        postCell.enableLoggedInFeatures = isLoggedIn
        postCell.headerBlogButtonIsEnabled = !ReaderHelpers.isTopicSite(readerTopic!)
        postCell.configureCell(post)
    }


    public func configureCrossPostCell(cell: ReaderCrossPostCell, atIndexPath indexPath:NSIndexPath) {
        if tableViewHandler.resultsController.fetchedObjects == nil {
            return
        }
        cell.accessoryType = .None
        cell.selectionStyle = .None

        guard let posts = tableViewHandler.resultsController.fetchedObjects as? [ReaderPost] else {
            return
        }

        let post = posts[indexPath.row]
        cell.configureCell(post)
    }


    public func configureBlockedCell(cell: ReaderBlockedSiteCell, atIndexPath indexPath: NSIndexPath) {
        if tableViewHandler.resultsController.fetchedObjects == nil {
            return
        }
        cell.accessoryType = .None
        cell.selectionStyle = .None

        guard let posts = tableViewHandler.resultsController.fetchedObjects as? [ReaderPost] else {
            return
        }
        let post = posts[indexPath.row]
        cell.setSiteName(post.blogName)
    }


    public func configureGapMarker(cell: ReaderGapMarkerCell) {
        cell.animateActivityView(syncIsFillingGap)
    }


    func handleContextDidSaveNotification(notification:NSNotification) {
        displayContext.mergeChangesFromContextDidSaveNotification(notification)
    }


    // MARK: - Helpers for ReaderStreamHeader


    func toggleFollowingForTag(topic:ReaderTagTopic) {
        if !topic.following {
            WPNotificationFeedbackGenerator.notificationOccurred(.Success)
        }

        let service = ReaderTopicService(managedObjectContext: topic.managedObjectContext)
        service.toggleFollowingForTag(topic, success: nil, failure: { (error:NSError?) in
            WPNotificationFeedbackGenerator.notificationOccurred(.Error)
            self.updateStreamHeaderIfNeeded()
        })
        self.updateStreamHeaderIfNeeded()
    }


    func toggleFollowingForSite(topic:ReaderSiteTopic) {
        if !topic.following {
            WPNotificationFeedbackGenerator.notificationOccurred(.Success)
        }

        let service = ReaderTopicService(managedObjectContext: topic.managedObjectContext)
        service.toggleFollowingForSite(topic, success:nil, failure: { (error:NSError?) in
            WPNotificationFeedbackGenerator.notificationOccurred(.Error)
            self.updateStreamHeaderIfNeeded()
        })
        self.updateStreamHeaderIfNeeded()
    }
}


// MARK: - ReaderStreamHeaderDelegate

extension ReaderStreamViewController : ReaderStreamHeaderDelegate {

    public func handleFollowActionForHeader(header:ReaderStreamHeader) {
        if let topic = readerTopic as? ReaderTagTopic {
            toggleFollowingForTag(topic)

        } else if let topic = readerTopic as? ReaderSiteTopic {
            toggleFollowingForSite(topic)

        } else if let topic = readerTopic as? ReaderDefaultTopic where ReaderHelpers.topicIsFollowing(topic) {
            showManageSites()
        }
    }
}


// MARK: - WPContentSyncHelperDelegate

extension ReaderStreamViewController : WPContentSyncHelperDelegate {

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


    public func syncContentFailed() {
        cleanupAfterSync(refresh: false)
    }
}


// MARK: - ReaderPostCellDelegate

extension ReaderStreamViewController : ReaderPostCellDelegate {


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

    public func readerCell(cell: ReaderPostCardCell, saveActionForProvider provider: ReaderPostContentProvider) {
        let post = provider as! ReaderPost
        toggleSavedForPost(post)
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


    public func readerCellImageRequestAuthToken(cell: ReaderPostCardCell) -> String? {
        return imageRequestAuthToken
    }
}


// MARK: - WPTableViewHandlerDelegate

extension ReaderStreamViewController : WPTableViewHandlerDelegate {

    // MARK: Scrolling Related

    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        if refreshControl.refreshing {
            refreshControl.endRefreshing()
        }
    }


    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate {
            return
        }
        if cleanupAndRefreshAfterScrolling {
            cleanupAfterSync()
        }
    }


    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if cleanupAndRefreshAfterScrolling {
            cleanupAfterSync()
        }
    }


    // MARK: - Fetched Results Related

    public func managedObjectContext() -> NSManagedObjectContext {
        return displayContext
    }


    public func fetchRequest() -> NSFetchRequest {
        let fetchRequest = NSFetchRequest(entityName: ReaderPost.classNameWithoutNamespaces())
        fetchRequest.predicate = predicateForFetchRequest()
        fetchRequest.sortDescriptors = sortDescriptorsForFetchRequest()
        return fetchRequest
    }


    public func tableViewDidChangeContent(tableView: UITableView) {
        if tableViewHandler.resultsController.fetchedObjects?.count == 0 {
            displayNoResultsView()
        }
    }


    // MARK - Refresh Bookends

    public func tableViewHandlerWillRefreshTableViewPreservingOffset(tableViewHandler: WPTableViewHandler) {
        // Reload the table view to reflect new content.
        managedObjectContext().reset()
        updateAndPerformFetchRequest()
    }


    public func tableViewHandlerDidRefreshTableViewPreservingOffset(tableViewHandler: WPTableViewHandler) {
        if tableViewHandler.resultsController.fetchedObjects?.count == 0 {
            if syncHelper.isSyncing {
                return
            }
            displayNoResultsView()
        } else {
            hideResultsStatus()
            tableView.flashScrollIndicators()
        }
    }


    // MARK: - TableView Related

    public func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        // When using UITableViewAutomaticDimension for auto-sizing cells, UITableView
        // likes to reload rows in a strange way.
        // It uses the estimated height as a starting value for reloading animations.
        // So this estimated value needs to be as accurate as possible to avoid any "jumping" in
        // the cell heights during reload animations.
        // Note: There may (and should) be a way to get around this, but there is currently no obvious solution.
        // Brent C. August 8/2016
        if let height = estimatedHeightsCache.objectForKey(indexPath) as? CGFloat {
            // Return the previously known height as it was cached via willDisplayCell.
            return height
        }
        return estimatedRowHeight
    }


    public func tableView(aTableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
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
            return cell
        }

        let cell = tableView.dequeueReusableCellWithIdentifier(readerCardCellReuseIdentifier) as! ReaderPostCardCell
        configurePostCardCell(cell, post: post)
        return cell
    }

    public func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        // Cache the cell's layout height as the currently known height, for estimation.
        // See estimatedHeightForRowAtIndexPath
        estimatedHeightsCache.setObject(cell.frame.height, forKey: indexPath)

        // Check to see if we need to load more.
        let criticalRow = tableView.numberOfRowsInSection(indexPath.section) - loadMoreThreashold
        if (indexPath.section == tableView.numberOfSections - 1) && (indexPath.row >= criticalRow) {
            if syncHelper.hasMoreContent && !syncHelper.isSyncing {
                syncHelper.syncMoreContent()
            }
        }
        guard cell.isKindOfClass(ReaderPostCardCell) || cell.isKindOfClass(ReaderCrossPostCell) else {
            return
        }
        // Bump the render tracker if necessary.
        let posts = tableViewHandler.resultsController.fetchedObjects as! [ReaderPost]
        let post = posts[indexPath.row]
        if !post.rendered, let railcar = post.railcarDictionary() {
            post.rendered = true
            WPAppAnalytics.track(.TrainTracksRender, withProperties: railcar)
        }
    }


    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        guard let posts = tableViewHandler.resultsController.fetchedObjects as? [ReaderPost] else {
            DDLogSwift.logError("[ReaderStreamViewController tableView:didSelectRowAtIndexPath:] fetchedObjects was nil.")
            return
        }

        let apost = posts[indexPath.row]
        guard let post = postInMainContext(apost) else {
            return
        }

        if post.isKindOfClass(ReaderGapMarker) {
            syncFillingGap(indexPath)
            return
        }

        if recentlyBlockedSitePostObjectIDs.containsObject(apost.objectID) {
            unblockSiteForPost(apost)
            return
        }

        if let topic = readerTopic where ReaderHelpers.isTopicSearchTopic(topic) {
            WPAppAnalytics.track(.ReaderSearchResultTapped)

            // We can use `if let` when `ReaderPost` adopts nullability.
            let railcar = apost.railcarDictionary()
            if railcar != nil {
                WPAppAnalytics.trackTrainTracksInteraction(.ReaderSearchResultTapped, withProperties: railcar)
            }
        }

        var controller: ReaderDetailViewController
        if post.sourceAttributionStyle() == .Post &&
            post.sourceAttribution.postID != nil &&
            post.sourceAttribution.blogID != nil {

            controller = ReaderDetailViewController.controllerWithPostID(post.sourceAttribution.postID!, siteID: post.sourceAttribution.blogID!)

        } else if post.isCrossPost() {
            controller = ReaderDetailViewController.controllerWithPostID(post.crossPostMeta.postID, siteID: post.crossPostMeta.siteID)

        } else {
            controller = ReaderDetailViewController.controllerWithPost(post)

        }

        navigationController?.pushViewController(controller, animated: true)
    }


    public func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        // Do nothing
    }

}


extension ReaderStreamViewController : WPNoResultsViewDelegate
{
    public func didTapNoResultsView(noResultsView: WPNoResultsView!) {
        showManageSites()
    }
}
