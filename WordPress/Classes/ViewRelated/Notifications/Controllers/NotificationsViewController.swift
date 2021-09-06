import Foundation
import CoreData
import CocoaLumberjack
import WordPressShared
import WordPressAuthenticator
import Gridicons

/// The purpose of this class is to render the collection of Notifications, associated to the main
/// WordPress.com account.
///
/// Plus, we provide a simple mechanism to render the details for a specific Notification,
/// given its remote identifier.
///
class NotificationsViewController: UITableViewController, UIViewControllerRestoration {

    @objc static let selectedNotificationRestorationIdentifier = "NotificationsSelectedNotificationKey"
    @objc static let selectedSegmentIndexRestorationIdentifier   = "NotificationsSelectedSegmentIndexKey"

    // MARK: - Properties

    let formatter = FormattableContentFormatter()

    /// TableHeader
    ///
    @IBOutlet var tableHeaderView: UIView!

    /// Filtering Tab Bar
    ///
    @IBOutlet weak var filterTabBar: FilterTabBar!

    /// The unified list requires an extra 10pt space on top of the list, but returns to the original padding
    /// while scrolled and stickied. This should be removed once the unified list is fully rolled out.
    /// See: https://git.io/JBQlU
    ///
    @IBOutlet private weak var filterTabBarBottomConstraint: NSLayoutConstraint!

    /// Inline Prompt Header View
    ///
    @IBOutlet var inlinePromptView: AppFeedbackPromptView!

    /// TableView Handler: Our commander in chief!
    ///
    fileprivate var tableViewHandler: WPTableViewHandler!

    /// NoResults View
    ///
    private let noResultsViewController = NoResultsViewController.controller()

    /// All of the data will be fetched during the FetchedResultsController init. Prevent overfetching
    ///
    fileprivate var lastReloadDate = Date()

    /// Indicates whether the view is required to reload results on viewWillAppear, or not
    ///
    fileprivate var needsReloadResults = false

    /// Cached values used for returning the estimated row heights of autosizing cells.
    ///
    fileprivate let estimatedRowHeightsCache = NSCache<AnyObject, AnyObject>()

    /// Notifications that must be deleted display an "Undo" button, which simply cancels the deletion task.
    ///
    fileprivate var notificationDeletionRequests: [NSManagedObjectID: NotificationDeletionRequest] = [:]

    /// Notifications being deleted are proactively filtered from the list.
    ///
    fileprivate var notificationIdsBeingDeleted = Set<NSManagedObjectID>()

    /// Notifications that were unread when the list was loaded.
    ///
    fileprivate var unreadNotificationIds = Set<NSManagedObjectID>()

    /// Used to store (and restore) the currently selected filter segment.
    ///
    fileprivate var restorableSelectedSegmentIndex: Int = 0

    /// Used to keep track of the currently selected notification,
    /// to restore it between table view reloads and state restoration.
    ///
    fileprivate var selectedNotification: Notification? = nil

    /// JetpackLoginVC being presented.
    ///
    internal var jetpackLoginViewController: JetpackLoginViewController? = nil

    /// Timestamp of the most recent note before updates
    /// Used to count notifications to show the second notifications prompt
    ///
    private var timestampBeforeUpdatesForSecondAlert: String?

    /// Activity Indicator to be shown when refreshing a Jetpack site status.
    ///
    let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    /// Notification Settings button
    lazy var notificationSettingsButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: .gridicon(.cog), style: .plain, target: self, action: #selector(showNotificationSettings))
        button.accessibilityLabel = NSLocalizedString("Notification Settings", comment: "Link to Notification Settings section")
        return button
    }()

    /// Convenience property that stores feature flag value for unified list.
    /// This should be removed once the feature is fully rolled out.
    private var usesUnifiedList: Bool = FeatureFlag.unifiedCommentsAndNotificationsList.enabled {
        didSet {
            // Since this view controller is the root view controller for notifications tab, we need to check whether
            // the value has changed in `viewWillAppear`. If so, reload the table view to use the correct design.
            if usesUnifiedList != oldValue {
                reloadTableViewPreservingSelection()
                updateFilterBarConstraints()
            }
        }
    }

    // MARK: - View Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        restorationClass = NotificationsViewController.self

        startListeningToAccountNotifications()
        startListeningToTimeChangeNotifications()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
        setupTableView()
        setupTableFooterView()
        setupTableHandler()
        setupRefreshControl()
        setupNoResultsView()
        setupFilterBar()

        tableView.tableHeaderView = tableHeaderView
        setupConstraints()

        reloadTableViewPreservingSelection()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setupInlinePrompt()

        // Manually deselect the selected row.
        if splitViewControllerIsHorizontallyCompact {
            // This is required due to a bug in iOS7 / iOS8
            tableView.deselectSelectedRowWithAnimation(true)

            selectedNotification = nil
        }

        // While we're onscreen, please, update rows with animations
        tableViewHandler.updateRowAnimation = .fade

        // Tracking
        WPAnalytics.track(WPAnalyticsStat.openedNotificationsList)

        // Notifications
        startListeningToNotifications()
        resetApplicationBadge()
        updateLastSeenTime()

        // Refresh the UI
        reloadResultsControllerIfNeeded()

        if !splitViewControllerIsHorizontallyCompact {
            reloadTableViewPreservingSelection()
        }

        if !AccountHelper.isDotcomAvailable() {
            promptForJetpackCredentials()
        } else {
            jetpackLoginViewController?.view.removeFromSuperview()
            jetpackLoginViewController?.removeFromParent()
        }

        // Refresh feature flag value for unified list.
        // This should be removed when the feature is fully rolled out.
        usesUnifiedList = FeatureFlag.unifiedCommentsAndNotificationsList.enabled

        showNoResultsViewIfNeeded()
        selectFirstNotificationIfAppropriate()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        syncNewNotifications()
        markSelectedNotificationAsRead()

        registerUserActivity()

        markWelcomeNotificationAsSeenIfNeeded()

        if userDefaults.notificationsTabAccessCount < Constants.inlineTabAccessCount {
            userDefaults.notificationsTabAccessCount += 1
        }

        if shouldShowPrimeForPush {
            setupNotificationPrompt()
        } else if AppRatingUtility.shared.shouldPromptForAppReview(section: InlinePrompt.section) {
            setupAppRatings()
            self.showInlinePrompt()
        }
        showNotificationPrimerAlertIfNeeded()
        showSecondNotificationsAlertIfNeeded()

        if AppConfiguration.showsWhatIsNew {
            WPTabBarController.sharedInstance()?.presentWhatIsNew(on: self)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopListeningToNotifications()

        dismissNoNetworkAlert()

        // If we're not onscreen, don't use row animations. Otherwise the fade animation might get animated incrementally
        tableViewHandler.updateRowAnimation = .none
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.layoutHeaderView()
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        DispatchQueue.main.async {
            self.showNoResultsViewIfNeeded()
        }

        if splitViewControllerIsHorizontallyCompact {
            tableView.deselectSelectedRowWithAnimation(true)
        } else {
            if let selectedNotification = selectedNotification {
                selectRow(for: selectedNotification, animated: true, scrollPosition: .middle)
            } else {
                selectFirstNotificationIfAppropriate()
            }
        }

        tableView.tableHeaderView = tableHeaderView
    }

    // MARK: - State Restoration

    static func viewController(withRestorationIdentifierPath identifierComponents: [String],
                               coder: NSCoder) -> UIViewController? {
        return WPTabBarController.sharedInstance().notificationsViewController
    }

    override func encodeRestorableState(with coder: NSCoder) {
        if let uriRepresentation = selectedNotification?.objectID.uriRepresentation() {
            coder.encode(uriRepresentation, forKey: type(of: self).selectedNotificationRestorationIdentifier)
        }

        // If the filter's 'Unread', we won't save it because the notification
        // that's selected won't be unread any more once we come back to it.
        let index: Filter = (filter != .unread) ? filter : .none
        coder.encode(index.rawValue, forKey: type(of: self).selectedSegmentIndexRestorationIdentifier)

        super.encodeRestorableState(with: coder)
    }

    override func decodeRestorableState(with coder: NSCoder) {
        decodeSelectedSegmentIndex(with: coder)
        decodeSelectedNotification(with: coder)

        reloadResultsController()

        super.decodeRestorableState(with: coder)
    }

    fileprivate func decodeSelectedNotification(with coder: NSCoder) {
        if let uriRepresentation = coder.decodeObject(forKey: type(of: self).selectedNotificationRestorationIdentifier) as? URL {
            let context = ContextManager.sharedInstance().mainContext
            if let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uriRepresentation),
                let object = try? context.existingObject(with: objectID),
                let notification = object as? Notification {
                selectedNotification = notification
            }
        }
    }

    fileprivate func decodeSelectedSegmentIndex(with coder: NSCoder) {
        restorableSelectedSegmentIndex = coder.decodeInteger(forKey: type(of: self).selectedSegmentIndexRestorationIdentifier)

        if let filterTabBar = filterTabBar, filterTabBar.selectedIndex != restorableSelectedSegmentIndex {
            filterTabBar.setSelectedIndex(restorableSelectedSegmentIndex, animated: false)
        }
    }

    override func applicationFinishedRestoringState() {
        super.applicationFinishedRestoringState()

        guard let navigationControllers = navigationController?.children else {
            return
        }

        for case let detailVC as NotificationDetailsViewController in navigationControllers {
            if detailVC.onDeletionRequestCallback == nil, let note = detailVC.note {
                configureDetailsViewController(detailVC, withNote: note)
            }
        }
    }

    // MARK: - UITableView Methods

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionInfo = tableViewHandler.resultsController.sections?[section] else {
            return nil
        }

        if usesUnifiedList,
           let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ListTableHeaderView.defaultReuseID) as? ListTableHeaderView {
            headerView.title = Notification.descriptionForSectionIdentifier(sectionInfo.name)
            return headerView
        }

        let headerView = NoteTableHeaderView.makeFromNib()
        headerView.title = Notification.descriptionForSectionIdentifier(sectionInfo.name)
        headerView.separatorColor = tableView.separatorColor

        return headerView
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // Make sure no SectionFooter is rendered
        return CGFloat.leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // Make sure no SectionFooter is rendered
        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = usesUnifiedList ? ListTableViewCell.defaultReuseID : NoteTableViewCell.reuseIdentifier()
        let expectedType = usesUnifiedList ? ListTableViewCell.self : NoteTableViewCell.self
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)

        guard type(of: cell) == expectedType else {
            DDLogError("Error getting Notification table cell.")
            return .init()
        }

        configureCell(cell, at: indexPath)

        return cell
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        estimatedRowHeightsCache.setObject(cell.frame.height as AnyObject, forKey: indexPath as AnyObject)
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if let height = estimatedRowHeightsCache.object(forKey: indexPath as AnyObject) as? CGFloat {
            return height
        }
        return Settings.estimatedRowHeight
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Failsafe: Make sure that the Notification (still) exists
        guard let note = tableViewHandler.resultsController.managedObject(atUnsafe: indexPath) as? Notification else {
            tableView.deselectSelectedRowWithAnimation(true)
            return
        }

        // Push the Details: Unless the note has a pending deletion!
        guard deletionRequestForNoteWithID(note.objectID) == nil else {
            return
        }

        selectedNotification = note
        showDetails(for: note)
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // skip when the notification is marked for deletion.
        guard let note = tableViewHandler.resultsController.object(at: indexPath) as? Notification,
              deletionRequestForNoteWithID(note.objectID) == nil else {
            return nil
        }

        let isRead = note.read

        let title = isRead ? NSLocalizedString("Mark Unread", comment: "Marks a notification as unread") : NSLocalizedString("Mark Read", comment: "Marks a notification as unread")

        let action = UIContextualAction(style: .normal, title: title, handler: { (action, view, completionHandler) in
            if isRead {
                self.markAsUnread(note: note)
            } else {
                self.markAsRead(note: note)
            }
            completionHandler(true)
        })
        action.backgroundColor = .neutral(.shade50)

        return UISwipeActionsConfiguration(actions: [action])
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // skip when the notification is marked for deletion.
        guard let note = tableViewHandler.resultsController.object(at: indexPath) as? Notification,
            let block: FormattableCommentContent = note.contentGroup(ofKind: .comment)?.blockOfKind(.comment),
            deletionRequestForNoteWithID(note.objectID) == nil else {
            return nil
        }

        var actions: [UIContextualAction] = []

        // Trash comment
        if let trashAction = block.action(id: TrashCommentAction.actionIdentifier()),
            let command = trashAction.command,
            let title = command.actionTitle {
            let action = UIContextualAction(style: .normal, title: title, handler: { (_, _, completionHandler) in
                let actionContext = ActionContext(block: block, completion: { [weak self] (request, success) in
                    guard let request = request else {
                        return
                    }
                    self?.showUndeleteForNoteWithID(note.objectID, request: request)
                })
                trashAction.execute(context: actionContext)
                completionHandler(true)
            })
            action.backgroundColor = command.actionColor
            actions.append(action)
        }

        // Approve comment
        guard let approveEnabled = block.action(id: ApproveCommentAction.actionIdentifier())?.enabled, approveEnabled == true else {
            return nil
        }

        let approveAction = block.action(id: ApproveCommentAction.actionIdentifier())
        if let title = approveAction?.command?.actionTitle {
            let action = UIContextualAction(style: .normal, title: title, handler: { (_, _, completionHandler) in
                let actionContext = ActionContext(block: block)
                approveAction?.execute(context: actionContext)
                completionHandler(true)
            })
            action.backgroundColor = approveAction?.command?.actionColor
            actions.append(action)
        }

        let configuration = UISwipeActionsConfiguration(actions: actions)
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let note = sender as? Notification else {
            return
        }

        guard let detailsViewController = segue.destination as? NotificationDetailsViewController else {
            return
        }

        configureDetailsViewController(detailsViewController, withNote: note)
    }

    fileprivate func configureDetailsViewController(_ detailsViewController: NotificationDetailsViewController, withNote note: Notification) {
        detailsViewController.navigationItem.largeTitleDisplayMode = .never
        detailsViewController.dataSource = self
        detailsViewController.note = note
        detailsViewController.onDeletionRequestCallback = { request in
            self.showUndeleteForNoteWithID(note.objectID, request: request)
        }
        detailsViewController.onSelectedNoteChange = { note in
            self.selectRow(for: note)
        }
    }
}



// MARK: - User Interface Initialization
//
private extension NotificationsViewController {
    func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        // Don't show 'Notifications' in the next-view back button
        // we are using a space character because we need a non-empty string to ensure a smooth
        // transition back, with large titles enabled.
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        navigationItem.title = NSLocalizedString("Notifications", comment: "Notifications View Controller title")
    }

    func updateNavigationItems() {
        navigationItem.rightBarButtonItem = shouldDisplaySettingsButton ? notificationSettingsButton : nil
    }

    @objc func closeNotificationSettings() {
        dismiss(animated: true, completion: nil)
    }

    func setupConstraints() {
        // Inline prompt is initially hidden!
        inlinePromptView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableHeaderView.topAnchor.constraint(equalTo: tableView.topAnchor),
            tableHeaderView.safeLeadingAnchor.constraint(equalTo: tableView.safeLeadingAnchor),
            tableHeaderView.safeTrailingAnchor.constraint(equalTo: tableView.safeTrailingAnchor)
        ])
    }

    func setupTableView() {
        // Since this view controller is a root view controller for the notifications tab, both `NoteTableViewCell` and the new List components
        // need to be registered to handle feature flag changes. When the feature is fully rolled out, let's remove NoteTableViewCell.

        // Register unified list components.
        tableView.register(ListTableHeaderView.defaultNib, forHeaderFooterViewReuseIdentifier: ListTableHeaderView.defaultReuseID)
        tableView.register(ListTableViewCell.defaultNib, forCellReuseIdentifier: ListTableViewCell.defaultReuseID)

        // Register the cells
        let nib = UINib(nibName: NoteTableViewCell.classNameWithoutNamespaces(), bundle: Bundle.main)
        tableView.register(nib, forCellReuseIdentifier: NoteTableViewCell.reuseIdentifier())

        // UITableView
        tableView.accessibilityIdentifier  = "Notifications Table"
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.estimatedSectionHeaderHeight = UITableView.automaticDimension
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
        WPStyleGuide.configureColors(view: view, tableView: tableView)
    }

    func setupTableFooterView() {
        //  Fix: Hide the cellSeparators, when the table is empty
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 1))
    }

    func setupTableHandler() {
        let handler = WPTableViewHandler(tableView: tableView)
        handler.cacheRowHeights = false
        handler.delegate = self
        tableViewHandler = handler
    }

    func setupInlinePrompt() {
        precondition(inlinePromptView != nil)

        inlinePromptView.alpha = WPAlphaZero

        inlinePromptView.isHidden = true
    }

    func setupRefreshControl() {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(refresh), for: .valueChanged)
        refreshControl = control
    }

    func setupNoResultsView() {
        noResultsViewController.delegate = self
    }

    func setupFilterBar() {
        WPStyleGuide.configureFilterTabBar(filterTabBar)
        filterTabBar.superview?.backgroundColor = .filterBarBackground

        filterTabBar.items = Filter.allFilters
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
        updateFilterBarConstraints()
    }

    /// If notifications are displayed with the new unified list, add an extra space below the filter tab bar.
    /// Once unified list is fully rolled out, this should be applied in Notifications.storyboard instead.
    /// See: https://git.io/JBQlU
    func updateFilterBarConstraints() {
        filterTabBarBottomConstraint.constant = usesUnifiedList ? Constants.filterTabBarBottomSpace : 0

        // With the 10pt bottom padding addition, ensure that the extra padding has the same background color
        // as the table header cell. NOTE: Move this line to `setupFilterBar` once the feature flag is removed.
        filterTabBar.superview?.backgroundColor = usesUnifiedList ? .systemBackground : .filterBarBackground
    }
}



// MARK: - Notifications
//
private extension NotificationsViewController {
    func startListeningToNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        nc.addObserver(self, selector: #selector(notificationsWereUpdated), name: NSNotification.Name(rawValue: NotificationSyncMediatorDidUpdateNotifications), object: nil)
        nc.addObserver(self, selector: #selector(dynamicTypeDidChange), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }

    func startListeningToAccountNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(defaultAccountDidChange), name: NSNotification.Name.WPAccountDefaultWordPressComAccountChanged, object: nil)
    }

    func startListeningToTimeChangeNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(significantTimeChange),
                       name: UIApplication.significantTimeChangeNotification,
                       object: nil)
    }

    func stopListeningToNotifications() {
        let nc = NotificationCenter.default
        nc.removeObserver(self,
                          name: UIApplication.didBecomeActiveNotification,
                          object: nil)
        nc.removeObserver(self,
                          name: NSNotification.Name(rawValue: NotificationSyncMediatorDidUpdateNotifications),
                          object: nil)
    }

    @objc func applicationDidBecomeActive(_ note: Foundation.Notification) {
        // Let's reset the badge, whenever the app comes back to FG, and this view was upfront!
        guard isViewLoaded == true && view.window != nil else {
            return
        }

        resetApplicationBadge()
        updateLastSeenTime()
        reloadResultsControllerIfNeeded()
    }

    @objc func defaultAccountDidChange(_ note: Foundation.Notification) {
        needsReloadResults = true
        resetNotifications()
        resetLastSeenTime()
        resetApplicationBadge()
        syncNewNotifications()
    }

    @objc func notificationsWereUpdated(_ note: Foundation.Notification) {
        // If we're onscreen, don't leave the badge updated behind
        guard UIApplication.shared.applicationState == .active else {
            return
        }

        resetApplicationBadge()
        updateLastSeenTime()
    }

    @objc func significantTimeChange(_ note: Foundation.Notification) {
        needsReloadResults = true
        if UIApplication.shared.applicationState == .active
            && isViewLoaded == true
            && view.window != nil {
            reloadResultsControllerIfNeeded()
        }
    }

    @objc func dynamicTypeDidChange() {
        tableViewHandler.resultsController.fetchedObjects?.forEach {
            ($0 as? Notification)?.resetCachedAttributes()
        }
    }
}



// MARK: - Public Methods
//
extension NotificationsViewController {
    /// Pushes the Details for a given notificationID, immediately, if the notification is already available.
    /// Otherwise, will attempt to Sync the Notification. If this cannot be achieved before the timeout defined
    /// by `Syncing.pushMaxWait` kicks in, we'll just do nothing (in order not to disrupt the UX!).
    ///
    /// - Parameter notificationID: The ID of the Notification that should be rendered onscreen.
    ///
    @objc
    func showDetailsForNotificationWithID(_ noteId: String) {
        if let note = loadNotification(with: noteId) {
            showDetails(for: note)
            return
        }

        syncNotification(with: noteId, timeout: Syncing.pushMaxWait) { note in
            self.showDetails(for: note)
        }
    }

    /// Pushes the details for a given Notification Instance.
    ///
    private func showDetails(for note: Notification) {
        DDLogInfo("Pushing Notification Details for: [\(note.notificationId)]")

        // Before trying to show the details of a notification, we need to make sure the view is loaded.
        //
        // Ref: https://github.com/wordpress-mobile/WordPress-iOS/issues/12669#issuecomment-561579415
        // Ref: https://sentry.io/organizations/a8c/issues/1329631657/
        //
        loadViewIfNeeded()

        /// Note: markAsRead should be the *first* thing we do. This triggers a context save, and may have many side effects that
        /// could affect the OP's that go below!!!.
        ///
        /// YES figuring that out took me +90 minutes of debugger time!!!
        ///
        markAsRead(note: note)
        trackWillPushDetails(for: note)

        ensureNotificationsListIsOnscreen()
        ensureNoteIsNotBeingFiltered(note)
        selectRow(for: note, animated: false, scrollPosition: .top)

        // Display Details
        //
        if let postID = note.metaPostID, let siteID = note.metaSiteID, note.kind == .matcher || note.kind == .newPost {
            let readerViewController = ReaderDetailViewController.controllerWithPostID(postID, siteID: siteID)
            readerViewController.navigationItem.largeTitleDisplayMode = .never
            showDetailViewController(readerViewController, sender: nil)

            return
        }

        // This dispatch avoids a bug that was occurring occasionally where navigation (nav bar and tab bar)
        // would be missing entirely when launching the app from the background and presenting a notification.
        // The issue seems tied to performing a `pop` in `prepareToShowDetails` and presenting
        // the new detail view controller at the same time. More info: https://github.com/wordpress-mobile/WordPress-iOS/issues/6976
        //
        // Plus: Avoid pushing multiple DetailsViewController's, upon quick & repeated touch events.
        //
        view.isUserInteractionEnabled = false

        DispatchQueue.main.async {
            self.performSegue(withIdentifier: NotificationDetailsViewController.classNameWithoutNamespaces(), sender: note)
            self.view.isUserInteractionEnabled = true
        }
    }

    /// Tracks: Details Event!
    ///
    private func trackWillPushDetails(for note: Notification) {
        // Ensure we don't track if the app has been launched by a push notification in the background
        if UIApplication.shared.applicationState != .background {
            let properties = [Stats.noteTypeKey: note.type ?? Stats.noteTypeUnknown]
            WPAnalytics.track(.openedNotificationDetails, withProperties: properties)
        }
    }

    /// Failsafe: Make sure the Notifications List is onscreen!
    ///
    private func ensureNotificationsListIsOnscreen() {
        guard navigationController?.visibleViewController != self else {
            return
        }

        _ = navigationController?.popViewController(animated: false)
    }

    /// This method will make sure the Notification that's about to be displayed is not currently being filtered.
    ///
    private func ensureNoteIsNotBeingFiltered(_ note: Notification) {
        guard filter != .none else {
            return
        }

        let noteIndexPath = tableView.indexPathsForVisibleRows?.first { indexPath in
            return note == tableViewHandler.resultsController.object(at: indexPath) as? Notification
        }

        guard noteIndexPath == nil else {
            return
        }

        filter = .none
    }

    /// Will display an Undelete button on top of a given notification.
    /// On timeout, the destructive action (received via parameter) will be exeuted, and the notification
    /// will (supposedly) get deleted.
    ///
    /// -   Parameters:
    ///     -   noteObjectID: The Core Data ObjectID associated to a given notification.
    ///     -   request: A DeletionRequest Struct
    ///
    private func showUndeleteForNoteWithID(_ noteObjectID: NSManagedObjectID, request: NotificationDeletionRequest) {
        // Mark this note as Pending Deletion and Reload
        notificationDeletionRequests[noteObjectID] = request
        reloadRowForNotificationWithID(noteObjectID)

        // Dispatch the Action block
        perform(#selector(deleteNoteWithID), with: noteObjectID, afterDelay: Syncing.undoTimeout)
    }

    /// Presents the Notifications Settings screen.
    ///
    @objc func showNotificationSettings() {
        let controller = NotificationSettingsViewController()
        controller.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(closeNotificationSettings))

        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .formSheet
        navigationController.modalTransitionStyle = .coverVertical

        present(navigationController, animated: true, completion: nil)
    }
}


// MARK: - Notifications Deletion Mechanism
//
private extension NotificationsViewController {
    @objc func deleteNoteWithID(_ noteObjectID: NSManagedObjectID) {
        // Was the Deletion Canceled?
        guard let request = deletionRequestForNoteWithID(noteObjectID) else {
            return
        }

        // Hide the Notification
        notificationIdsBeingDeleted.insert(noteObjectID)
        reloadResultsController()

        // Hit the Deletion Action
        request.action { success in
            self.notificationDeletionRequests.removeValue(forKey: noteObjectID)
            self.notificationIdsBeingDeleted.remove(noteObjectID)

            // Error: let's unhide the row
            if success == false {
                self.reloadResultsController()
            }
        }
    }

    func cancelDeletionRequestForNoteWithID(_ noteObjectID: NSManagedObjectID) {
        notificationDeletionRequests.removeValue(forKey: noteObjectID)
        reloadRowForNotificationWithID(noteObjectID)

        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(deleteNoteWithID), object: noteObjectID)
    }

    func deletionRequestForNoteWithID(_ noteObjectID: NSManagedObjectID) -> NotificationDeletionRequest? {
        return notificationDeletionRequests[noteObjectID]
    }
}



// MARK: - Marking as Read
//
private extension NotificationsViewController {

    func markSelectedNotificationAsRead() {
        guard let note = selectedNotification else {
            return
        }

        markAsRead(note: note)
    }

    func markAsRead(note: Notification) {
        guard !note.read else {
            return
        }

        NotificationSyncMediator()?.markAsRead(note)
    }

    func markAsUnread(note: Notification) {
        guard note.read else {
            return
        }

        NotificationSyncMediator()?.markAsUnread(note)
    }

    func markWelcomeNotificationAsSeenIfNeeded() {
        let welcomeNotificationSeenKey = userDefaults.welcomeNotificationSeenKey
        if !userDefaults.bool(forKey: welcomeNotificationSeenKey) {
            userDefaults.set(true, forKey: welcomeNotificationSeenKey)
            resetApplicationBadge()
        }
    }
}



// MARK: - Unread notifications caching
//
private extension NotificationsViewController {
    /// Updates the cached list of unread notifications, and optionally reloads the results controller.
    ///
    func refreshUnreadNotifications(reloadingResultsController: Bool = true) {
        guard let notes = tableViewHandler.resultsController.fetchedObjects as? [Notification] else {
            return
        }

        let previous = unreadNotificationIds

        // This is additive because we don't want to remove anything
        // from the list unless we explicitly call
        // clearUnreadNotifications()
        notes.lazy.filter({ !$0.read }).forEach { note in
            unreadNotificationIds.insert(note.objectID)
        }
        if previous != unreadNotificationIds && reloadingResultsController {
            reloadResultsController()
        }
    }

    /// Empties the cached list of unread notifications.
    ///
    func clearUnreadNotifications() {
        let shouldReload = !unreadNotificationIds.isEmpty
        unreadNotificationIds.removeAll()
        if shouldReload {
            reloadResultsController()
        }
    }
}



// MARK: - WPTableViewHandler Helpers
//
private extension NotificationsViewController {
    func reloadResultsControllerIfNeeded() {
        // NSFetchedResultsController groups notifications based on a transient property ("sectionIdentifier").
        // Simply calling reloadData doesn't make the FRC recalculate the sections.
        // For that reason, let's force a reload, only when 1 day has elapsed, and sections would have changed.
        //
        let daysElapsed = Calendar.current.daysElapsedSinceDate(lastReloadDate)
        guard daysElapsed != 0 || needsReloadResults else {
            return
        }

        reloadResultsController()
    }

    func reloadResultsController() {
        // Update the Predicate: We can't replace the previous fetchRequest, since it's readonly!
        let fetchRequest = tableViewHandler.resultsController.fetchRequest
        fetchRequest.predicate = predicateForFetchRequest()

        /// Refetch + Reload
        _ = try? tableViewHandler.resultsController.performFetch()

        reloadTableViewPreservingSelection()

        // Empty State?
        showNoResultsViewIfNeeded()

        // Don't overwork!
        lastReloadDate = Date()
        needsReloadResults = false
    }

    func reloadRowForNotificationWithID(_ noteObjectID: NSManagedObjectID) {
        do {
            let note = try mainContext.existingObject(with: noteObjectID)

            if let indexPath = tableViewHandler.resultsController.indexPath(forObject: note) {
                tableView.reloadRows(at: [indexPath], with: .fade)
            }
        } catch {
            DDLogError("Error refreshing Notification Row \(error)")
        }
    }

    func selectRow(for notification: Notification, animated: Bool = true,
                   scrollPosition: UITableView.ScrollPosition = .none) {
        selectedNotification = notification

        if let indexPath = tableViewHandler.resultsController.indexPath(forObject: notification), indexPath != tableView.indexPathForSelectedRow {
            DDLogInfo("\(self) \(#function) Selecting row at \(indexPath) for Notification: \(notification.notificationId) (\(notification.type ?? "Unknown type")) - \(notification.title ?? "No title")")
            tableView.selectRow(at: indexPath, animated: animated, scrollPosition: scrollPosition)
        }
    }

    func reloadTableViewPreservingSelection() {
        tableView.reloadData()

        // Show the current selection if our split view isn't collapsed
        if !splitViewControllerIsHorizontallyCompact, let notification = selectedNotification {
            selectRow(for: notification, animated: false, scrollPosition: .none)
        }
    }
}

// MARK: - UIRefreshControl Methods
//
extension NotificationsViewController {
    @objc func refresh() {
        guard let mediator = NotificationSyncMediator() else {
            refreshControl?.endRefreshing()
            return
        }

        let start = Date()

        mediator.sync { [weak self] (error, _) in

            let delta = max(Syncing.minimumPullToRefreshDelay + start.timeIntervalSinceNow, 0)
            let delay = DispatchTime.now() + Double(Int64(delta * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)

            DispatchQueue.main.asyncAfter(deadline: delay) {
                self?.refreshControl?.endRefreshing()
                self?.clearUnreadNotifications()

                if let _ = error {
                    self?.handleConnectionError()
                }
            }
        }
    }
}

extension NotificationsViewController: NetworkAwareUI {
    func contentIsEmpty() -> Bool {
        return tableViewHandler.resultsController.isEmpty()
    }

    func noConnectionMessage() -> String {
        return NSLocalizedString("No internet connection. Some content may be unavailable while offline.",
                                 comment: "Error message shown when the user is browsing Notifications without an internet connection.")
    }
}

extension NotificationsViewController: NetworkStatusDelegate {
    func networkStatusDidChange(active: Bool) {
        reloadResultsControllerIfNeeded()
    }
}

// MARK: - FilterTabBar Methods
//
extension NotificationsViewController {

    @objc func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        selectedNotification = nil

        let properties = [Stats.selectedFilter: filter.analyticsTitle]
        WPAnalytics.track(.notificationsTappedSegmentedControl, withProperties: properties)

        updateUnreadNotificationsForFilterTabChange()

        reloadResultsController()

        selectFirstNotificationIfAppropriate()
    }

    @objc func selectFirstNotificationIfAppropriate() {
        guard !splitViewControllerIsHorizontallyCompact && selectedNotification == nil else {
            return
        }

        // If we don't currently have a selected notification and there is a notification in the list, then select it.
        if let firstNotification = tableViewHandler.resultsController.fetchedObjects?.first as? Notification,
            let indexPath = tableViewHandler.resultsController.indexPath(forObject: firstNotification) {
            selectRow(for: firstNotification, animated: false, scrollPosition: .none)
            self.tableView(tableView, didSelectRowAt: indexPath)
            return
        }

        // If we're not showing the Jetpack prompt or the fullscreen No Results View,
        // then clear any detail view controller that may be present.
        // (i.e. don't add an empty detail VC if the primary is full width)
        if let splitViewController = splitViewController as? WPSplitViewController,
            splitViewController.wpPrimaryColumnWidth != WPSplitViewControllerPrimaryColumnWidth.full {
            let controller = UIViewController()
            controller.navigationItem.largeTitleDisplayMode = .never
            showDetailViewController(controller, sender: nil)
        }
    }

    @objc func updateUnreadNotificationsForFilterTabChange() {
        if filter == .unread {
            refreshUnreadNotifications(reloadingResultsController: false)
        } else {
            clearUnreadNotifications()
        }
    }
}



// MARK: - WPTableViewHandlerDelegate Methods
//
extension NotificationsViewController: WPTableViewHandlerDelegate {
    func managedObjectContext() -> NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }

    func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName())
        request.sortDescriptors = [NSSortDescriptor(key: Filter.sortKey, ascending: false)]
        request.predicate = predicateForFetchRequest()

        return request
    }

    @objc func predicateForFetchRequest() -> NSPredicate {
        let deletedIdsPredicate = NSPredicate(format: "NOT (SELF IN %@)", Array(notificationIdsBeingDeleted))
        let selectedFilterPredicate = predicateForSelectedFilters()
        return NSCompoundPredicate(andPredicateWithSubpredicates: [deletedIdsPredicate, selectedFilterPredicate])
    }

    @objc func predicateForSelectedFilters() -> NSPredicate {
        guard let condition = filter.condition else {
            return NSPredicate(value: true)
        }

        var subpredicates: [NSPredicate] = [NSPredicate(format: condition)]

        if filter == .unread {
            subpredicates.append(NSPredicate(format: "SELF IN %@", Array(unreadNotificationIds)))
        }
        return NSCompoundPredicate(orPredicateWithSubpredicates: subpredicates)
    }

    func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        // iOS 8 has a nice bug in which, randomly, the last cell per section was getting an extra separator.
        // For that reason, we draw our own separators.
        //
        guard let note = tableViewHandler.resultsController.object(at: indexPath) as? Notification else {
            return
        }

        let deletionRequest = deletionRequestForNoteWithID(note.objectID)
        let isLastRow = tableViewHandler.resultsController.isLastIndexPathInSection(indexPath)

        // configure unified list cell if the feature flag is enabled.
        if usesUnifiedList, let cell = cell as? ListTableViewCell {
            cell.configureWithNotification(note)

            // handle undo overlays
            cell.configureUndeleteOverlay(with: deletionRequest?.kind.legendText) { [weak self] in
                self?.cancelDeletionRequestForNoteWithID(note.objectID)
            }

            // additional configurations
            cell.showsBottomSeparator = !isLastRow
            cell.accessibilityHint = Self.accessibilityHint(for: note)

            return
        }

        // otherwise, configure using the (soon-to-be) legacy NoteTableViewCell.
        guard let cell = cell as? NoteTableViewCell else {
            return
        }

        cell.attributedSubject      = note.renderSubject()
        cell.attributedSnippet      = note.renderSnippet()

        cell.read                   = note.read
        cell.noticon                = note.noticon
        cell.unapproved             = note.isUnapprovedComment
        cell.showsBottomSeparator   = !isLastRow
        cell.undeleteOverlayText    = deletionRequest?.kind.legendText
        cell.onUndelete             = { [weak self] in
            self?.cancelDeletionRequestForNoteWithID(note.objectID)
        }

        cell.accessibilityHint = Self.accessibilityHint(for: note)
        cell.downloadIconWithURL(note.iconURL)
    }

    func sectionNameKeyPath() -> String {
        return "sectionIdentifier"
    }

    @objc func entityName() -> String {
        return Notification.classNameWithoutNamespaces()
    }

    private var shouldCountNotificationsForSecondAlert: Bool {
        userDefaults.notificationPrimerInlineWasAcknowledged &&
            userDefaults.secondNotificationsAlertCount != Constants.secondNotificationsAlertDisabled
    }

    func tableViewWillChangeContent(_ tableView: UITableView) {
        guard shouldCountNotificationsForSecondAlert,
            let notification = tableViewHandler.resultsController.fetchedObjects?.first as? Notification,
            let timestamp = notification.timestamp else {
                timestampBeforeUpdatesForSecondAlert = nil
                return
        }

        timestampBeforeUpdatesForSecondAlert = timestamp
    }

    func tableViewDidChangeContent(_ tableView: UITableView) {
        // Due to an UIKit bug, we need to draw our own separators (Issue #2845). Let's update the separator status
        // after a DB OP. This loop has been measured in the order of milliseconds (iPad Mini)
        //
        for indexPath in tableView.indexPathsForVisibleRows ?? [] {
            let cell = tableView.cellForRow(at: indexPath)

            // Apply the same handling for ListTableViewCell.
            // this should be removed when it's confirmed that default table separators no longer trigger issues
            // resolved in #2845, and the unified list feature is fully rolled out.
            if usesUnifiedList,
               let listCell = cell as? ListTableViewCell {
                let isLastRow = tableViewHandler.resultsController.isLastIndexPathInSection(indexPath)
                listCell.showsBottomSeparator = !isLastRow
                continue
            }

            if let noteCell = cell as? NoteTableViewCell {
                let isLastRow = tableViewHandler.resultsController.isLastIndexPathInSection(indexPath)
                noteCell.showsBottomSeparator = !isLastRow
            }
        }

        refreshUnreadNotifications()

        // Update NoResults View
        showNoResultsViewIfNeeded()

        if let selectedNotification = selectedNotification {
            selectRow(for: selectedNotification, animated: false, scrollPosition: .none)
        } else {
            selectFirstNotificationIfAppropriate()
        }
        // count new notifications for second alert
        guard shouldCountNotificationsForSecondAlert else {
            return
        }

        userDefaults.secondNotificationsAlertCount += newNotificationsForSecondAlert

        if isViewOnScreen() {
            showSecondNotificationsAlertIfNeeded()
        }
    }

    // counts the new notifications for the second alert
    private var newNotificationsForSecondAlert: Int {

        guard let previousTimestamp = timestampBeforeUpdatesForSecondAlert,
            let notifications = tableViewHandler.resultsController.fetchedObjects as? [Notification] else {

            return 0
        }
        for notification in notifications.enumerated() {
            if let timestamp = notification.element.timestamp, timestamp <= previousTimestamp {
                return notification.offset
            }
        }
        return 0
    }

    private static func accessibilityHint(for note: Notification) -> String? {
        switch note.kind {
        case .comment:
            return NSLocalizedString("Shows details and moderation actions.",
                                     comment: "Accessibility hint for a comment notification.")
        case .commentLike, .like:
            return NSLocalizedString("Shows all likes.",
                                     comment: "Accessibility hint for a post or comment “like” notification.")
        case .follow:
            return NSLocalizedString("Shows all followers",
                                     comment: "Accessibility hint for a follow notification.")
        case .matcher, .newPost:
            return NSLocalizedString("Shows the post",
                                     comment: "Accessibility hint for a match/mention on a post notification.")
        default:
            return nil
        }
    }
}

// MARK: - Filter Helpers
//
private extension NotificationsViewController {
    func showFiltersSegmentedControlIfApplicable() {
        guard filterTabBar.isHidden == true && shouldDisplayFilters == true else {
            return
        }

        UIView.animate(withDuration: WPAnimationDurationDefault, animations: {
            self.filterTabBar.isHidden = false
        })
    }

    func hideFiltersSegmentedControlIfApplicable() {
        if filterTabBar.isHidden == false && shouldDisplayFilters == false {
            self.filterTabBar.isHidden = true
        }
    }

    var shouldDisplayFilters: Bool {
        // Filters should only be hidden whenever there are no Notifications in the bucket (contrary to the FRC's
        // results, which are filtered by the active predicate!).
        //
        return mainContext.countObjects(ofType: Notification.self) > 0 && !shouldDisplayJetpackPrompt
    }
}



// MARK: - NoResults Helpers
//
private extension NotificationsViewController {
    func showNoResultsViewIfNeeded() {
        noResultsViewController.removeFromView()
        updateSplitViewAppearanceForNoResultsView()
        updateNavigationItems()

        // Hide the filter header if we're showing the Jetpack prompt
        hideFiltersSegmentedControlIfApplicable()

        // Show Filters if needed
        guard shouldDisplayNoResultsView == true else {
            showFiltersSegmentedControlIfApplicable()
            return
        }

        guard connectionAvailable() else {
            showNoConnectionView()
            return
        }

        // Refresh its properties: The user may have signed into WordPress.com
        noResultsViewController.configure(title: noResultsTitleText, buttonTitle: noResultsButtonText, subtitle: noResultsMessageText, image: "wp-illustration-notifications")
        addNoResultsToView()
    }

    func showNoConnectionView() {
        noResultsViewController.configure(title: noConnectionTitleText, subtitle: noConnectionMessage())
        addNoResultsToView()
    }

    func addNoResultsToView() {
        addChild(noResultsViewController)
        tableView.insertSubview(noResultsViewController.view, belowSubview: tableHeaderView)
        noResultsViewController.view.frame = tableView.frame
        setupNoResultsViewConstraints()
        noResultsViewController.didMove(toParent: self)
    }

    func setupNoResultsViewConstraints() {
        guard let nrv = noResultsViewController.view else {
            return
        }

        tableHeaderView.translatesAutoresizingMaskIntoConstraints = false
        nrv.translatesAutoresizingMaskIntoConstraints = false
        nrv.setContentHuggingPriority(.defaultLow, for: .horizontal)

        NSLayoutConstraint.activate([
            nrv.widthAnchor.constraint(equalTo: view.widthAnchor),
            nrv.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nrv.topAnchor.constraint(equalTo: tableHeaderView.bottomAnchor),
            nrv.bottomAnchor.constraint(equalTo: view.safeBottomAnchor)
        ])
    }

    func updateSplitViewAppearanceForNoResultsView() {
        guard let splitViewController = splitViewController as? WPSplitViewController else {
            return
        }

        let columnWidth: WPSplitViewControllerPrimaryColumnWidth = (shouldDisplayFullscreenNoResultsView || shouldDisplayJetpackPrompt) ? .full : .default

        if splitViewController.wpPrimaryColumnWidth != columnWidth {
            splitViewController.wpPrimaryColumnWidth = columnWidth
        }

        if columnWidth == .default {
            splitViewController.dimDetailViewController(shouldDimDetailViewController, withAlpha: WPAlphaZero)
        }
    }

    var noConnectionTitleText: String {
        return NSLocalizedString("Unable to Sync", comment: "Title of error prompt shown when a sync the user initiated fails.")
    }

    var noResultsTitleText: String {
        return filter.noResultsTitle
    }

    var noResultsMessageText: String? {
        guard AppConfiguration.showsReader else {
            return nil
        }
        return filter.noResultsMessage
    }

    var noResultsButtonText: String? {
        guard AppConfiguration.showsReader else {
            return nil
        }
        return filter.noResultsButtonTitle
    }

    var shouldDisplayJetpackPrompt: Bool {
        return AccountHelper.isDotcomAvailable() == false
    }

    var shouldDisplaySettingsButton: Bool {
        return AccountHelper.isDotcomAvailable()
    }

    var shouldDisplayNoResultsView: Bool {
        return tableViewHandler.resultsController.fetchedObjects?.count == 0 && !shouldDisplayJetpackPrompt
    }

    var shouldDisplayFullscreenNoResultsView: Bool {
        return shouldDisplayNoResultsView && filter == .none
    }

    var shouldDimDetailViewController: Bool {
        return shouldDisplayNoResultsView && filter != .none
    }

}

// MARK: - NoResultsViewControllerDelegate

extension NotificationsViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        let properties = [Stats.sourceKey: Stats.sourceValue]
        switch filter {
        case .none,
             .comment,
             .follow,
             .like:
            WPAnalytics.track(.notificationsTappedViewReader, withProperties: properties)
            WPTabBarController.sharedInstance().showReaderTab()
        case .unread:
            WPAnalytics.track(.notificationsTappedNewPost, withProperties: properties)
            WPTabBarController.sharedInstance().showPostTab()
        }
    }
}

// MARK: - Inline Prompt Helpers
//
internal extension NotificationsViewController {
    func showInlinePrompt() {
        guard inlinePromptView.alpha != WPAlphaFull,
            userDefaults.notificationPrimerAlertWasDisplayed,
            userDefaults.notificationsTabAccessCount >= Constants.inlineTabAccessCount else {
            return
        }

        UIView.animate(withDuration: WPAnimationDurationDefault, delay: 0, options: .curveEaseIn, animations: {
            self.inlinePromptView.isHidden = false
        })

        UIView.animate(withDuration: WPAnimationDurationDefault * 0.5, delay: WPAnimationDurationDefault * 0.75, options: .curveEaseIn, animations: {
            self.inlinePromptView.alpha = WPAlphaFull
        })

        WPAnalytics.track(.appReviewsSawPrompt)
    }

    func hideInlinePrompt(delay: TimeInterval) {
        UIView.animate(withDuration: WPAnimationDurationDefault * 0.75, delay: delay, animations: {
            self.inlinePromptView.alpha = WPAlphaZero
        })

        UIView.animate(withDuration: WPAnimationDurationDefault, delay: delay + WPAnimationDurationDefault * 0.5, animations: {
            self.inlinePromptView.isHidden = true
        })
    }
}

// MARK: - Sync'ing Helpers
//
private extension NotificationsViewController {
    func syncNewNotifications() {
        guard connectionAvailable() else {
            return
        }

        let mediator = NotificationSyncMediator()
        mediator?.sync()
    }

    func syncNotification(with noteId: String, timeout: TimeInterval, success: @escaping (_ note: Notification) -> Void) {
        let mediator = NotificationSyncMediator()
        let startDate = Date()

        DDLogInfo("Sync'ing Notification [\(noteId)]")

        mediator?.syncNote(with: noteId) { error, note in
            guard abs(startDate.timeIntervalSinceNow) <= timeout else {
                DDLogError("Error: Timeout while trying to load Notification [\(noteId)]")
                return
            }

            guard let note = note else {
                DDLogError("Error: Couldn't load Notification [\(noteId)]")
                return
            }

            DDLogInfo("Notification Sync'ed in \(startDate.timeIntervalSinceNow) seconds")
            success(note)
        }
    }

    func updateLastSeenTime() {
        guard let note = tableViewHandler.resultsController.fetchedObjects?.first as? Notification else {
            return
        }

        guard let timestamp = note.timestamp, timestamp != lastSeenTime else {
            return
        }

        let mediator = NotificationSyncMediator()
        mediator?.updateLastSeen(timestamp) { error in
            guard error == nil else {
                return
            }

            self.lastSeenTime = timestamp
        }
    }

    func loadNotification(with noteId: String) -> Notification? {
        let predicate = NSPredicate(format: "(notificationId == %@)", noteId)

        return mainContext.firstObject(ofType: Notification.self, matching: predicate)
    }

    func loadNotification(near note: Notification, withIndexDelta delta: Int) -> Notification? {
        guard let notifications = tableViewHandler?.resultsController.fetchedObjects as? [Notification] else {
            return nil
        }

        guard let noteIndex = notifications.firstIndex(of: note) else {
            return nil
        }

        let targetIndex = noteIndex + delta
        guard targetIndex >= 0 && targetIndex < notifications.count else {
            return nil
        }

        func notMatcher(_ note: Notification) -> Bool {
            return note.kind != .matcher
        }

        if delta > 0 {
            return notifications
                .suffix(from: targetIndex)
                .first(where: notMatcher)
        } else {
            return notifications
                .prefix(through: targetIndex)
                .reversed()
                .first(where: notMatcher)
        }
    }

    func resetNotifications() {
        do {
            selectedNotification = nil
            mainContext.deleteAllObjects(ofType: Notification.self)
            try mainContext.save()
            tableView.reloadData()
        } catch {
            DDLogError("Error while trying to nuke Notifications Collection: [\(error)]")
        }
    }

    func resetLastSeenTime() {
        lastSeenTime = nil
    }

    func resetApplicationBadge() {
        // These notifications are cleared, so we just need to take Zendesk unread notifications
        // into account when setting the app icon count.
        UIApplication.shared.applicationIconBadgeNumber = ZendeskUtils.unreadNotificationsCount
    }
}

// MARK: - WPSplitViewControllerDetailProvider
//
extension NotificationsViewController: WPSplitViewControllerDetailProvider {
    func initialDetailViewControllerForSplitView(_ splitView: WPSplitViewController) -> UIViewController? {
        // The first notification view will be populated by `selectFirstNotificationIfAppropriate`
        // on viewWillAppear, so we'll just return an empty view here.
        let controller = UIViewController()
        controller.view.backgroundColor = .basicBackground
        return controller
    }

    private func fetchFirstNotification() -> Notification? {
        let context = managedObjectContext()
        let fetchRequest = self.fetchRequest()
        fetchRequest.fetchLimit = 1

        if let results = try? context.fetch(fetchRequest) as? [Notification] {
            return results.first
        }

        return nil
    }
}

// MARK: - Details Navigation Datasource
//
extension NotificationsViewController: NotificationsNavigationDataSource {
    @objc func notification(succeeding note: Notification) -> Notification? {
        return loadNotification(near: note, withIndexDelta: -1)
    }

    @objc func notification(preceding note: Notification) -> Notification? {
        return loadNotification(near: note, withIndexDelta: +1)
    }
}


// MARK: - SearchableActivity Conformance
//
extension NotificationsViewController: SearchableActivityConvertable {
    var activityType: String {
        return WPActivityType.notifications.rawValue
    }

    var activityTitle: String {
        return NSLocalizedString("Notifications", comment: "Title of the 'Notifications' tab - used for spotlight indexing on iOS.")
    }

    var activityKeywords: Set<String>? {
        let keyWordString = NSLocalizedString("wordpress, notifications, alerts, updates",
                                              comment: "This is a comma separated list of keywords used for spotlight indexing of the 'Notifications' tab.")
        let keywordArray = keyWordString.arrayOfTags()

        guard !keywordArray.isEmpty else {
            return nil
        }

        return Set(keywordArray)
    }
}

// MARK: - Private Properties
//
private extension NotificationsViewController {
    var mainContext: NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }

    var actionsService: NotificationActionsService {
        return NotificationActionsService(managedObjectContext: mainContext)
    }

    var userDefaults: UserDefaults {
        return UserDefaults.standard
    }

    var lastSeenTime: String? {
        get {
            return userDefaults.string(forKey: Settings.lastSeenTime)
        }
        set {
            userDefaults.setValue(newValue, forKey: Settings.lastSeenTime)
        }
    }

    var filter: Filter {
        get {
            let selectedIndex = filterTabBar?.selectedIndex ?? Filter.none.rawValue
            return Filter(rawValue: selectedIndex) ?? .none
        }
        set {
            filterTabBar?.setSelectedIndex(newValue.rawValue)
            reloadResultsController()
        }
    }

    enum Filter: Int, FilterTabBarItem {
        case none = 0
        case unread = 1
        case comment = 2
        case follow = 3
        case like = 4

        var condition: String? {
            switch self {
            case .none:     return nil
            case .unread:   return "read = NO"
            case .comment:  return "type = '\(NotificationKind.comment.rawValue)'"
            case .follow:   return "type = '\(NotificationKind.follow.rawValue)'"
            case .like:     return "type = '\(NotificationKind.like.rawValue)' OR type = '\(NotificationKind.commentLike.rawValue)'"
            }
        }

        var title: String {
            switch self {
            case .none:     return NSLocalizedString("All", comment: "Displays all of the Notifications, unfiltered")
            case .unread:   return NSLocalizedString("Unread", comment: "Filters Unread Notifications")
            case .comment:  return NSLocalizedString("Comments", comment: "Filters Comments Notifications")
            case .follow:   return NSLocalizedString("Follows", comment: "Filters Follows Notifications")
            case .like:     return NSLocalizedString("Likes", comment: "Filters Likes Notifications")
            }
        }

        var analyticsTitle: String {
            switch self {
            case .none:     return "All"
            case .unread:   return "Unread"
            case .comment:  return "Comments"
            case .follow:   return "Follows"
            case .like:     return "Likes"
            }
        }

        var noResultsTitle: String {
            switch self {
            case .none:     return NSLocalizedString("No notifications yet",
                                                     comment: "Displayed in the Notifications Tab as a title, when there are no notifications")
            case .unread:   return NSLocalizedString("You're all up to date!",
                                                     comment: "Displayed in the Notifications Tab as a title, when the Unread Filter shows no unread notifications as a title")
            case .comment:  return NSLocalizedString("No comments yet",
                                                     comment: "Displayed in the Notifications Tab as a title, when the Comments Filter shows no notifications")
            case .follow:   return NSLocalizedString("No followers yet",
                                                     comment: "Displayed in the Notifications Tab as a title, when the Follow Filter shows no notifications")
            case .like:     return NSLocalizedString("No likes yet",
                                                     comment: "Displayed in the Notifications Tab as a title, when the Likes Filter shows no notifications")
            }
        }

        var noResultsMessage: String {
            switch self {
            case .none:     return NSLocalizedString("Get active! Comment on posts from blogs you follow.",
                                                     comment: "Displayed in the Notifications Tab as a message, when there are no notifications")
            case .unread:   return NSLocalizedString("Reignite the conversation: write a new post.",
                                                     comment: "Displayed in the Notifications Tab as a message, when the Unread Filter shows no notifications")
            case .comment:  return NSLocalizedString("Join a conversation: comment on posts from blogs you follow.",
                                                     comment: "Displayed in the Notifications Tab as a message, when the Comments Filter shows no notifications")
            case .follow,
                 .like:     return NSLocalizedString("Get noticed: comment on posts you've read.",
                                                     comment: "Displayed in the Notifications Tab as a message, when the Follow Filter shows no notifications")
            }
        }

        var noResultsButtonTitle: String {
            switch self {
            case .none,
                 .comment,
                 .follow,
                 .like:     return NSLocalizedString("Go to Reader",
                                                     comment: "Displayed in the Notifications Tab as a button title, when there are no notifications")
            case .unread:   return NSLocalizedString("Create a Post",
                                                     comment: "Displayed in the Notifications Tab as a button title, when the Unread Filter shows no notifications")
            }
        }

        static let sortKey = "timestamp"
        static let allFilters = [Filter.none, .unread, .comment, .follow, .like]
    }

    enum Settings {
        static let estimatedRowHeight = CGFloat(70)
        static let lastSeenTime = "notifications_last_seen_time"
    }

    enum Stats {
        static let networkStatusKey = "network_status"
        static let noteTypeKey = "notification_type"
        static let noteTypeUnknown = "unknown"
        static let sourceKey = "source"
        static let sourceValue = "notifications"
        static let selectedFilter = "selected_filter"
    }

    enum Syncing {
        static let minimumPullToRefreshDelay = TimeInterval(1.5)
        static let pushMaxWait = TimeInterval(1.5)
        static let syncTimeout = TimeInterval(10)
        static let undoTimeout = TimeInterval(4)
    }

    enum InlinePrompt {
        static let section = "notifications"
    }
}

// MARK: - Push Notifications Permission Alert
extension NotificationsViewController: UIViewControllerTransitioningDelegate {

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        guard let fancyAlertController = presented as? FancyAlertViewController else {
            return nil
        }
        return FancyAlertPresentationController(presentedViewController: fancyAlertController, presenting: presenting)
    }

    private func showNotificationPrimerAlertIfNeeded() {

        guard !userDefaults.notificationPrimerAlertWasDisplayed else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.displayAlertDelay) {
                self.showNotificationPrimerAlert()
        }
    }

    private func notificationAlertApproveAction(_ controller: FancyAlertViewController) {
        InteractiveNotificationsManager.shared.requestAuthorization { _ in
            DispatchQueue.main.async {
                controller.dismiss(animated: true)
            }
        }
    }

    private func showNotificationPrimerAlert() {
        let alertController = FancyAlertViewController.makeNotificationPrimerAlertController(approveAction: notificationAlertApproveAction(_:))
        showNotificationAlert(alertController)
    }

    private func showSecondNotificationAlert() {
        let alertController = FancyAlertViewController.makeNotificationSecondAlertController(approveAction: notificationAlertApproveAction(_:))
        showNotificationAlert(alertController)
    }

    private func showNotificationAlert(_ alertController: FancyAlertViewController) {
        let mainContext = ContextManager.shared.mainContext
        let accountService = AccountService(managedObjectContext: mainContext)

        guard accountService.defaultWordPressComAccount() != nil else {
            return
        }
        PushNotificationsManager.shared.loadAuthorizationStatus { [weak self] (enabled) in
            guard enabled == .notDetermined else {
                return
            }

            UserDefaults.standard.notificationPrimerAlertWasDisplayed = true

            let alert = alertController
            alert.modalPresentationStyle = .custom
            alert.transitioningDelegate = self
            self?.tabBarController?.present(alert, animated: true)
        }
    }

    private func showSecondNotificationsAlertIfNeeded() {
        guard userDefaults.secondNotificationsAlertCount >= Constants.secondNotificationsAlertThreshold else {
            return
        }
        showSecondNotificationAlert()
        userDefaults.secondNotificationsAlertCount = Constants.secondNotificationsAlertDisabled
    }

    private enum Constants {
        static let inlineTabAccessCount = 6
        static let displayAlertDelay = 0.2
        // number of notifications after which the second alert will show up
        static let secondNotificationsAlertThreshold = 10
        static let secondNotificationsAlertDisabled = -1
        /// the amount of bottom padding added to the filter tab bar. To be used with unified list.
        static let filterTabBarBottomSpace: CGFloat = 10.0
    }
}

// MARK: - Scrolling
//
extension NotificationsViewController: WPScrollableViewController {
    // Used to scroll view to top when tapping on tab bar item when VC is already visible.
    func scrollViewToTop() {
        tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true)
    }
}
