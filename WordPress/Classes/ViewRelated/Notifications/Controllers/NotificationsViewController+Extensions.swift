import Foundation
import CoreData
import Simperium
import WordPressComAnalytics
import WordPress_AppbotX
import WordPressShared




/// The purpose of this class is to render the collection of Notifications, associated to the main
/// WordPress.com account found in the system.
///
/// This class relies on both, Simperium and WPTableViewHandler to automatically receive
/// new Notifications that might be generated, and render them onscreen.
/// Plus, we provide a simple mechanism to render the details for a specific Notification,
/// given its remote identifier. This is specially useful when dealing with events derived from
/// interactions with Push Notifications OS banners.
///
class NotificationsViewController : UITableViewController
{
    @IBOutlet var tableHeaderView : UIView!
    @IBOutlet var filtersSegmentedControl : UISegmentedControl!
    @IBOutlet var ratingsView : ABXPromptView!
    @IBOutlet var ratingsHeightConstraint : NSLayoutConstraint!
    var tableViewHandler : WPTableViewHandler!
    private var noResultsView : WPNoResultsView!
    private var pushNotificationID : String?
    private var pushNotificationDate : NSDate?

    // All of the data will be fetched during the FetchedResultsController init. Prevent overfetching
    private var lastReloadDate = NSDate()

    // Notifications that received a destructive action will allow the user to Undo this action.
    // Once the Timeout elapses, we'll move the NotificationID to the BeingDeleted collection,
    // so that it can be proactively filtered from the list.
    private var notificationDeletionBlocks = [NSManagedObjectID: NotificationDeletionActionBlock]()
    private var notificationIdsBeingDeleted = Set<NSManagedObjectID>()


    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
        setupNotificationsBucketDelegate()

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
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        stopListeningToNotifications()

        // If we're not onscreen, don't use row animations. Otherwise the fade animation might get animated incrementally
        tableViewHandler.updateRowAnimation = .None
    }


    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        tableViewHandler.clearCachedRowHeights()
    }


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
        return NoteEstimatedHeight
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        // Load the Subject + Snippet
        guard let note = tableViewHandler.resultsController.objectOfType(Notification.self, atIndexPath: indexPath) else {
            return CGFloat.min
        }

        // Old School Height Calculation
        let subject = note.subjectBlock()?.attributedSubjectText()
        let snippet = note.snippetBlock()?.attributedSnippetText()

        return NoteTableViewCell.layoutHeightWithWidth(tableView.bounds.width, subject:subject, snippet:snippet)
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Failsafe: Make sure that the Notification (still) exists
        guard let note = tableViewHandler.resultsController.objectOfType(Notification.self, atIndexPath: indexPath) else {
            tableView.deselectSelectedRowWithAnimation(true)
            return
        }

        // Push the Details: Unless the note has a pending deletion!
        guard isNoteMarkedForDeletion(note.objectID) == false else {
            return
        }

        showDetailsForNotification(note)
    }


    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let note = sender as? Notification else {
            return
        }

        if let detailsViewController = segue.destinationViewController as? NotificationDetailsViewController {
            detailsViewController.setupWithNotification(note)
            detailsViewController.onDeletionRequestCallback = { onUndoTimeout in
                self.showUndelete(note.objectID, onTimeout: onUndoTimeout)
            }
        }

        if let readerViewController = segue.destinationViewController as? ReaderDetailViewController {
            readerViewController.setupWithPostID(note.metaPostID, siteID: note.metaSiteID)
        }
    }

    let NoteEstimatedHeight = CGFloat(70)
}



// MARK: - User Interface Initialization
//
extension NotificationsViewController
{
    func setupNavigationBar() {
        // Don't show 'Notifications' in the next-view back button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .Plain, target: nil, action: nil)

        // This is only required for debugging:
        // If we're sync'ing against a custom bucket, we should let the user know about it!
        let bucketName = Notification.classNameWithoutNamespaces()

        if let overridenName = simperium.bucketOverrides[bucketName] as? String where overridenName != WPNotificationsBucketName {
            title = "Notifications from [\(overridenName)]"
        } else {
            title = NSLocalizedString("Notifications", comment: "Notifications View Controller title")
        }
    }

    func setupConstraints() {
        precondition(ratingsHeightConstraint != nil)

        // Ratings is initially hidden!
        ratingsHeightConstraint.constant = 0
    }

    func setupTableView() {
        // Register the cells
        let nibNames = [ NoteTableViewCell.classNameWithoutNamespaces() ]
        let bundle = NSBundle.mainBundle()

        for nibName in nibNames {
            let nib = UINib(nibName: nibName, bundle: bundle)
            tableView.registerNib(nib, forCellReuseIdentifier: nibName)
        }

        // UITableView
        tableView.accessibilityIdentifier  = "Notifications Table"
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

        let ratingsSize = CGFloat(15.0)
        let ratingsFont = WPFontManager.systemRegularFontOfSize(ratingsSize)

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

        let titles = [
            NSLocalizedString("All", comment: "Displays all of the Notifications, unfiltered"),
            NSLocalizedString("Unread", comment: "Filters Unread Notifications"),
            NSLocalizedString("Comments", comment: "Filters Comments Notifications"),
            NSLocalizedString("Follows", comment: "Filters Follows Notifications"),
            NSLocalizedString("Likes", comment: "Filters Likes Notifications")
        ]

        for (index, title) in titles.enumerate() {
            filtersSegmentedControl.setTitle(title, forSegmentAtIndex: index)
        }

        WPStyleGuide.configureSegmentedControl(filtersSegmentedControl)
    }

    func setupNotificationsBucketDelegate() {
        notesBucket.delegate = self
        notesBucket.notifyWhileIndexing = true
    }
}



// MARK: - Notifications
//
extension NotificationsViewController
{
    func startListeningToNotifications() {
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: #selector(applicationDidBecomeActive), name:UIApplicationDidBecomeActiveNotification, object: nil)
        nc.addObserver(self, selector: #selector(applicationWillResignActive), name:UIApplicationWillResignActiveNotification, object: nil)
    }

    func startListeningToAccountNotifications() {
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: #selector(defaultAccountDidChange), name:WPAccountDefaultWordPressComAccountChangedNotification, object: nil)
    }

    func stopListeningToNotifications() {
        let nc = NSNotificationCenter.defaultCenter()
        nc.removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
        nc.removeObserver(self, name: UIApplicationWillResignActiveNotification, object: nil)
    }

    func applicationDidBecomeActive(note: NSNotification) {
        // Let's reset the badge, whenever the app comes back to FG, and this view was upfront!
        guard isViewLoaded() == true && view.window != nil else {
            return
        }

        // Reset the badge: the notifications are visible!
        resetApplicationBadge()
        updateLastSeenTime()
        reloadResultsControllerIfNeeded()
    }

    func applicationWillResignActive(note: NSNotification) {
        stopWaitingForNotification()
    }

    func defaultAccountDidChange(note: NSNotification) {
        resetApplicationBadge()
    }
}



// MARK: - Public Methods
//
extension NotificationsViewController
{
    /// Pushes the Details for a given notificationID. If the Notification is unavailable at the point in
    /// which this call is executed, we'll hold for the time interval specified by the `Syncing.pushMaxWait`
    /// constant.
    ///
    /// - Parameter notificationID: The simperiumKey of the Notification that should be rendered onscreen.
    ///
    func showDetailsForNotificationWithID(noteID: String) {
        guard let note = notesBucket.objectForKey(noteID) as? Notification else {
            startWaitingForNotification(noteID)
            return
        }

        showDetailsForNotification(note)
    }


    /// Pushes the details for a given Notification Instance.
    ///
    /// - Parameter note: The Notification that should be rendered.
    ///
    func showDetailsForNotification(note: Notification) {
        DDLogSwift.logInfo("Pushing Notification Details for: [\(note.simperiumKey)]")

        // Track
        let properties = [Stats.noteTypeKey : note.type ?? Stats.noteTypeUnknown]
        WPAnalytics.track(.OpenedNotificationDetails, withProperties: properties)

        // Mark as Read, if needed
        if note.read.boolValue == false {
            note.read = NSNumber(bool: true)
            ContextManager.sharedInstance().saveContext(note.managedObjectContext)
        }

        // Failsafe: Don't push nested!
        if navigationController?.visibleViewController != self {
            navigationController?.popViewControllerAnimated(false)
        }

        if note.isMatcher && note.metaPostID != nil && note.metaSiteID != nil {
            performSegueWithIdentifier(ReaderDetailViewController.classNameWithoutNamespaces(), sender: note)
        } else {
            performSegueWithIdentifier(NotificationDetailsViewController.classNameWithoutNamespaces(), sender: note)
        }
    }

    /// Will display an Undelete button on top of a given notification.
    /// On timeout, the destructive action (received via parameter) will be exeuted, and the notification
    /// will (supposedly) get deleted.
    ///
    /// -   Parameters:
    ///     -   noteObjectID: The Core Data ObjectID associated to a given notification.
    ///     -   onTimeout: A "destructive" closure, to be executed after a given timeout.
    ///
    func showUndelete(noteObjectID: NSManagedObjectID, onTimeout: NotificationDeletionActionBlock) {
        // Mark this note as Pending Deletichroon and Reload
        notificationDeletionBlocks[noteObjectID] = onTimeout
        reloadRowForNotificationWithID(noteObjectID)

        // Dispatch the Action block
        performSelector(#selector(performDeletionAction), withObject:noteObjectID, afterDelay:Syncing.undoTimeout)
    }
}


///
///
extension NotificationsViewController
{
    func performDeletionAction(noteObjectID: NSManagedObjectID) {
        // Was the Deletion Cancelled?
        guard let deletionBlock = notificationDeletionBlocks[noteObjectID] else {
            return
        }

        // Hide the Notification
        notificationIdsBeingDeleted.insert(noteObjectID)
        reloadResultsController()

        // Hit the Deletion Block
        deletionBlock { success in
            // Cleanup
            self.notificationDeletionBlocks.removeValueForKey(noteObjectID)
            self.notificationIdsBeingDeleted.remove(noteObjectID)

            // Error: let's unhide the row
            if success == false {
                self.reloadResultsController()
            }
        }
    }

    func cancelDeletionAction(noteObjectID: NSManagedObjectID) {
        notificationDeletionBlocks.removeValueForKey(noteObjectID)
        reloadRowForNotificationWithID(noteObjectID)

        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(performDeletionAction), object: noteObjectID)
    }

    func isNoteMarkedForDeletion(noteObjectID: NSManagedObjectID) -> Bool {
        return notificationDeletionBlocks[noteObjectID] != nil
    }
}



// MARK: - WPTableViewHandler Helpers
//
extension NotificationsViewController
{
    func reloadResultsControllerIfNeeded() {
        // Note:
        // NSFetchedResultsController groups notifications based on a transient property ("sectionIdentifier").
        // Simply calling reloadData doesn't make the FRC recalculate the sections.
        // For that reason, let's force a reload, only when 1 day has elapsed, and sections would have changed.
        //
        let daysElapsed = NSCalendar.currentCalendar().daysElapsedSinceDate(lastReloadDate)
        guard daysElapsed != 0 else {
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
    }


    func reloadRowForNotificationWithID(noteObjectID: NSManagedObjectID?) {
        // Failsafe
        guard let noteObjectID = noteObjectID else {
            return
        }

        // Load the Notification and its indexPath
        do {
            let note = try simperium.managedObjectContext().existingObjectWithID(noteObjectID)

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
        // Yes. This is dummy. Simperium handles sync for us!
        refreshControl?.endRefreshing()
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
        let filtersMap: [Filter: String] = [
            .None       : "",
            .Unread     : " AND (read = NO)",
            .Comment    : " AND (type = '\(NoteTypeComment)')",
            .Follow     : " AND (type = '\(NoteTypeFollow)')",
            .Like       : " AND (type = '\(NoteTypeLike)' OR type = '\(NoteTypeCommentLike)')"
        ]

        let filter = Filter(rawValue: filtersSegmentedControl.selectedSegmentIndex) ?? .None
        let condition = filtersMap[filter] ?? String()
        let format = "NOT (SELF IN %@)" + condition

        return NSPredicate(format: format, Array(notificationIdsBeingDeleted))
    }

    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        // Note:
        // iOS 8 has a nice bug in which, randomly, the last cell per section was getting an extra separator.
        // For that reason, we draw our own separators.
        //
        guard let note = tableViewHandler.resultsController.objectOfType(Notification.self, atIndexPath: indexPath) else {
            return
        }

        guard let cell = cell as? NoteTableViewCell else {
            return
        }

        let isMarkedForDeletion     = isNoteMarkedForDeletion(note.objectID)
        let isLastRow               = tableViewHandler.resultsController.isLastRowInSection(indexPath)

        cell.attributedSubject      = note.subjectBlock()?.attributedSubjectText()
        cell.attributedSnippet      = note.snippetBlock()?.attributedSnippetText()
        cell.read                   = note.read.boolValue
        cell.noticon                = note.noticon
        cell.unapproved             = note.isUnapprovedComment()
        cell.markedForDeletion      = isMarkedForDeletion
        cell.showsBottomSeparator   = !isLastRow && !isMarkedForDeletion
        cell.selectionStyle         = isMarkedForDeletion ? .None : .Gray
        cell.onUndelete             = { [weak self] in
            self?.cancelDeletionAction(note.objectID)
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
        // Update Separators:
        // Due to an UIKit bug, we need to draw our own separators (Issue #2845). Let's update the separator status
        // after a DB OP. This loop has been measured in the order of milliseconds (iPad Mini)
        for indexPath in tableView.indexPathsForVisibleRows ?? [] {
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! NoteTableViewCell
            let isLastRow = tableViewHandler.resultsController.isLastRowInSection(indexPath)
            cell.showsBottomSeparator = isLastRow == false
        }

        // Update NoResults View
        showNoResultsViewIfNeeded()
    }
}



// MARK - Filter Helpers
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
        // Note:
        // Filters should only be hidden whenever there are no Notifications in the bucket (contrary to the FRC's
        // results, which are filtered by the active predicate!).
        //
        return notesBucket.numObjects() > 0
    }
}



// MARK: - NoResults Helpers
//
extension NotificationsViewController
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
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)

        return service.defaultWordPressComAccount() == nil
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



// MARK: - SPBucketDelegate Methods
//
extension NotificationsViewController: SPBucketDelegate
{
    func bucket(bucket: SPBucket!, didChangeObjectForKey key: String!, forChangeType changeType: SPBucketChangeType, memberNames: [AnyObject]!) {
        // We're only concerned with New Notification Events
        guard changeType == .Insert else {
            return
        }

        // Mark as read immediately, if needed
        if isViewOnScreen() == true && UIApplication.sharedApplication().applicationState == .Active {
            resetApplicationBadge()
            updateLastSeenTime()
        }

        // Were we waiting for this notification?
        guard pushNotificationID == key else {
            return
        }

        // Show the details only if NotificationPushMaxWait hasn't elapsed
        guard let timeElapsed = pushNotificationDate?.timeIntervalSinceNow else {
            return
        }

        if abs(timeElapsed) <= Syncing.pushMaxWait {
            showDetailsForNotificationWithID(key)
        }
    }
}



// MARK: - Sync'ing Helpers
//
extension NotificationsViewController
{
    func resetApplicationBadge() {
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
    }

    func updateLastSeenTime() {
        guard let note = tableViewHandler.resultsController.fetchedObjects?.first as? Notification else {
            return
        }

        let bucketName = Meta.classNameWithoutNamespaces()
        guard let metadata = simperium.bucketForName(bucketName).objectForKey(bucketName.lowercaseString) as? Meta else {
            return
        }

        metadata.last_seen = NSNumber(double: note.timestampAsDate.timeIntervalSince1970)
        simperium.save()
    }

    func startWaitingForNotification(notificationID: String) {
        guard simperium.requiresConnection == false else {
            return
        }

        DDLogSwift.logInfo("Waiting \(Syncing.pushMaxWait) secs for Notification with ID [\(notificationID)]")

        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(notificationWaitDidTimeout), object: nil)
        performSelector(#selector(notificationWaitDidTimeout), withObject:nil, afterDelay: Syncing.syncTimeout)

        pushNotificationID = notificationID
        pushNotificationDate = NSDate()
    }

    func stopWaitingForNotification() {
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(notificationWaitDidTimeout), object: nil)
        pushNotificationID = nil
        pushNotificationDate = nil
    }

    func notificationWaitDidTimeout() {
        DDLogSwift.logInfo("Sync Timeout: Cancelling wait for notification with ID [\(pushNotificationID)]")

        pushNotificationID = nil
        pushNotificationDate = nil

        let properties = [Stats.networkStatusKey : simperium.networkStatus]
        WPAnalytics.track(.NotificationsMissingSyncWarning, withProperties: properties)
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
    var simperium: Simperium {
        return WordPressAppDelegate.sharedInstance().simperium
    }

    var notesBucket: SPBucket {
        return simperium.bucketForName(entityName())
    }

    enum Filter: Int {
        case None                   = 0
        case Unread                 = 1
        case Comment                = 2
        case Follow                 = 3
        case Like                   = 4

        static let sortKey          = "timestamp"
    }

    enum Stats {
        static let networkStatusKey = "network_status"
        static let noteTypeKey      = "notification_type"
        static let noteTypeUnknown  = "unknown"
        static let sourceKey        = "source"
        static let sourceValue      = "notifications"
    }

    enum Syncing {
        static let pushMaxWait      = NSTimeInterval(1)
        static let syncTimeout      = NSTimeInterval(10)
        static let undoTimeout      = NSTimeInterval(4)
    }

    enum Ratings {
        static let section          = "notifications"
        static let heightFull       = CGFloat(100)
        static let heightZero       = CGFloat(0)
        static let animationDelay   = NSTimeInterval(0.5)
        static let reviewURL        = AppRatingUtility.appReviewUrl()
    }
}
