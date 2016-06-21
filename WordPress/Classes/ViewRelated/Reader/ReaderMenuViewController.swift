import Foundation
import WordPressShared


/// The menu for the reader.
///
@objc class ReaderMenuViewController : UITableViewController
{
    let cellIdentifier = "MenuCellIdentifier"

    lazy var viewModel: ReaderMenuViewModel = {
        let vm = ReaderMenuViewModel()
        vm.delegate = self
        return vm
    }()


    /// A convenience method for instantiating the controller.
    ///
    /// - Returns: An instance of the controller.
    ///
    class func controller() -> ReaderMenuViewController {
        return ReaderMenuViewController(style: .Grouped)
    }


    // MARK: - Lifecycle Methods


    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("Reader", comment: "")

        configureTableView()
    }


    // MARK: - Configuration


    func configureTableView() {
        tableView.registerClass(WPTableViewCell.self, forCellReuseIdentifier: cellIdentifier)

        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }


    // MARK: - Instance Methods


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


    // MARK: - Tag Wrangling


    /// Prompts the user to confirm unfolowing a tag.
    ///
    /// - Parameters:
    ///     - topic: The tag topic that is to be unfollowed.
    ///
    func promptUnfollowTagTopic(topic: ReaderTagTopic) {
        let title = NSLocalizedString("Unfollow", comment: "Title of a prompt asking the user to confirm they no longer wish to subscribe to a certain tag.")
        let template = NSLocalizedString("Are you sure you wish to unfollow the tag: %@", comment: "A short message asking the user if they wish to unfollow the specified tag. The %@ is a placeholder for the name of the tag.")
        let message = String(format: template, topic.title)
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addCancelActionWithTitle(NSLocalizedString("Cancel", comment: "Title of a cancel button.")) { (action) in
            self.tableView.setEditing(false, animated: true)
        }
        alert.addDestructiveActionWithTitle(NSLocalizedString("Unfollow", comment: "Verb. Button title. Unfollows / unsubscribes the user from a topic in the reader.")) { (action) in
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

            let title = NSLocalizedString("Could not Unfollow Tag", comment: "Title of a prompt informing the user there was a probem unsubscribing from a tag in the reader.")
            let message = error.localizedDescription
            let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            alert.addCancelActionWithTitle(NSLocalizedString("OK", comment: "Button title. An acknowledge ment of the message displayed in a prompt."))
            alert.presentFromRootViewController()
        }
    }


    // MARK: - TableView Delegate Methods


    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return viewModel.numberOfSectionsInMenu()
    }


    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItemsInSection(section)
    }


    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let title = viewModel.titleForSection(section)
        let header = WPTableViewSectionHeaderFooterView(reuseIdentifier: nil, style: .Header)
        header.title = title
        return header
    }


    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let title = viewModel.titleForSection(section)
        return WPTableViewSectionHeaderFooterView.heightForHeader(title, width: view.frame.width)
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)!
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }


    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let menuItem = viewModel.menuItemAtIndexPath(indexPath) else {
            return
        }

        // TODO: Remember selection

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
        cell.accessoryType = .DisclosureIndicator
        cell.selectionStyle = .Default
        cell.textLabel?.text = menuItem.title
        cell.imageView?.image = menuItem.icon
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
        return NSLocalizedString("Unfollow", comment: "Label of the table view cell's delete button, when unfollowing tags.")
    }
}


extension ReaderMenuViewController : ReaderMenuViewModelDelegate
{

    func menuWillReloadContent() {

    }


    func menuDidReloadContent() {
        tableView.reloadData()
    }


    func menuSectionWillChangeContent(index: Int) {

    }


    func menuSectionDidChangeContent(index: Int) {
        tableView.reloadData()
    }

}
