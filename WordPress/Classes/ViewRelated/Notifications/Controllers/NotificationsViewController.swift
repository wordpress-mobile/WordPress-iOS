import Foundation
import CoreData
import WordPressComAnalytics
import WordPress_AppbotX
import WordPressShared



/// The purpose of this class is to render the collection of Notifications, associated to the main
/// WordPress.com account.
///
/// Plus, we provide a simple mechanism to render the details for a specific Notification,
/// given its remote identifier.
///
class NotificationsViewController : UITableViewController
{
    // MARK: - Properties

    /// TableHeader
    ///
    @IBOutlet var tableHeaderView: UIView!

    /// Filtering Segmented Control
    ///
    @IBOutlet var filtersSegmentedControl: UISegmentedControl!

    /// Ratings View
    ///
    @IBOutlet var ratingsView: ABXPromptView!

    /// Defines the Height of the Ratings View
    ///
    @IBOutlet var ratingsHeightConstraint: NSLayoutConstraint!

    /// TableView Handler: Our commander in chief!
    ///
    private var tableViewHandler: WPTableViewHandler!

    /// NoResults View
    ///
    private var noResultsView: WPNoResultsView!

    /// All of the data will be fetched during the FetchedResultsController init. Prevent overfetching
    ///
    private var lastReloadDate = NSDate()

    /// Indicates whether the view is required to reload results on viewWillAppear, or not
    ///
    private var needsReloadResults = false

    /// Notifications that must be deleted display an "Undo" button, which simply cancels the deletion task.
    ///
    private var notificationDeletionRequests: [NSManagedObjectID: NotificationDeletionRequest] = [:]

    /// Notifications being deleted are proactively filtered from the list.
    ///
    private var notificationIdsBeingDeleted = Set<NSManagedObjectID>()



    // MARK: - View Lifecycle

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        restorationClass = self.dynamicType

        startListeningToAccountNotifications()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
        setupConstraints()
        setupTableView()
        setupTableHeaderView()
        setupTableFooterView()
        setupTableHandler()
        setupRatingsView()
        setupRefreshControl()
        setupNoResultsView()
        setupFiltersSegmentedControl()

        tableView.reloadData()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Manually deselect the selected row. This is required due to a bug in iOS7 / iOS8
        tableView.deselectSelectedRowWithAnimation(true)

        // While we're onscreen, please, update rows with animations
        tableViewHandler.updateRowAnimation = .Fade

        // Tracking
        WPAnalytics.track(WPAnalyticsStat.OpenedNotificationsList)

        // Notifications
        startListeningToNotifications()
        resetApplicationBadge()
        updateLastSeenTime()

        // Refresh the UI
        reloadResultsControllerIfNeeded()
        showNoResultsViewIfNeeded()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        showRatingViewIfApplicable()
        syncNewNotifications()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        stopListeningToNotifications()

        // If we're not onscreen, don't use row animations. Otherwise the fade animation might get animated incrementally
        tableViewHandler.updateRowAnimation = .None
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        // Note: We're assuming `tableViewHandler` might be nil. Weird case in which the view
        // hasn't loaded, yet, but the method is still executed.
        tableViewHandler?.clearCachedRowHeights()
    }



    // MARK: - UITableView Methods

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return NoteTableHeaderView.headerHeight
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionInfo = tableViewHandler.resultsController.sections?[section] else {
            return nil
        }

        let headerView = NoteTableHeaderView()
        headerView.title = Notification.descriptionForSectionIdentifier(sectionInfo.name)
        headerView.separatorColor = tableView.separatorColor

        return headerView
    }

    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // Make sure no SectionFooter is rendered
        return CGFloat.min
    }

    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // Make sure no SectionFooter is rendered
        return nil
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let identifier = NoteTableViewCell.reuseIdentifier()
        guard let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as? NoteTableViewCell else {
            fatalError()
        }

        configureCell(cell, atIndexPath: indexPath)

        return cell
    }

    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return Settings.estimatedRowHeight
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        // Load the Subject + Snippet
        guard let note = tableViewHandler.resultsController.objectOfType(Notification.self, atIndexPath: indexPath) else {
            return CGFloat.min
        }

        // Old School Height Calculation
        let subject = note.subjectBlock?.attributedSubjectText
        let snippet = note.snippetBlock?.attributedSnippetText

        return NoteTableViewCell.layoutHeightWithWidth(tableView.bounds.width, subject:subject, snippet:snippet)
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Failsafe: Make sure that the Notification (still) exists
        guard let note = tableViewHandler.resultsController.objectOfType(Notification.self, atIndexPath: indexPath) else {
            tableView.deselectSelectedRowWithAnimation(true)
            return
        }

        // Push the Details: Unless the note has a pending deletion!
        guard deletionRequestForNoteWithID(note.objectID) == nil else {
            return
        }

        showDetailsForNotification(note)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let note = sender as? Notification else {
            return
        }

        guard let detailsViewController = segue.destinationViewController as? NotificationDetailsViewController else {
            return
        }

        detailsViewController.setupWithNotification(note)
        detailsViewController.onDeletionRequestCallback = { request in
            self.showUndeleteForNoteWithID(note.objectID, request: request)
        }
    }
}


// MARK: - Row Actions
//
extension NotificationsViewController
{
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }

    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        guard let note = tableViewHandler?.resultsController.objectOfType(Notification.self, atIndexPath: indexPath),
            let block = note.blockGroupOfKind(.Comment)?.blockOfKind(.Comment) else
        {
            // Not every single row will have actions: Slight hack so that the UX isn't terrible:
            //  -   First: Return an Empty UITableViewRowAction
            //  -   Second: Hide it after a few seconds.
            //
            tableView.disableEditionAfterDelay()

            return noopRowActions()
        }

        // Helpers
        var actions = [UITableViewRowAction]()

        // Comments: Trash
        if block.isActionEnabled(.Trash) {
            let title = NSLocalizedString("Trash", comment: "Trashes a comment")

            let trash = UITableViewRowAction(style: .Destructive, title: title, handler: { [weak self] _ in
                let request = NotificationDeletionRequest(kind: .Deletion, action: { [weak self] onCompletion in
                    self?.actionsService.deleteCommentWithBlock(block) { success in
                        onCompletion(success)
                    }
                })

                self?.showUndeleteForNoteWithID(note.objectID, request: request)

                self?.tableView.setEditing(false, animated: true)
            })

            trash.backgroundColor = WPStyleGuide.errorRed()
            actions.append(trash)
        }

        // Comments: Moderation Disabled
        guard block.isActionEnabled(.Approve) else {
            return actions
        }

        // Comments: Unapprove
        if block.isActionOn(.Approve) {
            let title = NSLocalizedString("Unapprove", comment: "Unapproves a Comment")

            let trash = UITableViewRowAction(style: .Normal, title: title, handler: { [weak self] _ in
                self?.actionsService.unapproveCommentWithBlock(block)
                self?.tableView.setEditing(false, animated: true)
            })

            trash.backgroundColor = WPStyleGuide.grey()
            actions.append(trash)

        // Comments: Approve
        } else {
            let title = NSLocalizedString("Approve", comment: "Approves a Comment")

            let trash = UITableViewRowAction(style: .Normal, title: title, handler: { [weak self] _ in
                self?.actionsService.approveCommentWithBlock(block)
                self?.tableView.setEditing(false, animated: true)
            })

            trash.backgroundColor = WPStyleGuide.wordPressBlue()
            actions.append(trash)
        }

        return actions
    }

    private func noopRowActions() -> [UITableViewRowAction] {
        let noop = UITableViewRowAction(style: .Normal, title: title, handler: { _ in })
        noop.backgroundColor = UIColor.clearColor()
        return [noop]
    }
}



// MARK: - User Interface Initialization
//
private extension NotificationsViewController
{
    func setupNavigationBar() {
        // Don't show 'Notifications' in the next-view back button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .Plain, target: nil, action: nil)
        navigationItem.title = NSLocalizedString("Notifications", comment: "Notifications View Controller title")
    }

    func setupConstraints() {
        precondition(ratingsHeightConstraint != nil)

        // Ratings is initially hidden!
        ratingsHeightConstraint.constant = 0
    }

    func setupTableView() {
        // Register the cells
        let nib = UINib(nibName: NoteTableViewCell.classNameWithoutNamespaces(), bundle: NSBundle.mainBundle())
        tableView.registerNib(nib, forCellReuseIdentifier: NoteTableViewCell.reuseIdentifier())

        // UITableView
        tableView.accessibilityIdentifier  = "Notifications Table"
        tableView.cellLayoutMarginsFollowReadableWidth = false
        WPStyleGuide.configureColorsForView(view, andTableView:tableView)
    }

    func setupTableHeaderView() {
        precondition(tableHeaderView != nil)

        // Fix: Update the Frame manually: Autolayout doesn't really help us, when it comes to Table Headers
        let requiredSize        = tableHeaderView.systemLayoutSizeFittingSize(view.bounds.size)
        var headerFrame         = tableHeaderView.frame
        headerFrame.size.height = requiredSize.height

        tableHeaderView.frame  = headerFrame
        tableHeaderView.layoutIfNeeded()

        // Due to iOS awesomeness, unless we re-assign the tableHeaderView, iOS might never refresh the UI
        tableView.tableHeaderView = tableHeaderView
        tableView.setNeedsLayout()
    }

    func setupTableFooterView() {
        //  Fix: Hide the cellSeparators, when the table is empty
        tableView.tableFooterView = UIView()
    }

    func setupTableHandler() {
        let handler = WPTableViewHandler(tableView: tableView)
        handler.cacheRowHeights = true
        handler.delegate = self
        tableViewHandler = handler
    }

    func setupRatingsView() {
        precondition(ratingsView != nil)

        let ratingsFont = WPFontManager.systemRegularFontOfSize(Ratings.fontSize)

        ratingsView.label.font = ratingsFont
        ratingsView.leftButton.titleLabel?.font = ratingsFont
        ratingsView.rightButton.titleLabel?.font = ratingsFont
        ratingsView.delegate = self
        ratingsView.alpha = WPAlphaZero
    }

    func setupRefreshControl() {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(refresh), forControlEvents: .ValueChanged)
        refreshControl = control
    }

    func setupNoResultsView() {
        noResultsView = WPNoResultsView()
        noResultsView.delegate = self
    }

    func setupFiltersSegmentedControl() {
        precondition(filtersSegmentedControl != nil)

        for filter in Filter.allFilters {
            filtersSegmentedControl.setTitle(filter.title, forSegmentAtIndex: filter.rawValue)
        }

        WPStyleGuide.Notifications.configureSegmentedControl(filtersSegmentedControl)
    }
}



// MARK: - Notifications
//
private extension NotificationsViewController
{
    func startListeningToNotifications() {
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: #selector(applicationDidBecomeActive), name:UIApplicationDidBecomeActiveNotification, object: nil)
        nc.addObserver(self, selector: #selector(notificationsWereUpdated), name:NotificationSyncServiceDidUpdateNotifications, object: nil)
    }

    func startListeningToAccountNotifications() {
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: #selector(defaultAccountDidChange), name:WPAccountDefaultWordPressComAccountChangedNotification, object: nil)
    }

    func stopListeningToNotifications() {
        let nc = NSNotificationCenter.defaultCenter()
        nc.removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
        nc.removeObserver(self, name:NotificationSyncServiceDidUpdateNotifications, object: nil)
    }

    @objc func applicationDidBecomeActive(note: NSNotification) {
        // Let's reset the badge, whenever the app comes back to FG, and this view was upfront!
        guard isViewLoaded() == true && view.window != nil else {
            return
        }

        resetApplicationBadge()
        updateLastSeenTime()
        reloadResultsControllerIfNeeded()
    }

    @objc func defaultAccountDidChange(note: NSNotification) {
        needsReloadResults = true
        resetNotifications()
        resetLastSeenTime()
        resetApplicationBadge()
        syncNewNotifications()
    }

    @objc func notificationsWereUpdated(note: NSNotification) {
        // If we're onscreen, don't leave the badge updated behind
        guard UIApplication.sharedApplication().applicationState == .Active else {
            return
        }

        resetApplicationBadge()
        updateLastSeenTime()
    }
}



// MARK: - Public Methods
//
extension NotificationsViewController
{
    /// Pushes the Details for a given notificationID, immediately, if the notification is already available.
    /// Otherwise, will attempt to Sync the Notification. If this cannot be achieved before the timeout defined
    /// by `Syncing.pushMaxWait` kicks in, we'll just do nothing (in order not to disrupt the UX!).
    ///
    /// - Parameter notificationID: The ID of the Notification that should be rendered onscreen.
    ///
    func showDetailsForNotificationWithID(noteId: String) {
        if let note = loadNotificationWithID(noteId) {
            showDetailsForNotification(note)
            return
        }

        syncNotificationWithID(noteId, timeout: Syncing.pushMaxWait) { note in
            self.showDetailsForNotification(note)
        }
    }

    /// Pushes the details for a given Notification Instance.
    ///
    /// - Parameter note: The Notification that should be rendered.
    ///
    func showDetailsForNotification(note: Notification) {
        DDLogSwift.logInfo("Pushing Notification Details for: [\(note.notificationId)]")

        // Track
        let properties = [Stats.noteTypeKey : note.type ?? Stats.noteTypeUnknown]
        WPAnalytics.track(.OpenedNotificationDetails, withProperties: properties)

        // Failsafe: Don't push nested!
        if navigationController?.visibleViewController != self {
            navigationController?.popViewControllerAnimated(false)
        }

        // Mark as Read
        if note.read == false {
            let service = NotificationSyncService()
            service?.markAsRead(note)
        }

        // Display Details
        if let postID = note.metaPostID, let siteID = note.metaSiteID where note.kind == .Matcher {
            let readerViewController = ReaderDetailViewController.controllerWithPostID(postID, siteID: siteID)
            navigationController?.pushViewController(readerViewController, animated: true)
            return
        }

        performSegueWithIdentifier(NotificationDetailsViewController.classNameWithoutNamespaces(), sender: note)
    }

    /// Will display an Undelete button on top of a given notification.
    /// On timeout, the destructive action (received via parameter) will be exeuted, and the notification
    /// will (supposedly) get deleted.
    ///
    /// -   Parameters:
    ///     -   noteObjectID: The Core Data ObjectID associated to a given notification.
    ///     -   request: A DeletionRequest Struct
    ///
    func showUndeleteForNoteWithID(noteObjectID: NSManagedObjectID, request: NotificationDeletionRequest) {
        // Mark this note as Pending Deletion and Reload
        notificationDeletionRequests[noteObjectID] = request
        reloadRowForNotificationWithID(noteObjectID)

        // Dispatch the Action block
        performSelector(#selector(deleteNoteWithID), withObject: noteObjectID, afterDelay: Syncing.undoTimeout)
    }
}


// MARK: - Notifications Deletion Mechanism
//
private extension NotificationsViewController
{
    @objc func deleteNoteWithID(noteObjectID: NSManagedObjectID) {
        // Was the Deletion Cancelled?
        guard let request = deletionRequestForNoteWithID(noteObjectID) else {
            return
        }

        // Hide the Notification
        notificationIdsBeingDeleted.insert(noteObjectID)
        reloadResultsController()

        // Hit the Deletion Action
        request.action { success in
            self.notificationDeletionRequests.removeValueForKey(noteObjectID)
            self.notificationIdsBeingDeleted.remove(noteObjectID)

            // Error: let's unhide the row
            if success == false {
                self.reloadResultsController()
            }
        }
    }

    func cancelDeletionRequestForNoteWithID(noteObjectID: NSManagedObjectID) {
        notificationDeletionRequests.removeValueForKey(noteObjectID)
        reloadRowForNotificationWithID(noteObjectID)

        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(deleteNoteWithID), object: noteObjectID)
    }

    func deletionRequestForNoteWithID(noteObjectID: NSManagedObjectID) -> NotificationDeletionRequest? {
        return notificationDeletionRequests[noteObjectID]
    }
}



// MARK: - WPTableViewHandler Helpers
//
private extension NotificationsViewController
{
    func reloadResultsControllerIfNeeded() {
        // NSFetchedResultsController groups notifications based on a transient property ("sectionIdentifier").
        // Simply calling reloadData doesn't make the FRC recalculate the sections.
        // For that reason, let's force a reload, only when 1 day has elapsed, and sections would have changed.
        //
        let daysElapsed = NSCalendar.currentCalendar().daysElapsedSinceDate(lastReloadDate)
        guard daysElapsed != 0 || needsReloadResults else {
            return
        }

        reloadResultsController()
    }

    func reloadResultsController() {
        // Update the Predicate: We can't replace the previous fetchRequest, since it's readonly!
        let fetchRequest = tableViewHandler.resultsController.fetchRequest
        fetchRequest.predicate = predicateForSelectedFilters()

        /// Refetch + Reload
        tableViewHandler.clearCachedRowHeights()
        _ = try? tableViewHandler.resultsController.performFetch()
        tableView.reloadData()

        // Empty State?
        showNoResultsViewIfNeeded()

        // Don't overwork!
        lastReloadDate = NSDate()
        needsReloadResults = false
    }

    func reloadRowForNotificationWithID(noteObjectID: NSManagedObjectID) {
        do {
            let note = try mainContext.existingObjectWithID(noteObjectID)

            if let indexPath = tableViewHandler.resultsController.indexPathForObject(note) {
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
        } catch {
            DDLogSwift.logError("Error refreshing Notification Row \(error)")
        }
    }
}



// MARK: - UIRefreshControl Methods
//
extension NotificationsViewController
{
    func refresh() {
        guard let service = NotificationSyncService() else {
            refreshControl?.endRefreshing()
            return
        }

        service.sync { _ in
            self.refreshControl?.endRefreshing()
        }
    }
}



// MARK: - UISegmentedControl Methods
//
extension NotificationsViewController
{
    func segmentedControlDidChange(sender: UISegmentedControl) {
        reloadResultsController()

        // It's a long way, to the top (if you wanna rock'n roll!)
        guard tableViewHandler.resultsController.fetchedObjects?.count != 0 else {
            return
        }

        let path = NSIndexPath(forRow: 0, inSection: 0)
        tableView.scrollToRowAtIndexPath(path, atScrollPosition: .Bottom, animated: true)
    }
}



// MARK: - WPTableViewHandlerDelegate Methods
//
extension NotificationsViewController: WPTableViewHandlerDelegate
{
    func managedObjectContext() -> NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }

    func fetchRequest() -> NSFetchRequest {
        let request = NSFetchRequest(entityName: entityName())
        request.sortDescriptors = [NSSortDescriptor(key: Filter.sortKey, ascending: false)]
        request.predicate = predicateForSelectedFilters()

        return request
    }

    func predicateForSelectedFilters() -> NSPredicate {
        var format = "NOT (SELF IN %@)"
        if let filter = Filter(rawValue: filtersSegmentedControl.selectedSegmentIndex), let condition = filter.condition {
            format += " AND \(condition)"
        }

        return NSPredicate(format: format, Array(notificationIdsBeingDeleted))
    }

    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        // iOS 8 has a nice bug in which, randomly, the last cell per section was getting an extra separator.
        // For that reason, we draw our own separators.
        //
        guard let note = tableViewHandler.resultsController.objectOfType(Notification.self, atIndexPath: indexPath) else {
            return
        }

        guard let cell = cell as? NoteTableViewCell else {
            return
        }

        let deletionRequest         = deletionRequestForNoteWithID(note.objectID)
        let isLastRow               = tableViewHandler.resultsController.isLastIndexPathInSection(indexPath)

        cell.forceCustomCellMargins = true
        cell.attributedSubject      = note.subjectBlock?.attributedSubjectText
        cell.attributedSnippet      = note.snippetBlock?.attributedSnippetText
        cell.read                   = note.read
        cell.noticon                = note.noticon
        cell.unapproved             = note.isUnapprovedComment
        cell.showsBottomSeparator   = !isLastRow
        cell.undeleteOverlayText    = deletionRequest?.kind.legendText
        cell.onUndelete             = { [weak self] in
            self?.cancelDeletionRequestForNoteWithID(note.objectID)
        }

        cell.downloadIconWithURL(note.iconURL)
    }

    func sectionNameKeyPath() -> String {
        return "sectionIdentifier"
    }

    func entityName() -> String {
        return Notification.classNameWithoutNamespaces()
    }

    func tableViewDidChangeContent(tableView: UITableView) {
        // Due to an UIKit bug, we need to draw our own separators (Issue #2845). Let's update the separator status
        // after a DB OP. This loop has been measured in the order of milliseconds (iPad Mini)
        //
        for indexPath in tableView.indexPathsForVisibleRows ?? [] {
            guard let cell = tableView.cellForRowAtIndexPath(indexPath) as? NoteTableViewCell else {
                continue
            }

            let isLastRow = tableViewHandler.resultsController.isLastIndexPathInSection(indexPath)
            cell.showsBottomSeparator = !isLastRow
        }

        // Update NoResults View
        showNoResultsViewIfNeeded()
    }
}



// MARK: - Filter Helpers
//
private extension NotificationsViewController
{
    func showFiltersSegmentedControlIfApplicable() {
        guard tableHeaderView.alpha == WPAlphaZero && shouldDisplayFilters == true else {
            return
        }

        UIView.animateWithDuration(WPAnimationDurationDefault) {
            self.tableHeaderView.alpha = WPAlphaFull
        }
    }

    func hideFiltersSegmentedControlIfApplicable() {
        if tableHeaderView.alpha == WPAlphaFull && shouldDisplayFilters == false {
            tableHeaderView.alpha = WPAlphaZero
        }
    }

    var shouldDisplayFilters: Bool {
        // Filters should only be hidden whenever there are no Notifications in the bucket (contrary to the FRC's
        // results, which are filtered by the active predicate!).
        //
        let helper = CoreDataHelper<Notification>(context: mainContext)
        return helper.countObjects() > 0
    }
}



// MARK: - NoResults Helpers
//
private extension NotificationsViewController
{
    func showNoResultsViewIfNeeded() {
        // Remove + Show Filters, if needed
        guard shouldDisplayNoResultsView == true else {
            noResultsView.removeFromSuperview()
            showFiltersSegmentedControlIfApplicable()
            return
        }

        // Attach the view
        if noResultsView.superview == nil {
            tableView.addSubviewWithFadeAnimation(noResultsView)
        }

        // Refresh its properties: The user may have signed into WordPress.com
        noResultsView.titleText     = noResultsTitleText
        noResultsView.messageText   = noResultsMessageText
        noResultsView.accessoryView = noResultsAccessoryView
        noResultsView.buttonTitle   = noResultsButtonText

        // Hide the filter header if we're showing the Jetpack prompt
        hideFiltersSegmentedControlIfApplicable()
    }

    var noResultsTitleText: String {
        guard shouldDisplayJetpackMessage == false else {
            return NSLocalizedString("Connect to Jetpack", comment: "Notifications title displayed when a self-hosted user is not connected to Jetpack")
        }

        let messageMap: [Filter: String] = [
            .None       : NSLocalizedString("No notifications yet", comment: "Displayed in the Notifications Tab, when there are no notifications"),
            .Unread     : NSLocalizedString("No unread notifications", comment: "Displayed in the Notifications Tab, when the Unread Filter shows no notifications"),
            .Comment    : NSLocalizedString("No comments notifications", comment: "Displayed in the Notifications Tab, when the Comments Filter shows no notifications"),
            .Follow     : NSLocalizedString("No new followers notifications", comment: "Displayed in the Notifications Tab, when the Follow Filter shows no notifications"),
            .Like       : NSLocalizedString("No like notifications", comment: "Displayed in the Notifications Tab, when the Likes Filter shows no notifications")
        ]

        let filter = Filter(rawValue: filtersSegmentedControl.selectedSegmentIndex) ?? .None
        return messageMap[filter] ?? String()
    }

    var noResultsMessageText: String? {
        let jetpackMessage = NSLocalizedString("Jetpack supercharges your self-hosted WordPress site.", comment: "Notifications message displayed when a self-hosted user is not connected to Jetpack")
        return shouldDisplayJetpackMessage ? jetpackMessage : nil
    }

    var noResultsAccessoryView: UIView? {
        return shouldDisplayJetpackMessage ? UIImageView(image: UIImage(named: "icon-jetpack-gray")) : nil
    }

    var noResultsButtonText: String? {
        return shouldDisplayJetpackMessage ? NSLocalizedString("Learn more", comment: "") : nil
    }

    var shouldDisplayJetpackMessage: Bool {
        return AccountHelper.isDotcomAvailable() == false
    }

    var shouldDisplayNoResultsView: Bool {
        return tableViewHandler.resultsController.fetchedObjects?.count == 0
    }
}


// MARK: - WPNoResultsViewDelegate Methods
//
extension NotificationsViewController: WPNoResultsViewDelegate
{
    func didTapNoResultsView(noResultsView: WPNoResultsView) {
        guard let targetURL = NSURL(string: WPJetpackInformationURL) else {
            fatalError()
        }

        let webViewController = WPWebViewController(URL: targetURL)
        let navController = UINavigationController(rootViewController: webViewController)
        presentViewController(navController, animated: true, completion: nil)

        let properties = [Stats.sourceKey: Stats.sourceValue]
        WPAnalytics.track(.SelectedLearnMoreInConnectToJetpackScreen, withProperties: properties)
    }
}


// MARK: - RatingsView Helpers
//
private extension NotificationsViewController
{
    func showRatingViewIfApplicable() {
        guard AppRatingUtility.shouldPromptForAppReviewForSection(Ratings.section) else {
            return
        }

        guard ratingsHeightConstraint.constant != Ratings.heightFull && ratingsView.alpha != WPAlphaFull else {
            return
        }

        ratingsView.alpha = WPAlphaZero

        UIView.animateWithDuration(WPAnimationDurationDefault, delay: Ratings.animationDelay, options: .CurveEaseIn, animations: {
            self.ratingsView.alpha = WPAlphaFull
            self.ratingsHeightConstraint.constant = Ratings.heightFull

            self.setupTableHeaderView()
        }, completion: nil)

        WPAnalytics.track(.AppReviewsSawPrompt)
    }

    func hideRatingView() {
        UIView.animateWithDuration(WPAnimationDurationDefault) {
            self.ratingsView.alpha = WPAlphaZero
            self.ratingsHeightConstraint.constant = Ratings.heightZero

            self.setupTableHeaderView()
        }
    }
}


// MARK: - Sync'ing Helpers
//
private extension NotificationsViewController
{
    func syncNewNotifications() {
        let service = NotificationSyncService()
        service?.sync()
    }

    func syncNotificationWithID(noteId: String, timeout: NSTimeInterval, success: (note: Notification) -> Void) {
        let service = NotificationSyncService()
        let startDate = NSDate()

        DDLogSwift.logInfo("Sync'ing Notification [\(noteId)]")

        service?.syncNote(with: noteId) { error, note in
            guard abs(startDate.timeIntervalSinceNow) <= timeout else {
                DDLogSwift.logError("Error: Timeout while trying to load Notification [\(noteId)]")
                return
            }

            guard let note = note else {
                DDLogSwift.logError("Error: Couldn't load Notification [\(noteId)]")
                return
            }

            DDLogSwift.logInfo("Notification Sync'ed in \(startDate.timeIntervalSinceNow) seconds")
            success(note: note)
        }
    }

    func updateLastSeenTime() {
        guard let note = tableViewHandler.resultsController.fetchedObjects?.first as? Notification else {
            return
        }

        guard let timestamp = note.timestamp where timestamp != lastSeenTime else {
            return
        }

        let service = NotificationSyncService()
        service?.updateLastSeen(timestamp) { error in
            guard error == nil else {
                return
            }

            self.lastSeenTime = timestamp
        }
    }

    func loadNotificationWithID(noteId: String) -> Notification? {
        let helper = CoreDataHelper<Notification>(context: mainContext)
        let predicate = NSPredicate(format: "(notificationId == %@)", noteId)

        return helper.firstObject(matchingPredicate: predicate)
    }

    func resetNotifications() {
        do {
            let helper = CoreDataHelper<Notification>(context: mainContext)
            helper.deleteAllObjects()
            try mainContext.save()
        } catch {
            DDLogSwift.logError("Error while trying to nuke Notifications Collection: [\(error)]")
        }
    }

    func resetLastSeenTime() {
        lastSeenTime = nil
    }

    func resetApplicationBadge() {
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
    }
}



// MARK: - ABXPromptViewDelegate Methods
//
extension NotificationsViewController: ABXPromptViewDelegate
{
    func appbotPromptForReview() {
        WPAnalytics.track(.AppReviewsRatedApp)
        AppRatingUtility.ratedCurrentVersion()
        hideRatingView()

        if let targetURL = NSURL(string: Ratings.reviewURL) {
            UIApplication.sharedApplication().openURL(targetURL)
        }
    }

    func appbotPromptForFeedback() {
        WPAnalytics.track(.AppReviewsOpenedFeedbackScreen)
        ABXFeedbackViewController.showFromController(self, placeholder: nil, delegate: nil)
        AppRatingUtility.gaveFeedbackForCurrentVersion()
        hideRatingView()
    }

    func appbotPromptClose() {
        WPAnalytics.track(.AppReviewsDeclinedToRateApp)
        AppRatingUtility.declinedToRateCurrentVersion()
        hideRatingView()
    }

    func appbotPromptLiked() {
        WPAnalytics.track(.AppReviewsLikedApp)
        AppRatingUtility.likedCurrentVersion()
    }

    func appbotPromptDidntLike() {
        WPAnalytics.track(.AppReviewsDidntLikeApp)
        AppRatingUtility.dislikedCurrentVersion()
    }

    func abxFeedbackDidSendFeedback () {
        WPAnalytics.track(.AppReviewsSentFeedback)
    }

    func abxFeedbackDidntSendFeedback() {
        WPAnalytics.track(.AppReviewsCanceledFeedbackScreen)
    }
}



// MARK: - Private Properties
//
private extension NotificationsViewController
{
    typealias NoteKind = Notification.Kind

    var mainContext: NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }

    var actionsService: NotificationActionsService {
        return NotificationActionsService(managedObjectContext: mainContext)
    }

    var userDefaults: NSUserDefaults{
        return NSUserDefaults.standardUserDefaults()
    }

    var lastSeenTime: String? {
        get {
            return userDefaults.stringForKey(Settings.lastSeenTime)
        }
        set {
            userDefaults.setValue(newValue, forKey: Settings.lastSeenTime)
            userDefaults.synchronize()
        }
    }

    enum Filter: Int {
        case None = 0
        case Unread = 1
        case Comment = 2
        case Follow = 3
        case Like = 4

        var condition: String? {
            switch self {
            case .None:     return nil
            case .Unread:   return "read = NO"
            case .Comment:  return "type = '\(NoteKind.Comment.toTypeValue)'"
            case .Follow:   return "type = '\(NoteKind.Follow.toTypeValue)'"
            case .Like:     return "type = '\(NoteKind.Like.toTypeValue)' OR type = '\(NoteKind.CommentLike.toTypeValue)'"
            }
        }

        var title: String {
            switch self {
            case .None:     return NSLocalizedString("All", comment: "Displays all of the Notifications, unfiltered")
            case .Unread:   return NSLocalizedString("Unread", comment: "Filters Unread Notifications")
            case .Comment:  return NSLocalizedString("Comments", comment: "Filters Comments Notifications")
            case .Follow:   return NSLocalizedString("Follows", comment: "Filters Follows Notifications")
            case .Like:     return NSLocalizedString("Likes", comment: "Filters Likes Notifications")
            }
        }

        static let sortKey = "timestamp"
        static let allFilters = [Filter.None, .Unread, .Comment, .Follow, .Like]
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
    }

    enum Syncing {
        static let pushMaxWait = NSTimeInterval(1.5)
        static let syncTimeout = NSTimeInterval(10)
        static let undoTimeout = NSTimeInterval(4)
    }

    enum Ratings {
        static let section = "notifications"
        static let heightFull = CGFloat(100)
        static let heightZero = CGFloat(0)
        static let animationDelay = NSTimeInterval(0.5)
        static let fontSize = CGFloat(15.0)
        static let reviewURL = AppRatingUtility.appReviewUrl()
    }
}
