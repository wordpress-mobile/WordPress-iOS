import Foundation
import WordPressShared
import CocoaLumberjack
import WordPressFlux
import Gridicons

/// Displays the list of sites a user follows in the Reader.  Provides functionality
/// for following new sites by URL, and unfollowing existing sites via a swipe
/// gesture.  Followed sites can be tapped to browse their posts.
///
class ReaderFollowedSitesViewController: UIViewController, UIViewControllerRestoration {
    @IBOutlet var searchBar: UISearchBar!

    fileprivate var refreshControl: UIRefreshControl!
    fileprivate var isSyncing = false
    fileprivate var tableView: UITableView!
    fileprivate var tableViewHandler: WPTableViewHandler!
    fileprivate var tableViewController: UITableViewController!
    fileprivate let cellIdentifier = "CellIdentifier"

    private var currentKeyboardHeight: CGFloat = 0
    private var deviceIsRotating = false
    private lazy var noResultsViewController: NoResultsViewController = {
        return NoResultsViewController.controller()
    }()

    private var showsAccessoryFollowButtons: Bool = false
    private var showsSectionTitle: Bool = true

    /// Convenience method for instantiating an instance of ReaderFollowedSitesViewController
    ///
    /// - Returns: An instance of the controller
    ///
    @objc class func controller(showsAccessoryFollowButtons: Bool = false, showsSectionTitle: Bool = true) -> ReaderFollowedSitesViewController {
        let storyboard = UIStoryboard(name: "Reader", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "ReaderFollowedSitesViewController") as! ReaderFollowedSitesViewController
        controller.showsAccessoryFollowButtons = showsAccessoryFollowButtons
        controller.showsSectionTitle = showsSectionTitle
        return controller
    }


    // MARK: - State Restoration


    static func viewController(withRestorationIdentifierPath identifierComponents: [String],
                               coder: NSCoder) -> UIViewController? {
        return controller()
    }


    // MARK: - LifeCycle Methods


    override func awakeAfter(using aDecoder: NSCoder) -> Any? {
        restorationClass = type(of: self)

        return super.awakeAfter(using: aDecoder)
    }


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        tableViewController = segue.destination as? UITableViewController
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = NSLocalizedString("Manage", comment: "Page title for the screen to manage your list of followed sites.")
        setupTableView()
        setupTableViewHandler()
        configureSearchBar()
        setupBackgroundTapGestureRecognizer()

        WPStyleGuide.configureColors(view: view, tableView: tableView)
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        syncSites()
        configureNoResultsView()
        startListeningToNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopListeningToNotifications()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        deviceIsRotating = true
        coordinator.animate(alongsideTransition: nil, completion: { _ in
            self.deviceIsRotating = false
        })
    }


    // MARK: - Setup


    fileprivate func setupTableView() {
        assert(tableViewController != nil, "The tableViewController must be assigned before configuring the tableView")

        tableView = tableViewController.tableView

        refreshControl = tableViewController.refreshControl!
        refreshControl.addTarget(self, action: #selector(ReaderStreamViewController.handleRefresh(_:)), for: .valueChanged)
    }


    fileprivate func setupTableViewHandler() {
        assert(tableView != nil, "A tableView must be assigned before configuring a handler")

        tableViewHandler = WPTableViewHandler(tableView: tableView)
        tableViewHandler.delegate = self
    }


    // MARK: - Configuration


    @objc func configureSearchBar() {
        let placeholderText = NSLocalizedString("Enter the URL of a site to follow", comment: "Placeholder text prompting the user to type the name of the URL they would like to follow.")
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self, ReaderFollowedSitesViewController.self]).placeholder = placeholderText
        WPStyleGuide.configureSearchBar(searchBar)

        let iconSizes = CGSize(width: 20, height: 20)
        let clearImage = UIImage.gridicon(.crossCircle, size: iconSizes).withTintColor(.searchFieldIcons).withRenderingMode(.alwaysOriginal)
        let addOutline = UIImage.gridicon(.addOutline, size: iconSizes).withTintColor(.searchFieldIcons).withRenderingMode(.alwaysOriginal)

        searchBar.autocapitalizationType = .none
        searchBar.keyboardType = .URL
        searchBar.setImage(clearImage, for: .clear, state: UIControl.State())
        searchBar.setImage(addOutline, for: .search, state: UIControl.State())
        searchBar.searchTextField.accessibilityLabel = NSLocalizedString("Site URL", comment: "The accessibility label for the followed sites search field")
        searchBar.searchTextField.accessibilityValue = nil
        searchBar.searchTextField.accessibilityHint = placeholderText
    }

    func setupBackgroundTapGestureRecognizer() {
        let gestureRecognizer = UITapGestureRecognizer()
        gestureRecognizer.on(call: { [weak self] (gesture) in
            self?.view.endEditing(true)
        })
        gestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(gestureRecognizer)
    }


    // MARK: - Keyboard Handling


    @objc func keyboardWillShow(_ notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject],
            let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            else {
                return
        }

        currentKeyboardHeight = keyboardFrame.height
    }

    @objc func keyboardWillHide(_ notification: Foundation.Notification) {
        currentKeyboardHeight = 0
    }


    // MARK: - Instance Methods


    fileprivate func syncSites() {
        if isSyncing {
            return
        }
        isSyncing = true
        let service = ReaderTopicService(managedObjectContext: managedObjectContext())
        service.fetchFollowedSites(success: {[weak self] in
            self?.isSyncing = false
            self?.configureNoResultsView()
            self?.refreshControl.endRefreshing()
        }, failure: { [weak self] (error) in
            DDLogError("Could not sync sites: \(String(describing: error))")
            self?.isSyncing = false
            self?.configureNoResultsView()
            self?.refreshControl.endRefreshing()

        })
    }


    @objc func handleRefresh(_ sender: AnyObject) {
        syncSites()
    }


    @objc func refreshFollowedPosts() {
        let service = ReaderSiteService(managedObjectContext: managedObjectContext())
        service.syncPostsForFollowedSites()
    }


    @objc func unfollowSiteAtIndexPath(_ indexPath: IndexPath) {
        guard let site = tableViewHandler.resultsController.object(at: indexPath) as? ReaderSiteTopic else {
            return
        }

        NotificationCenter.default.post(name: .ReaderTopicUnfollowed,
                                        object: nil,
                                        userInfo: [ReaderNotificationKeys.topic: site])

        let service = ReaderTopicService(managedObjectContext: managedObjectContext())
        service.toggleFollowing(forSite: site, success: { [weak self] follow in
            let siteURL = URL(string: site.siteURL)
            let notice = Notice(title: NSLocalizedString("Unfollowed site", comment: "User unfollowed a site."),
                                message: siteURL?.host,
                                feedbackType: .success)
            self?.post(notice)

            self?.syncSites()
            self?.refreshFollowedPosts()
        }, failure: { [weak self] (follow, error) in
            DDLogError("Could not unfollow site: \(String(describing: error))")

            let notice = Notice(title: NSLocalizedString("Could not unfollow site", comment: "Title of a prompt."),
                                message: error?.localizedDescription,
                                feedbackType: .error)
            self?.post(notice)
        })
    }


    @objc func followSite(_ site: String) {
        guard let url = urlFromString(site) else {
            let title = NSLocalizedString("Please enter a valid URL", comment: "Title of a prompt.")
            promptWithTitle(title, message: "")
            return
        }

        let service = ReaderSiteService(managedObjectContext: managedObjectContext())
        service.followSite(by: url, success: { [weak self] in
            let notice = Notice(title: NSLocalizedString("Followed site", comment: "User followed a site."),
                                message: url.host,
                                feedbackType: .success)
            self?.post(notice)
            self?.syncSites()
            self?.refreshPostsForFollowedTopic()
            self?.postFollowedNotification(siteUrl: url)

        }, failure: { [weak self] error in
            DDLogError("Could not follow site: \(String(describing: error))")

            let title = error?.localizedDescription ?? NSLocalizedString("Could not follow site", comment: "Title of a prompt.")
            let notice = Notice(title: title,
                                message: url.host,
                                feedbackType: .error)

            // The underlying services for `followSite` don't consistently run the callback
            // on the main thread, so we'll ensure that we post the notice on the main
            // thread to prevent crashes.
            DispatchQueue.main.async {
                self?.post(notice)
            }
        })
    }

    private func postFollowedNotification(siteUrl: URL) {
        let service = ReaderSiteService(managedObjectContext: managedObjectContext())
        service.topic(withSiteURL: siteUrl, success: { topic in
            if let topic = topic {
                NotificationCenter.default.post(name: .ReaderSiteFollowed,
                                                object: nil,
                                                userInfo: [ReaderNotificationKeys.topic: topic])
            }
        }, failure: { error in
            DDLogError("Unable to find topic by siteURL: \(String(describing: error?.localizedDescription))")
        })

    }

    @objc func refreshPostsForFollowedTopic() {
        let service = ReaderPostService(managedObjectContext: managedObjectContext())
        service.refreshPostsForFollowedTopic()
    }


    @objc func urlFromString(_ str: String) -> URL? {
        // if the string contains space its not a URL
        if str.contains(" ") {
            return nil
        }

        // if the string does not have either a dot or protocol its not a URL
        if !str.contains(".") && !str.contains("://") {
            return nil
        }

        var urlStr = str
        if !urlStr.contains("://") {
            urlStr = "http://\(str)"
        }

        if let url = URL(string: urlStr), url.host != nil {
            return url
        }

        return nil
    }


    @objc func showPostListForSite(_ site: ReaderSiteTopic) {
        let controller = ReaderStreamViewController.controllerWithTopic(site)
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc func promptWithTitle(_ title: String, message: String) {
        let buttonTitle = NSLocalizedString("OK", comment: "Button title. Acknowledges a prompt.")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addCancelActionWithTitle(buttonTitle)
        alert.presentFromRootViewController()
    }

    private func post(_ notice: Notice) {
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }
}

// MARK: - No Results Handling

private extension ReaderFollowedSitesViewController {

    func configureNoResultsView() {
        // During rotation, the keyboard hides and shows.
        // To prevent view flashing, do nothing until rotation is finished.
        if deviceIsRotating == true {
            return
        }

        noResultsViewController.removeFromView()

        if let count = tableViewHandler.resultsController.fetchedObjects?.count, count > 0 {
            return
        }

        noResultsViewController = NoResultsViewController.controller()

        if isSyncing {
            noResultsViewController.configure(title: NoResultsText.loadingTitle, accessoryView: NoResultsViewController.loadingAccessoryView())
        } else {
            noResultsViewController = NoResultsViewController.noFollowedSitesController(showActionButton: false)
        }

        showNoResultView()
    }

    func showNoResultView() {
        tableViewController.addChild(noResultsViewController)
        tableView.addSubview(withFadeAnimation: noResultsViewController.view)
        noResultsViewController.view.frame = tableView.frame

        if currentKeyboardHeight > 0 {
            noResultsViewController.view.frame.size.height -= (currentKeyboardHeight - searchBar.frame.height)
        }

        noResultsViewController.didMove(toParent: tableViewController)
    }

    struct NoResultsText {
        static let loadingTitle = NSLocalizedString("Fetching sites...", comment: "A short message to inform the user data for their followed sites is being fetched..")
    }

    func startListeningToNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        nc.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func stopListeningToNotifications() {
        let nc = NotificationCenter.default
        nc.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        nc.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

}

extension ReaderFollowedSitesViewController: WPTableViewHandlerDelegate {

    func managedObjectContext() -> NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }


    func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ReaderSiteTopic")
        fetchRequest.predicate = NSPredicate(format: "following = YES")

        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare))
        fetchRequest.sortDescriptors = [sortDescriptor]

        return fetchRequest
    }


    func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        guard let site = tableViewHandler.resultsController.object(at: indexPath) as? ReaderSiteTopic else {
            return
        }

        var placeholderImage: UIImage = .siteIconPlaceholder
        if site.isP2Type {
            placeholderImage = UIImage.gridicon(.p2, size: CGSize(width: 40, height: 40))
        }

        // Reset the site icon first to address: https://github.com/wordpress-mobile/WordPress-iOS/issues/8513
        cell.imageView?.image = placeholderImage
        cell.imageView?.tintColor = .listIcon
        cell.imageView?.backgroundColor = UIColor.listForeground

        if showsAccessoryFollowButtons {
            let button = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
            button.setImage(UIImage.gridicon(.readerFollowing), for: .normal)
            button.imageView?.tintColor = UIColor.success
            button.addTarget(self, action: #selector(tappedAccessory(_:)), for: .touchUpInside)
            let unfollowSiteString = NSLocalizedString("Unfollow %@", comment: "Accessibility label for unfollowing a site")
            button.accessibilityLabel = String(format: unfollowSiteString, site.title)
            cell.accessoryView = button
            cell.accessibilityElements = [button]
        } else {
            cell.accessoryType = .disclosureIndicator
        }

        cell.textLabel?.text = site.title
        cell.detailTextLabel?.text = URL(string: site.siteURL)?.host
        cell.imageView?.downloadSiteIcon(at: site.siteBlavatar, placeholderImage: placeholderImage)

        WPStyleGuide.configureTableViewSmallSubtitleCell(cell)
        cell.layoutSubviews()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) ?? WPTableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)

        configureCell(cell, at: indexPath)
        return cell
    }


    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54.0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        guard showsSectionTitle else {
            return nil
        }

        let count = tableViewHandler.resultsController.fetchedObjects?.count ?? 0
        if count > 0 {
            return NSLocalizedString("Followed Sites", comment: "Section title for sites the user has followed.")
        }
        return nil
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        guard let site = tableViewHandler.resultsController.object(at: indexPath) as? ReaderSiteTopic else {
            return
        }
        showPostListForSite(site)
    }


    func tableView(_ tableView: UITableView,
                   canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }


    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        unfollowSiteAtIndexPath(indexPath)
    }


    func tableView(_ tableView: UITableView,
                   editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }


    func tableView(_ tableView: UITableView,
                   titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return NSLocalizedString("Unfollow", comment: "Label of the table view cell's delete button, when unfollowing a site.")
    }

    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        unfollowSiteAtIndexPath(indexPath)
    }

    func tableViewDidChangeContent(_ tableView: UITableView) {
        configureNoResultsView()

        // If we're not following any sites, reload the table view to ensure the
        // section header is no longer showing.
        if tableViewHandler.resultsController.fetchedObjects?.count == 0 {
            tableView.reloadData()
        }
    }

    @objc func tappedAccessory(_ sender: UIButton) {
        if let point = sender.superview?.convert(sender.center, to: tableView),
            let indexPath = tableView.indexPathForRow(at: point) {
            self.tableView(tableView, accessoryButtonTappedForRowWith: indexPath)
        }
    }
}

extension ReaderFollowedSitesViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let site =  searchBar.text?.trim(), !site.isEmpty {
            followSite(site)
        }
        searchBar.text = nil
        searchBar.resignFirstResponder()
    }
}
