import UIKit
import SwiftUI
import WordPressData
import WordPressShared
import WordPressUI
import Gridicons

public protocol BlogDetailsPresentationDelegate: AnyObject {
    func presentBlogDetailsViewController(_ viewController: UIViewController)
}

public class BlogDetailsViewController: UIViewController {

    public var blog: Blog {
        didSet {
            tableViewModel?.blog = blog
        }
    }
    public private(set) var tableViewModel: BlogDetailsTableViewModel?
    public weak var presentationDelegate: BlogDetailsPresentationDelegate?
    public var isSidebarModeEnabled = false
    public weak var presentedSiteSettingsViewController: UIViewController?

    var headerViewController: UIViewController? {
        didSet { hostingController?.rootView.headerViewController = headerViewController }
    }
    lazy var onRefresh: () async -> Void = { [weak self] in
        await self?.refreshMenu()
    }

    private var hostingController: UIHostingController<BlogDetailsView>?

    private lazy var blogService = BlogService(coreDataStack: ContextManager.shared)
    private var hasLoggedDomainCreditPromptShownEvent = false

    init(blog: Blog) {
        self.blog = blog
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        let viewModel = BlogDetailsTableViewModel(blog: blog, viewController: self)
        tableViewModel = viewModel
        // Deep links need the menu actions before the view appears.
        viewModel.configureTableViewData()

        let host = UIHostingController(
            rootView: BlogDetailsView(
                viewModel: viewModel,
                headerViewController: headerViewController,
                refresh: { [weak self] in await self?.onRefresh() }
            )
        )
        hostingController = host
        host.view.backgroundColor = .clear
        add(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(host.view)

        view.backgroundColor = isSidebarModeEnabled ? .systemBackground : .systemGroupedBackground

        hasLoggedDomainCreditPromptShownEvent = false
        preloadMetadata()

        if let account = blog.account, account.userID == nil {
            let service = AccountService(coreDataStack: ContextManager.shared)
            service.updateUserDetails(for: account, success: nil, failure: nil)
        }

        observeManagedObjectContextObjectsDidChangeNotification()
        observeGravatarImageUpdate()
        downloadGravatarImage()

        registerForTraitChanges([UITraitHorizontalSizeClass.self], action: #selector(handleTraitChanges))
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        observeWillEnterForegroundNotification()
        tableViewModel?.viewWillAppear()
        // Configure and reload table data when appearing to ensure pending comment count is updated
        configureTableViewData()
        preloadBlogData()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        createUserActivity()

        WPAnalytics.track(
            .mySiteSiteMenuShown,
            properties: [
                "has_application_password": (try? blog.getApplicationToken()) != nil ? "true" : "false"
            ],
            blog: blog
        )

        if shouldShowJetpackInstallCard() {
            WPAnalytics.track(.jetpackInstallFullPluginCardViewed, properties: [WPAppAnalyticsKeyTabSource: "site_menu"])
        }

        if shouldShowBlaze() {
            BlazeEventsTracker.trackEntryPointDisplayed(for: .menuItem, blogProperties: blog.analyticsProperties)
        }
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopObservingWillEnterForegroundNotification()
    }

    @objc private func handleTraitChanges() {
        configureTableViewData()
    }

    public func configureTableViewData() {
        tableViewModel?.configureTableViewData()
    }

    public func `switch`(to blog: Blog) {
        self.blog = blog
        showInitialDetailsForBlog()
        preloadMetadata()
    }

    public func showInitialDetailsForBlog() {
        tableViewModel?.showInitialDetailsForBlog()
    }

    @MainActor
    func refreshMenu() async {
        await withCheckedContinuation { continuation in
            blogService.syncBlogAndAllMetadata(blog) {
                continuation.resume()
            }
        }

        if let service = CustomPostTypeService(blog: blog) {
            tableViewModel?.hasCustomPostTypes = (try? await service.customTypes())?.isEmpty == false
        } else {
            tableViewModel?.hasCustomPostTypes = false
        }

        configureTableViewData()
    }

    public func refresh() {
        Task { await refreshMenu() }
    }

    private func preloadBlogData() {
        // only preload on wifi
        guard ReachabilityUtils.isReachableViaWiFi() else {
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
        Task {
            await refreshMenu()
        }
    }

    private func preloadDomains() {
        guard shouldAddDomainRegistrationRow() else {
            return
        }

        blogService.refreshDomains(for: blog, success: nil, failure: nil)
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
        }
    }

    @objc private func handleWillEnterForeground(_ notification: NSNotification) {
        configureTableViewData()
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
            tableViewModel?.clearSelection()
        }
    }
}
