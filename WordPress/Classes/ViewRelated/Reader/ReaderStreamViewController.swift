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
@objc class ReaderStreamViewController: UIViewController, UIViewControllerRestoration {
    @objc static let restorationClassIdentifier = "ReaderStreamViewControllerRestorationIdentifier"
    @objc static let restorableTopicPathKey: String = "RestorableTopicPathKey"

    // MARK: - Properties

    /// Called if the stream or tag fails to load
    var streamLoadFailureBlock: (() -> Void)? = nil

    var tableView: UITableView! {
        return tableViewController.tableView
    }

    private var syncHelpers: [ReaderAbstractTopic: WPContentSyncHelper] = [:]

    private var syncHelper: WPContentSyncHelper? {
        guard let topic = readerTopic else {
            return nil
        }
        let currentHelper = syncHelpers[topic] ?? WPContentSyncHelper()
        syncHelpers[topic] = currentHelper
        return currentHelper
    }

    private var noResultsStatusViewController = NoResultsViewController.controller()
    private var noFollowedSitesViewController: NoResultsViewController?

    var resultsStatusView: NoResultsViewController {
        get {
            guard let noFollowedSitesVC = noFollowedSitesViewController else {
                return noResultsStatusViewController
            }

            return noFollowedSitesVC
        }
    }

    lazy var syncContext: NSManagedObjectContext = {
        return ContextManager.sharedInstance().newDerivedContext()
    }()

    lazy var service: ReaderPostService = {
        return ReaderPostService(managedObjectContext: syncContext)
    }()

    private(set) lazy var footerView: PostListFooterView = {
        return tableConfiguration.footer()
    }()

    private let tableViewController = UITableViewController(style: .plain)

    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        tableViewController.refreshControl = refreshControl
        return refreshControl
    }()

    private var noTopicController: UIViewController?

    private let loadMoreThreashold = 4

    private let refreshInterval = 300
    private var cleanupAndRefreshAfterScrolling = false
    private let recentlyBlockedSitePostObjectIDs = NSMutableArray()
    private let frameForEmptyHeaderView = CGRect(x: 0.0, y: 0.0, width: 320.0, height: 30.0)
    private let heightForFooterView = CGFloat(34.0)
    private let estimatedHeightsCache = NSCache<AnyObject, AnyObject>()
    private var isLoggedIn = false
    private var isFeed = false
    private var syncIsFillingGap = false
    private var indexPathForGapMarker: IndexPath?
    private var didSetupView = false
    private var listentingForBlockedSiteNotification = false
    private var didBumpStats = false

    /// Content management
    let content = ReaderTableContent()
    /// Configuration of table view and registration of cells
    private let tableConfiguration = ReaderTableConfiguration()
    /// Configuration of cells
    private let cellConfiguration = ReaderCellConfiguration()
    /// Actions
    private var postCellActions: ReaderPostCellActions?

    /// Used for fetching content.
    private lazy var displayContext: NSManagedObjectContext = ContextManager.sharedInstance().newMainContextChildContext()


    private var siteID: NSNumber? {
        didSet {
            if siteID != nil {
                fetchSiteTopic()
            }
        }
    }


    private var tagSlug: String? {
        didSet {
            if tagSlug != nil {
                // Fixes https://github.com/wordpress-mobile/WordPress-iOS/issues/5223
                title = NSLocalizedString("Topic", comment: "Topic page title")

                fetchTagTopic()
            }
        }
    }

    private var hideHeader = false

    private var isShowingResultStatusView: Bool {
        return resultsStatusView.view?.superview != nil
    }

    private var isLoadingDiscover: Bool {
        return readerTopic == nil &&
            contentType == .topic &&
            siteID == ReaderHelpers.discoverSiteID
    }

    /// The topic can be nil while a site or tag topic is being fetched, hence, optional.
    @objc var readerTopic: ReaderAbstractTopic? {
        didSet {
            if let oldValue = oldValue {
                oldValue.inUse = false
                syncHelpers[oldValue]?.delegate = nil
            }
            syncHelper?.delegate = self

            if let newTopic = readerTopic {
                newTopic.inUse = true
                ContextManager.sharedInstance().save(newTopic.managedObjectContext!)
            }

            if readerTopic != nil && readerTopic != oldValue {
                if didSetupView {
                    updateContent()
                    if let syncHelper = syncHelper, syncHelper.isSyncing, !isShowingResultStatusView {
                        displayLoadingViewIfNeeded()
                    }
                }
                // Discard the siteID (if there was one) now that we have a good topic
                siteID = nil
                tagSlug = nil
            }
        }
    }

    var isContentFiltered: Bool = false

    var contentType: ReaderContentType = .topic {
        willSet {
            if contentType == .saved && newValue != .saved {
                postCellActions?.clearRemovedPosts()
            }
        }
        didSet {
            if contentType == .saved {
                updateContent(synchronize: false)
                trackSavedListAccessed()
            }
            postCellActions?.visibleConfirmation = contentType != .saved
        }
    }

    /// Facilitates sharing of a blog via `ReaderStreamViewController+Sharing.swift`.
    let sharingController = PostSharingController()

    let ghostableTableView = UITableView()

    /// Convenience method for instantiating an instance of ReaderStreamViewController
    /// for a existing topic.
    ///
    /// - Parameters:
    ///     - topic: Any subclass of ReaderAbstractTopic
    ///
    /// - Returns: An instance of the controller
    ///
    @objc class func controllerWithTopic(_ topic: ReaderAbstractTopic) -> ReaderStreamViewController {
        // if a default discover topic is provided, treat it as a site to retrieve the header
        if ReaderHelpers.topicIsDiscover(topic) {
            return controllerWithSiteID(ReaderHelpers.discoverSiteID, isFeed: false)
        }

        let controller = ReaderStreamViewController()
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
    @objc class func controllerWithSiteID(_ siteID: NSNumber, isFeed: Bool) -> ReaderStreamViewController {
        let controller = ReaderStreamViewController()
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
    @objc class func controllerWithTagSlug(_ tagSlug: String) -> ReaderStreamViewController {
        let storyboard = UIStoryboard(name: "Reader", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "ReaderStreamViewController") as! ReaderStreamViewController
        controller.tagSlug = tagSlug

        return controller
    }

    /// Convenience method to create an instance for saved posts
    class func controllerForContentType(_ contentType: ReaderContentType) -> ReaderStreamViewController {
        let controller = ReaderStreamViewController()
        controller.contentType = contentType
        return controller
    }


    // MARK: - State Restoration


    public static func viewController(withRestorationIdentifierPath identifierComponents: [String],
                                      coder: NSCoder) -> UIViewController? {
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


    override func encodeRestorableState(with coder: NSCoder) {
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

        NotificationCenter.default.removeObserver(self)
    }


    override func awakeAfter(using aDecoder: NSCoder) -> Any? {
        restorationIdentifier = type(of: self).restorationClassIdentifier
        restorationClass = type(of: self)

        return super.awakeAfter(using: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Disable the view until we have a topic.  This prevents a premature
        // pull to refresh animation.
        view.isUserInteractionEnabled = readerTopic != nil

        NotificationCenter.default.addObserver(self, selector: #selector(defaultAccountDidChange(_:)), name: NSNotification.Name.WPAccountDefaultWordPressComAccountChanged, object: nil)

        refreshImageRequestAuthToken()

        setupTableView()
        setupFooterView()
        setupContentHandler()
        setupResultsStatusView()

        observeNetworkStatus()

        WPStyleGuide.configureColors(view: view, tableView: tableView)

        didSetupView = true

        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)

        guard !shouldDisplayNoTopicController else {
            return
        }

        if readerTopic != nil || contentType == .saved {
            // Do not perform a sync since a sync will be executed in viewWillAppear anyway. This
            // prevents a possible internet connection error being shown twice.
            updateContent(synchronize: false)
        } else if (siteID != nil || tagSlug != nil) && isShowingResultStatusView == false {
            displayLoadingStream()
        }
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        syncIfAppropriate()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let mainContext = ContextManager.sharedInstance().mainContext
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextDidSave, object: mainContext)

        bumpStats()
        registerUserActivity()
    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        dismissNoNetworkAlert()

        // We want to listen for any changes (following, liked) in a post detail so we can refresh the child context.
        let mainContext = ContextManager.sharedInstance().mainContext
        NotificationCenter.default.addObserver(self, selector: #selector(ReaderStreamViewController.handleContextDidSaveNotification(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: mainContext)

        ReaderTracker.shared.stop(.filteredList)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            if self.isShowingResultStatusView {
                self.resultsStatusView.updateAccessoryViewsVisibility()
            }

            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        })
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // There appears to be a scenario where this method can be called prior to
        // the view being fully setup in viewDidLoad.
        // See: https://github.com/wordpress-mobile/WordPress-iOS/issues/4419
        if didSetupView {
            refreshTableViewHeaderLayout()
        }
    }

    @objc func willEnterForeground() {
        guard isViewOnScreen() else {
            return
        }

        ReaderTracker.shared.start(.filteredList)
    }


    // MARK: - Topic acquisition

    /// Fetches a site topic for the value of the `siteID` property.
    ///
    // TODO: - READERNAV - Remove this when the new reader is released
    private func fetchSiteTopic() {
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
                    if self?.isLoadingDiscover ?? false {
                        self?.updateContent(synchronize: false)
                    }
                    self?.displayLoadingStreamFailed()
                    self?.reportStreamLoadFailure()
                    return
                }
                self?.readerTopic = topic

            },
            failure: { [weak self] (error: Error?) in
                if self?.isLoadingDiscover ?? false {
                    self?.updateContent(synchronize: false)
                }
                self?.displayLoadingStreamFailed()
                self?.reportStreamLoadFailure()
            })
    }


    /// Fetches a tag topic for the value of the `tagSlug` property
    ///
    // TODO: - READERNAV - Remove this when the new reader is released
    private func fetchTagTopic() {
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
                    self?.reportStreamLoadFailure()
                    return
                }
                self?.readerTopic = topic

            },
            failure: { [weak self] (error: Error?) in
                self?.displayLoadingStreamFailed()
                self?.reportStreamLoadFailure()
            })
    }


    // MARK: - Setup

    private func setupTableView() {
        configureRefreshControl()
        add(tableViewController)
        layoutTableView()
        tableConfiguration.setup(tableView)
        setupUndoCell(tableView)
    }

    @objc func configureRefreshControl() {
        refreshControl.addTarget(self, action: #selector(ReaderStreamViewController.handleRefresh(_:)), for: .valueChanged)
    }

    private func layoutTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])
    }

    private func setupContentHandler() {
        assert(tableView != nil, "A tableView must be assigned before configuring a handler")

        content.initializeContent(tableView: tableView, delegate: self)
    }

    private func setupResultsStatusView() {
        resultsStatusView.delegate = self
    }

    private func setupFooterView() {
        footerView.showSpinner(false)
        var frame = footerView.frame
        frame.size.height = heightForFooterView
        footerView.frame = frame
        tableView.tableFooterView = footerView
        footerView.isHidden = true
    }

    // MARK: - Configuration / Topic Presentation

    @objc private func configureStreamHeader() {
        guard let topic = readerTopic else {
            assertionFailure()
            return
        }

        guard let header = headerForStream(topic, isLoggedIn: isLoggedIn, container: tableViewController) else {
            tableView.tableHeaderView = nil
            return
        }

        guard !hideHeader else {
            tableView.tableHeaderView = nil
            hideHeader = false
            return
        }

        if let tableHeaderView = tableView.tableHeaderView {
            header.isHidden = tableHeaderView.isHidden
        }

        tableView.tableHeaderView = header
        // This feels somewhat hacky, but it is the only way I found to insert a stack view into the header without breaking the autolayout constraints.
        let centerConstraint = header.centerXAnchor.constraint(equalTo: tableView.centerXAnchor)
        let topConstraint = header.topAnchor.constraint(equalTo: tableView.topAnchor)
        let headerWidthConstraint = header.widthAnchor.constraint(equalTo: tableView.widthAnchor)
        headerWidthConstraint.priority = UILayoutPriority(999)

        NSLayoutConstraint.activate([
            centerConstraint,
            headerWidthConstraint,
            topConstraint
        ])
        tableView.tableHeaderView?.layoutIfNeeded()
        tableView.tableHeaderView = tableView.tableHeaderView
    }


    // Refresh the header of a site topic when returning in case the
    // topic's following status changed.
    private func refreshTableHeaderIfNeeded() {
        guard let _ = readerTopic else {
            return
        }
        configureStreamHeader()
    }


    /// Updates the content based on the values of `readerTopic` and `contentType`
    private func updateContent(synchronize: Bool = true) {
        // if the view has not been loaded yet, this will be called in viewDidLoad
        guard isViewLoaded else {
            return
        }
        // Enable the view now that we have a topic.
        view.isUserInteractionEnabled = true

        if let topic = readerTopic, ReaderHelpers.isTopicSearchTopic(topic) {
            // Disable pull to refresh for search topics.
            // Searches are a snap shot in time, and ephemeral. There should be no
            // need to refresh.
            tableViewController.refreshControl = nil
        }

        // saved posts are local so do not need a pull to refresh
        if contentType == .saved {
            tableViewController.refreshControl = nil
        }

        // Rather than repeatedly creating a service to check if the user is logged in, cache it here.
        isLoggedIn = AccountHelper.isDotcomAvailable()

        // Reset our display context to ensure its current.
        managedObjectContext().reset()

        configureTitleForTopic()
        configureShareButtonIfNeeded()
        hideResultsStatus()
        recentlyBlockedSitePostObjectIDs.removeAllObjects()
        updateAndPerformFetchRequest()
        if readerTopic != nil {
            configureStreamHeader()
        } else {
            tableView.tableHeaderView = nil
        }
        tableView.setContentOffset(CGPoint.zero, animated: false)
        content.refresh()
        refreshTableViewHeaderLayout()

        if synchronize {
            syncIfAppropriate()
        }

        bumpStats()

        // Make sure we're showing the no results view if appropriate
        if let syncHelper = syncHelper, !syncHelper.isSyncing, content.isEmpty {
            displayNoResultsView()
        } else if contentType == .saved, content.isEmpty {
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


    private func configureTitleForTopic() {
        guard let topic = readerTopic else {
            title = NSLocalizedString("Reader", comment: "The default title of the Reader")
            return
        }

        if ReaderHelpers.isTopicTag(topic) {
             title = NSLocalizedString("Topic", comment: "Topic page title")
        } else {
            title = topic.title
        }
    }


    /// Fetch and cache the current defaultAccount authtoken, if available.
    private func refreshImageRequestAuthToken() {
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
    private func postInMainContext(_ post: ReaderPost) -> ReaderPost? {
        guard let post = (try? ContextManager.sharedInstance().mainContext.existingObject(with: post.objectID)) as? ReaderPost else {
            DDLogError("Error retrieving an exsting post from the main context by its object ID.")
            return nil
        }
        return post
    }


    /// Refreshes the layout of the header.  Required for sizing the tableHeaderView according
    /// to its intrinsic content layout, and after major layout changes on the viewcontroller itself.
    ///
    private func refreshTableViewHeaderLayout() {
        guard let headerView = tableView.tableHeaderView else {
            return
        }

        // The tableView may need to layout, run this layout now, if needed.
        // This ensures the proper margins, such as readable margins, are
        // inherited and calculated by the headerView.
        tableView.layoutIfNeeded()

        // Start with the provided UILayoutFittingCompressedSize to let iOS handle its own magic
        // number for a "compressed" height, meaning we want our fitting size to be the minimal height.
        var fittingSize = UIView.layoutFittingCompressedSize

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
    @objc func scrollViewToTop() {
        tableView.setContentOffset(.zero, animated: true)
    }


    /// Returns the analytics property dictionary for the current topic.
    private func topicPropertyForStats() -> [AnyHashable: Any]? {
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
    private func updateAndPerformFetchRequest() {
        assert(Thread.isMainThread, "ReaderStreamViewController Error: updating fetch request on a background thread.")

        content.updateAndPerformFetchRequest(predicate: predicateForFetchRequest())
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


    func showManageSites(animated: Bool = true) {
        let controller = ReaderFollowedSitesViewController.controller()
        navigationController?.pushViewController(controller, animated: animated)
    }

    private func showFollowing() {
        WPTabBarController.sharedInstance().switchToFollowedSites()
    }

    // MARK: - Blocking

    private func blockSiteForPost(_ post: ReaderPost) {
        guard let indexPath = content.indexPath(forObject: post) else {
            return
        }

        let objectID = post.objectID
        recentlyBlockedSitePostObjectIDs.add(objectID)
        updateAndPerformFetchRequest()

        tableView.reloadRows(at: [indexPath], with: UITableView.RowAnimation.fade)

        ReaderBlockSiteAction(asBlocked: true).execute(with: post, context: managedObjectContext()) { [weak self] in
            self?.recentlyBlockedSitePostObjectIDs.remove(objectID)
            self?.tableView.reloadRows(at: [indexPath], with: UITableView.RowAnimation.fade)
        }
    }


    private func unblockSiteForPost(_ post: ReaderPost) {
        guard let indexPath = content.indexPath(forObject: post) else {
            return
        }

        let objectID = post.objectID
        recentlyBlockedSitePostObjectIDs.remove(objectID)

        tableView.reloadRows(at: [indexPath], with: UITableView.RowAnimation.fade)

        ReaderBlockSiteAction(asBlocked: false).execute(with: post, context: managedObjectContext()) { [weak self] in
            self?.recentlyBlockedSitePostObjectIDs.add(objectID)
            self?.tableView.reloadRows(at: [indexPath], with: UITableView.RowAnimation.fade)
        }
    }


    /// A user can block a site from the detail screen.  When this happens, we need
    /// to update the list UI to properly reflect the change. Listen for the
    /// notification and call blockSiteForPost as needed.
    ///
    @objc private func handleBlockSiteNotification(_ notification: Foundation.Notification) {
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
        if isLoadingDiscover {
            fetchSiteTopic()
            return
        }
        syncHelper?.syncContentWithUserInteraction(true)
        WPAnalytics.track(.readerPullToRefresh, properties: topicPropertyForStats() ?? [:])
    }


    // MARK: - Analytics


    /// Bump tracked analytics stats if necessary.
    ///
    private func bumpStats() {
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
    private func updateLastSyncedForTopic(_ objectID: NSManagedObjectID) {
        let context = ContextManager.sharedInstance().mainContext
        guard let topic = (try? context.existingObject(with: objectID)) as? ReaderAbstractTopic else {
            DDLogError("Failed to retrive an existing topic when updating last sync date.")
            return
        }
        topic.lastSynced = Date()
        ContextManager.sharedInstance().save(context)
    }


    private func canSync() -> Bool {
        return (readerTopic != nil || isLoadingDiscover) && connectionAvailable()
    }

    @objc func connectionAvailable() -> Bool {
        return WordPressAppDelegate.shared!.connectionAvailable
    }


    /// Kicks off a "background" sync without updating the UI if certain conditions
    /// are met.
    /// - There must be a topic
    /// - The controller must be the active controller.
    /// - The app must have a internet connection.
    /// - The app must be running on the foreground.
    /// - The current time must be greater than the last sync interval.
    ///
    func syncIfAppropriate(forceSync: Bool = false) {
        guard UIApplication.shared.isRunningTestSuite() == false else {
            return
        }

        guard WordPressAppDelegate.shared?.runningInBackground == false else {
            return
        }

        guard let topic = readerTopic else {
            return
        }

        if ReaderHelpers.isTopicSearchTopic(topic) && topicPostsCount > 0 {
            // We only perform an initial sync if the topic has no results.
            // The rest of the time it should just support infinite scroll.
            // Normal the newly added topic will have no existing posts. The
            // exception is state restoration of a search topic that was being
            // viewed when the app was backgrounded.
            return
        }

        let lastSynced = topic.lastSynced ?? Date(timeIntervalSince1970: 0)
        let interval = Int( Date().timeIntervalSince(lastSynced))

        if forceSync || (canSync() && (interval >= refreshInterval || topicPostsCount == 0)) {
            syncHelper?.syncContentWithUserInteraction(false)
        } else {
            handleConnectionError()
        }
    }

    /// Returns the number of posts for the current topic
    /// This allows the count to be overriden by subclasses
    var topicPostsCount: Int {
        return readerTopic?.posts.count ?? 0
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

    private func syncFillingGap(_ indexPath: IndexPath) {
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
        if let syncHelper = syncHelper, syncHelper.isSyncing {
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
        syncHelper?.syncContentWithUserInteraction(true)
    }

    private func syncItems(_ success: ((_ hasMore: Bool) -> Void)?, failure: ((_ error: NSError) -> Void)?) {
        guard let topic = readerTopic else {
            DDLogError("Error: Reader tried to sync items when the topic was nil.")
            return
        }

        syncContext.perform { [weak self] in
            guard let topicInContext = (try? self?.syncContext.existingObject(with: topic.objectID)) as? ReaderAbstractTopic else {
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

            self?.fetch(for: topicInContext, success: successBlock, failure: failureBlock)
        }
    }

    func fetch(for topic: ReaderAbstractTopic, success: @escaping ((_ count: Int, _ hasMore: Bool) -> Void), failure: @escaping ((_ error: Error?) -> Void)) {
        if ReaderHelpers.isTopicSearchTopic(topic) {
            service.fetchPosts(for: topic, atOffset: 0, deletingEarlier: false, success: success, failure: failure)
        } else if let topic = topic as? ReaderTagTopic {
            service.fetchPostsV2(for: topic, success: success, failure: failure)
        } else {
            service.fetchPosts(for: topic, earlierThan: Date(), success: success, failure: failure)
        }
    }

    private func syncItemsForGap(_ success: ((_ hasMore: Bool) -> Void)?, failure: ((_ error: NSError) -> Void)?) {
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

        let sortDate = post.sortDate

        syncContext.perform { [weak self] in
            guard let topicInContext = (try? self?.syncContext.existingObject(with: topic.objectID)) as? ReaderAbstractTopic else {
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
                self?.service.fetchPosts(for: topicInContext, atOffset: 0, deletingEarlier: true, success: successBlock, failure: failureBlock)
            } else {
                self?.service.fetchPosts(for: topicInContext, earlierThan: sortDate, deletingEarlier: true, success: successBlock, failure: failureBlock)
            }
        }
    }


    func loadMoreItems(_ success: ((_ hasMore: Bool) -> Void)?, failure: ((_ error: NSError) -> Void)?) {
        guard let topic = readerTopic else {
            assertionFailure("Tried to fill a gap when the topic was nil.")
            return
        }

        footerView.showSpinner(true)

        syncContext.perform { [weak self] in
            guard let topicInContext = (try? self?.syncContext.existingObject(with: topic.objectID)) as? ReaderAbstractTopic else {
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

            self?.fetchMore(for: topicInContext, success: successBlock, failure: failureBlock)
        }

        if let properties = topicPropertyForStats() {
            WPAppAnalytics.track(.readerInfiniteScroll, withProperties: properties)
        }
    }

    func fetchMore(for topic: ReaderAbstractTopic, success: @escaping ((Int, Bool) -> Void), failure: @escaping ((Error?) -> Void)) {
        guard
            let posts = content.content,
            let post = posts.last as? ReaderPost,
            let sortDate = post.sortDate
        else {
            DDLogError("Error: Unable to retrieve an existing reader gap marker.")
            return
        }

        if ReaderHelpers.isTopicSearchTopic(topic) {
            let offset = UInt(content.contentCount)
            service.fetchPosts(for: topic, atOffset: UInt(offset), deletingEarlier: false, success: success, failure: failure)
        } else if let topic = topic as? ReaderTagTopic {
            service.fetchPostsV2(for: topic, isFirstPage: false, success: success, failure: failure)
        } else {
            let earlierThan = sortDate
            service.fetchPosts(for: topic, earlierThan: earlierThan, success: success, failure: failure)
        }
    }

    private func cleanupAfterSync(refresh: Bool = true) {
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

    @objc private func defaultAccountDidChange(_ notification: Foundation.Notification) {
        refreshImageRequestAuthToken()
    }

    // MARK: - Helpers for TableViewHandler


    func predicateForFetchRequest() -> NSPredicate {
        // If readerTopic is nil return a predicate that is valid, but still
        // avoids returning readerPosts that do not belong to a topic (e.g. those
        // loaded from a notification). We can do this by specifying that self
        // has to exist within an empty set.
        let predicateForNilTopic = contentType == .saved ?
            NSPredicate(format: "isSavedForLater == YES") :
            NSPredicate(format: "topic = NULL AND SELF in %@", [])

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


    func sortDescriptorsForFetchRequest(ascending: Bool = false) -> [NSSortDescriptor] {
        let sortDescriptor = NSSortDescriptor(key: "sortRank", ascending: ascending)
        return [sortDescriptor]
    }


    private func configurePostCardCell(_ cell: UITableViewCell, post: ReaderPost) {
        if postCellActions == nil {
            postCellActions = ReaderPostCellActions(context: managedObjectContext(), origin: self, topic: readerTopic)
        }
        postCellActions?.isLoggedIn = isLoggedIn
        postCellActions?.savedPostsDelegate = self

        // Restrict the topics header to only display on the Discover, and tag detail views
        var displayTopics = false

        if let topic = readerTopic {
            let type = ReaderHelpers.topicType(topic)

            switch type {
            case .discover, .tag:
                displayTopics = true
            default:
                displayTopics = false
            }
        }

        cellConfiguration.configurePostCardCell(cell,
                                                withPost: post,
                                                topic: readerTopic ?? post.topic,
                                                delegate: postCellActions,
                                                loggedInActionVisibility: .visible(enabled: isLoggedIn),
                                                topicChipsDelegate: self,
                                                displayTopics: displayTopics)

    }

    @objc private func handleContextDidSaveNotification(_ notification: Foundation.Notification) {
        ContextManager.sharedInstance().mergeChanges(displayContext, fromContextDidSave: notification)
    }


    // MARK: - Helpers for ReaderStreamHeader
    public func toggleFollowingForTopic(_ topic: ReaderAbstractTopic?, completion: ((Bool) -> Void)?) {
        if let topic = topic as? ReaderTagTopic {
            toggleFollowingForTag(topic, completion: completion)
        } else if let topic = topic as? ReaderSiteTopic {
            toggleFollowingForSite(topic, completion: completion)
        } else if let topic = topic as? ReaderDefaultTopic, ReaderHelpers.topicIsFollowing(topic) {
            showManageSites()
        }
    }

    private func toggleFollowingForTag(_ topic: ReaderTagTopic, completion: ((Bool) -> Void)?) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()

        if !topic.following {
            generator.notificationOccurred(.success)
        }

        let service = ReaderTopicService(managedObjectContext: topic.managedObjectContext!)
        service.toggleFollowing(forTag: topic, success: {
            completion?(true)
        }, failure: { (error: Error?) in
            generator.notificationOccurred(.error)
            completion?(false)
        })
    }

    private func toggleFollowingForSite(_ topic: ReaderSiteTopic, completion: ((Bool) -> Void)?) {
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
            if toFollow {
                self?.dispatchSubscribingNotificationNotice(with: siteTitle, siteID: siteID)
            }

            completion?(true)
        }, failure: { (error: Error?) in
            generator.notificationOccurred(.error)
            completion?(false)
        })
    }
}


// MARK: - ReaderStreamHeaderDelegate

extension ReaderStreamViewController: ReaderStreamHeaderDelegate {

    func handleFollowActionForHeader(_ header: ReaderStreamHeader) {
        toggleFollowingForTopic(readerTopic) { [weak self] success in
            if success {
                self?.syncHelper?.syncContent()
            }

            self?.updateStreamHeaderIfNeeded()
        }

        updateStreamHeaderIfNeeded()
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
            reportStreamLoadFailure()
        }
    }

    private func reportStreamLoadFailure() {
        streamLoadFailureBlock?()

        // We'll nil out the failure block so we don't perform multiple callbacks
        streamLoadFailureBlock = nil
    }
}

// MARK: - WPTableViewHandlerDelegate

extension ReaderStreamViewController: WPTableViewHandlerDelegate {

    // MARK: Scrolling Related

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
    }


    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate {
            return
        }
        if cleanupAndRefreshAfterScrolling {
            cleanupAfterSync()
        }
    }


    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if cleanupAndRefreshAfterScrolling {
            cleanupAfterSync()
        }
    }


    // MARK: - Fetched Results Related

    func managedObjectContext() -> NSManagedObjectContext {
        return displayContext
    }


    func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderPost.classNameWithoutNamespaces())
        fetchRequest.predicate = predicateForFetchRequest()
        fetchRequest.sortDescriptors = sortDescriptorsForFetchRequest()
        return fetchRequest
    }


    func tableViewDidChangeContent(_ tableView: UITableView) {
        if content.contentCount == 0 {
            displayNoResultsView()
        }
    }


    // MARK: - Refresh Bookends

    func tableViewHandlerWillRefreshTableViewPreservingOffset(_ tableViewHandler: WPTableViewHandler) {
        // Reload the table view to reflect new content.
        managedObjectContext().reset()
        updateAndPerformFetchRequest()
    }

    func tableViewHandlerDidRefreshTableViewPreservingOffset(_ tableViewHandler: WPTableViewHandler) {
        hideResultsStatus()
        if tableViewHandler.resultsController.fetchedObjects?.count == 0 {
            if let syncHelper = syncHelper, syncHelper.isSyncing {
                return
            }
            displayNoResultsView()
        } else {
            tableView.flashScrollIndicators()
        }
    }


    // MARK: - TableView Related
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
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

    func tableView(_ aTableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let posts = content.content as? [ReaderPost] else {
            return UITableViewCell()
        }

        let post = posts[indexPath.row]

        return cell(for: post, at: indexPath)
    }

    func cell(for post: ReaderPost, at indexPath: IndexPath) -> UITableViewCell {
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

        if contentType == .saved, postCellActions?.postIsRemoved(post) == true {
            let cell = undoCell(tableView)
            configureUndoCell(cell, with: post)
            return cell
        }

        let cell = tableConfiguration.postCardCell(tableView)
        configurePostCardCell(cell, post: post)
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
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
            if let syncHelper = syncHelper, syncHelper.hasMoreContent && !syncHelper.isSyncing && !cleanupAndRefreshAfterScrolling {
                syncHelper.syncMoreContent()
            }
        }
        guard cell.isKind(of: ReaderPostCardCell.self) || cell.isKind(of: ReaderCrossPostCell.self) else {
            return
        }

        guard let posts = content.content as? [ReaderPost] else {
            return
        }

        let post = posts[indexPath.row]
        bumpRenderTracker(post)
    }

    func bumpRenderTracker(_ post: ReaderPost) {
        // Bump the render tracker if necessary.
        if !post.rendered, let railcar = post.railcarDictionary() {
            post.rendered = true
            WPAppAnalytics.track(.trainTracksRender, withProperties: railcar)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let posts = content.content as? [ReaderPost] else {
            DDLogError("[ReaderStreamViewController tableView:didSelectRowAtIndexPath:] fetchedObjects was nil.")
            return
        }

        let apost = posts[indexPath.row]
        didSelectPost(apost, at: indexPath)
    }

    func didSelectPost(_ apost: ReaderPost, at indexPath: IndexPath) {
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

        let controller = ReaderDetailViewController.controllerWithPost(post)

        if post.isSavedForLater || contentType == .saved {
            trackSavedPostNavigation()
        } else {
            WPAnalytics.track(.readerPostCardTapped, properties: topicPropertyForStats() ?? [:])
        }

        navigationController?.pushFullscreenViewController(controller, animated: true)

        tableView.deselectRow(at: indexPath, animated: false)
    }


    func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
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

// MARK: - Handling Loading and No Results

extension ReaderStreamViewController {

    func displayLoadingStream() {
        configureResultsStatus(title: ResultsStatusText.loadingStreamTitle, accessoryView: NoResultsViewController.loadingAccessoryView())
        displayResultsStatus()
        showGhost()
    }

    func displayLoadingStreamFailed() {
        configureResultsStatus(title: ResultsStatusText.loadingErrorTitle, subtitle: ResultsStatusText.loadingErrorMessage)
        displayResultsStatus()
        hideGhost()
    }

    func displayLoadingViewIfNeeded() {
        if content.contentCount > 0 {
            return
        }

        tableView.tableHeaderView?.isHidden = true
        configureResultsStatus(title: ResultsStatusText.fetchingPostsTitle, accessoryView: NoResultsViewController.loadingAccessoryView())
        displayResultsStatus()
        showGhost()
    }

    func displayNoResultsView() {
        // Its possible the topic was deleted before a sync could be completed,
        // so make certain its not nil.
        guard let topic = readerTopic else {
            if contentType == .saved {
                displayNoResultsForSavedPosts()
            } else if contentType == .topic && siteID == ReaderHelpers.discoverSiteID {
                displayNoResultsViewForDiscover()
            }
            return
        }

        tableView.tableHeaderView?.isHidden = true

        guard connectionAvailable() else {
            displayNoConnectionView()
            return
        }

        guard ReaderHelpers.topicIsFollowing(topic) else {
            let response: NoResultsResponse = ReaderStreamViewController.responseForNoResults(topic)

            let buttonTitle = buttonTitleForTopic(topic)

            configureResultsStatus(title: response.title, subtitle: response.message, buttonTitle: buttonTitle, imageName: readerEmptyImageName)
            displayResultsStatus()
            return
        }

        view.isUserInteractionEnabled = true

        if noFollowedSitesViewController == nil {
            let controller = NoResultsViewController.noFollowedSitesController(showActionButton: isLoggedIn)
            controller.delegate = self
            noFollowedSitesViewController = controller
        }

        displayResultsStatus()
    }

    func displayNoConnectionView() {
        configureResultsStatus(title: ResultsStatusText.noConnectionTitle, subtitle: noConnectionMessage())
        displayResultsStatus()
        hideGhost()
    }

    /// Removes the no followed sites view controller if it exists
    func resetNoFollowedSitesViewController() {
        if let noFollowedSitesVC = noFollowedSitesViewController {
            noFollowedSitesVC.removeFromView()
            noFollowedSitesViewController = nil
        }
    }

    func configureResultsStatus(title: String,
                                subtitle: String? = nil,
                                buttonTitle: String? = nil,
                                imageName: String? = nil,
                                accessoryView: UIView? = nil) {
        resetNoFollowedSitesViewController()

        resultsStatusView.configure(title: title, buttonTitle: buttonTitle, subtitle: subtitle, image: imageName, accessoryView: accessoryView)
    }

    private func displayNoResultsForSavedPosts() {
        resetNoFollowedSitesViewController()
        configureNoResultsViewForSavedPosts()
        displayResultsStatus()
    }

    private func displayNoResultsViewForDiscover() {
        configureResultsStatus(title: ReaderStreamViewController.defaultResponse.title,
                               subtitle: ReaderStreamViewController.defaultResponse.message,
                               imageName: readerEmptyImageName)
        displayResultsStatus()
    }

    func displayResultsStatus() {
        resultsStatusView.removeFromView()
        tableViewController.addChild(resultsStatusView)
        tableView.insertSubview(resultsStatusView.view, belowSubview: refreshControl)
        resultsStatusView.view.frame = tableView.frame
        resultsStatusView.didMove(toParent: tableViewController)
        resultsStatusView.updateView()
        footerView.isHidden = true
        hideGhost()
    }

    func hideResultsStatus() {
        resultsStatusView.removeFromView()
        footerView.isHidden = false
        tableView.tableHeaderView?.isHidden = false
        hideGhost()
    }

    func buttonTitleForTopic(_ topic: ReaderAbstractTopic) -> String? {
        if ReaderHelpers.topicIsFollowing(topic) {
            return ResultsStatusText.manageSitesButtonTitle
        }

        if ReaderHelpers.topicIsLiked(topic) {
            return ResultsStatusText.followingButtonTitle
        }

        return nil
    }

    struct ResultsStatusText {
        static let fetchingPostsTitle = NSLocalizedString("Fetching posts...", comment: "A brief prompt shown when the reader is empty, letting the user know the app is currently fetching new posts.")
        static let loadingStreamTitle = NSLocalizedString("Loading stream...", comment: "A short message to inform the user the requested stream is being loaded.")
        static let loadingErrorTitle = NSLocalizedString("Problem loading stream", comment: "Error message title informing the user that a stream could not be loaded.")
        static let loadingErrorMessage = NSLocalizedString("Sorry. The stream could not be loaded.", comment: "A short error message letting the user know the requested stream could not be loaded.")
        static let manageSitesButtonTitle = NSLocalizedString("Manage Sites", comment: "Button title. Tapping lets the user manage the sites they follow.")
        static let followingButtonTitle = NSLocalizedString("Go to Following", comment: "Button title. Tapping lets the user view the sites they follow.")
        static let noConnectionTitle = NSLocalizedString("Unable to Sync", comment: "Title of error prompt shown when a sync the user initiated fails.")
    }

    var readerEmptyImageName: String {
      return "wp-illustration-reader-empty"
    }

}

// MARK: - NoResultsViewControllerDelegate

extension ReaderStreamViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        guard let topic = readerTopic else {
            return
        }

        if ReaderHelpers.topicIsFollowing(topic) {
            showManageSites()
            return
        }

        if ReaderHelpers.topicIsLiked(topic) {
            showFollowing()
        }
    }
}

// MARK: - NetworkAwareUI Conformance

extension ReaderStreamViewController: NetworkAwareUI {
    func contentIsEmpty() -> Bool {
        return content.contentCount == 0
    }

    func noConnectionMessage() -> String {
        return NSLocalizedString("No internet connection. Some content may be unavailable while offline.",
                                 comment: "Error message shown when the user is browsing Reader without an internet connection.")
    }
}

// MARK: - NetworkAwareUI NetworkStatusDelegate

extension ReaderStreamViewController: NetworkStatusDelegate {
    func networkStatusDidChange(active: Bool) {
        if isLoadingDiscover {
            fetchSiteTopic()
        } else {
            syncIfAppropriate()
        }
    }
}

// MARK: - UIViewControllerTransitioningDelegate
//
extension ReaderStreamViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        guard presented is FancyAlertViewController else {
            return nil
        }

        return FancyAlertPresentationController(presentedViewController: presented, presenting: presenting)
    }
}


// MARK: - ReaderContentViewController
extension ReaderStreamViewController: ReaderContentViewController {
    func setContent(_ content: ReaderContent) {
        isContentFiltered = content.topicType == .tag || content.topicType == .site
        hideHeader = content.topicType == .site
        readerTopic = content.topicType == .discover ? nil : content.topic
        contentType = content.type
        guard !shouldDisplayNoTopicController else {
            return
        }
        siteID = content.topicType == .discover ? ReaderHelpers.discoverSiteID : nil
        trackFilterTime()
    }

    func trackFilterTime() {
        if isContentFiltered {
            ReaderTracker.shared.start(.filteredList)
        } else {
            ReaderTracker.shared.stop(.filteredList)
        }
    }
}


// MARK: - Saved Posts Delegate
extension ReaderStreamViewController: ReaderSavedPostCellActionsDelegate {
    func willRemove(_ cell: ReaderPostCardCell) {
        if let cellIndex = tableView.indexPath(for: cell) {
            tableView.reloadRows(at: [cellIndex], with: .fade)
        }
    }
}


// MARK: - Undo
extension ReaderStreamViewController: ReaderPostUndoCellDelegate {
    func readerCellWillUndo(_ cell: ReaderSavedPostUndoCell) {
        if let cellIndex = tableView.indexPath(for: cell),
            let post: ReaderPost = content.object(at: cellIndex) {
                postCellActions?.restoreUnsavedPost(post)
                tableView.reloadRows(at: [cellIndex], with: .fade)
        }
    }
}

// MARK: - View content types without a topic
private extension ReaderStreamViewController {

    var shouldDisplayNoTopicController: Bool {
        switch contentType {
        case .selfHostedFollowing:
            displaySelfHostedFollowingController()
            return true
        case .contentError:
            displayContentErrorController()
            return true
        default:
            removeNoTopicController()
            return false
        }
    }

    func displaySelfHostedFollowingController() {
        let controller = NoResultsViewController.noFollowedSitesController(showActionButton: isLoggedIn)
        controller.delegate = self

        addNoTopicController(controller)

        view.isUserInteractionEnabled = true
    }

    func displayContentErrorController() {
        let controller = noTopicViewController(title: NoTopicConstants.contentErrorTitle,
                             subtitle: NoTopicConstants.contentErrorSubtitle,
                             image: NoTopicConstants.contentErrorImage)
        addNoTopicController(controller)

        view.isUserInteractionEnabled = true
    }


    func noTopicViewController(title: String,
                               buttonTitle: String? = nil,
                               subtitle: String? = nil,
                               image: String? = nil) -> NoResultsViewController {
        let controller = NoResultsViewController.controller()
        controller.configure(title: title,
                             buttonTitle: buttonTitle,
                             subtitle: subtitle,
                             image: image)

        return controller
    }

    func addNoTopicController(_ controller: NoResultsViewController) {
        addChild(controller)
        view.addSubview(controller.view)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(controller.view)
        controller.didMove(toParent: self)
        noTopicController = controller
    }

    func removeNoTopicController() {
        if let controller = noTopicController as? NoResultsViewController {
            controller.removeFromView()
            noTopicController = nil
        }
    }

    enum NoTopicConstants {
        static let retryButtonTitle = NSLocalizedString("Retry", comment: "title for action that tries to connect to the reader after a loading error.")
        static let contentErrorTitle = NSLocalizedString("Unable to load this content right now.", comment: "Default title shown for no-results when the device is offline.")
        static let contentErrorSubtitle = NSLocalizedString("Check your network connection and try again.", comment: "Default subtitle for no-results when there is no connection")
        static let contentErrorImage = "cloud"
    }
}

extension ReaderStreamViewController: ReaderTopicsChipsDelegate {
    func heightDidChange() {
        // Forces the table view to layout the cells and update their heights
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    func didSelect(topic: String) {
        let topicStreamViewController = ReaderStreamViewController.controllerWithTagSlug(topic)
        navigationController?.pushViewController(topicStreamViewController, animated: true)
    }
}
