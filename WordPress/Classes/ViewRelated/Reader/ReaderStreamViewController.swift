import Foundation
import CocoaLumberjack
import SVProgressHUD
import WordPressShared
import WordPressFlux

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
@objc open class ReaderStreamViewController: UIViewController, UIViewControllerRestoration {
    @objc static let restorationClassIdentifier = "ReaderStreamViewControllerRestorationIdentifier"
    @objc static let restorableTopicPathKey: String = "RestorableTopicPathKey"

    // MARK: - Properties

    fileprivate var tableView: UITableView!
    fileprivate var refreshControl: UIRefreshControl!
    fileprivate var syncHelper: WPContentSyncHelper!
    fileprivate var tableViewController: UITableViewController!
    fileprivate var resultsStatusView: WPNoResultsView!
    fileprivate var footerView: PostListFooterView!

    fileprivate let loadMoreThreashold = 4

    fileprivate let refreshInterval = 300
    fileprivate var cleanupAndRefreshAfterScrolling = false
    fileprivate let recentlyBlockedSitePostObjectIDs = NSMutableArray()
    fileprivate let frameForEmptyHeaderView = CGRect(x: 0.0, y: 0.0, width: 320.0, height: 30.0)
    fileprivate let heightForFooterView = CGFloat(34.0)
    fileprivate let estimatedHeightsCache = NSCache<AnyObject, AnyObject>()
    fileprivate var isLoggedIn = false
    fileprivate var isFeed = false
    fileprivate var syncIsFillingGap = false
    fileprivate var indexPathForGapMarker: IndexPath?
    fileprivate var didSetupView = false
    fileprivate var listentingForBlockedSiteNotification = false
    fileprivate var didBumpStats = false

    /// Content management
    private let content = ReaderTableContent()
    /// Configuration of table view and registration of cells
    private let tableConfiguration = ReaderTableConfiguration()
    /// Configuration of cells
    private let cellConfiguration = ReaderCellConfiguration()
    /// Actions
    private var postCellActions: ReaderPostCellActions?

    /// Used for fetching content.
    fileprivate lazy var displayContext: NSManagedObjectContext = ContextManager.sharedInstance().newMainContextChildContext()


    fileprivate var siteID: NSNumber? {
        didSet {
            if siteID != nil {
                fetchSiteTopic()
            }
        }
    }


    fileprivate var tagSlug: String? {
        didSet {
            if tagSlug != nil {
                // Fixes https://github.com/wordpress-mobile/WordPress-iOS/issues/5223
                title = tagSlug

                fetchTagTopic()
            }
        }
    }


    /// The topic can be nil while a site or tag topic is being fetched, hence, optional.
    @objc open var readerTopic: ReaderAbstractTopic? {
        didSet {
            oldValue?.inUse = false

            if let newTopic = readerTopic {
                newTopic.inUse = true
                ContextManager.sharedInstance().save(newTopic.managedObjectContext!)
            }

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
    @objc open class func controllerWithTopic(_ topic: ReaderAbstractTopic) -> ReaderStreamViewController {
        let storyboard = UIStoryboard(name: "Reader", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "ReaderStreamViewController") as! ReaderStreamViewController
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
    @objc open class func controllerWithSiteID(_ siteID: NSNumber, isFeed: Bool) -> ReaderStreamViewController {
        let storyboard = UIStoryboard(name: "Reader", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "ReaderStreamViewController") as! ReaderStreamViewController
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
    @objc open class func controllerWithTagSlug(_ tagSlug: String) -> ReaderStreamViewController {
        let storyboard = UIStoryboard(name: "Reader", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "ReaderStreamViewController") as! ReaderStreamViewController
        controller.tagSlug = tagSlug

        return controller
    }


    // MARK: - State Restoration


    public static func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {
        guard let path = coder.decodeObject(forKey: restorableTopicPathKey) as? String else {
            return nil
        }

        let context = ContextManager.sharedInstance().mainContext
        let service = ReaderTopicService(managedObjectContext: context)
        guard let topic = service.find(withPath: path) else {
            return nil
        }

        let storyboard = UIStoryboard(name: "Reader", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "ReaderStreamViewController") as! ReaderStreamViewController
        controller.readerTopic = topic
        return controller
    }


    open override func encodeRestorableState(with coder: NSCoder) {
        if let topic = readerTopic {
            coder.encode(topic.path, forKey: type(of: self).restorableTopicPathKey)
        }
        super.encodeRestorableState(with: coder)
    }


    // MARK: - LifeCycle Methods

    deinit {
        if let topic = readerTopic {
            topic.inUse = false
            ContextManager.sharedInstance().save(topic.managedObjectContext!)
        }
    }


    open override func awakeAfter(using aDecoder: NSCoder) -> Any? {
        restorationIdentifier = type(of: self).restorationClassIdentifier
        restorationClass = type(of: self)

        return super.awakeAfter(using: aDecoder)
    }


    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        tableViewController = segue.destination as? UITableViewController
    }


    open override func viewDidLoad() {
        super.viewDidLoad()

        // Disable the view until we have a topic.  This prevents a premature
        // pull to refresh animation.
        view.isUserInteractionEnabled = readerTopic != nil

        NotificationCenter.default.addObserver(self, selector: #selector(defaultAccountDidChange(_:)), name: NSNotification.Name.WPAccountDefaultWordPressComAccountChanged, object: nil)
        refreshImageRequestAuthToken()

        setupTableView()
        setupFooterView()
        setupContentHandler()
        setupSyncHelper()
        setupResultsStatusView()

        observeNetworkStatus()

        WPStyleGuide.configureColors(for: view, andTableView: tableView)

        didSetupView = true

        if readerTopic != nil {
            configureControllerForTopic()
        } else if siteID != nil || tagSlug != nil {
            displayLoadingStream()
        }
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Trigger layouts, if needed, to correct for any inherited layout changes, such as margins.
        refreshTableHeaderIfNeeded()
        syncIfAppropriate()
    }


    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let mainContext = ContextManager.sharedInstance().mainContext
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextDidSave, object: mainContext)

        bumpStats()
        registerUserActivity()
    }


    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // We want to listen for any changes (following, liked) in a post detail so we can refresh the child context.
        let mainContext = ContextManager.sharedInstance().mainContext
        NotificationCenter.default.addObserver(self, selector: #selector(ReaderStreamViewController.handleContextDidSaveNotification(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: mainContext)
    }


    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }


    open override func viewDidLayoutSubviews() {
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
    fileprivate func fetchSiteTopic() {
        if isViewLoaded {
            displayLoadingStream()
        }
        assert(siteID != nil, "A siteID is required before fetching a site topic")
        let service = ReaderTopicService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.siteTopicForSite(withID: siteID!,
            isFeed: isFeed,
            success: { [weak self] (objectID: NSManagedObjectID?, isFollowing: Bool) in

                let context = ContextManager.sharedInstance().mainContext
                guard let objectID = objectID, let topic = (try? context.existingObject(with: objectID)) as? ReaderAbstractTopic else {
                    DDLogError("Reader: Error retriving an existing site topic by its objectID")
                    self?.displayLoadingStreamFailed()
                    return
                }
                self?.readerTopic = topic

            },
            failure: { [weak self] (error: Error?) in
                self?.displayLoadingStreamFailed()
            })
    }


    /// Fetches a tag topic for the value of the `tagSlug` property
    ///
    fileprivate func fetchTagTopic() {
        if isViewLoaded {
            displayLoadingStream()
        }
        assert(tagSlug != nil, "A tag slug is requred before fetching a tag topic")
        let service = ReaderTopicService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.tagTopicForTag(withSlug: tagSlug,
            success: { [weak self] (objectID: NSManagedObjectID?) in

                let context = ContextManager.sharedInstance().mainContext
                guard let objectID = objectID, let topic = (try? context.existingObject(with: objectID)) as? ReaderAbstractTopic else {
                    DDLogError("Reader: Error retriving an existing tag topic by its objectID")
                    self?.displayLoadingStreamFailed()
                    return
                }
                self?.readerTopic = topic

            },
            failure: { [weak self] (error: Error?) in
                self?.displayLoadingStreamFailed()
            })
    }


    // MARK: - Setup

    fileprivate func setupTableView() {
        assert(tableViewController != nil, "The tableViewController must be assigned before configuring the tableView")

        tableView = tableViewController.tableView
        refreshControl = tableViewController.refreshControl!
        refreshControl.addTarget(self, action: #selector(ReaderStreamViewController.handleRefresh(_:)), for: .valueChanged)

        tableConfiguration.setup(tableView)
    }


    fileprivate func setupContentHandler() {
        assert(tableView != nil, "A tableView must be assigned before configuring a handler")

        content.initializeContent(tableView: tableView, delegate: self)
    }


    fileprivate func setupSyncHelper() {
        syncHelper = WPContentSyncHelper()
        syncHelper.delegate = self
    }

    fileprivate func setupResultsStatusView() {
        resultsStatusView = WPNoResultsView()
    }

    fileprivate func setupFooterView() {
        guard let footer = tableConfiguration.footer() as? PostListFooterView else {
            assertionFailure()
            return
        }

        footerView = footer
        footerView.showSpinner(false)
        var frame = footerView.frame
        frame.size.height = heightForFooterView
        footerView.frame = frame
        tableView.tableFooterView = footerView
        footerView.isHidden = true
    }


    // MARK: - Handling Loading and No Results

    private func setStatusViewTitle(_ title: String, message: String) {
        // Potential fix for a crash where it seems we attempted to update the status view
        // title or message before the IBOutlets were connected: https://github.com/wordpress-mobile/WordPress-iOS/issues/9745
        guard isViewLoaded else {
            return
        }

        resultsStatusView.titleText = title
        resultsStatusView.messageText = message
    }

    @objc func displayLoadingStream() {
        setStatusViewTitle(NSLocalizedString("Loading stream...", comment: "A short message to inform the user the requested stream is being loaded."),
                                             message: "")
        displayResultsStatus()
    }


    @objc func displayLoadingStreamFailed() {
        setStatusViewTitle(NSLocalizedString("Problem loading stream", comment: "Error message title informing the user that a stream could not be loaded."),
                           message: NSLocalizedString("Sorry. The stream could not be loaded.", comment: "A short error message leting the user know the requested stream could not be loaded."))
        displayResultsStatus()
    }


    @objc func displayLoadingViewIfNeeded() {
        let count = content.contentCount
        if count > 0 {
            return
        }

        tableView.tableHeaderView?.isHidden = true
        resultsStatusView.titleText = NSLocalizedString("Fetching posts...", comment: "A brief prompt shown when the reader is empty, letting the user know the app is currently fetching new posts.")
        resultsStatusView.messageText = ""
        resultsStatusView.buttonTitle = nil
        resultsStatusView.delegate = nil

        let boxView = WPAnimatedBox()
        resultsStatusView.accessoryView = boxView
        displayResultsStatus()
        boxView.animate(afterDelay: 0.3)
    }


    @objc func displayNoResultsView() {
        // Its possible the topic was deleted before a sync could be completed,
        // so make certain its not nil.
        guard let topic = readerTopic else {
            return
        }

        tableView.tableHeaderView?.isHidden = true

        guard connectionAvailable() else {
            displayNoConnectionView(topic)
            return
        }

        let response: NoResultsResponse = ReaderStreamViewController.responseForNoResults(topic)
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

    private func displayNoConnectionView(_ topic: ReaderAbstractTopic) {
        resultsStatusView.titleText = NSLocalizedString("Unable to Sync", comment: "Title of error prompt shown when a sync the user initiated fails.")
        resultsStatusView.messageText = noConnectionMessage()
        resultsStatusView.accessoryView = nil
        displayResultsStatus()
    }


    @objc func displayResultsStatus() {
        if !resultsStatusView.isDescendant(of: tableView) {
            tableView.addSubview(withFadeAnimation: resultsStatusView)
            resultsStatusView.translatesAutoresizingMaskIntoConstraints = false
            tableView.pinSubviewAtCenter(resultsStatusView)
        }

        footerView.isHidden = true
    }


    @objc func centerResultsStatusViewIfNeeded() {
        if resultsStatusView.isDescendant(of: tableView) {
            resultsStatusView.centerInSuperview()
        }
    }


    @objc func hideResultsStatus() {
        resultsStatusView.removeFromSuperview()
        footerView.isHidden = false
        tableView.tableHeaderView?.isHidden = false
    }


    // MARK: - Configuration / Topic Presentation


    @objc func configureStreamHeader() {
        guard let topic = readerTopic else {
            assertionFailure()
            return
        }

        guard let header = ReaderStreamViewController.headerWithNewsCardForStream(topic, isLoggedIn: isLoggedIn, delegate: self) else {
            tableView.tableHeaderView = nil
            return
        }

        tableView.tableHeaderView = header

        // This feels somewhat hacky, but it is the only way I found to insert a stack view into the header whitput breaking the autolayout constraints.
        header.centerXAnchor.constraint(equalTo: tableView.centerXAnchor).isActive = true
        header.widthAnchor.constraint(equalTo: tableView.widthAnchor).isActive = true
        header.topAnchor.constraint(equalTo: tableView.topAnchor).isActive = true

        tableView.tableHeaderView?.layoutIfNeeded()
        tableView.tableHeaderView = tableView.tableHeaderView
    }


    // Refresh the header of a site topic when returning in case the
    // topic's following status changed.
    @objc func refreshTableHeaderIfNeeded() {
        guard let _ = readerTopic else {
            return
        }
        configureStreamHeader()
    }


    /// Configures the controller for the `readerTopic`.  This should only be called
    /// once when the topic is set.
    @objc func configureControllerForTopic() {
        assert(readerTopic != nil, "A reader topic is required")
        assert(isViewLoaded, "The controller's view must be loaded before displaying the topic")

        // Enable the view now that we have a topic.
        view.isUserInteractionEnabled = true

        if let topic = readerTopic, ReaderHelpers.isTopicSearchTopic(topic) {
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
        tableView.setContentOffset(CGPoint.zero, animated: false)
        content.refresh()
        refreshTableViewHeaderLayout()
        syncIfAppropriate()

        bumpStats()

        let count = content.contentCount

        // Make sure we're showing the no results view if appropriate
        if !syncHelper.isSyncing && count == 0 {
            displayNoResultsView()
        }

        if !listentingForBlockedSiteNotification {
            listentingForBlockedSiteNotification = true
            NotificationCenter.default.addObserver(self,
                selector: #selector(ReaderStreamViewController.handleBlockSiteNotification(_:)),
                name: NSNotification.Name(rawValue: ReaderPostMenu.BlockSiteNotification),
                object: nil)
        }
    }


    @objc func configureTitleForTopic() {
        guard let topic = readerTopic else {
            title = NSLocalizedString("Reader", comment: "The default title of the Reader")
            return
        }

        title = topic.title
    }


    /// Fetch and cache the current defaultAccount authtoken, if available.
    fileprivate func refreshImageRequestAuthToken() {
        let acctServ = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        postCellActions?.imageRequestAuthToken = acctServ.defaultWordPressComAccount()?.authToken
    }


    // MARK: - Instance Methods


    /// Retrieve an instance of the specified post from the main NSManagedObjectContext.
    ///
    /// - Parameters:
    ///     - post: The post to retrieve.
    ///
    /// - Returns: The post fetched from the main context or nil if the post does not exist in the context.
    ///
    @objc func postInMainContext(_ post: ReaderPost) -> ReaderPost? {
        guard let post = (try? ContextManager.sharedInstance().mainContext.existingObject(with: post.objectID)) as? ReaderPost else {
            DDLogError("Error retrieving an exsting post from the main context by its object ID.")
            return nil
        }
        return post
    }


    /// Refreshes the layout of the header.  Required for sizing the tableHeaderView according
    /// to its intrinsic content layout, and after major layout changes on the viewcontroller itself.
    ///
    @objc func refreshTableViewHeaderLayout() {
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
        let size = headerView.systemLayoutSizeFitting(fittingSize,
                                                      withHorizontalFittingPriority: .required,
                                                      verticalFittingPriority: .fittingSizeLevel)
        // Update the tableHeaderView itself. Classic.
        var headerFrame = headerView.frame
        headerFrame.size.height = size.height
        headerView.frame = headerFrame
        tableView.tableHeaderView = headerView
    }


    /// Scrolls to the top of the list of posts.
    ///
    @objc open func scrollViewToTop() {
        tableView.setContentOffset(.zero, animated: true)
    }


    /// Returns the analytics property dictionary for the current topic.
    fileprivate func topicPropertyForStats() -> [AnyHashable: Any]? {
        guard let topic = readerTopic else {
            assertionFailure("A reader topic is required")
            return nil
        }
        let title = topic.title
        var key: String = "list"
        if ReaderHelpers.isTopicTag(topic) {
            key = "tag"
        } else if ReaderHelpers.isTopicSite(topic) {
            key = "site"
        }
        return [key: title]
    }

    /// The fetch request can need a different predicate depending on how the content
    /// being displayed has changed (blocking sites for instance).  Call this method to
    /// update the fetch request predicate and then perform a new fetch.
    ///
    fileprivate func updateAndPerformFetchRequest() {
        assert(Thread.isMainThread, "ReaderStreamViewController Error: updating fetch request on a background thread.")

        content.updateAndPerformFetchRequest(predicate: predicateForFetchRequest())
    }


    @objc func updateStreamHeaderIfNeeded() {
        guard let topic = readerTopic else {
            assertionFailure("A reader topic is required")
            return
        }
        guard let header = tableView.tableHeaderView as? ReaderStreamHeader else {
            return
        }
        header.configureHeader(topic)
    }


    @objc func showManageSites(animated: Bool = true) {
        let controller = ReaderFollowedSitesViewController.controller()
        navigationController?.pushViewController(controller, animated: animated)
    }


    // MARK: - Blocking


    fileprivate func blockSiteForPost(_ post: ReaderPost) {
        guard let indexPath = content.indexPath(forObject: post) else {
            return
        }

        let objectID = post.objectID
        recentlyBlockedSitePostObjectIDs.add(objectID)
        updateAndPerformFetchRequest()

        tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.fade)

        ReaderBlockSiteAction(asBlocked: true).execute(with: post, context: managedObjectContext()) { [weak self] in
            self?.recentlyBlockedSitePostObjectIDs.remove(objectID)
            self?.tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.fade)
        }
    }


    fileprivate func unblockSiteForPost(_ post: ReaderPost) {
        guard let indexPath = content.indexPath(forObject: post) else {
            return
        }

        let objectID = post.objectID
        recentlyBlockedSitePostObjectIDs.remove(objectID)

        tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.fade)

        ReaderBlockSiteAction(asBlocked: false).execute(with: post, context: managedObjectContext()) { [weak self] in
            self?.recentlyBlockedSitePostObjectIDs.add(objectID)
            self?.tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.fade)
        }
    }


    /// A user can block a site from the detail screen.  When this happens, we need
    /// to update the list UI to properly reflect the change. Listen for the
    /// notification and call blockSiteForPost as needed.
    ///
    @objc func handleBlockSiteNotification(_ notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo, let aPost = userInfo["post"] as? ReaderPost else {
            return
        }

        guard let post = (try? managedObjectContext().existingObject(with: aPost.objectID)) as? ReaderPost else {
            DDLogError("Error fetching existing post from context.")
            return
        }

        if let _ = content.indexPath(forObject: post) {
            blockSiteForPost(post)
        }
    }


    // MARK: - Actions


    /// Handles the user initiated pull to refresh action.
    ///
    @objc func handleRefresh(_ sender: UIRefreshControl) {
        if !canSync() {
            cleanupAfterSync()

            /// Delay presenting the alert, so that the refreshControl can end its own dismissal animation, and the table view scroll back to its original offset
            let _ = DispatchDelayedAction(delay: .milliseconds(200)) { [weak self] in
                self?.handleConnectionError()
            }

            return
        }
        syncHelper.syncContentWithUserInteraction(true)
    }

    /// Handle's the user tapping the search button.  Displays the search controller
    ///
    @objc func handleSearchButtonTapped(_ sender: UIBarButtonItem) {
        let controller = ReaderSearchViewController.controller()
        navigationController?.pushViewController(controller, animated: true)
    }


    // MARK: - Analytics


    /// Bump tracked analytics stats if necessary.
    ///
    @objc func bumpStats() {
        if didBumpStats {
            return
        }

        guard let topic = readerTopic, let properties = topicPropertyForStats(), isViewLoaded && view.window != nil else {
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
    @objc func updateLastSyncedForTopic(_ objectID: NSManagedObjectID) {
        let context = ContextManager.sharedInstance().mainContext
        guard let topic = (try? context.existingObject(with: objectID)) as? ReaderAbstractTopic else {
            DDLogError("Failed to retrive an existing topic when updating last sync date.")
            return
        }
        topic.lastSynced = Date()
        ContextManager.sharedInstance().save(context)
    }


    @objc func canSync() -> Bool {
        return (readerTopic != nil) && connectionAvailable()
    }

    @objc func connectionAvailable() -> Bool {
        return WordPressAppDelegate.sharedInstance()!.connectionAvailable
    }

    @objc func canLoadMore() -> Bool {
        if content.contentCount == 0 {
            return false
        }
        return canSync()
    }


    /// Kicks off a "background" sync without updating the UI if certain conditions
    /// are met.
    /// - There must be a topic
    /// - The controller must be the active controller.
    /// - The app must have a internet connection.
    /// - The app must be running on the foreground.
    /// - The current time must be greater than the last sync interval.
    ///
    @objc func syncIfAppropriate() {
        guard UIApplication.shared.isRunningTestSuite() == false else {
            return
        }

        guard WordPressAppDelegate.sharedInstance().runningInBackground == false else {
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

        let lastSynced = topic.lastSynced ?? Date(timeIntervalSince1970: 0)
        let interval = Int( Date().timeIntervalSince(lastSynced))
        if canSync() && (interval >= refreshInterval || topic.posts.count == 0) {
            syncHelper.syncContentWithUserInteraction(false)
        } else {
            handleConnectionError()
        }
    }

    /// Used to fetch new content in response to a background refresh event.  
    /// Not intended for use as part of a user interaction. See syncIfAppropriate instead.
    ///
    @objc func backgroundFetch(_ completionHandler: @escaping ((UIBackgroundFetchResult) -> Void)) {
        let lastSeenPostID = (content.content?.first as? ReaderPost)?.postID ?? -1

        syncHelper?.backgroundSync(success: { [weak self, weak lastSeenPostID] in
            let newestFetchedPostID = (self?.content.content?.first as? ReaderPost)?.postID ?? -1
            if lastSeenPostID == newestFetchedPostID {
                completionHandler(.noData)
            } else {
                if let numberOfRows = self?.tableView?.numberOfRows(inSection: 0), numberOfRows > 0 {
                    self?.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                }
                completionHandler(.newData)
            }
        }, failure: { (_) in
            completionHandler(.failed)
        })
    }

    @objc func syncFillingGap(_ indexPath: IndexPath) {
        if !canSync() {
            let alertTitle = NSLocalizedString("Unable to Load Posts", comment: "Title of a prompt saying the app needs an internet connection before it can load posts")
            let alertMessage = NSLocalizedString("Please check your internet connection and try again.", comment: "Politely asks the user to check their internet connection before trying again. ")
            let cancelTitle = NSLocalizedString("OK", comment: "Title of a button that dismisses a prompt")
            let alertController = UIAlertController(title: alertTitle,
                message: alertMessage,
                preferredStyle: .alert)
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
                preferredStyle: .alert)
            alertController.addCancelActionWithTitle(cancelTitle, handler: nil)
            alertController.presentFromRootViewController()

            return
        }
        indexPathForGapMarker = indexPath
        syncIsFillingGap = true
        syncHelper.syncContentWithUserInteraction(true)
    }


    @objc func syncItems(_ success: ((_ hasMore: Bool) -> Void)?, failure: ((_ error: NSError) -> Void)?) {
        guard let topic = readerTopic else {
            DDLogError("Error: Reader tried to sync items when the topic was nil.")
            return
        }

        let syncContext = ContextManager.sharedInstance().newDerivedContext()
        let service =  ReaderPostService(managedObjectContext: syncContext)

        syncContext.perform { [weak self] in
            guard let topicInContext = (try? syncContext.existingObject(with: topic.objectID)) as? ReaderAbstractTopic else {
                DDLogError("Error: Could not retrieve an existing topic via its objectID")
                return
            }

            let objectID = topicInContext.objectID

            let successBlock = { [weak self] (count: Int, hasMore: Bool) in
                DispatchQueue.main.async {
                    if let strongSelf = self {
                        if strongSelf.recentlyBlockedSitePostObjectIDs.count > 0 {
                            strongSelf.recentlyBlockedSitePostObjectIDs.removeAllObjects()
                            strongSelf.updateAndPerformFetchRequest()
                        }
                        strongSelf.updateLastSyncedForTopic(objectID)
                    }
                    success?(hasMore)
                }
            }

            let failureBlock = { (error: Error?) in
                DispatchQueue.main.async {
                    if let error = error {
                        failure?(error as NSError)
                    }
                }
            }

            if ReaderHelpers.isTopicSearchTopic(topicInContext) {
                service.fetchPosts(for: topicInContext, atOffset: 0, deletingEarlier: false, success: successBlock, failure: failureBlock)
            } else {
                service.fetchPosts(for: topicInContext, earlierThan: Date(), success: successBlock, failure: failureBlock)
            }
        }
    }


    @objc func syncItemsForGap(_ success: ((_ hasMore: Bool) -> Void)?, failure: ((_ error: NSError) -> Void)?) {
        assert(syncIsFillingGap)
        guard let topic = readerTopic else {
            assertionFailure("Tried to fill a gap when the topic was nil.")
            return
        }

        guard let indexPath = indexPathForGapMarker else {
            DDLogError("Error: Tried to sync a gap when the index path for the gap was nil.")
            return
        }

        guard let post: ReaderGapMarker = content.object(at: indexPath) else {
            DDLogError("Error: Unable to retrieve an existing reader gap marker.")
            return
        }

        // Reload the gap cell so it will start animating.
        tableView.reloadRows(at: [indexPath], with: .none)

        let syncContext = ContextManager.sharedInstance().newDerivedContext()
        let service =  ReaderPostService(managedObjectContext: syncContext)
        let sortDate = post.sortDate

        syncContext.perform { [weak self] in
            guard let topicInContext = (try? syncContext.existingObject(with: topic.objectID)) as? ReaderAbstractTopic else {
                DDLogError("Error: Could not retrieve an existing topic via its objectID")
                return
            }

            let successBlock = { [weak self] (count: Int, hasMore: Bool) in
                DispatchQueue.main.async {
                    if let strongSelf = self {
                        if strongSelf.recentlyBlockedSitePostObjectIDs.count > 0 {
                            strongSelf.recentlyBlockedSitePostObjectIDs.removeAllObjects()
                            strongSelf.updateAndPerformFetchRequest()
                        }
                    }

                    success?(hasMore)
                }
            }

            let failureBlock = { (error: Error?) in
                guard let error = error as NSError? else {
                    return
                }

                DispatchQueue.main.async {
                    failure?(error as NSError)
                }
            }

            if ReaderHelpers.isTopicSearchTopic(topicInContext) {
                assertionFailure("Search topics should no have a gap to fill.")
                service.fetchPosts(for: topicInContext, atOffset: 0, deletingEarlier: true, success: successBlock, failure: failureBlock)
            } else {
                service.fetchPosts(for: topicInContext, earlierThan: sortDate, deletingEarlier: true, success: successBlock, failure: failureBlock)
            }
        }
    }


    @objc func loadMoreItems(_ success: ((_ hasMore: Bool) -> Void)?, failure: ((_ error: NSError) -> Void)?) {
        guard let topic = readerTopic else {
            assertionFailure("Tried to fill a gap when the topic was nil.")
            return
        }

        guard let post = content.content?.last as? ReaderPost else {
            DDLogError("Error: Unable to retrieve an existing reader gap marker.")
            return
        }

        footerView.showSpinner(true)

        let earlierThan = post.sortDate
        let syncContext = ContextManager.sharedInstance().newDerivedContext()
        let service =  ReaderPostService(managedObjectContext: syncContext)
        let offset = content.contentCount
        syncContext.perform {
            guard let topicInContext = (try? syncContext.existingObject(with: topic.objectID)) as? ReaderAbstractTopic else {
                DDLogError("Error: Could not retrieve an existing topic via its objectID")
                return
            }

            let successBlock = { (count: Int, hasMore: Bool) in
                DispatchQueue.main.async(execute: {
                    success?(hasMore)
                })
            }

            let failureBlock = { (error: Error?) in
                guard let error = error else {
                    return
                }

                DispatchQueue.main.async(execute: {
                    failure?(error as NSError)
                })
            }

            if ReaderHelpers.isTopicSearchTopic(topicInContext) {
                service.fetchPosts(for: topicInContext, atOffset: UInt(offset), deletingEarlier: false, success: successBlock, failure: failureBlock)
            } else {
                service.fetchPosts(for: topicInContext, earlierThan: earlierThan, success: successBlock, failure: failureBlock)
            }
        }

        if let properties = topicPropertyForStats() {
            WPAppAnalytics.track(.readerInfiniteScroll, withProperties: properties)
        }
    }


    @objc open func cleanupAfterSync(refresh: Bool = true) {
        syncIsFillingGap = false
        indexPathForGapMarker = nil
        cleanupAndRefreshAfterScrolling = false
        if refresh {
            content.refreshPreservingOffset()
        }
        refreshControl.endRefreshing()
        footerView.showSpinner(false)
    }


    // MARK: - Notifications

    @objc fileprivate func defaultAccountDidChange(_ notification: Foundation.Notification) {
        refreshImageRequestAuthToken()
    }


    // MARK: - Helpers for TableViewHandler


    @objc func predicateForFetchRequest() -> NSPredicate {

        // If readerTopic is nil return a predicate that is valid, but still
        // avoids returning readerPosts that do not belong to a topic (e.g. those
        // loaded from a notification). We can do this by specifying that self
        // has to exist within an empty set.
        let predicateForNilTopic = NSPredicate(format: "topic = NULL AND SELF in %@", [])

        guard let topic = readerTopic else {
            return predicateForNilTopic
        }

        guard let topicInContext = (try? managedObjectContext().existingObject(with: topic.objectID)) as? ReaderAbstractTopic else {
            DDLogError("Error: Could not retrieve an existing topic via its objectID")
            return predicateForNilTopic
        }

        if recentlyBlockedSitePostObjectIDs.count > 0 {
            return NSPredicate(format: "topic = %@ AND (isSiteBlocked = NO OR SELF in %@)", topicInContext, recentlyBlockedSitePostObjectIDs)
        }

        return NSPredicate(format: "topic = %@ AND isSiteBlocked = NO", topicInContext)
    }


    @objc func sortDescriptorsForFetchRequest() -> [NSSortDescriptor] {
        let sortDescriptor = NSSortDescriptor(key: "sortRank", ascending: false)
        return [sortDescriptor]
    }


    @objc open func configurePostCardCell(_ cell: UITableViewCell, post: ReaderPost) {
        guard let topic = readerTopic else {
            return
        }

        if postCellActions == nil {
            postCellActions = ReaderPostCellActions(context: managedObjectContext(), origin: self, topic: readerTopic)
        }
        postCellActions?.isLoggedIn = isLoggedIn

        cellConfiguration.configurePostCardCell(cell,
                                                withPost: post,
                                                topic: topic,
                                                delegate: postCellActions,
                                                loggedInActionVisibility: .visible(enabled: isLoggedIn))
    }

    @objc func handleContextDidSaveNotification(_ notification: Foundation.Notification) {
        ContextManager.sharedInstance().mergeChanges(displayContext, fromContextDidSave: notification)
    }


    // MARK: - Helpers for ReaderStreamHeader


    @objc func toggleFollowingForTag(_ topic: ReaderTagTopic) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()

        if !topic.following {
            generator.notificationOccurred(.success)
        }

        let service = ReaderTopicService(managedObjectContext: topic.managedObjectContext!)
        service.toggleFollowing(forTag: topic, success: { [weak self] in
            self?.syncHelper.syncContent()
        }, failure: { [weak self] (error: Error?) in
            generator.notificationOccurred(.error)
            self?.updateStreamHeaderIfNeeded()
        })

        updateStreamHeaderIfNeeded()
    }


    @objc func toggleFollowingForSite(_ topic: ReaderSiteTopic) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()

        if !topic.following {
            generator.notificationOccurred(.success)
        }

        let toFollow = !topic.following
        let siteID = topic.siteID
        let siteTitle = topic.title

        if !toFollow {
            ReaderSubscribingNotificationAction().execute(for: siteID, context: managedObjectContext(), value: !topic.isSubscribedForPostNotifications)
        }

        let service = ReaderTopicService(managedObjectContext: topic.managedObjectContext!)
        service.toggleFollowing(forSite: topic, success: { [weak self] in
            self?.syncHelper.syncContent()
            if toFollow {
                self?.dispatchSubscribingNotificationNotice(with: siteTitle, siteID: siteID)
            }
        }, failure: { [weak self] (error: Error?) in
            generator.notificationOccurred(.error)
            self?.updateStreamHeaderIfNeeded()
        })

        updateStreamHeaderIfNeeded()
    }
}


// MARK: - ReaderStreamHeaderDelegate

extension ReaderStreamViewController: ReaderStreamHeaderDelegate {

    public func handleFollowActionForHeader(_ header: ReaderStreamHeader) {
        if let topic = readerTopic as? ReaderTagTopic {
            toggleFollowingForTag(topic)

        } else if let topic = readerTopic as? ReaderSiteTopic {
            toggleFollowingForSite(topic)

        } else if let topic = readerTopic as? ReaderDefaultTopic, ReaderHelpers.topicIsFollowing(topic) {
            showManageSites()
        }
    }
}


// MARK: - WPContentSyncHelperDelegate

extension ReaderStreamViewController: WPContentSyncHelperDelegate {

    func syncHelper(_ syncHelper: WPContentSyncHelper, syncContentWithUserInteraction userInteraction: Bool, success: ((_ hasMore: Bool) -> Void)?, failure: ((_ error: NSError) -> Void)?) {
        displayLoadingViewIfNeeded()
        if syncIsFillingGap {
            syncItemsForGap(success, failure: failure)
        } else {
            syncItems(success, failure: failure)
        }
    }


    func syncHelper(_ syncHelper: WPContentSyncHelper, syncMoreWithSuccess success: ((_ hasMore: Bool) -> Void)?, failure: ((_ error: NSError) -> Void)?) {
        loadMoreItems(success, failure: failure)
    }


    func syncContentEnded(_ syncHelper: WPContentSyncHelper) {
        if content.isScrolling {
            cleanupAndRefreshAfterScrolling = true
            return
        }
        cleanupAfterSync()
    }


    func syncContentFailed(_ syncHelper: WPContentSyncHelper) {
        cleanupAfterSync(refresh: false)

        if let count = content.content?.count,
            count == 0 {
            displayLoadingStreamFailed()
        }
    }
}

// MARK: - WPTableViewHandlerDelegate

extension ReaderStreamViewController: WPTableViewHandlerDelegate {

    // MARK: Scrolling Related

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
    }


    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate {
            return
        }
        if cleanupAndRefreshAfterScrolling {
            cleanupAfterSync()
        }
    }


    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if cleanupAndRefreshAfterScrolling {
            cleanupAfterSync()
        }
    }


    // MARK: - Fetched Results Related

    public func managedObjectContext() -> NSManagedObjectContext {
        return displayContext
    }


    public func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderPost.classNameWithoutNamespaces())
        fetchRequest.predicate = predicateForFetchRequest()
        fetchRequest.sortDescriptors = sortDescriptorsForFetchRequest()
        return fetchRequest
    }


    public func tableViewDidChangeContent(_ tableView: UITableView) {
        if content.contentCount == 0 {
            displayNoResultsView()
        }
    }


    // MARK: - Refresh Bookends

    public func tableViewHandlerWillRefreshTableViewPreservingOffset(_ tableViewHandler: WPTableViewHandler) {
        // Reload the table view to reflect new content.
        managedObjectContext().reset()
        updateAndPerformFetchRequest()
    }


    public func tableViewHandlerDidRefreshTableViewPreservingOffset(_ tableViewHandler: WPTableViewHandler) {
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

    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        // When using UITableViewAutomaticDimension for auto-sizing cells, UITableView
        // likes to reload rows in a strange way.
        // It uses the estimated height as a starting value for reloading animations.
        // So this estimated value needs to be as accurate as possible to avoid any "jumping" in
        // the cell heights during reload animations.
        // Note: There may (and should) be a way to get around this, but there is currently no obvious solution.
        // Brent C. August 8/2016
        if let height = estimatedHeightsCache.object(forKey: indexPath as AnyObject) as? CGFloat {
            // Return the previously known height as it was cached via willDisplayCell.
            return height
        }
        return tableConfiguration.estimatedRowHeight()
    }


    public func tableView(_ aTableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let posts = content.content as? [ReaderPost] else {
            return UITableViewCell()
        }

        let post = posts[indexPath.row]

        if post.isKind(of: ReaderGapMarker.self) {
            let cell = tableConfiguration.gapMarkerCell(tableView)
            cellConfiguration.configureGapMarker(cell, filling: syncIsFillingGap)
            return cell
        }

        if recentlyBlockedSitePostObjectIDs.contains(post.objectID) {
            let cell = tableConfiguration.blockedSiteCell(tableView)
            cellConfiguration.configureBlockedCell(cell,
                                                   withContent: content,
                                                   atIndexPath: indexPath)
            return cell
        }

        if post.isCross() {
            let cell = tableConfiguration.crossPostCell(tableView)
            cellConfiguration.configureCrossPostCell(cell,
                                                     withContent: content,
                                                     atIndexPath: indexPath)
            return cell
        }

        let cell = tableConfiguration.postCardCell(tableView)
        configurePostCardCell(cell, post: post)
        return cell
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Cache the cell's layout height as the currently known height, for estimation.
        // See estimatedHeightForRowAtIndexPath
        estimatedHeightsCache.setObject(cell.frame.height as AnyObject, forKey: indexPath as AnyObject)

        // Check to see if we need to load more.
        let criticalRow = tableView.numberOfRows(inSection: indexPath.section) - loadMoreThreashold
        if (indexPath.section == tableView.numberOfSections - 1) && (indexPath.row >= criticalRow) {
            // We only what to load more when:
            // - there is more content,
            // - when we are not alrady syncing
            // - when we are not waiting for scrolling to end to cleanup and refresh the list
            if syncHelper.hasMoreContent && !syncHelper.isSyncing && !cleanupAndRefreshAfterScrolling {
                syncHelper.syncMoreContent()
            }
        }
        guard cell.isKind(of: ReaderPostCardCell.self) || cell.isKind(of: ReaderCrossPostCell.self) else {
            return
        }

        guard let posts = content.content as? [ReaderPost] else {
            return
        }
        // Bump the render tracker if necessary.
        let post = posts[indexPath.row]
        if !post.rendered, let railcar = post.railcarDictionary() {
            post.rendered = true
            WPAppAnalytics.track(.trainTracksRender, withProperties: railcar)
        }
    }


    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let posts = content.content as? [ReaderPost] else {
            DDLogError("[ReaderStreamViewController tableView:didSelectRowAtIndexPath:] fetchedObjects was nil.")
            return
        }

        let apost = posts[indexPath.row]
        guard let post = postInMainContext(apost) else {
            return
        }

        if post.isKind(of: ReaderGapMarker.self) {
            syncFillingGap(indexPath)
            return
        }

        if recentlyBlockedSitePostObjectIDs.contains(apost.objectID) {
            unblockSiteForPost(apost)
            return
        }

        if let topic = post.topic, ReaderHelpers.isTopicSearchTopic(topic) {
            WPAppAnalytics.track(.readerSearchResultTapped)

            // We can use `if let` when `ReaderPost` adopts nullability.
            let railcar = apost.railcarDictionary()
            if railcar != nil {
                WPAppAnalytics.trackTrainTracksInteraction(.readerSearchResultTapped, withProperties: railcar)
            }
        }

        var controller: ReaderDetailViewController
        if post.sourceAttributionStyle() == .post &&
            post.sourceAttribution.postID != nil &&
            post.sourceAttribution.blogID != nil {

            controller = ReaderDetailViewController.controllerWithPostID(post.sourceAttribution.postID!, siteID: post.sourceAttribution.blogID!)

        } else if post.isCross() {
            controller = ReaderDetailViewController.controllerWithPostID(post.crossPostMeta.postID, siteID: post.crossPostMeta.siteID)

        } else {
            controller = ReaderDetailViewController.controllerWithPost(post)

        }

        if post.isSavedForLater {
            trackSavedPostNavigation()
        }

        navigationController?.pushFullscreenViewController(controller, animated: true)

        tableView.deselectRow(at: indexPath, animated: false)
    }


    public func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        // Do nothing
    }

}

// MARK: - SearchableActivity Conformance

extension ReaderStreamViewController: SearchableActivityConvertable {
    var activityType: String {
        return WPActivityType.reader.rawValue
    }

    var activityTitle: String {
        return NSLocalizedString("Reader", comment: "Title of the 'Reader' tab - used for spotlight indexing on iOS.")
    }

    var activityKeywords: Set<String>? {
        let keyWordString = NSLocalizedString("wordpress, reader, articles, posts, blog post, followed, discover, likes, my likes, tags, topics",
                                              comment: "This is a comma-separated list of keywords used for spotlight indexing of the 'Reader' tab.")
        let keywordArray = keyWordString.arrayOfTags()

        guard !keywordArray.isEmpty else {
            return nil
        }

        return Set(keywordArray)
    }
}

// MARK: - WPNoResultsViewDelegate Conformance

extension ReaderStreamViewController: WPNoResultsViewDelegate {
    public func didTap(_ noResultsView: WPNoResultsView!) {
        showManageSites()
    }
}

// MARK: - NetworkAwareUI Conformance

extension ReaderStreamViewController: NetworkAwareUI {
    func contentIsEmpty() -> Bool {
        return content.contentCount == 0
    }
}

// MARK: - NetworkAwareUI NetworkStatusDelegate

extension ReaderStreamViewController: NetworkStatusDelegate {
    func networkStatusDidChange(active: Bool) {
        syncIfAppropriate()
    }
}

// MARK: - UIViewControllerTransitioningDelegate
//
extension ReaderStreamViewController: UIViewControllerTransitioningDelegate {
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        guard presented is FancyAlertViewController else {
            return nil
        }

        return FancyAlertPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
