import Foundation
import Gridicons
import WordPressShared


/// The menu for the reader.
///
@objc class ReaderMenuViewController : UITableViewController, UIViewControllerRestoration
{

    static let restorationIdentifier = "ReaderMenuViewController"
    let defaultCellIdentifier = "DefaultCellIdentifier"
    let actionCellIdentifier = "ActionCellIdentifier"
    let manageCellIdentifier = "ManageCellIdentifier"
    let readerHasBeenPreviouslyViewedKey = "ReaderHasBeenPreviouslyViewedKey"
    var isSyncing = false
    var didSyncTopics = false

    lazy var viewModel: ReaderMenuViewModel = {
        let vm = ReaderMenuViewModel()
        vm.delegate = self
        return vm
    }()

    var readerHasBeenPreviouslyViewed: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey(readerHasBeenPreviouslyViewedKey)
        }

        set {
            let defaults = NSUserDefaults.standardUserDefaults()
            if newValue {
                defaults.setBool(true, forKey: readerHasBeenPreviouslyViewedKey)
            } else {
                defaults.removeObjectForKey(readerHasBeenPreviouslyViewedKey)
            }
            defaults.synchronize()
        }
    }


    /// A convenience method for instantiating the controller.
    ///
    /// - Returns: An instance of the controller.
    ///
    static let sharedInstance: ReaderMenuViewController = {
        return ReaderMenuViewController(style: .Grouped)
    }()


    // MARK: - Restoration Methods


    static func viewControllerWithRestorationIdentifierPath(identifierComponents: [AnyObject], coder: NSCoder) -> UIViewController? {
        return sharedInstance
    }


    // MARK: - Lifecycle Methods


    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }


    override init(style: UITableViewStyle) {
        super.init(style: style)
        restorationIdentifier = self.dynamicType.restorationIdentifier
        restorationClass = self.dynamicType

        cleanupStaleContent(removeAllTopics: false)
        setupRefreshControl()
        setupAccountChangeNotificationObserver()
    }


    required convenience init() {
        self.init(style: .Grouped)
    }


    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("Reader", comment: "")

        configureTableView()
        syncTopics()
    }


    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        handleFirstLaunchIfNeeded()
    }


    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animateAlongsideTransition(nil) { (_) in
            self.tableView.reloadData()
        }
    }


    // MARK: - Configuration


    func setupRefreshControl() {
        if refreshControl != nil {
            return
        }

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(self.dynamicType.syncTopics), forControlEvents: .ValueChanged)
    }


    func setupAccountChangeNotificationObserver() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.dynamicType.handleAccountChanged), name: WPAccountDefaultWordPressComAccountChangedNotification, object: nil)
    }


    func configureTableView() {

        tableView.registerClass(WPTableViewCell.self, forCellReuseIdentifier: defaultCellIdentifier)
        tableView.registerClass(WPTableViewCell.self, forCellReuseIdentifier: actionCellIdentifier)

        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }


    // MARK: - Instance Methods

    /// Clean up topics that do not belong in the menu and posts that have no topic
    /// This is merely a convenient place to perform this task.
    ///
    func cleanupStaleContent(removeAllTopics removeAll: Bool) {
        let context = ContextManager.sharedInstance().mainContext
        ReaderPostService(managedObjectContext: context).deletePostsWithNoTopic()

        if removeAll {
            ReaderTopicService(managedObjectContext: context).deleteAllTopics()
        } else {
            ReaderTopicService(managedObjectContext: context).deleteNonMenuTopics()
        }
    }


    /// When logged out return the nav stack to the menu
    ///
    func handleAccountChanged(notification: NSNotification) {
        // Return to the root vc.
        navigationController?.popToRootViewControllerAnimated(false)

        // Clear the flag so Discover will be present and ready to view.
        readerHasBeenPreviouslyViewed = false

        // Clean up obsolete content.
        cleanupStaleContent(removeAllTopics: true)

        // Clean up stale search history
        let context = ContextManager.sharedInstance().mainContext
        ReaderSearchSuggestionService(managedObjectContext: context).deleteAllSuggestions()

        // Sync the menu fresh
        syncTopics()
    }


    /// The first time the Reader is launched, we want to show the Discover topic,
    /// not the menu.
    ///
    func handleFirstLaunchIfNeeded() {
        if readerHasBeenPreviouslyViewed {
            return
        }

        // Wait til the view is loaded, and only proceed if there are topics synced.
        if !isViewLoaded() || !didSyncTopics {
            return
        }

        // Show the Discover topic if it exists.
        let service = ReaderTopicService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        if let topic = service.topicForDiscover() {
            showPostsForTopic(topic)
            readerHasBeenPreviouslyViewed = true
        }
    }


    /// Sync the Reader's menu
    ///
    func syncTopics() {
        if isSyncing {
            return
        }

        isSyncing = true
        let service = ReaderTopicService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.fetchReaderMenuWithSuccess({ [weak self] in
                self?.didSyncTopics = true
                self?.cleanupAfterSync()
                self?.handleFirstLaunchIfNeeded()
            }, failure: { [weak self] (error) in
                self?.cleanupAfterSync()
                DDLogSwift.logError("Error syncing menu: \(error)")
        })
    }


    /// Reset's state after a sync.
    ///
    func cleanupAfterSync() {
        refreshControl?.endRefreshing()
        isSyncing = false
    }


    /// Presents the detail view controller for the specified post on the specified
    /// blog. This is a convenience method for use with Notifications (for example).
    ///
    /// - Parameters:
    ///     - postID: The ID of the post on the specified blog.
    ///     - blogID: The ID of the blog.
    ///
    func openPost(postID: NSNumber, onBlog blogID: NSNumber) {
        let controller = ReaderDetailViewController.controllerWithPostID(postID, siteID: blogID)
        navigationController?.pushViewController(controller, animated: true)
    }


    /// Presents the post list for the specified topic.
    ///
    /// - Parameters:
    ///     - topic: The topic to show.
    ///
    func showPostsForTopic(topic: ReaderAbstractTopic) {
        let controller = ReaderStreamViewController.controllerWithTopic(topic)
        navigationController?.pushViewController(controller, animated: true)
    }


    /// Presents the reader's search view controller.
    ///
    func showReaderSearch() {
        let controller = ReaderSearchViewController.controller()
        navigationController?.pushViewController(controller, animated: true)
    }


    /// Presents a new view controller for subscribing to a new tag.
    ///
    func showAddTag() {
        let placeholder = NSLocalizedString("Add any tag", comment: "Placeholder text. A call to action for the user to type any tag to which they would like to subscribe.")
        let controller = SettingsTextViewController(text: nil, placeholder: placeholder, hint: nil)
        controller.title = NSLocalizedString("Add a Tag", comment: "Title of a feature to add a new tag to the tags subscribed by the user.")
        controller.onValueChanged = { value in
            if value.trim().characters.count > 0 {
                self.followTagNamed(value.trim())
            }
        }
        controller.mode = .LowerCaseText
        controller.displaysActionButton = true
        controller.actionText = NSLocalizedString("Add Tag", comment: "Button Title. Tapping subscribes the user to a new tag.")
        controller.onActionPress = {
            self.dismissModal()
        }

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(ReaderMenuViewController.dismissModal))
        controller.navigationItem.leftBarButtonItem = cancelButton

        let navController = UINavigationController(rootViewController: controller)
        navController.modalPresentationStyle = .FormSheet

        presentViewController(navController, animated: true, completion: nil)
    }


    /// Dismisses a presented view controller.
    ///
    func dismissModal() {
        dismissViewControllerAnimated(true, completion: nil)
    }


    // MARK: - Tag Wrangling


    /// Prompts the user to confirm unfolowing a tag.
    ///
    /// - Parameters:
    ///     - topic: The tag topic that is to be unfollowed.
    ///
    func promptUnfollowTagTopic(topic: ReaderTagTopic) {
        let title = NSLocalizedString("Remove", comment: "Title of a prompt asking the user to confirm they no longer wish to subscribe to a certain tag.")
        let template = NSLocalizedString("Are you sure you wish to remove the tag '%@'", comment: "A short message asking the user if they wish to unfollow the specified tag. The %@ is a placeholder for the name of the tag.")
        let message = String(format: template, topic.title)
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addCancelActionWithTitle(NSLocalizedString("Cancel", comment: "Title of a cancel button.")) { (action) in
            self.tableView.setEditing(false, animated: true)
        }
        alert.addDestructiveActionWithTitle(NSLocalizedString("Remove", comment: "Verb. Button title. Unfollows / unsubscribes the user from a topic in the reader.")) { (action) in
            self.unfollowTagTopic(topic)
        }
        alert.presentFromRootViewController()
    }


    /// Tells the ReaderTopicService to unfollow the specified topic.
    ///
    /// - Parameters:
    ///     - topic: The tag topic that is to be unfollowed.
    ///
    func unfollowTagTopic(topic: ReaderTagTopic) {
        let service = ReaderTopicService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.unfollowTag(topic, withSuccess: nil) { (error) in
            DDLogSwift.logError("Could not unfollow topic \(topic), \(error)")

            let title = NSLocalizedString("Could Not Remove Tag", comment: "Title of a prompt informing the user there was a probem unsubscribing from a tag in the reader.")
            let message = error.localizedDescription
            let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            alert.addCancelActionWithTitle(NSLocalizedString("OK", comment: "Button title. An acknowledgement of the message displayed in a prompt."))
            alert.presentFromRootViewController()
        }
    }


    /// Follow a new tag with the specified tag name.
    ///
    /// - Parameters:
    ///     - tagName: The name of the tag to follow.
    ///
    func followTagNamed(tagName: String) {
        let service = ReaderTopicService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        service.followTagNamed(tagName, withSuccess: { [weak self] in
            // A successful follow makes the new tag the currentTopic.
            if let tag = service.currentTopic as? ReaderTagTopic {
                self?.scrollToTag(tag)
            }

            }, failure: { (error) in
                DDLogSwift.logError("Could not follow tag named \(tagName) : \(error)")

                let title = NSLocalizedString("Could Not Follow Tag", comment: "Title of a prompt informing the user there was a probem unsubscribing from a tag in the reader.")
                let message = error.localizedDescription
                let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
                alert.addCancelActionWithTitle(NSLocalizedString("OK", comment: "Button title. An acknowledgement of the message displayed in a prompt."))
                alert.presentFromRootViewController()
        })
    }


    /// Scrolls the tableView so the specified tag is in view.
    ///
    /// - Paramters:
    ///     - tag: The tag to scroll into view.
    ///
    func scrollToTag(tag: ReaderTagTopic) {
        guard let indexPath = viewModel.indexPathOfTag(tag) else {
            return
        }
        tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .Middle)

        let time = dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(0.7 * Double(NSEC_PER_SEC))
        )
        dispatch_after(time, dispatch_get_main_queue()) { [weak self] in
            self?.tableView.deselectSelectedRowWithAnimation(true)
        }
    }


    // MARK: - TableView Delegate Methods


    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return viewModel.numberOfSectionsInMenu()
    }


    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItemsInSection(section)
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.titleForSection(section)
    }

    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionHeader(view)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let menuItem = viewModel.menuItemAtIndexPath(indexPath)
        if menuItem?.type == .AddItem {
            let cell = tableView.dequeueReusableCellWithIdentifier(actionCellIdentifier)!
            configureActionCell(cell, atIndexPath: indexPath)
            return cell
        }

        let cell = tableView.dequeueReusableCellWithIdentifier(defaultCellIdentifier)!
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }


    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let menuItem = viewModel.menuItemAtIndexPath(indexPath) else {
            return
        }

        if menuItem.type == .AddItem {
            tableView.deselectSelectedRowWithAnimation(true)
            showAddTag()
            return
        }

        if let topic = menuItem.topic {
            showPostsForTopic(topic)
            return
        }

        if menuItem.type == .Search {
            showReaderSearch()
            return
        }
    }


    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let menuItem = viewModel.menuItemAtIndexPath(indexPath) else {
            return
        }

        WPStyleGuide.configureTableViewCell(cell)
        cell.accessoryView = nil
        cell.accessoryType = .DisclosureIndicator
        cell.selectionStyle = .Default
        cell.textLabel?.text = menuItem.title
        cell.imageView?.image = menuItem.icon
    }


    func configureActionCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let menuItem = viewModel.menuItemAtIndexPath(indexPath) else {
            return
        }

        WPStyleGuide.configureTableViewActionCell(cell)

        if cell.accessoryView == nil {
            let image = Gridicon.iconOfType(.Plus)
            let imageView = UIImageView(image: image)
            imageView.tintColor = WPStyleGuide.wordPressBlue()
            cell.accessoryView = imageView
        }

        cell.selectionStyle = .Default
        cell.imageView?.image = menuItem.icon
        cell.imageView?.tintColor = WPStyleGuide.wordPressBlue()
        cell.textLabel?.text = menuItem.title
    }


    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if !ReaderHelpers.isLoggedIn() {
            return false
        }

        guard let menuItem = viewModel.menuItemAtIndexPath(indexPath) else {
            return false
        }

        guard let topic = menuItem.topic else {
            return false
        }

        return ReaderHelpers.isTopicTag(topic)
    }


    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        guard let menuItem = viewModel.menuItemAtIndexPath(indexPath) else {
            return
        }

        guard let topic = menuItem.topic as? ReaderTagTopic else {
            return
        }

        promptUnfollowTagTopic(topic)
    }


    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }


    override func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
        return NSLocalizedString("Remove", comment: "Label of the table view cell's delete button, when unfollowing tags.")
    }
}


extension ReaderMenuViewController : ReaderMenuViewModelDelegate
{

    func menuDidReloadContent() {
        tableView.reloadData()
    }

    func menuSectionDidChangeContent(index: Int) {
        tableView.reloadData()
    }

}
