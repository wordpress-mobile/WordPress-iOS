import Foundation
import CocoaLumberjack
import Gridicons
import WordPressShared


/// The menu for the reader.
///
@objc class ReaderMenuViewController: UITableViewController, UIViewControllerRestoration {

    @objc static let restorationIdentifier = "ReaderMenuViewController"
    @objc static let selectedIndexPathRestorationIdentifier = "ReaderMenuSelectedIndexPathKey"
    @objc static let currentReaderStreamIdentifier = "ReaderMenuCurrentStream"

    @objc let defaultCellIdentifier = "DefaultCellIdentifier"
    @objc let actionCellIdentifier = "ActionCellIdentifier"
    @objc let manageCellIdentifier = "ManageCellIdentifier"

    @objc var isSyncing = false
    @objc var didSyncTopics = false

    @objc var currentReaderStream: ReaderStreamViewController?

    fileprivate var defaultIndexPath: IndexPath {
        return viewModel.indexPathOfDefaultMenuItemWithOrder(order: .followed)
    }

    fileprivate var restorableSelectedIndexPath: IndexPath?

    @objc lazy var viewModel: ReaderMenuViewModel = {
        let sectionCreators: [ReaderMenuItemCreator] = [
            FollowingMenuItemCreator(),
            DiscoverMenuItemCreator(),
            LikedMenuItemCreator()
        ]

        let vm = ReaderMenuViewModel(sectionCreators: sectionCreators)
        vm.delegate = self
        return vm
    }()

    /// A convenience method for instantiating the controller.
    ///
    /// - Returns: An instance of the controller.
    ///
    @objc static func controller() -> ReaderMenuViewController {
        return ReaderMenuViewController(style: .grouped)
    }

    // MARK: - Restoration Methods


    static func viewController(withRestorationIdentifierPath identifierComponents: [String],
                               coder: NSCoder) -> UIViewController? {
        return WPTabBarController.sharedInstance().readerMenuViewController
    }

    override func encodeRestorableState(with coder: NSCoder) {
        coder.encode(restorableSelectedIndexPath, forKey: type(of: self).selectedIndexPathRestorationIdentifier)
        coder.encode(currentReaderStream, forKey: type(of: self).currentReaderStreamIdentifier)

        super.encodeRestorableState(with: coder)
    }

    override func decodeRestorableState(with coder: NSCoder) {
        decodeRestorableSelectedIndexPathWithCoder(coder: coder)
        decodeRestorableCurrentStreamWithCoder(coder: coder)

        super.decodeRestorableState(with: coder)
    }

    fileprivate func decodeRestorableSelectedIndexPathWithCoder(coder: NSCoder) {
        if let indexPath = coder.decodeObject(forKey: type(of: self).selectedIndexPathRestorationIdentifier) as? IndexPath {
            restorableSelectedIndexPath = indexPath
        }
    }

    fileprivate func decodeRestorableCurrentStreamWithCoder(coder: NSCoder) {
        if let currentStream = coder.decodeObject(forKey: type(of: self).currentReaderStreamIdentifier) as? ReaderStreamViewController {
            currentReaderStream = currentStream
        }
    }

    // MARK: - Lifecycle Methods

    override init(style: UITableView.Style) {
        super.init(style: style)
        // Need to use `super` to work around a Swift compiler bug
        // https://bugs.swift.org/browse/SR-3465
        super.restorationIdentifier = ReaderMenuViewController.restorationIdentifier
        restorationClass = ReaderMenuViewController.self

        clearsSelectionOnViewWillAppear = false

        if restorableSelectedIndexPath == nil {
            restorableSelectedIndexPath = defaultIndexPath
        }

        setupRefreshControl()
        setupAccountChangeNotificationObserver()
        setupApplicationWillTerminateNotificationObserver()
    }


    required convenience init() {
        self.init(style: .grouped)
    }


    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("Reader", comment: "Noun. Title of the Reader feature in the app.")

        configureTableView()
        syncTopics()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // We shouldn't show a selection if our split view is collapsed
        if splitViewControllerIsHorizontallyCompact {
            animateDeselectionInteractively()

            restorableSelectedIndexPath = defaultIndexPath
        }

        reloadTableViewPreservingSelection()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        registerUserActivity()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        reloadTableViewPreservingSelection()
    }

    // MARK: - Configuration


    @objc func setupRefreshControl() {
        if refreshControl != nil {
            return
        }

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(type(of: self).syncTopics), for: .valueChanged)
    }


    @objc func setupApplicationWillTerminateNotificationObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleApplicationWillTerminate),
                                               name: UIApplication.willTerminateNotification,
                                               object: nil)
    }


    @objc func setupAccountChangeNotificationObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleAccountChanged),
                                               name: .WPAccountDefaultWordPressComAccountChanged,
                                               object: nil)
    }


    @objc func configureTableView() {

        tableView.register(WPTableViewCell.self, forCellReuseIdentifier: defaultCellIdentifier)
        tableView.register(WPTableViewCell.self, forCellReuseIdentifier: actionCellIdentifier)

        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
    }


    // MARK: - Cleanup Methods


    /// Clears the inUse flag from any topics or posts so marked.
    ///
    @objc func unflagInUseContent() {
        let context = ContextManager.sharedInstance().mainContext
        ReaderPostService(managedObjectContext: context).clearInUseFlags()
        ReaderTopicService(managedObjectContext: context).clearInUseFlags()
    }


    /// Clean up topics that do not belong in the menu and posts that have no topic
    /// This is merely a convenient place to perform this task.
    ///
    @objc func cleanupStaleContent(removeAllTopics removeAll: Bool) {
        let context = ContextManager.sharedInstance().mainContext
        ReaderPostService(managedObjectContext: context).deletePostsWithNoTopic()

        if removeAll {
            ReaderTopicService(managedObjectContext: context).deleteAllTopics()
        } else {
            ReaderTopicService(managedObjectContext: context).deleteNonMenuTopics()
        }
    }

    /// Clears all saved posts, so they can be deleted by cleanup methods.
    ///
    func clearSavedPosts() {
        let context = ContextManager.sharedInstance().mainContext
        ReaderPostService(managedObjectContext: context).clearSavedPostFlags()
    }

    // MARK: - Instance Methods


    /// Handle the UIApplicationWillTerminate notification.
    //
    @objc func handleApplicationWillTerminate(_ notification: Foundation.Notification) {
        // Its important to clean up stale content before unflagging, otherwise
        // content we want to preserve for state restoration might also be
        // deleted.
        cleanupStaleContent(removeAllTopics: false)
        unflagInUseContent()
    }

    /// When logged out return the nav stack to the menu
    ///
    @objc func handleAccountChanged(_ notification: Foundation.Notification) {
        // Reset the selected index path
        restorableSelectedIndexPath = defaultIndexPath

        // Clean up obsolete content.
        unflagInUseContent()
        clearSavedPosts()
        cleanupStaleContent(removeAllTopics: true)

        // Clean up stale search history
        let context = ContextManager.sharedInstance().mainContext
        ReaderSearchSuggestionService(managedObjectContext: context).deleteAllSuggestions()

        // Sync the menu fresh
        syncTopics()
    }

    /// Sync the Reader's menu and fetch followed site list
    ///
    @objc func syncTopics() {
        if isSyncing {
            return
        }

        isSyncing = true

        let dispatchGroup = DispatchGroup()
        let service = ReaderTopicService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        dispatchGroup.enter()
        service.fetchReaderMenu(success: { [weak self] in
                self?.didSyncTopics = true
                dispatchGroup.leave()
            }, failure: { (error) in
                dispatchGroup.leave()
                DDLogError("Error syncing menu: \(String(describing: error))")
        })

        dispatchGroup.enter()
        service.fetchFollowedSites(success: {
            dispatchGroup.leave()
        }, failure: { (error) in
            dispatchGroup.leave()
            DDLogError("Could not sync sites: \(String(describing: error))")
        })

        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.cleanupAfterSync()
        }
    }


    /// Reset's state after a sync.
    ///
    @objc func cleanupAfterSync() {
        refreshControl?.endRefreshing()
        isSyncing = false
    }

    /// Presents the post list for the specified topic.
    ///
    /// - Parameters:
    ///     - topic: The topic to show.
    ///
    @objc func showPostsForTopic(_ topic: ReaderAbstractTopic) {
        showDetailViewController(viewControllerForTopic(topic), sender: self)
    }

    fileprivate func viewControllerForTopic(_ topic: ReaderAbstractTopic) -> ReaderStreamViewController {
        return ReaderStreamViewController.controllerWithTopic(topic)
    }

    /// Presents the reader's search view controller.
    ///
    fileprivate func viewControllerForSearch() -> ReaderSearchViewController {
        return ReaderSearchViewController.controller()
    }

    /// Present the Discover stream as a Site stream.
    ///
    private func viewControllerForDiscover() -> ReaderStreamViewController {
        return ReaderStreamViewController.controllerWithSiteID(ReaderHelpers.discoverSiteID, isFeed: false)
    }

    /// Presents the view controller for a default menu item
    func showSectionForDefaultMenuItem(withOrder order: ReaderDefaultMenuItemOrder,
                                       animated: Bool) {
        let indexPath = viewModel.indexPathOfDefaultMenuItemWithOrder(order: order)

        showViewController(for: indexPath, animated: animated)
    }

    /// Presents the saved for later view controller
    @objc func showSavedForLater() {
        guard let indexPath = viewModel.indexPathOfSavedForLater(),
            let menuItem = viewModel.menuItemAtIndexPath(indexPath),
            let viewController = viewControllerForMenuItem(menuItem) else {
                return
        }

        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .middle)
        restorableSelectedIndexPath = indexPath

        showDetailViewController(viewController, sender: self)
    }

    fileprivate func viewControllerForSavedPosts() -> ReaderSavedPostsViewController {
        return ReaderSavedPostsViewController()
    }

    /// Presents a team view controller
    func showSectionForTeam(withSlug slug: String, animated: Bool) {
        guard let indexPath = viewModel.indexPathOfTeam(withSlug: slug) else {
            return
        }

        showViewController(for: indexPath, animated: animated)
    }

    private func showViewController(for indexPath: IndexPath,
                                    animated: Bool) {
        guard let menuItem = viewModel.menuItemAtIndexPath(indexPath),
            let viewController = viewControllerForMenuItem(menuItem) else {
                return
        }

        let actions = {
            self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .middle)
            self.restorableSelectedIndexPath = indexPath

            self.showDetailViewController(viewController, sender: self)
        }

        if animated {
            actions()
        } else {
            UIView.performWithoutAnimation(actions)
        }
    }

    /// Presents a new view controller for subscribing to a new tag.
    ///
    @objc func showAddTag() {
        let placeholder = NSLocalizedString("Add any topic", comment: "Placeholder text. A call to action for the user to type any topic to which they would like to subscribe.")
        let controller = SettingsTextViewController(text: nil, placeholder: placeholder, hint: nil)
        controller.title = NSLocalizedString("Add a Topic", comment: "Title of a feature to add a new topic to the topics subscribed by the user.")
        controller.onValueChanged = { value in
            if value.trim().count > 0 {
                self.followTagNamed(value.trim())
            }
        }
        controller.mode = .lowerCaseText
        controller.displaysActionButton = true
        controller.actionText = NSLocalizedString("Add Topic", comment: "Button Title. Tapping subscribes the user to a new topic.")
        controller.onActionPress = {
            self.dismissModal()
        }

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(ReaderMenuViewController.dismissModal))
        controller.navigationItem.leftBarButtonItem = cancelButton

        let navController = UINavigationController(rootViewController: controller)
        navController.modalPresentationStyle = .formSheet

        present(navController, animated: true)
    }


    /// Dismisses a presented view controller.
    ///
    @objc func dismissModal() {
        dismiss(animated: true)
    }

    func deselectSelectedRow(animated: Bool) {
        tableView.deselectSelectedRowWithAnimation(animated)
        restorableSelectedIndexPath = defaultIndexPath
    }

    // MARK: - Tag Wrangling


    /// Prompts the user to confirm unfolowing a tag.
    ///
    /// - Parameters:
    ///     - topic: The tag topic that is to be unfollowed.
    ///
    @objc func promptUnfollowTagTopic(_ topic: ReaderTagTopic) {
        let title = NSLocalizedString("Remove", comment: "Title of a prompt asking the user to confirm they no longer wish to subscribe to a certain tag.")
        let template = NSLocalizedString("Are you sure you wish to remove the topic '%@'?", comment: "A short message asking the user if they wish to unfollow the specified topic. The %@ is a placeholder for the name of the topic.")
        let message = String(format: template, topic.title)
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
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
    @objc func unfollowTagTopic(_ topic: ReaderTagTopic) {
        let service = ReaderTopicService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.unfollowTag(topic, withSuccess: nil) { (error) in
            DDLogError("Could not unfollow topic \(topic), \(String(describing: error))")

            let title = NSLocalizedString("Could Not Remove Topic", comment: "Title of a prompt informing the user there was a probem unsubscribing from a topic in the reader.")
            let message = error?.localizedDescription
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addCancelActionWithTitle(NSLocalizedString("OK", comment: "Button title. An acknowledgement of the message displayed in a prompt."))
            alert.presentFromRootViewController()
        }
    }


    /// Follow a new tag with the specified tag name.
    ///
    /// - Parameters:
    ///     - tagName: The name of the tag to follow.
    ///
    @objc func followTagNamed(_ tagName: String) {
        let service = ReaderTopicService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        let generator = UINotificationFeedbackGenerator()
        generator.prepare()

        service.followTagNamed(tagName, withSuccess: { [weak self] in
            generator.notificationOccurred(.success)

            // A successful follow makes the new tag the currentTopic.
            if let tag = service.currentTopic as? ReaderTagTopic {
                self?.scrollToTag(tag)
            }

            }, failure: { (error) in
                DDLogError("Could not follow tag named \(tagName) : \(String(describing: error))")

                generator.notificationOccurred(.error)

                let title = NSLocalizedString("Could Not Follow Topic", comment: "Title of a prompt informing the user there was a probem unsubscribing from a topic in the reader.")
                let message = error?.localizedDescription
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addCancelActionWithTitle(NSLocalizedString("OK", comment: "Button title. An acknowledgement of the message displayed in a prompt."))
                alert.presentFromRootViewController()
        })
    }


    /// Scrolls the tableView so the specified tag is in view.
    ///
    /// - Paramters:
    ///     - tag: The tag to scroll into view.
    ///
    @objc func scrollToTag(_ tag: ReaderTagTopic) {
        guard let indexPath = viewModel.indexPathOfTag(tag) else {
            return
        }

        tableView.flashRowAtIndexPath(indexPath, scrollPosition: .middle, completion: {
            if !self.splitViewControllerIsHorizontallyCompact {
                self.tableView(self.tableView, didSelectRowAt: indexPath)
            }
        })
    }


    // MARK: - TableView Delegate Methods


    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSectionsInMenu()
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItemsInSection(section)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.titleForSection(section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let menuItem = viewModel.menuItemAtIndexPath(indexPath)
        if menuItem?.type == .addItem {
            let cell = tableView.dequeueReusableCell(withIdentifier: actionCellIdentifier)!
            configureActionCell(cell, atIndexPath: indexPath)
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: defaultCellIdentifier)!
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let menuItem = viewModel.menuItemAtIndexPath(indexPath) else {
            return
        }

        if menuItem.type == .search {
            QuickStartTourGuide.shared.visited(.readerSearch)
        }

        if menuItem.type == .addItem {
            tableView.deselectSelectedRowWithAnimation(true)
            showAddTag()
            return
        }

        if menuItem.type == .savedPosts {
            trackSavedPostsNavigation()
        }

        restorableSelectedIndexPath = indexPath

        if let viewController = viewControllerForMenuItem(menuItem) {
            showDetailViewController(viewController, sender: self)
        }
    }

    fileprivate func viewControllerForMenuItem(_ menuItem: ReaderMenuItem) -> UIViewController? {

        if let topic = menuItem.topic, ReaderHelpers.topicIsDiscover(topic) {
            return viewControllerForDiscover()
        }

        if let topic = menuItem.topic {
            currentReaderStream = viewControllerForTopic(topic)
            return currentReaderStream
        }

        if menuItem.type == .search {
            currentReaderStream = nil
            return viewControllerForSearch()
        }

        if menuItem.type == .savedPosts {
            currentReaderStream = nil
            return viewControllerForSavedPosts()
        }

        return nil
    }


    @objc func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        guard let menuItem = viewModel.menuItemAtIndexPath(indexPath) else {
            return
        }

        WPStyleGuide.configureTableViewCell(cell)
        cell.accessoryView = nil
        cell.accessoryType = (splitViewControllerIsHorizontallyCompact) ? .disclosureIndicator : .none
        if menuItem.type == .search && QuickStartTourGuide.shared.isCurrentElement(.readerSearch) {
            cell.accessoryView = QuickStartSpotlightView()
        }

        cell.selectionStyle = .default
        cell.textLabel?.text = menuItem.title
        cell.imageView?.tintColor = .listIcon
        cell.imageView?.image = menuItem.icon?.withRenderingMode(.alwaysTemplate)
    }


    @objc func configureActionCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        guard let menuItem = viewModel.menuItemAtIndexPath(indexPath) else {
            return
        }

        WPStyleGuide.configureTableViewActionCell(cell)

        if cell.accessoryView == nil {
            let imageView = UIImageView(image: .gridicon(.plus))
            imageView.tintColor = .primary
            cell.accessoryView = imageView
        }

        cell.selectionStyle = .default
        cell.imageView?.image = menuItem.icon
        cell.imageView?.tintColor = .primary
        cell.textLabel?.text = menuItem.title
    }


    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
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


    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        guard let menuItem = viewModel.menuItemAtIndexPath(indexPath) else {
            return
        }

        guard let topic = menuItem.topic as? ReaderTagTopic else {
            return
        }

        promptUnfollowTagTopic(topic)
    }


    override func tableView(_ tableView: UITableView,
                            editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }


    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return NSLocalizedString("Remove", comment: "Label of the table view cell's delete button, when unfollowing tags.")
    }
}


extension ReaderMenuViewController: ReaderMenuViewModelDelegate {

    @objc func menuDidReloadContent() {
        reloadTableViewPreservingSelection()
    }

    @objc func menuSectionDidChangeContent(_ index: Int) {
        reloadTableViewPreservingSelection()
    }

    @objc func reloadTableViewPreservingSelection() {
        let selectedIndexPath = restorableSelectedIndexPath

        tableView.reloadData()

        // Show the current selection if our split view isn't collapsed
        if !splitViewControllerIsHorizontallyCompact {
            tableView.selectRow(at: selectedIndexPath,
                                           animated: false, scrollPosition: .none)
        }
    }

}

extension ReaderMenuViewController: WPSplitViewControllerDetailProvider {
    func initialDetailViewControllerForSplitView(_ splitView: WPSplitViewController) -> UIViewController? {
        if restorableSelectedIndexPath == defaultIndexPath {
            let service = ReaderTopicService(managedObjectContext: ContextManager.sharedInstance().mainContext)
            if let topic = service.topicForFollowedSites() {
                return viewControllerForTopic(topic)
            } else {
                restorableSelectedIndexPath = IndexPath(row: 0, section: 0)
                if let item = viewModel.menuItemAtIndexPath(restorableSelectedIndexPath!) {
                    return viewControllerForMenuItem(item)
                }
            }
        }

        return nil
    }
}

// MARK: - SearchableActivity Conformance

extension ReaderMenuViewController: SearchableActivityConvertable {
    var activityType: String {
        return WPActivityType.reader.rawValue
    }

    var activityTitle: String {
        return NSLocalizedString("Reader", comment: "Title of the 'Reader' tab - used for spotlight indexing on iOS.")
    }

    var activityKeywords: Set<String>? {
        let keyWordString = NSLocalizedString("wordpress, reader, articles, posts, blog post, followed, discover, likes, my likes, tags, topics",
                                              comment: "This is a comma separated list of keywords used for spotlight indexing of the 'Reader' tab.")
        let keywordArray = keyWordString.arrayOfTags()

        guard !keywordArray.isEmpty else {
            return nil
        }

        return Set(keywordArray)
    }
}
