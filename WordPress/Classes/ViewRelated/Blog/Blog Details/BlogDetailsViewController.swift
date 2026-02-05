import UIKit
import WordPressData
import WordPressKit
import WordPressShared
import WordPressUI
import Reachability
import Gridicons

public protocol BlogDetailsPresentationDelegate: AnyObject {
    func presentBlogDetailsViewController(_ viewController: UIViewController)
}

public class BlogDetailsViewController: UIViewController {

    public var blog: Blog
    public private(set) var tableView: UITableView?
    public private(set) var tableViewModel: BlogDetailsTableViewModel?
    public var isScrollEnabled = false
    public weak var presentationDelegate: BlogDetailsPresentationDelegate?
    public var isSidebarModeEnabled = false
    public weak var presentedSiteSettingsViewController: UIViewController?

    private lazy var blogService = BlogService(coreDataStack: ContextManager.shared)
    private var hasLoggedDomainCreditPromptShownEvent = false
    private(set) var showXMLRPCDisabled: Bool = false

    init(blog: Blog) {
        self.blog = blog
        self.isScrollEnabled = false
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        let tableView: UITableView
        if isSidebarModeEnabled {
            tableView = UITableView(frame: .zero, style: .grouped)
        } else if isScrollEnabled {
            tableView = UITableView(frame: .zero, style: .insetGrouped)
        } else {
            tableView = IntrinsicTableView(frame: .zero, style: .insetGrouped)
            tableView.isScrollEnabled = false
        }
        self.tableView = tableView

        tableViewModel = BlogDetailsTableViewModel(blog: blog, viewController: self)
        tableViewModel?.configure(tableView: tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false

        if isSidebarModeEnabled {
            tableView.separatorStyle = .none
            additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        }

        view.addSubview(tableView)
        view.pinSubviewToAllEdges(tableView)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pulledToRefreshTriggered), for: .valueChanged)
        tableView.refreshControl = refreshControl

        tableView.accessibilityIdentifier = "Blog Details Table"
        tableView.cellLayoutMarginsFollowReadableWidth = true

        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)

        hasLoggedDomainCreditPromptShownEvent = false
        preloadMetadata()

        if let account = blog.account, account.userID == nil {
            let service = AccountService(coreDataStack: ContextManager.shared)
            service.updateUserDetails(for: account, success: nil, failure: nil)
        }

        observeManagedObjectContextObjectsDidChangeNotification()
        observeGravatarImageUpdate()
        downloadGravatarImage()
        checkXMLRPCStatus()

        registerForTraitChanges([UITraitHorizontalSizeClass.self], action: #selector(handleTraitChanges))
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        observeWillEnterForegroundNotification()
        tableViewModel?.viewWillAppear()
        // Configure and reload table data when appearing to ensure pending comment count is updated
        configureTableViewData()
        reloadTableViewPreservingSelection()
        preloadBlogData()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        createUserActivity()

        WPAnalytics.track(.mySiteSiteMenuShown)

        if shouldShowJetpackInstallCard() {
            WPAnalytics.track(.jetpackInstallFullPluginCardViewed, properties: [WPAppAnalyticsKeyTabSource: "site_menu"])
        }

        if shouldShowBlaze() {
            BlazeEventsTracker.trackEntryPointDisplayed(for: .menuItem)
        }
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopObservingWillEnterForegroundNotification()
    }

    @objc private func handleTraitChanges() {
        configureTableViewData()
        reloadTableViewPreservingSelection()
    }

    public func reloadTableViewPreservingSelection() {
        tableViewModel?.reloadTableViewPreservingSelection()
    }

    public func configureTableViewData() {
        tableViewModel?.configureTableViewData()
    }

    public func `switch`(to blog: Blog) {
        self.blog = blog
        showInitialDetailsForBlog()
        tableView?.reloadData()
        preloadMetadata()
    }

    public func showInitialDetailsForBlog() {
        tableViewModel?.showInitialDetailsForBlog()
    }

    public func updateTableView(completion: (() -> Void)?) {
        let completionBlock = completion ?? {}
        blogService.syncBlogAndAllMetadata(blog) { [weak self] in
            self?.configureTableViewData()
            self?.reloadTableViewPreservingSelection()
            completionBlock()
        }
    }

    public func pulledToRefresh(with refreshControl: UIRefreshControl, onCompletion completion: (() -> Void)?) {
        let completionBlock = completion ?? {}
        checkXMLRPCStatus()
        updateTableView { [weak refreshControl] in
            DispatchQueue.main.async {
                refreshControl?.endRefreshing()
                completionBlock()
            }
        }
    }

    public func refresh() {
        guard let refreshControl = tableView?.refreshControl else {
            wpAssertionFailure("Can't get the UIRefreshControl instance")
            return
        }
        refreshControl.beginRefreshing()
        pulledToRefreshTriggered(refreshControl)
    }

    private func preloadBlogData() {
        // only preload on wifi
        guard ReachabilityUtils.internetReachability?.isReachableViaWiFi() == true else {
            return
        }

        preloadComments()
        preloadMetadata()
        preloadDomains()
    }

    private func preloadComments() {
        let commentService = CommentService(coreDataStack: ContextManager.shared)

        if CommentService.shouldRefreshCache(for: blog) {
            commentService.syncComments(for: blog, withStatus: CommentStatusFilterAll, success: nil, failure: nil)
        }
    }

    public func preloadMetadata() {
        blogService.syncBlogAndAllMetadata(blog) { [weak self] in
            self?.configureTableViewData()
            self?.reloadTableViewPreservingSelection()
        }
    }

    private func preloadDomains() {
        guard shouldAddDomainRegistrationRow() else {
            return
        }

        blogService.refreshDomains(for: blog, success: nil, failure: nil)
    }

    private func checkXMLRPCStatus() {
        guard blog.isSelfHosted, let xmlrpcApi = blog.xmlrpcApi,
                let username = blog.username, let password = blog.password else {
            showXMLRPCDisabled = false
            return
        }

        Task { @MainActor in
            let availability = await xmlrpcApi.isXMLRPCAvailable(username: username, password: password)
            let wasDisabled = self.showXMLRPCDisabled
            self.showXMLRPCDisabled = availability == .unavailable

            if wasDisabled != self.showXMLRPCDisabled {
                self.configureTableViewData()
                self.reloadTableViewPreservingSelection()
            }
        }
    }

    public func showRemoveSiteAlert() {
        let model = UIDevice.current.localizedModel
        let message = String(format: NSLocalizedString(
            "Are you sure you want to continue?\n All site data will be removed from your %@.",
            comment: "Title for the remove site confirmation alert, %@ will be replaced with iPhone/iPad/iPod Touch"
        ), model)

        let destructiveTitle = NSLocalizedString("Remove Site", comment: "Button to remove a site from the app")

        let alertStyle: UIAlertController.Style = UIDevice.isPad() ? .alert : .actionSheet
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: alertStyle)

        alertController.addCancelActionWithTitle(SharedStrings.Button.cancel, handler: nil)
        alertController.addDestructiveActionWithTitle(destructiveTitle) { [weak self] _ in
            self?.confirmRemoveSite()
        }

        present(alertController, animated: true)
    }

    @objc private func pulledToRefreshTriggered(_ control: UIRefreshControl) {
        pulledToRefresh(with: control, onCompletion: {})
    }

    @objc private func handleDataModelChange(_ notification: NSNotification) {
        guard let deletedObjects = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject> else {
            return
        }

        if deletedObjects.contains(blog) {
            navigationController?.popToRootViewController(animated: false)
            return
        }

        if blog.account == nil || blog.account?.isDeleted == true {
            return
        }

        guard let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> else {
            return
        }

        if updatedObjects.contains(blog) || (blog.settings != nil && updatedObjects.contains(blog.settings!)) {
            configureTableViewData()
            reloadTableViewPreservingSelection()
        }
    }

    @objc private func handleWillEnterForeground(_ notification: NSNotification) {
        configureTableViewData()
        reloadTableViewPreservingSelection()
        checkXMLRPCStatus()
    }

    private func observeManagedObjectContextObjectsDidChangeNotification() {
        let context = ContextManager.shared.mainContext
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDataModelChange(_:)),
            name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
            object: context
        )
    }

    private func observeWillEnterForegroundNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWillEnterForeground(_:)),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    private func stopObservingWillEnterForegroundNotification() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
}

extension BlogDetailsViewController: UIViewControllerTransitioningDelegate {

    public func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        if presented is FancyAlertViewController {
            return FancyAlertPresentationController(
                presentedViewController: presented,
                presenting: presenting
            )
        }
        return nil
    }

}

extension BlogDetailsViewController: UIAdaptivePresentationControllerDelegate {

    public func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        if presentationController.presentedViewController == presentedSiteSettingsViewController {
            tableView?.deselectSelectedRowWithAnimation(true)
        }
    }

}
