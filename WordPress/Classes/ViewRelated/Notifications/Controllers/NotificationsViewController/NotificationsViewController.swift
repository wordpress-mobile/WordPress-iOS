import Foundation
import Combine
import CoreData
import CocoaLumberjack
import WordPressShared
import WordPressAuthenticator
import Gridicons
import UIKit
import WordPressUI

/// The purpose of this class is to render the collection of Notifications, associated to the main
/// WordPress.com account.
///
/// Plus, we provide a simple mechanism to render the details for a specific Notification,
/// given its remote identifier.
///
class NotificationsViewController: UIViewController, UIViewControllerRestoration, UITableViewDataSource, UITableViewDelegate {

    @objc static let selectedNotificationRestorationIdentifier = "NotificationsSelectedNotificationKey"
    @objc static let selectedSegmentIndexRestorationIdentifier   = "NotificationsSelectedSegmentIndexKey"

    // MARK: - Properties

    /// Table View
    ///
    @IBOutlet weak var tableView: UITableView!
    /// TableHeader
    ///
    @IBOutlet var tableHeaderView: UIView!

    /// Filtering Tab Bar
    ///
    @IBOutlet weak var filterTabBar: FilterTabBar!

    /// Jetpack Banner View
    /// Only visible in WordPress
    ///
    @IBOutlet weak var jetpackBannerView: JetpackBannerView!

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
    var needsReloadResults = false

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

    private lazy var notificationCommentDetailCoordinator: NotificationCommentDetailCoordinator = {
        return NotificationCommentDetailCoordinator(notificationsNavigationDataSource: self)
    }()

    /// Activity Indicator to be shown when refreshing a Jetpack site status.
    ///
    let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    /// Navigation Bar More Menu
    private let moreMenuNavigationBarButtonItem: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage.DS.icon(named: .ellipsisVertical))
        button.accessibilityLabel = Strings.NavigationBar.menuButtonAccessibilityLabel
        return button
    }()

    /// Notification Settings button
    private var settingsMenuAction: UIAction {
        return UIAction(title: Strings.NavigationBar.notificationSettingsActionTitle, image: .DS.icon(named: .gearshapeFill)) { [weak self] _ in
            self?.showNotificationSettings()
        }
    }

    /// Mark All As Read button
    private var markAllAsReadMenuAction: UIAction {
        return UIAction(title: Strings.NavigationBar.markAllAsReadActionTitle, image: .DS.icon(named: .checkmark)) { [weak self] _ in
            self?.showMarkAllAsReadConfirmation()
        }
    }

    /// Used by JPScrollViewDelegate to send scroll position
    internal let scrollViewTranslationPublisher = PassthroughSubject<Bool, Never>()

    lazy var viewModel: NotificationsViewModel = {
        NotificationsViewModel(userDefaults: userDefaults)
    }()

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
        setupTableHandler()
        setupTableView()
        setupTableFooterView()
        setupRefreshControl()
        setupNoResultsView()
        setupFilterBar()

        tableView.tableHeaderView = tableHeaderView
        setupConstraints()
        configureJetpackBanner()

        reloadTableViewPreservingSelection()
        startListeningToCommentDeletedNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        JetpackFeaturesRemovalCoordinator.presentOverlayIfNeeded(in: self, source: .notifications)

        syncNotificationsWithModeratedComments()
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
        updateMoreMenuNavigationItem()

        if !splitViewControllerIsHorizontallyCompact {
            reloadTableViewPreservingSelection()
        }

        if shouldDisplayJetpackPrompt {
            promptForJetpackCredentials()
        } else {
            jetpackLoginViewController?.remove()
        }

        showNoResultsViewIfNeeded()
        selectFirstNotificationIfAppropriate()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        defer {
            if AppConfiguration.showsWhatIsNew {
                RootViewCoordinator.shared.presentWhatIsNew(on: self)
            }
        }

        syncNewNotifications()
        markSelectedNotificationAsRead()

        registerUserActivity()

        markWelcomeNotificationAsSeenIfNeeded()

        if userDefaults.notificationsTabAccessCount < Constants.inlineTabAccessCount {
            userDefaults.notificationsTabAccessCount += 1
        }

        // Don't show the notification primers if we already asked during onboarding
        if userDefaults.onboardingNotificationsPromptDisplayed, userDefaults.notificationsTabAccessCount == 1 {
            return
        }

        if shouldShowPrimeForPush {
            setupNotificationPrompt()
        }
        // TODO: Remove this when In-App Rating project is shipped
//        else if AppRatingUtility.shared.shouldPromptForAppReview(section: InlinePrompt.section) {
//            setupAppRatings()
//            self.showInlinePrompt()
//        }

        showNotificationPrimerAlertIfNeeded()
        showSecondNotificationsAlertIfNeeded()
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
        return RootViewCoordinator.sharedPresenter.notificationsViewController
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

        // TODO: add check for CommentDetailViewController
        for case let detailVC as NotificationDetailsViewController in navigationControllers {
            if detailVC.onDeletionRequestCallback == nil, let note = detailVC.note {
                configureDetailsViewController(detailVC, withNote: note)
            }
        }
    }

    // MARK: - UITableViewDataSource Methods

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableViewHandler.tableView(tableView, numberOfRowsInSection: section)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        tableViewHandler.numberOfSections(in: tableView)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ListTableViewCell.defaultReuseID, for: indexPath)
        configureCell(cell, at: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    // MARK: - UITableViewDelegate Methods

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionInfo = tableViewHandler.resultsController?.sections?[section],
              let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ListTableHeaderView.defaultReuseID) as? ListTableHeaderView else {
            return nil
        }

        headerView.title = Notification.descriptionForSectionIdentifier(sectionInfo.name)
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // Make sure no SectionFooter is rendered
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // Make sure no SectionFooter is rendered
        return nil
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        estimatedRowHeightsCache.setObject(cell.frame.height as AnyObject, forKey: indexPath as AnyObject)
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if let height = estimatedRowHeightsCache.object(forKey: indexPath as AnyObject) as? CGFloat {
            return height
        }
        return Settings.estimatedRowHeight
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Failsafe: Make sure that the Notification (still) exists
        guard let note = tableViewHandler.resultsController?.managedObject(atUnsafe: indexPath) as? Notification else {
            tableView.deselectSelectedRowWithAnimation(true)
            return
        }

        // Push the Details: Unless the note has a pending deletion!
        guard deletionRequestForNoteWithID(note.objectID) == nil else {
            return
        }

        showDetails(for: note)

        if !note.read {
            AppRatingUtility.shared.incrementSignificantEvent()
        }

        if !splitViewControllerIsHorizontallyCompact {
            syncNotificationsWithModeratedComments()
        }

    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // skip when the notification is marked for deletion.
        guard let note = tableViewHandler.resultsController?.managedObject(atUnsafe: indexPath) as? Notification,
              deletionRequestForNoteWithID(note.objectID) == nil else {
            return nil
        }

        let isRead = note.read

        let title = isRead ? NSLocalizedString("Mark Unread", comment: "Marks a notification as unread") :
                             NSLocalizedString("Mark Read", comment: "Marks a notification as unread")

        let action = UIContextualAction(style: .normal, title: title, handler: { (action, view, completionHandler) in
            if isRead {
                WPAnalytics.track(.notificationMarkAsUnreadTapped)
                self.markAsUnread(note: note)
            } else {
                WPAnalytics.track(.notificationMarkAsReadTapped)
                self.markAsRead(note: note)
            }
            completionHandler(true)
        })
        action.backgroundColor = .neutral(.shade50)

        return UISwipeActionsConfiguration(actions: [action])
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // skip when the notification is marked for deletion.
        guard let note = tableViewHandler.resultsController?.managedObject(atUnsafe: indexPath) as? Notification,
            let block: FormattableCommentContent = note.contentGroup(ofKind: .comment)?.blockOfKind(.comment),
            deletionRequestForNoteWithID(note.objectID) == nil else {
            return nil
        }

        // Approve comment
        guard let approveEnabled = block.action(id: ApproveCommentAction.actionIdentifier())?.enabled,
              approveEnabled == true,
              let approveAction = block.action(id: ApproveCommentAction.actionIdentifier()),
              let actionTitle = approveAction.command?.actionTitle else {
            return nil
        }

        let action = UIContextualAction(style: .normal, title: actionTitle, handler: { (_, _, completionHandler) in
            WPAppAnalytics.track(approveAction.on ? .notificationsCommentUnapproved : .notificationsCommentApproved,
                                 withProperties: [Stats.sourceKey: Stats.sourceValue],
                                 withBlogID: block.metaSiteID)

            let actionContext = ActionContext(block: block)
            approveAction.execute(context: actionContext)
            completionHandler(true)
        })
        action.backgroundColor = approveAction.command?.actionColor

        let configuration = UISwipeActionsConfiguration(actions: [action])
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
        detailsViewController.notificationCommentDetailCoordinator = notificationCommentDetailCoordinator
        detailsViewController.note = note
        detailsViewController.onDeletionRequestCallback = { [weak self] request in
            guard let self else { return }

            self.showUndeleteForNoteWithID(note.objectID, request: request)
        }
        detailsViewController.onSelectedNoteChange = { [weak self] note in
            guard let self else { return }

            self.selectRow(for: note)
        }
    }
}

// MARK: - User Interface Initialization
//
private extension NotificationsViewController {
    func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never

        // Don't show 'Notifications' in the next-view back button
        // we are using a space character because we need a non-empty string to ensure a smooth
        // transition back, with large titles enabled.
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        navigationItem.title = NSLocalizedString("Notifications", comment: "Notifications View Controller title")
    }

    func updateNavigationItems() {
        self.navigationItem.rightBarButtonItem = moreMenuNavigationBarButtonItem
        self.updateMoreMenuNavigationItem()
    }

    func updateMoreMenuNavigationItem() {
        guard let notes = tableViewHandler.resultsController?.fetchedObjects as? [Notification] else {
            return
        }

        var menuItems: [UIAction] = []

        // Mark All As Read
        let markAllAsReadMenuAction = markAllAsReadMenuAction
        let isEnabled = notes.first { !$0.read } != nil
        markAllAsReadMenuAction.attributes = isEnabled ? .init(rawValue: 0) : .disabled
        menuItems.append(markAllAsReadMenuAction)

        // Settings
        if shouldDisplaySettingsButton {
            menuItems.append(settingsMenuAction)
        }

        // Update menu
        let menu: UIMenu = {
            if let menu = self.moreMenuNavigationBarButtonItem.menu {
                return menu.replacingChildren(menuItems)
            } else {
                return UIMenu(children: menuItems)
            }
        }()
        self.moreMenuNavigationBarButtonItem.menu = menu
    }

    @objc func closeNotificationSettings() {
        dismiss(animated: true, completion: nil)
    }

    func setupConstraints() {
        // Inline prompt is initially hidden!
        inlinePromptView.translatesAutoresizingMaskIntoConstraints = false
        filterTabBar.tabBarHeightConstraintPriority = 999

        let leading = tableHeaderView.safeLeadingAnchor.constraint(equalTo: tableView.safeLeadingAnchor)
        let trailing = tableHeaderView.safeTrailingAnchor.constraint(equalTo: tableView.safeTrailingAnchor)

        leading.priority = UILayoutPriority(999)
        trailing.priority = UILayoutPriority(999)

        NSLayoutConstraint.activate([
            tableHeaderView.topAnchor.constraint(equalTo: tableView.topAnchor),
            leading,
            trailing
        ])
    }

    func setupTableView() {
        // Register the cells
        tableView.register(ListTableHeaderView.defaultNib, forHeaderFooterViewReuseIdentifier: ListTableHeaderView.defaultReuseID)
        tableView.register(ListTableViewCell.defaultNib, forCellReuseIdentifier: ListTableViewCell.defaultReuseID)

        // UITableView
        tableView.accessibilityIdentifier  = "notifications-table"
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
        tableView.refreshControl = control
    }

    func setupNoResultsView() {
        noResultsViewController.delegate = self
    }

    func setupFilterBar() {
        WPStyleGuide.configureFilterTabBar(filterTabBar)
        filterTabBar.superview?.backgroundColor = .systemBackground

        filterTabBar.items = Filter.allCases
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
    }
}

// MARK: - Jetpack banner UI Initialization
//
extension NotificationsViewController {

    /// Called on view load to determine whether the Jetpack banner should be shown on the view
    /// Also called in the completion block of the JetpackLoginViewController to show the banner once the user connects to a .com account
    func configureJetpackBanner() {
        guard JetpackBrandingVisibility.all.enabled else {
            return
        }
        let textProvider = JetpackBrandingTextProvider(screen: JetpackBannerScreen.notifications)
        jetpackBannerView.configure(title: textProvider.brandingText()) { [unowned self] in
            JetpackBrandingCoordinator.presentOverlay(from: self)
            JetpackBrandingAnalyticsHelper.trackJetpackPoweredBannerTapped(screen: .notifications)
        }
        jetpackBannerView.isHidden = false
        addTranslationObserver(jetpackBannerView)
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

    func startListeningToCommentDeletedNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(removeDeletedNotification),
                                               name: .NotificationCommentDeletedNotification,
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
        resetNotifications()
        viewModel.didChangeDefaultAccount()
        resetApplicationBadge()
        guard isViewLoaded == true && view.window != nil else {
            needsReloadResults = true
            return
        }
        reloadResultsController()
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
        tableViewHandler.resultsController?.fetchedObjects?.forEach {
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

        syncNotification(with: noteId, timeout: Syncing.pushMaxWait) { [weak self] note in
            guard let self else { return }

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

        // The `selectedNotification` property will be set to `note` later in the `selectRow` functioin call. The reason
        // we duplicate the assignment here (explicityly before the `markAsRead` function call) is to workaround a crash
        // caused by recursive `NSManagedObjectContext.save` calls.
        //
        // Here is the recursive call chain:
        // markAsRead(note) -> NSManagedObjectContext.save -> NSFetchedResultControllerDelegate.controllerDidChangeContent
        // -> tableViewDidChangeContent -> markAsRead(selectedNotification) -> NSManagedObjectContext.save
        //
        // If the two Notication instances passed to the two `markAsRead` function calls are the same object, the last `save`
        // call won't happen because `selectedNotification.read` is already true and `markAsRead(selectedNotification)` does nothing.
        //
        // Considering the `selectedNotification` will be set to `note` later, it should be safe to duplicate that assignment
        // here, just for the sake of breaking the recursive calls.
        //
        // The ideal solution would be not updating and saving `Notification.read` property in the main context.
        // Use `CoreDataStack.performAndSave` to do it in a background context instead. However, based on the comments on
        // `markAsRead` function call below, it appears we intentionally save the main context to maintain some undocumented
        // but apperently important "side effects". We may need more careful testing around moving the saving operation from
        // the main context to a background context.
        //
        // See also https://github.com/wordpress-mobile/WordPress-iOS/issues/20850
        selectedNotification = note

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
        if let postID = note.metaPostID,
            let siteID = note.metaSiteID,
            note.kind == .matcher || note.kind == .newPost {
            let readerViewController = ReaderDetailViewController.controllerWithPostID(postID, siteID: siteID)
            readerViewController.navigationItem.largeTitleDisplayMode = .never
            showDetailViewController(readerViewController, sender: nil)

            return
        }

        presentDetails(for: note)
    }

    private func presentDetails(for note: Notification) {
        // This dispatch avoids a bug that was occurring occasionally where navigation (nav bar and tab bar)
        // would be missing entirely when launching the app from the background and presenting a notification.
        // The issue seems tied to performing a `pop` in `prepareToShowDetails` and presenting
        // the new detail view controller at the same time. More info: https://github.com/wordpress-mobile/WordPress-iOS/issues/6976
        //
        // Plus: Avoid pushing multiple DetailsViewController's, upon quick & repeated touch events.

        view.isUserInteractionEnabled = false

        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            self.view.isUserInteractionEnabled = true

            if note.kind == .comment {
                guard let commentDetailViewController = self.notificationCommentDetailCoordinator.createViewController(with: note) else {
                    DDLogError("Notifications: failed creating Comment Detail view.")
                    return
                }

                self.notificationCommentDetailCoordinator.onSelectedNoteChange = { [weak self] note in
                    self?.selectRow(for: note)
                }

                commentDetailViewController.navigationItem.largeTitleDisplayMode = .never
                self.showDetailViewController(commentDetailViewController, sender: nil)

                return
            }

            self.performSegue(withIdentifier: NotificationDetailsViewController.classNameWithoutNamespaces(), sender: note)
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
            return note == tableViewHandler.resultsController?.managedObject(atUnsafe: indexPath) as? Notification
        }

        guard noteIndexPath == nil else {
            return
        }

        filter = .none
    }

    /// Will display an Undelete button on top of a given notification.
    /// On timeout, the destructive action (received via parameter) will be executed, and the notification
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
        request.action { [weak self] success in
            guard let self else { return }

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

    // MARK: - Notifications Deletion from CommentDetailViewController

    // Comment moderation is handled by the view.
    // To avoid updating the Notifications here prematurely, affecting the previous/next buttons,
    // the Notifications are tracked in NotificationCommentDetailCoordinator when their comments are moderated.
    // Those Notifications are updated here when the view is shown to update the list accordingly.
    func syncNotificationsWithModeratedComments() {
        selectNextAvailableNotification(ignoring: notificationCommentDetailCoordinator.notificationsCommentModerated)

        notificationCommentDetailCoordinator.notificationsCommentModerated.forEach {
            syncNotification(with: $0.notificationId, timeout: Syncing.pushMaxWait, success: {_ in })
        }

        notificationCommentDetailCoordinator.notificationsCommentModerated = []
    }

    @objc func removeDeletedNotification(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let deletedCommentID = userInfo[userInfoCommentIdKey] as? Int32,
              let notifications = tableViewHandler.resultsController?.fetchedObjects as? [Notification] else {
                  return
              }

        let notification = notifications.first(where: { notification -> Bool in
            guard let commentID = notification.metaCommentID else {
                return false
            }

            return commentID.intValue == deletedCommentID
        })

        syncDeletedNotification(notification)
    }

    func syncDeletedNotification(_ notification: Notification?) {
        guard let notification = notification else {
            return
        }

        selectNextAvailableNotification(ignoring: [notification])

        syncNotification(with: notification.notificationId, timeout: Syncing.pushMaxWait, success: { [weak self] notification in
            self?.notificationCommentDetailCoordinator.notificationsCommentModerated.removeAll(where: { $0.notificationId == notification.notificationId })
        })
    }

    func selectNextAvailableNotification(ignoring: [Notification]) {
        // If the currently selected notification is about to be removed, find the next available and select it.
        // This is only necessary for split view to prevent the details from showing for removed notifications.
        if !splitViewControllerIsHorizontallyCompact,
           let selectedNotification = selectedNotification,
           ignoring.contains(selectedNotification) {

            guard let notifications = tableViewHandler.resultsController?.fetchedObjects as? [Notification],
                  let nextAvailable = notifications.first(where: { !ignoring.contains($0) }),
                  let indexPath = tableViewHandler.resultsController?.indexPath(forObject: nextAvailable) else {
                      self.selectedNotification = nil
                      return
                  }

            self.selectedNotification = nextAvailable
            tableView(tableView, didSelectRowAt: indexPath)
        }
    }

}

// MARK: - Marking as Read
//
private extension NotificationsViewController {
    private enum Localization {
        static let markAllAsReadNoticeSuccess = NSLocalizedString(
            "Notifications marked as read",
            comment: "Title for mark all as read success notice"
        )

        static let markAllAsReadNoticeFailure = NSLocalizedString(
            "Failed marking Notifications as read",
            comment: "Message for mark all as read success notice"
        )
    }

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

    /// Marks all messages as read under the selected filter.
    ///
    @objc func markAllAsRead() {
        guard let notes = tableViewHandler.resultsController?.fetchedObjects as? [Notification] else {
            return
        }

        WPAnalytics.track(.notificationsMarkAllReadTapped)

        let unreadNotifications = notes.filter {
            !$0.read
        }

        NotificationSyncMediator()?.markAsRead(unreadNotifications, completion: { [weak self] error in
            let notice = Notice(
                title: error != nil ? Localization.markAllAsReadNoticeFailure : Localization.markAllAsReadNoticeSuccess
            )
            ActionDispatcherFacade().dispatch(NoticeAction.post(notice))
            self?.updateMoreMenuNavigationItem()
        })
    }

    /// Presents a confirmation action sheet for mark all as read action.
    @objc func showMarkAllAsReadConfirmation() {
        let title: String

        switch filter {
        case .none:
            title = NSLocalizedString(
                "Mark all notifications as read?",
                comment: "Confirmation title for marking all notifications as read."
            )

        default:
            title = NSLocalizedString(
                "Mark all %1$@ notifications as read?",
                comment: "Confirmation title for marking all notifications under a filter as read. %1$@ is replaced by the filter name."
            )
        }

        let cancelTitle = NSLocalizedString(
            "Cancel",
            comment: "Cancels the mark all as read action."
        )
        let markAllTitle = NSLocalizedString(
            "OK",
            comment: "Marks all notifications as read."
        )

        let alertController = UIAlertController(
            title: String.localizedStringWithFormat(title, filter.confirmationMessageTitle),
            message: nil,
            preferredStyle: .alert
        )
        alertController.view.accessibilityIdentifier = "mark-all-as-read-alert"

        alertController.addCancelActionWithTitle(cancelTitle)

        alertController.addActionWithTitle(markAllTitle, style: .default) { [weak self] _ in
            self?.markAllAsRead()
        }

        present(alertController, animated: true, completion: nil)
    }

    func markAsUnread(note: Notification) {
        guard note.read else {
            return
        }

        NotificationSyncMediator()?.markAsUnread(note)
        updateMoreMenuNavigationItem()
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
        guard let notes = tableViewHandler.resultsController?.fetchedObjects as? [Notification] else {
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
        let fetchRequest = tableViewHandler.resultsController?.fetchRequest
        fetchRequest?.predicate = predicateForFetchRequest()

        /// Refetch + Reload
        _ = try? tableViewHandler.resultsController?.performFetch()

        reloadTableViewPreservingSelection()

        // Empty State?
        showNoResultsViewIfNeeded()

        // Don't overwork!
        lastReloadDate = Date()
        needsReloadResults = false
        updateMoreMenuNavigationItem()
    }

    func reloadRowForNotificationWithID(_ noteObjectID: NSManagedObjectID) {
        do {
            let note = try mainContext.existingObject(with: noteObjectID)

            if let indexPath = tableViewHandler.resultsController?.indexPath(forObject: note) {
                tableView.reloadRows(at: [indexPath], with: .fade)
            }
        } catch {
            DDLogError("Error refreshing Notification Row \(error)")
        }
    }

    func selectRow(for notification: Notification, animated: Bool = true,
                   scrollPosition: UITableView.ScrollPosition = .none) {
        selectedNotification = notification

        // also ensure that the index path returned from results controller does not have negative row index.
        // ref: https://github.com/wordpress-mobile/WordPress-iOS/issues/15370
        guard let indexPath = tableViewHandler.resultsController?.indexPath(forObject: notification),
              indexPath != tableView.indexPathForSelectedRow,
              0..<tableView.numberOfRows(inSection: indexPath.section) ~= indexPath.row else {
                  return
              }

        DDLogInfo("\(self) \(#function) Selecting row at \(indexPath) for Notification: \(notification.notificationId) (\(notification.type ?? "Unknown type")) - \(notification.title ?? "No title")")
        tableView.selectRow(at: indexPath, animated: animated, scrollPosition: scrollPosition)
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
            tableView.refreshControl?.endRefreshing()
            return
        }

        let start = Date()

        mediator.sync { [weak self] (error, _) in

            let delta = max(Syncing.minimumPullToRefreshDelay + start.timeIntervalSinceNow, 0)
            let delay = DispatchTime.now() + Double(Int64(delta * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)

            DispatchQueue.main.asyncAfter(deadline: delay) {
                self?.tableView.refreshControl?.endRefreshing()
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
        return tableViewHandler.resultsController?.isEmpty() ?? true
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
        if let firstNotification = tableViewHandler.resultsController?.fetchedObjects?.first as? Notification,
           let indexPath = tableViewHandler.resultsController?.indexPath(forObject: firstNotification) {
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

    func fetchRequest() -> NSFetchRequest<NSFetchRequestResult>? {
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
        guard let note = tableViewHandler.resultsController?.managedObject(atUnsafe: indexPath) as? Notification,
              let cell = cell as? ListTableViewCell else {
            return
        }

        cell.configureWithNotification(note)

        // handle undo overlays
        let deletionRequest = deletionRequestForNoteWithID(note.objectID)
        cell.configureUndeleteOverlay(with: deletionRequest?.kind.legendText) { [weak self] in
            self?.cancelDeletionRequestForNoteWithID(note.objectID)
        }

        // additional configurations
        cell.accessibilityHint = Self.accessibilityHint(for: note)
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
              let notification = tableViewHandler.resultsController?.fetchedObjects?.first as? Notification,
            let timestamp = notification.timestamp else {
                timestampBeforeUpdatesForSecondAlert = nil
                return
        }

        timestampBeforeUpdatesForSecondAlert = timestamp
    }

    func tableViewDidChangeContent(_ tableView: UITableView) {
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
              let notifications = tableViewHandler.resultsController?.fetchedObjects as? [Notification] else {

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

        // Ref: https://github.com/wordpress-mobile/WordPress-iOS/issues/14547
        // Don't attempt to resize the columns for full width.
        let columnWidth: WPSplitViewControllerPrimaryColumnWidth = .default
        // The above line should be replace with the following line when the full width issue is resolved.
        // let columnWidth: WPSplitViewControllerPrimaryColumnWidth = (shouldDisplayFullscreenNoResultsView || shouldDisplayJetpackPrompt) ? .full : .default

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
        return filter.noResultsMessage
    }

    var noResultsButtonText: String? {
        return filter.noResultsButtonTitle
    }

    var shouldDisplayJetpackPrompt: Bool {
        return AccountHelper.isDotcomAvailable() == false && blogForJetpackPrompt != nil
    }

    var shouldDisplaySettingsButton: Bool {
        return AccountHelper.isDotcomAvailable()
    }

    var shouldDisplayNoResultsView: Bool {
        return tableViewHandler.resultsController?.fetchedObjects?.count == 0 && !shouldDisplayJetpackPrompt
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
            RootViewCoordinator.sharedPresenter.showReaderTab()
        case .unread:
            WPAnalytics.track(.notificationsTappedNewPost, withProperties: properties)
            RootViewCoordinator.sharedPresenter.showPostTab()
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
        guard let note = tableViewHandler.resultsController?.fetchedObjects?.first as? Notification else {
            return
        }

        viewModel.lastSeenChanged(timestamp: note.timestamp)
    }

    func loadNotification(with noteId: String) -> Notification? {
        let predicate = NSPredicate(format: "(notificationId == %@)", noteId)

        return mainContext.firstObject(ofType: Notification.self, matching: predicate)
    }

    func loadNotification(near note: Notification, withIndexDelta delta: Int) -> Notification? {
        guard let notifications = tableViewHandler?.resultsController?.fetchedObjects as? [Notification] else {
            return nil
        }

        return viewModel.loadNotification(
            near: note,
            allNotifications: notifications,
            withIndexDelta: delta
        )
    }

    func resetNotifications() {
        do {
            selectedNotification = nil
            mainContext.deleteAllObjects(ofType: Notification.self)
            try mainContext.save()
        } catch {
            DDLogError("Error while trying to nuke Notifications Collection: [\(error)]")
        }
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

    var userDefaults: UserPersistentRepository {
        return UserPersistentStoreFactory.instance()
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

    enum Filter: Int, FilterTabBarItem, CaseIterable {
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

        var confirmationMessageTitle: String {
            switch self {
            case .none:     return ""
            case .unread:   return NSLocalizedString("unread", comment: "Displayed in the confirmation alert when marking unread notifications as read.")
            case .comment:  return NSLocalizedString("comment", comment: "Displayed in the confirmation alert when marking comment notifications as read.")
            case .follow:   return NSLocalizedString("follow", comment: "Displayed in the confirmation alert when marking follow notifications as read.")
            case .like:     return NSLocalizedString("like", comment: "Displayed in the confirmation alert when marking like notifications as read.")
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
    }

    enum Settings {
        static let estimatedRowHeight = CGFloat(70)
    }

    enum Stats {
        static let noteTypeKey = "notification_type"
        static let noteTypeUnknown = "unknown"
        static let sourceKey = "source"
        static let sourceValue = "notifications"
        static let selectedFilter = "selected_filter"
    }

    enum Syncing {
        static let minimumPullToRefreshDelay = TimeInterval(1.5)
        static let pushMaxWait = TimeInterval(1.5)
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
        guard shouldShowPrimeForPush, !userDefaults.notificationPrimerAlertWasDisplayed else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.displayAlertDelay) {
            self.showNotificationPrimerAlert()
        }
    }

    private func notificationAlertApproveAction(_ controller: FancyAlertViewController) {
        InteractiveNotificationsManager.shared.requestAuthorization { allowed in
            if allowed {
                // User has allowed notifications so we don't need to show the inline prompt
                UserPersistentStoreFactory.instance().notificationPrimerInlineWasAcknowledged = true
            }

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
        guard (try? WPAccount.lookupDefaultWordPressComAccount(in: mainContext)) != nil else {
            return
        }

        PushNotificationsManager.shared.loadAuthorizationStatus { [weak self] (enabled) in
            guard enabled == .notDetermined else {
                return
            }

            UserPersistentStoreFactory.instance().notificationPrimerAlertWasDisplayed = true

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
    }
}

// MARK: - Scrolling
//
extension NotificationsViewController: WPScrollableViewController {
    // Used to scroll view to top when tapping on tab bar item when VC is already visible.
    func scrollViewToTop() {
        if isViewLoaded {
            tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true)
        }
    }
}

// MARK: - Jetpack banner delegate
//
extension NotificationsViewController: JPScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        processJetpackBannerVisibility(scrollView)
    }
}

// MARK: - StoryboardLoadable

extension NotificationsViewController: StoryboardLoadable {
    static var defaultStoryboardName: String {
        return "Notifications"
    }
}
