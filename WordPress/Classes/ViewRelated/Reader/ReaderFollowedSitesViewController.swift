import Foundation
import WordPressShared
import SVProgressHUD

///
///
class ReaderFollowedSitesViewController: UIViewController, UIViewControllerRestoration
{
    @IBOutlet var searchBar: UISearchBar!

    private var refreshControl: UIRefreshControl!
    private var isSyncing = false
    private var tableView: UITableView!
    private var tableViewHandler: WPTableViewHandler!
    private var tableViewController: UITableViewController!

    private let cellIdentifier = "CellIdentifier"

    lazy var noResultsView: WPNoResultsView = {
        let title = NSLocalizedString("No Sites", comment: "Title of a message explaining that the user is not currently following any blogs in their reader.")
        let message = NSLocalizedString("You are not following any sites yet. Why not follow one now?", comment: "A suggestion to the user that they try following a site in their reader.")
        return WPNoResultsView(title: title, message: message, accessoryView: nil, buttonTitle: nil)
    }()


    /// Convenience method for instantiating an instance of ReaderFollowedSitesViewController
    ///
    /// - Returns: An instance of the controller
    ///
    class func controller() -> ReaderFollowedSitesViewController {
        let storyboard = UIStoryboard(name: "Reader", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("ReaderFollowedSitesViewController") as! ReaderFollowedSitesViewController
        return controller
    }


    // MARK: - State Restoration


    static func viewControllerWithRestorationIdentifierPath(identifierComponents: [AnyObject], coder: NSCoder) -> UIViewController? {
        return controller()
    }


//    public override func encodeRestorableStateWithCoder(coder: NSCoder) {
//        if let topic = readerTopic {
//            // TODO: Mark the topic as restorable and do not purge it during the clean up at launch
//            coder.encodeObject(topic.path, forKey: self.dynamicType.restorableTopicPathKey)
//        }
//        super.encodeRestorableStateWithCoder(coder)
//    }


    // MARK: - LifeCycle Methods


    override func awakeAfterUsingCoder(aDecoder: NSCoder) -> AnyObject? {
        restorationClass = self.dynamicType

        return super.awakeAfterUsingCoder(aDecoder)
    }


    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        tableViewController = segue.destinationViewController as? UITableViewController
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("Manage Sites", comment: "Page title for the screen to manage your list of followed sites.")
        setupTableView()
        setupTableViewHandler()
        configureSearchBar()

        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }


    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        configureNoResultsView()
        syncSites()
    }


    // MARK: - Setup


    private func setupTableView() {
        assert(tableViewController != nil, "The tableViewController must be assigned before configuring the tableView")

        tableView = tableViewController.tableView
        WPStyleGuide.resetReadableMarginsForTableView(tableView)

        refreshControl = tableViewController.refreshControl!
        refreshControl.addTarget(self, action: #selector(ReaderStreamViewController.handleRefresh(_:)), forControlEvents: .ValueChanged)
    }


    private func setupTableViewHandler() {
        assert(tableView != nil, "A tableView must be assigned before configuring a handler")

        tableViewHandler = WPTableViewHandler(tableView: tableView)
        tableViewHandler.delegate = self
    }


    // MARK: - Configuration


    func configureSearchBar() {
        let placeholderText = NSLocalizedString("Enter the URL of a site to follow", comment: "Placeholder text prompting the user to type the name of the URL they would like to follow.")
        let attributes = WPStyleGuide.defaultSearchBarTextAttributes(WPStyleGuide.grey())
        let attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: attributes)
        UITextField.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self, ReaderFollowedSitesViewController.self]).attributedPlaceholder = attributedPlaceholder
        let textAttributes = WPStyleGuide.defaultSearchBarTextAttributes(WPStyleGuide.greyDarken30())
        UITextField.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self, ReaderFollowedSitesViewController.self]).defaultTextAttributes = textAttributes

        searchBar.autocapitalizationType = .None
        searchBar.translucent = false
        searchBar.tintColor = WPStyleGuide.grey()
        searchBar.barTintColor = WPStyleGuide.greyLighten30()
        searchBar.backgroundImage = UIImage()
        searchBar.returnKeyType = .Done
        searchBar.setImage(UIImage(named: "icon-clear-textfield"), forSearchBarIcon: .Clear, state: .Normal)
        searchBar.setImage(UIImage(named: "icon-reader-search-plus"), forSearchBarIcon: .Search, state: .Normal)
    }


    func configureNoResultsView() {
        if let count = tableViewHandler.resultsController.fetchedObjects?.count where count > 0 {
            noResultsView.removeFromSuperview()
        } else {
            view.addSubview(noResultsView)
            noResultsView.centerInSuperview()
        }
    }


    // MARK: - Instance Methods


    private func syncSites() {
        if isSyncing {
            return
        }
        isSyncing = true
        let service = ReaderTopicService(managedObjectContext: managedObjectContext())
        service.fetchFollowedSitesWithSuccess({[weak self] in
            self?.configureNoResultsView()
            self?.refreshControl.endRefreshing()
            self?.isSyncing = false
        }, failure: { [weak self] (error) in
            DDLogSwift.logError("Could not sync sites: \(error)")
            self?.configureNoResultsView()
            self?.refreshControl.endRefreshing()
            self?.isSyncing = false
        })
    }


    func handleRefresh(sender: AnyObject) {
        syncSites()
    }


    func refreshFollowedPosts() {
        let service = ReaderSiteService(managedObjectContext: managedObjectContext())
        service.syncPostsForFollowedSites()
    }


    func unfollowSiteAtIndexPath(indexPath: NSIndexPath) {
        guard let site = tableViewHandler.resultsController.objectAtIndexPath(indexPath) as? ReaderSiteTopic else {
            return
        }

        let service = ReaderTopicService(managedObjectContext: managedObjectContext())
        service.toggleFollowingForSite(site, success: { [weak self] in
            self?.syncSites()
            self?.refreshFollowedPosts()
        }, failure: { [weak self] (error) in
            DDLogSwift.logError("Could not unfollow site: \(error)")
            let title = NSLocalizedString("Could not Unfollow Site", comment: "Title of a prompt.")
            let description = error.localizedDescription
            self?.promptWithTitle(title, message: description)
        })
    }


    func followSite(site: String) {
        guard let url = urlFromString(site) else {
            let title = NSLocalizedString("Please enter a valid URL", comment: "Title of a prompt.")
            promptWithTitle(title, message: "")
            return
        }

        let service = ReaderSiteService(managedObjectContext: managedObjectContext())
        service.followSiteByURL(url, success: { [weak self] in
            let success = NSLocalizedString("Followed", comment: "User followed a site.")
            SVProgressHUD.showSuccessWithStatus(success)
            self?.syncSites()

        }, failure: { [weak self] (error) in
            DDLogSwift.logError("Could not follow site: \(error)")
            let title = NSLocalizedString("Could not Follow Site", comment: "Title of a prompt.")
            let description = error.localizedDescription
            self?.promptWithTitle(title, message: description)
        })
    }


    func urlFromString(str: String) -> NSURL? {
        // if the string contains space its not a URL
        if str.containsString(" ") {
            return nil
        }

        // if the string does not have either a dot or protocol its not a URL
        if !str.containsString(".") && !str.containsString("://")  {
            return nil
        }

        var urlStr = str
        if !urlStr.containsString("://") {
            urlStr = "http://\(str)"
        }

        if let url = NSURL(string: urlStr) where url.host != nil {
            return url
        }

        return nil
    }


    func showPostListForSite(site: ReaderSiteTopic) {
        let controller = ReaderStreamViewController.controllerWithTopic(site)
        navigationController?.pushViewController(controller, animated: true)
    }


    func promptWithTitle(title: String, message: String) {
        let buttonTitle = NSLocalizedString("OK", comment: "Button title. Acknowledges a prompt.")
        let alert = UIAlertController(title: title, message: description, preferredStyle: .Alert)
        alert.addCancelActionWithTitle(buttonTitle)
        alert.presentFromRootViewController()
    }
}


extension ReaderFollowedSitesViewController : WPTableViewHandlerDelegate
{

    func managedObjectContext() -> NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }


    func fetchRequest() -> NSFetchRequest {
        let fetchRequest = NSFetchRequest(entityName: "ReaderSiteTopic")
        fetchRequest.predicate = NSPredicate(format: "following = YES")

        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare))
        fetchRequest.sortDescriptors = [sortDescriptor]

        return fetchRequest
    }


    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let site = tableViewHandler.resultsController.objectAtIndexPath(indexPath) as? ReaderSiteTopic else {
            return
        }

        cell.accessoryType = .DisclosureIndicator
        cell.imageView?.backgroundColor = WPStyleGuide.greyLighten30()

        cell.textLabel?.text = site.title
        cell.detailTextLabel?.text = NSURL(string: site.siteURL)?.host
        cell.imageView?.setImageWithSiteIcon(site.siteBlavatar, placeholderImage: UIImage(named: "blavatar-default"))


        WPStyleGuide.configureTableViewSmallSubtitleCell(cell)
        cell.layoutSubviews()
    }


    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) ?? WPTableViewCell(style: .Subtitle, reuseIdentifier: cellIdentifier)

        configureCell(cell, atIndexPath: indexPath)
        return cell
    }


    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 54.0
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let count = tableViewHandler.resultsController.fetchedObjects?.count ?? 0
        if count > 0 {
            return NSLocalizedString("Sites", comment: "Section title for sites the user has followed.")
        }
        return nil
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let site = tableViewHandler.resultsController.objectAtIndexPath(indexPath) as? ReaderSiteTopic else {
            return
        }
        showPostListForSite(site)
    }


    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }


    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        unfollowSiteAtIndexPath(indexPath)
    }


    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }


    func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
        return NSLocalizedString("Unfollow", comment: "Label of the table view cell's delete button, when unfollowing a site.")
    }


    func tableViewDidChangeContent(tableView: UITableView) {
        configureNoResultsView()
    }

}


extension ReaderFollowedSitesViewController : UISearchBarDelegate
{
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if let site =  searchBar.text?.trim() where !site.isEmpty {
            followSite(site)
        }
        searchBar.text = nil
        searchBar.resignFirstResponder()
    }
}
